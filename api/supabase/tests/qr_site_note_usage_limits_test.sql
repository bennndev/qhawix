begin;
select plan(8);

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

insert into auth.users (id) values ('f0000000-0000-4000-8000-000000000001');
select set_config('request.jwt.claim.role', '', true);
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select is(public.qr_site_note_consume_quota('f0000000-0000-4000-8000-000000000001', 1), true,
  'service role from modern JSON claims can consume quota');
select is(public.qr_site_note_consume_quota('f0000000-0000-4000-8000-000000000001', 1), false,
  'a second request beyond the daily cap is rejected');
select set_config('request.jwt.claims', '{"role":"authenticated"}', true);
select throws_ok(
  $$select public.qr_site_note_consume_quota('f0000000-0000-4000-8000-000000000001', 1)$$,
  'P0001', 'service role required', 'non-service JSON claims cannot consume quota'
);

select * from finish();
rollback;
