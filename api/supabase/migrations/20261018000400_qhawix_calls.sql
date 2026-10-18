-- Llamadas de voz entre usuarios Qhawix, con audio en una sala LiveKit.
alter table public.calls drop constraint if exists calls_source_check;
alter table public.calls add constraint calls_source_check
  check (source in ('twilio', 'simulation', 'speaker', 'qhawix'));

create table public.qhawix_calls (
  id uuid primary key default gen_random_uuid(),
  analysis_call_id uuid not null unique references public.calls (id) on delete cascade,
  caller_id uuid not null references public.profiles (id) on delete cascade,
  callee_id uuid not null references public.profiles (id) on delete cascade,
  room_name text not null unique,
  status text not null default 'ringing' check (status in ('ringing', 'active', 'rejected', 'ended', 'missed')),
  created_at timestamptz not null default now(),
  answered_at timestamptz,
  ended_at timestamptz,
  check (caller_id <> callee_id)
);

create index qhawix_calls_callee_status_idx on public.qhawix_calls (callee_id, status, created_at desc);
create index qhawix_calls_caller_created_idx on public.qhawix_calls (caller_id, created_at desc);

alter table public.qhawix_calls enable row level security;
create policy qhawix_calls_participant_select on public.qhawix_calls for select to authenticated
  using ((select auth.uid()) in (caller_id, callee_id));
grant select on public.qhawix_calls to authenticated;

alter publication supabase_realtime add table public.qhawix_calls;
