-- Durable per-account daily quota for qr-site-notes (Escudo QR personal notes
-- stored in Atomic Memory). Only the Edge Function, as service_role, can
-- consume it; the table keeps counters only, never note text or hosts.
create table if not exists public.qr_site_note_daily_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  usage_date date not null default (now() at time zone 'utc')::date,
  request_count integer not null default 0 check (request_count >= 0),
  primary key (user_id, usage_date)
);

alter table public.qr_site_note_daily_usage enable row level security;
revoke all on table public.qr_site_note_daily_usage from anon, authenticated;
grant all on table public.qr_site_note_daily_usage to service_role;

create or replace function public.qr_site_note_consume_quota(
  p_user_id uuid,
  p_daily_limit integer
) returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  next_count integer;
begin
  if current_setting('request.jwt.claim.role', true) is distinct from 'service_role' then
    raise exception 'service role required';
  end if;
  if p_user_id is null or p_daily_limit < 1 or p_daily_limit > 500 then
    raise exception 'invalid quota request';
  end if;

  insert into public.qr_site_note_daily_usage as daily_usage (user_id, usage_date, request_count)
  values (p_user_id, (now() at time zone 'utc')::date, 1)
  on conflict (user_id, usage_date)
  do update set request_count = daily_usage.request_count + 1
    where daily_usage.request_count < p_daily_limit
  returning request_count into next_count;

  return next_count is not null;
end;
$$;

revoke all on function public.qr_site_note_consume_quota(uuid, integer) from public, anon, authenticated;
grant execute on function public.qr_site_note_consume_quota(uuid, integer) to service_role;
