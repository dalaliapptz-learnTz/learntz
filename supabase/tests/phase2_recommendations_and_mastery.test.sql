begin;
select plan(15);

-- 1. Schema structure checks
select has_table('public', 'learner_recommendations', 'learner_recommendations table exists');
select has_column('public', 'learner_recommendations', 'recommendation_type', 'has recommendation_type column');
select has_column('public', 'learner_recommendations', 'is_dismissed', 'has is_dismissed column');
select has_column('public', 'learner_recommendations', 'priority', 'has priority column');

-- 2. Test setup: Auth users
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'c1000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'parent_rec@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Rec Parent","country_code":"TZ"}', now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'c1000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'stranger_rec@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Stranger Parent","country_code":"TZ"}', now(), now()
  )
on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'c1000000-0000-0000-0000-000000000001', true);

-- Create learner
select set_config(
  'test.learner_id',
  (public.create_learner(
    '60000000-0000-0000-0000-000000000001',
    'Rehema',
    null,
    'Tester',
    '2016-09-12',
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

-- Stranger cannot access recommendations
select set_config('request.jwt.claim.sub', 'c1000000-0000-0000-0000-000000000002', true);

select throws_ok(
  format('select public.get_learner_recommendations(%L::uuid)', current_setting('test.learner_id')),
  '42501',
  'Authorized parent access is required for this learner',
  'Stranger cannot access learner recommendations'
);

select throws_ok(
  format('select public.get_learner_mastery_report(%L::uuid)', current_setting('test.learner_id')),
  '42501',
  'Authorized parent access is required for this learner',
  'Stranger cannot access learner mastery report'
);

-- Switch back to authorized parent
select set_config('request.jwt.claim.sub', 'c1000000-0000-0000-0000-000000000001', true);

-- Seed topic mastery: 1 weak topic (<60%)
insert into public.learner_topic_mastery (
  learner_id, topic_id, mastery_status, accuracy_rate, quizzes_attempted, best_score_percent, last_practiced_at
) values (
  current_setting('test.learner_id')::uuid,
  '30000000-0000-0000-0000-000000000201',
  'in_progress',
  40.00,
  1,
  40,
  now()
);

-- Test get_learner_recommendations generates a remedial recommendation
select is(
  (
    select count(*)::integer
    from jsonb_array_elements(public.get_learner_recommendations(current_setting('test.learner_id')::uuid))
  ),
  1,
  'get_learner_recommendations generates 1 recommendation for weak topic'
);

select is(
  (public.get_learner_recommendations(current_setting('test.learner_id')::uuid) -> 0 ->> 'recommendation_type'),
  'remedial',
  'Weak topic creates a remedial recommendation'
);

-- Store recommendation id
select set_config(
  'test.rec_id',
  (public.get_learner_recommendations(current_setting('test.learner_id')::uuid) -> 0 ->> 'id'),
  true
);

-- Dismiss recommendation
select is(
  public.dismiss_learner_recommendation(
    current_setting('test.learner_id')::uuid,
    current_setting('test.rec_id')::uuid
  ),
  true,
  'dismiss_learner_recommendation successfully dismisses recommendation'
);

select is(
  (
    select count(*)::integer
    from jsonb_array_elements(public.get_learner_recommendations(current_setting('test.learner_id')::uuid))
  ),
  0,
  'Dismissed recommendation is excluded from active recommendations'
);

-- Test Mastery Report
select is(
  (public.get_learner_mastery_report(current_setting('test.learner_id')::uuid) ->> 'learner_id'),
  current_setting('test.learner_id'),
  'get_learner_mastery_report returns correct learner_id'
);

select cmp_ok(
  (public.get_learner_mastery_report(current_setting('test.learner_id')::uuid) ->> 'total_topics')::integer,
  '>=',
  1,
  'Mastery report includes curriculum topics count'
);

select is(
  (public.get_learner_mastery_report(current_setting('test.learner_id')::uuid) ->> 'in_progress_topics')::integer,
  1,
  'Mastery report reflects 1 in_progress topic'
);

select cmp_ok(
  (public.get_learner_mastery_report(current_setting('test.learner_id')::uuid) ->> 'readiness_index')::integer,
  '>=',
  0,
  'Readiness index calculated'
);

select is(
  jsonb_typeof(public.get_learner_mastery_report(current_setting('test.learner_id')::uuid) -> 'subjects_breakdown'),
  'array',
  'Mastery report includes subjects breakdown array'
);

select * from finish();
rollback;
