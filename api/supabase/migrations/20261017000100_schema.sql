-- Qhawix fase 1: esquema base. Privacidad: sin audio; el numero del llamante solo como hash.

create extension if not exists pgcrypto with schema extensions;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  -- celular real +51 que recibe el <Dial>
  phone_e164 text unique check (phone_e164 is null or phone_e164 ~ '^\+[1-9][0-9]{7,14}$'),
  -- numero Qhawix (+51 9..) que marcan los externos. Fase 1: 1 DID = 1 usuario protegido
  protected_number text unique check (protected_number is null or protected_number ~ '^\+[1-9][0-9]{7,14}$'),
  consent_transcript boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  user_agent text,
  created_at timestamptz not null default now()
);
create index devices_user_idx on public.devices (user_id);

create table public.calls (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  provider_call_sid text unique,
  source text not null check (source in ('twilio', 'simulation', 'speaker')),
  from_hash text,
  status text not null default 'active' check (status in ('active', 'ended')),
  started_at timestamptz not null default now(),
  ended_at timestamptz
);
create index calls_user_started_idx on public.calls (user_id, started_at desc);

create table public.transcript_segments (
  id bigint generated always as identity primary key,
  call_id uuid not null references public.calls (id) on delete cascade,
  speaker text not null check (speaker in ('caller', 'user')),
  text text not null,
  final boolean not null default true,
  seq integer,
  at timestamptz not null default now(),
  -- retencion corta por defecto; se purga con purge_expired_segments()
  expires_at timestamptz not null default (now() + interval '24 hours')
);
create index segments_call_at_idx on public.transcript_segments (call_id, at);
create index segments_expires_idx on public.transcript_segments (expires_at);

create table public.verdicts (
  id uuid primary key default gen_random_uuid(),
  call_id uuid not null references public.calls (id) on delete cascade,
  tier text not null check (tier in ('green', 'amber', 'red')),
  score integer not null check (score between 0 and 100),
  label text not null check (label in ('benign', 'suspicious', 'scam')),
  confidence real not null,
  signals jsonb not null default '[]'::jsonb,
  reasons text[] not null default '{}',
  advice text not null default '',
  degraded text[] not null default '{}',
  engine text not null check (engine in ('rules', 'rules+llm')),
  at timestamptz not null default now()
);
create index verdicts_call_at_idx on public.verdicts (call_id, at desc);

create table public.alerts (
  id uuid primary key default gen_random_uuid(),
  call_id uuid not null references public.calls (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  tier text not null check (tier in ('amber', 'red')),
  title text not null,
  body text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);
create index alerts_user_created_idx on public.alerts (user_id, created_at desc);
create index alerts_call_idx on public.alerts (call_id);

-- Reportes anonimos de numeros (fase posterior, se deja la tabla lista). Solo hash, nunca el numero.
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  number_hash text not null,
  reporter_id uuid references public.profiles (id) on delete set null,
  kind text not null check (kind in ('extortion', 'scam', 'other')),
  created_at timestamptz not null default now()
);
create index reports_hash_idx on public.reports (number_hash, created_at desc);

-- Perfil automatico al registrarse
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Purga de transcripciones vencidas (programar con pg_cron o llamar desde una funcion)
create or replace function public.purge_expired_segments()
returns integer
language sql
security definer
set search_path = ''
as $$
  with d as (delete from public.transcript_segments where expires_at < now() returning 1)
  select count(*)::integer from d;
$$;
revoke all on function public.purge_expired_segments() from public, anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
