-- pgTAP Test Suite: Phase 5 Sub-Stage 3
-- Public Sector Workspaces (Ministry, Exam Authority, Regional & District Offices)

begin;
select plan(12);

-- 1. Create a super admin user for testing public sector workspaces
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-0000-0000-000000000701',
  'authenticated', 'authenticated',
  'inspector-general@learntz.test', '', now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Inspector General","country_code":"TZ"}',
  now(), now()
);

-- Grant super_admin role
insert into public.user_roles (user_id, role, country_code)
values ('00000000-0000-0000-0000-000000000701', 'super_admin', null);

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000701', true);

-- 2. Test get_ministry_workspace_kpis RPC
select lives_ok(
  $$ select public.get_ministry_workspace_kpis('a0000000-0000-0000-0000-000000000001') $$,
  'Super admin can query Ministry of Education workspace KPIs'
);

select results_eq(
  $$ select (public.get_ministry_workspace_kpis('a0000000-0000-0000-0000-000000000001')->>'country_code')::text $$,
  $$ values ('TZ'::text) $$,
  'Ministry workspace KPI country matches TZ'
);

select is(
  ((public.get_ministry_workspace_kpis('a0000000-0000-0000-0000-000000000001')->>'total_accredited_schools')::integer >= 1),
  true,
  'Ministry workspace reports at least 1 accredited school in hierarchy'
);

select is(
  jsonb_typeof(public.get_ministry_workspace_kpis('a0000000-0000-0000-0000-000000000001')->'regional_distribution'),
  'array',
  'Ministry workspace includes regional distribution array'
);

-- 3. Test get_exam_authority_workspace_kpis RPC
select lives_ok(
  $$ select public.get_exam_authority_workspace_kpis('a0000000-0000-0000-0000-000000000002') $$,
  'Super admin can query NECTA Examination Authority workspace KPIs'
);

select results_eq(
  $$ select (public.get_exam_authority_workspace_kpis('a0000000-0000-0000-0000-000000000002')->>'authority_code')::text $$,
  $$ values ('NECTA'::text) $$,
  'Examination Authority matches authority code NECTA'
);

select is(
  ((public.get_exam_authority_workspace_kpis('a0000000-0000-0000-0000-000000000002')->>'archived_papers_count')::integer >= 1),
  true,
  'Examination Authority reports archived papers in national repository'
);

select is(
  jsonb_typeof(public.get_exam_authority_workspace_kpis('a0000000-0000-0000-0000-000000000002')->'recent_papers'),
  'array',
  'Examination Authority reports recent examination papers array'
);

-- 4. Test get_governance_office_workspace_kpis RPC
select lives_ok(
  $$ select public.get_governance_office_workspace_kpis('a0000000-0000-0000-0000-000000000003') $$,
  'Can query Dar es Salaam Regional Office KPIs'
);

select results_eq(
  $$ select (public.get_governance_office_workspace_kpis('a0000000-0000-0000-0000-000000000003')->>'office_type')::text $$,
  $$ values ('regional_office'::text) $$,
  'Office type matches regional_office'
);

select lives_ok(
  $$ select public.get_governance_office_workspace_kpis('a0000000-0000-0000-0000-000000000004') $$,
  'Can query Ilala District Office KPIs'
);

select results_eq(
  $$ select (public.get_governance_office_workspace_kpis('a0000000-0000-0000-0000-000000000004')->>'office_type')::text $$,
  $$ values ('district_office'::text) $$,
  'Office type matches district_office'
);

select * from finish();
rollback;
