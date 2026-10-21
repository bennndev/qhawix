begin;

-- Provider caches and quota counters are disposable, not incident evidence.
delete from private.qr_reputation_match_cache;
delete from private.qr_gateway_quota_windows;

alter table private.qr_gateway_config
  drop constraint qr_gateway_config_schema_version_check,
  drop constraint qr_gateway_config_provider_id_check,
  drop constraint qr_gateway_config_threat_types_check,
  add column per_hour_limit integer not null default 50 check (per_hour_limit > 0);

update private.qr_gateway_config
set schema_version = 2, provider_id = 'urlscan_v1',
    threat_types = array['URLSCAN_VERDICT'],
    per_minute_limit = 5, per_hour_limit = 50,
    per_day_limit = 50, per_month_limit = 1500, updated_at = now()
where singleton = true;

alter table private.qr_gateway_config
  add constraint qr_gateway_schema_v2_check check (schema_version = 2),
  add constraint qr_gateway_urlscan_provider_check check (provider_id = 'urlscan_v1'),
  add constraint qr_gateway_urlscan_scope_check check (threat_types = array['URLSCAN_VERDICT']);

alter table private.qr_gateway_quota_windows
  drop constraint qr_gateway_quota_windows_bucket_check,
  add constraint qr_gateway_quota_bucket_check check (bucket in ('minute', 'hour', 'day', 'month'));

-- Replace both generated category constraints while retaining other cache checks.
do $$
declare constraint_name text;
begin
  for constraint_name in
    select conname from pg_constraint
    where conrelid = 'private.qr_reputation_match_cache'::regclass
      and contype = 'c' and pg_get_constraintdef(oid) like '%categories%'
  loop
    execute format('alter table private.qr_reputation_match_cache drop constraint %I', constraint_name);
  end loop;
end;
$$;

alter table private.qr_reputation_match_cache
  add constraint qr_cache_urlscan_categories_check check (
    cardinality(categories) > 0 and
    array_position(categories, null) is null and
    categories <@ array['URLSCAN_MALICIOUS', 'URLSCAN_PHISHING']::text[]
  );

create or replace function public.qr_gateway_get_config()
returns jsonb language sql security definer
set search_path = pg_catalog, private
as $$
  select jsonb_build_object(
    'schemaVersion', schema_version, 'provider', provider_id, 'threatTypes', threat_types,
    'perMinuteLimit', per_minute_limit, 'perHourLimit', per_hour_limit,
    'perDayLimit', per_day_limit, 'perMonthLimit', per_month_limit
  ) from private.qr_gateway_config where singleton = true;
$$;

create or replace function public.qr_consume_reputation_quota()
returns jsonb language plpgsql security definer
set search_path = pg_catalog, private
as $$
declare
  v_config private.qr_gateway_config%rowtype;
  v_now timestamptz := clock_timestamp();
  v_window record;
  v_count integer;
begin
  perform pg_advisory_xact_lock(hashtext('qhawix.qr_reputation_global_quota'));
  select * into v_config from private.qr_gateway_config where singleton = true;
  if not found then return jsonb_build_object('allowed', false, 'code', 'not_configured'); end if;

  delete from private.qr_gateway_quota_windows
  where (bucket in ('minute', 'hour') and window_start < v_now - interval '2 days')
     or (bucket = 'day' and window_start < v_now - interval '35 days')
     or (bucket = 'month' and window_start < v_now - interval '13 months');

  for v_window in select * from (values
    ('minute', date_trunc('minute', v_now at time zone 'UTC') at time zone 'UTC', interval '1 minute', v_config.per_minute_limit),
    ('hour', date_trunc('hour', v_now at time zone 'UTC') at time zone 'UTC', interval '1 hour', v_config.per_hour_limit),
    ('day', date_trunc('day', v_now at time zone 'UTC') at time zone 'UTC', interval '1 day', v_config.per_day_limit),
    ('month', date_trunc('month', v_now at time zone 'UTC') at time zone 'UTC', interval '1 month', v_config.per_month_limit)
  ) as windows(bucket, started_at, duration, quota)
  loop
    select request_count into v_count from private.qr_gateway_quota_windows
    where bucket = v_window.bucket and window_start = v_window.started_at;
    if coalesce(v_count, 0) >= v_window.quota then
      return jsonb_build_object('allowed', false,
        'code', case when v_window.bucket in ('minute', 'hour') then 'rate_limited' else 'quota_exhausted' end,
        'retryAfterSeconds', greatest(1, ceil(extract(epoch from (v_window.started_at + v_window.duration - v_now)))::integer));
    end if;
  end loop;

  insert into private.qr_gateway_quota_windows (bucket, window_start, request_count)
  values
    ('minute', date_trunc('minute', v_now at time zone 'UTC') at time zone 'UTC', 1),
    ('hour', date_trunc('hour', v_now at time zone 'UTC') at time zone 'UTC', 1),
    ('day', date_trunc('day', v_now at time zone 'UTC') at time zone 'UTC', 1),
    ('month', date_trunc('month', v_now at time zone 'UTC') at time zone 'UTC', 1)
  on conflict (bucket, window_start) do update
  set request_count = private.qr_gateway_quota_windows.request_count + 1;
  return jsonb_build_object('allowed', true);
end;
$$;

create or replace function public.qr_store_reputation_match(
  p_cache_key text, p_categories text[],
  p_provider_checked_at timestamptz, p_provider_expires_at timestamptz
)
returns boolean language plpgsql security definer
set search_path = pg_catalog, private
as $$
begin
  if p_cache_key is null or p_cache_key !~ '^[0-9a-f]{64}$'
     or p_categories is null or cardinality(p_categories) = 0
     or array_position(p_categories, null) is not null
     or not (p_categories <@ array['URLSCAN_MALICIOUS', 'URLSCAN_PHISHING']::text[])
     or p_provider_checked_at is null or p_provider_checked_at > clock_timestamp()
     or p_provider_expires_at is null or p_provider_expires_at <= p_provider_checked_at
     or p_provider_expires_at > p_provider_checked_at + interval '5 minutes'
     or p_provider_expires_at <= clock_timestamp() then
    return false;
  end if;

  insert into private.qr_reputation_match_cache (cache_key, categories, provider_checked_at, expires_at)
  values (p_cache_key, array(select distinct category from unnest(p_categories) as category order by category),
          p_provider_checked_at, p_provider_expires_at)
  on conflict (cache_key) do update set categories = excluded.categories,
    provider_checked_at = excluded.provider_checked_at, expires_at = excluded.expires_at, created_at = now();
  return true;
end;
$$;

-- Existing functions remain privileged server operations; the public app key grants no access.
revoke all on function public.qr_gateway_get_config() from public, anon, authenticated;
revoke all on function public.qr_consume_reputation_quota() from public, anon, authenticated;
revoke all on function public.qr_store_reputation_match(text, text[], timestamptz, timestamptz) from public, anon, authenticated;
grant execute on function public.qr_gateway_get_config() to service_role;
grant execute on function public.qr_consume_reputation_quota() to service_role;
grant execute on function public.qr_store_reputation_match(text, text[], timestamptz, timestamptz) to service_role;

commit;
