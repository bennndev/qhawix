begin;

create index if not exists qr_reputation_match_cache_expires_at_idx
  on private.qr_reputation_match_cache (expires_at);

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

  with expired as (
    select cache_key
    from private.qr_reputation_match_cache
    where expires_at <= clock_timestamp()
    order by expires_at
    limit 100
    for update skip locked
  )
  delete from private.qr_reputation_match_cache as cache
  using expired
  where cache.cache_key = expired.cache_key;

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

  with expired as (
    select cache_key
    from private.qr_reputation_match_cache
    where expires_at <= clock_timestamp()
    order by expires_at
    limit 100
    for update skip locked
  )
  delete from private.qr_reputation_match_cache as cache
  using expired
  where cache.cache_key = expired.cache_key;

  return true;
end;
$$;

revoke all on function public.qr_get_reputation_match(text) from public, anon, authenticated;
revoke all on function public.qr_store_reputation_match(text, text[], timestamptz, timestamptz) from public, anon, authenticated;
grant execute on function public.qr_get_reputation_match(text) to service_role;
grant execute on function public.qr_store_reputation_match(text, text[], timestamptz, timestamptz) to service_role;

commit;
