-- ============================================================================
-- Test Suite: phase2_dashboards_and_explorer.test.sql
-- Description: Tests get_parent_dashboard_overview, get_learner_dashboard_data,
--              and get_curriculum_explorer_tree RPCs.
-- ============================================================================

begin;
select plan(14);

-- 1. Function existence
select has_function('public', 'get_parent_dashboard_overview', ARRAY[]::text[], 'get_parent_dashboard_overview should exist');
select has_function('public', 'get_learner_dashboard_data', ARRAY['uuid'], 'get_learner_dashboard_data should exist');
select has_function('public', 'get_curriculum_explorer_tree', ARRAY['text', 'uuid', 'uuid', 'uuid'], 'get_curriculum_explorer_tree should exist');

-- 2. Unauthenticated calls are blocked for parent & learner dashboard
select throws_ok(
  $$ select public.get_parent_dashboard_overview() $$,
  '28000',
  'Authentication is required',
  'Anonymous get_parent_dashboard_overview throws 28000'
);

select throws_ok(
  $$ select public.get_learner_dashboard_data('20000000-0000-0000-0000-000000000001'::uuid) $$,
  '28000',
  'Authentication is required',
  'Anonymous get_learner_dashboard_data throws 28000'
);

-- 3. Anonymous can call get_curriculum_explorer_tree
select lives_ok(
  $$ select public.get_curriculum_explorer_tree('TZ', '20000000-0000-0000-0000-000000000001'::uuid) $$,
  'Anonymous can query curriculum explorer tree'
);

select is(
  jsonb_typeof(public.get_curriculum_explorer_tree('TZ', '20000000-0000-0000-0000-000000000001'::uuid)),
  'array',
  'Curriculum explorer tree returns an array of subjects'
);

-- 4. Setup Test Parent and Learner
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'a1000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'parent_p2@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Mwalimu Parent","country_code":"TZ"}', now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'a1000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'stranger_p2@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Stranger Parent","country_code":"TZ"}', now(), now()
  )
on conflict (id) do nothing;

-- 5. Create learner as authorized parent
set local role authenticated;
select set_config('request.jwt.claim.sub', 'a1000000-0000-0000-0000-000000000001', true);

select set_config(
  'test.learner_id',
  (public.create_learner(
    '40000000-0000-0000-0000-000000000001',
    'Baraka',
    null,
    'Parent',
    '2016-05-10',
    null,
    'TZ',
    '20000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    (select id from public.education_grades where code = 'STANDARD_1'),
    null
  )).id::text,
  true
);

-- 6. Test as stranger: stranger cannot access learner dashboard data
select set_config('request.jwt.claim.sub', 'a1000000-0000-0000-0000-000000000002', true);

select throws_ok(
  format('select public.get_learner_dashboard_data(%L::uuid)', current_setting('test.learner_id')),
  '42501',
  'Authorized parent access is required for this learner',
  'Unauthorized parent cannot view learner dashboard data'
);

select is(
  public.get_parent_dashboard_overview(),
  '[]'::jsonb,
  'Parent with no learners receives empty array from get_parent_dashboard_overview'
);

-- 7. Test as authorized parent
select set_config('request.jwt.claim.sub', 'a1000000-0000-0000-0000-000000000001', true);

select is(
  jsonb_array_length(public.get_parent_dashboard_overview()),
  1,
  'Authorized parent gets 1 learner in overview'
);

select is(
  (public.get_parent_dashboard_overview() -> 0 ->> 'first_name'),
  'Baraka',
  'Overview contains Baraka'
);

select is(
  (public.get_learner_dashboard_data(current_setting('test.learner_id')::uuid) ->> 'full_name'),
  'Baraka Parent',
  'Learner dashboard returns Baraka Parent'
);

select is(
  (public.get_learner_dashboard_data(current_setting('test.learner_id')::uuid) -> 'academic_calendar' ->> 'name'),
  'Mwaka wa Masomo 2026',
  'Learner dashboard embeds active 2026 academic calendar'
);

select is(
  (public.get_learner_dashboard_data(current_setting('test.learner_id')::uuid) ->> 'daily_target_lessons')::int,
  1,
  'Learner dashboard has daily target of 1 lesson'
);

select * from finish();
rollback;
