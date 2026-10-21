begin;
select plan(5);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.qr_site_note_daily_usage'::regclass),
  'quota table has RLS enabled'
);
select ok(
  not has_table_privilege('anon', 'public.qr_site_note_daily_usage', 'select'),
  'anon cannot read quota counters'
);
select ok(
  not has_table_privilege('authenticated', 'public.qr_site_note_daily_usage', 'select'),
  'authenticated users cannot read quota counters'
);
select ok(
  not has_function_privilege('authenticated', 'public.qr_site_note_consume_quota(uuid, integer)', 'execute'),
  'authenticated users cannot consume quota directly'
);
select ok(
  has_function_privilege('service_role', 'public.qr_site_note_consume_quota(uuid, integer)', 'execute'),
  'the Edge Function role can consume quota'
);

select * from finish();
rollback;
