-- RLS: cada usuario ve solo lo suyo. Las Edge Functions escriben con service_role (bypass RLS).

alter table public.profiles enable row level security;
alter table public.devices enable row level security;
alter table public.calls enable row level security;
alter table public.transcript_segments enable row level security;
alter table public.verdicts enable row level security;
alter table public.alerts enable row level security;
alter table public.reports enable row level security;

create policy profiles_select_own on public.profiles for select to authenticated
  using ((select auth.uid()) = id);
-- El usuario edita su nombre, celular y consentimiento; protected_number lo asigna el admin
create policy profiles_update_own on public.profiles for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
revoke update on public.profiles from authenticated;
grant update (display_name, phone_e164, consent_transcript) on public.profiles to authenticated;

create policy devices_all_own on public.devices for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy calls_select_own on public.calls for select to authenticated
  using ((select auth.uid()) = user_id);

create policy segments_select_own on public.transcript_segments for select to authenticated
  using (exists (select 1 from public.calls c where c.id = call_id and c.user_id = (select auth.uid())));

create policy verdicts_select_own on public.verdicts for select to authenticated
  using (exists (select 1 from public.calls c where c.id = call_id and c.user_id = (select auth.uid())));

create policy alerts_select_own on public.alerts for select to authenticated
  using ((select auth.uid()) = user_id);
create policy alerts_update_own on public.alerts for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
revoke update on public.alerts from authenticated;
grant update (read_at) on public.alerts to authenticated;

-- reports: sin politicas para clientes. Solo service_role (aplicacion futura via funcion).

-- Realtime: la PWA escucha cambios de sus propias llamadas
alter publication supabase_realtime add table public.calls, public.transcript_segments, public.verdicts, public.alerts;
