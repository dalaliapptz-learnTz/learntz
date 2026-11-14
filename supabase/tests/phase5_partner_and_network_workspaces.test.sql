begin;
select plan(14);

-- Test 1: Function exists checks
select has_function('public', 'get_school_network_workspace_kpis', ARRAY['uuid'], 'get_school_network_workspace_kpis function exists');
select has_function('public', 'get_research_institution_workspace_kpis', ARRAY['uuid'], 'get_research_institution_workspace_kpis function exists');
select has_function('public', 'get_development_partner_workspace_kpis', ARRAY['uuid'], 'get_development_partner_workspace_kpis function exists');
select has_function('public', 'export_anonymized_research_dataset', ARRAY['uuid', 'text'], 'export_anonymized_research_dataset function exists');

-- Create a test super_admin user
insert into auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  aud,
  role
) values (
  '00000000-0000-0000-0000-000000000801',
  'superadmin_partner_test@learntz.test',
  '',
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"full_name":"Super Admin Partner Tester"}'::jsonb,
  now(),
  now(),
  'authenticated',
  'authenticated'
) on conflict (id) do nothing;

insert into public.user_roles (user_id, role, country_code)
values ('00000000-0000-0000-0000-000000000801', 'super_admin', null)
on conflict do nothing;

-- Test 2: Unauthenticated query throws 42501
select throws_matching(
  $$ select public.get_school_network_workspace_kpis('d0000000-0000-0000-0000-000000000003') $$,
  'Authentication required',
  'Unauthenticated query to school network workspace fails'
);

-- Set authenticated session for super admin
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000801', true);

-- Test 3: Super admin queries School Network KPIs
select lives_ok(
  $$ select public.get_school_network_workspace_kpis('d0000000-0000-0000-0000-000000000003') $$,
  'Super admin can query School Network workspace KPIs'
);

select results_eq(
  $$ select (public.get_school_network_workspace_kpis('d0000000-0000-0000-0000-000000000003')->>'network_name')::text $$,
  $$ values ('Feza Schools Network'::text) $$,
  'School Network returns correct network name'
);

-- Test 4: Super admin queries Research Institution KPIs
select lives_ok(
  $$ select public.get_research_institution_workspace_kpis('d0000000-0000-0000-0000-000000000002') $$,
  'Super admin can query Research Institution workspace KPIs'
);

select results_eq(
  $$ select (public.get_research_institution_workspace_kpis('d0000000-0000-0000-0000-000000000002')->>'institution_name')::text $$,
  $$ values ('East African Institute of Educational Research'::text) $$,
  'Research Institution returns correct institution name'
);

-- Test 5: Super admin queries Development Partner KPIs
select lives_ok(
  $$ select public.get_development_partner_workspace_kpis('d0000000-0000-0000-0000-000000000001') $$,
  'Super admin can query Development Partner workspace KPIs'
);

select results_eq(
  $$ select (public.get_development_partner_workspace_kpis('d0000000-0000-0000-0000-000000000001')->>'partner_name')::text $$,
  $$ values ('UNICEF East Africa Education Initiative'::text) $$,
  'Development Partner returns correct partner name'
);

-- Test 6: Wrong organization type throws 22023
select throws_matching(
  $$ select public.get_school_network_workspace_kpis('a0000000-0000-0000-0000-000000000001') $$,
  'is not a school network entity',
  'Passing ministry org to school network throws 22023'
);

-- Test 7: Export Anonymized Research Dataset
select lives_ok(
  $$ select public.export_anonymized_research_dataset('d0000000-0000-0000-0000-000000000002', 'TZ_2025_CSEE_STEM_ANON') $$,
  'Research staff can export anonymized dataset'
);

select results_eq(
  $$ select count(*)::integer from public.research_export_logs where organization_id = 'd0000000-0000-0000-0000-000000000002' $$,
  $$ values (1::integer) $$,
  'Research export log entry was created with audit tracking'
);

select * from finish();
rollback;
