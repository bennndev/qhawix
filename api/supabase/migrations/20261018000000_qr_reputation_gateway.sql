begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to service_role;

create table private.qr_gateway_config (
  singleton boolean primary key default true check (singleton),
  schema_version integer not null check (schema_version = 1),
  provider_id text not null check (provider_id = 'google_web_risk_lookup'),
  threat_types text[] not null,
  per_minute_limit integer not null check (per_minute_limit > 0),
  per_day_limit integer not null check (per_day_limit > 0),
  per_month_limit integer not null check (per_month_limit > 0),
  updated_at timestamptz not null default now(),
  check (threat_types <@ array['MALWARE', 'SOCIAL_ENGINEERING', 'UNWANTED_SOFTWARE']::text[])
);

insert into private.qr_gateway_config (
  singleton,
  schema_version,
  provider_id,
  threat_types,
  per_minute_limit,
  per_day_limit,
  per_month_limit
)
values (
  true,
  1,
  'google_web_risk_lookup',
  array['MALWARE', 'SOCIAL_ENGINEERING', 'UNWANTED_SOFTWARE'],
  2,
  3000,
  90000
)
on conflict (singleton) do nothing;

create table private.qr_gateway_quota_windows (
  bucket text not null check (bucket in ('minute', 'day', 'month')),
  window_start timestamptz not null,
  request_count integer not null check (request_count >= 0),
  primary key (bucket, window_start)
);

create table private.qr_reputation_match_cache (
  cache_key text primary key check (cache_key ~ '^[0-9a-f]{64}$'),
  categories text[] not null,
  provider_checked_at timestamptz not null,
  expires_at timestamptz not null check (expires_at > provider_checked_at),
  created_at timestamptz not null default now(),
  check (cardinality(categories) > 0),
  check (categories <@ array['MALWARE', 'SOCIAL_ENGINEERING', 'UNWANTED_SOFTWARE']::text[])
);

alter table private.qr_gateway_config enable row level security;
alter table private.qr_gateway_quota_windows enable row level security;
alter table private.qr_reputation_match_cache enable row level security;

create or replace function public.qr_gateway_get_config()
returns jsonb
language sql
security definer
set search_path = pg_catalog, private
as $$
  select jsonb_build_object(
    'schemaVersion', schema_version,
    'provider', provider_id,
    'threatTypes', threat_types,
    'perMinuteLimit', per_minute_limit,
    'perDayLimit', per_day_limit,
    'perMonthLimit', per_month_limit
  )
  from private.qr_gateway_config
  where singleton = true;
$$;

create or replace function public.qr_consume_reputation_quota()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, private
as $$
declare
  v_config private.qr_gateway_config%rowtype;
  v_now timestamptz := clock_timestamp();
  v_minute timestamptz;
  v_day timestamptz;
  v_month timestamptz;
  v_count integer;
  v_retry integer;
begin
  perform pg_advisory_xact_lock(hashtext('qhawix.qr_reputation_global_quota'));

  select * into v_config
  from private.qr_gateway_config
  where singleton = true;

  if not found then
    return jsonb_build_object('allowed', false, 'code', 'not_configured');
  end if;

  v_minute := date_trunc('minute', v_now at time zone 'UTC') at time zone 'UTC';
  v_day := date_trunc('day', v_now at time zone 'UTC') at time zone 'UTC';
  v_month := date_trunc('month', v_now at time zone 'UTC') at time zone 'UTC';

  delete from private.qr_gateway_quota_windows
  where (bucket = 'minute' and window_start < v_now - interval '2 days')
     or (bucket = 'day' and window_start < v_now - interval '35 days')
     or (bucket = 'month' and window_start < v_now - interval '13 months');

  select coalesce(request_count, 0) into v_count
  from private.qr_gateway_quota_windows
  where bucket = 'minute' and window_start = v_minute;
  if coalesce(v_count, 0) >= v_config.per_minute_limit then
    v_retry := greatest(1, ceil(extract(epoch from (v_minute + interval '1 minute' - v_now)))::integer);
    return jsonb_build_object('allowed', false, 'code', 'rate_limited', 'retryAfterSeconds', v_retry);
  end if;

  select coalesce(request_count, 0) into v_count
  from private.qr_gateway_quota_windows
  where bucket = 'day' and window_start = v_day;
  if coalesce(v_count, 0) >= v_config.per_day_limit then
    v_retry := greatest(1, ceil(extract(epoch from (v_day + interval '1 day' - v_now)))::integer);
    return jsonb_build_object('allowed', false, 'code', 'quota_exhausted', 'retryAfterSeconds', v_retry);
  end if;

  select coalesce(request_count, 0) into v_count
  from private.qr_gateway_quota_windows
  where bucket = 'month' and window_start = v_month;
  if coalesce(v_count, 0) >= v_config.per_month_limit then
    v_retry := greatest(1, ceil(extract(epoch from (v_month + interval '1 month' - v_now)))::integer);
    return jsonb_build_object('allowed', false, 'code', 'quota_exhausted', 'retryAfterSeconds', v_retry);
  end if;

  insert into private.qr_gateway_quota_windows (bucket, window_start, request_count)
  values ('minute', v_minute, 1), ('day', v_day, 1), ('month', v_month, 1)
  on conflict (bucket, window_start)
  do update set request_count = private.qr_gateway_quota_windows.request_count + 1;

  return jsonb_build_object('allowed', true);
end;
$$;

create or replace function public.qr_get_reputation_match(p_cache_key text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, private
as $$
declare
  v_match private.qr_reputation_match_cache%rowtype;
begin
  if p_cache_key !~ '^[0-9a-f]{64}$' then
    return null;
  end if;

  delete from private.qr_reputation_match_cache
  where expires_at <= clock_timestamp();

  select * into v_match
  from private.qr_reputation_match_cache
  where cache_key = p_cache_key and expires_at > clock_timestamp();

  if not found then
    return null;
  end if;

  return jsonb_build_object(
    'categories', v_match.categories,
    'providerCheckedAt', v_match.provider_checked_at,
    'providerExpiresAt', v_match.expires_at
  );
end;
$$;

create or replace function public.qr_store_reputation_match(
  p_cache_key text,
  p_categories text[],
  p_provider_checked_at timestamptz,
  p_provider_expires_at timestamptz
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, private
as $$
begin
  if p_cache_key !~ '^[0-9a-f]{64}$'
     or cardinality(p_categories) = 0
     or not (p_categories <@ array['MALWARE', 'SOCIAL_ENGINEERING', 'UNWANTED_SOFTWARE']::text[])
     or p_provider_checked_at is null
     or p_provider_expires_at is null
     or p_provider_expires_at <= p_provider_checked_at
     or p_provider_expires_at <= clock_timestamp() then
    return false;
  end if;

  insert into private.qr_reputation_match_cache (
    cache_key,
    categories,
    provider_checked_at,
    expires_at
  )
  values (
    p_cache_key,
    array(select distinct category from unnest(p_categories) as category order by category),
    p_provider_checked_at,
    p_provider_expires_at
  )
  on conflict (cache_key) do update set
    categories = excluded.categories,
    provider_checked_at = excluded.provider_checked_at,
    expires_at = excluded.expires_at,
    created_at = now();

  delete from private.qr_reputation_match_cache
  where expires_at <= clock_timestamp();

  return true;
end;
$$;

revoke all on function public.qr_gateway_get_config() from public, anon, authenticated;
revoke all on function public.qr_consume_reputation_quota() from public, anon, authenticated;
revoke all on function public.qr_get_reputation_match(text) from public, anon, authenticated;
revoke all on function public.qr_store_reputation_match(text, text[], timestamptz, timestamptz) from public, anon, authenticated;
grant execute on function public.qr_gateway_get_config() to service_role;
grant execute on function public.qr_consume_reputation_quota() to service_role;
grant execute on function public.qr_get_reputation_match(text) to service_role;
grant execute on function public.qr_store_reputation_match(text, text[], timestamptz, timestamptz) to service_role;

commit;
