-- Hace atómico el inicio de llamada y evita llamadas a una persona ocupada.
-- Las Edge Functions llaman este RPC con service_role; no se expone a clientes.
create or replace function public.start_qhawix_call(p_caller_id uuid, p_phone text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_callee public.profiles%rowtype;
  v_call_id uuid := gen_random_uuid();
  v_analysis_call_id uuid := gen_random_uuid();
  v_first_lock bigint;
  v_second_lock bigint;
begin
  if p_phone is null or p_phone !~ '^\+[1-9][0-9]{7,14}$' then
    raise exception using errcode = '22023', message = 'invalid_phone';
  end if;

  select * into v_callee from public.profiles where phone_e164 = p_phone;
  if not found then
    raise exception using errcode = 'P0002', message = 'user_not_found';
  end if;
  if v_callee.id = p_caller_id then
    raise exception using errcode = '22023', message = 'cannot_call_self';
  end if;

  -- Bloquea ambos usuarios en orden estable. Una segunda solicitud simultánea
  -- espera y vuelve a comprobar el estado dentro de su propia transacción.
  v_first_lock := hashtextextended(least(p_caller_id::text, v_callee.id::text), 0);
  v_second_lock := hashtextextended(greatest(p_caller_id::text, v_callee.id::text), 0);
  perform pg_advisory_xact_lock(v_first_lock);
  perform pg_advisory_xact_lock(v_second_lock);

  if exists (
    select 1 from public.qhawix_calls c
    where c.status in ('ringing', 'active')
      and (c.caller_id in (p_caller_id, v_callee.id) or c.callee_id in (p_caller_id, v_callee.id))
  ) then
    raise exception using errcode = '55000', message = 'user_busy';
  end if;

  insert into public.calls (id, user_id, source) values (v_analysis_call_id, v_callee.id, 'qhawix');
  insert into public.qhawix_calls (id, analysis_call_id, caller_id, callee_id, room_name)
  values (v_call_id, v_analysis_call_id, p_caller_id, v_callee.id, 'qhawix-' || v_call_id::text);

  return jsonb_build_object(
    'call_id', v_call_id,
    'status', 'ringing',
    'callee_id', v_callee.id,
    'callee_name', coalesce(v_callee.display_name, 'Usuario Qhawix')
  );
end;
$$;

revoke all on function public.start_qhawix_call(uuid, text) from public, anon, authenticated;
grant execute on function public.start_qhawix_call(uuid, text) to service_role;
