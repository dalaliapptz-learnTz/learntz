begin;
select plan(21);

-- Test 1-5: Check Table Definitions
select has_table('public', 'examination_blueprints', 'Table examination_blueprints should exist');
select has_table('public', 'generated_mock_examinations', 'Table generated_mock_examinations should exist');
select has_table('public', 'mock_examination_items', 'Table mock_examination_items should exist');
select has_table('public', 'learner_exam_attempts', 'Table learner_exam_attempts should exist');
select has_table('public', 'learner_exam_responses', 'Table learner_exam_responses should exist');

-- Test 6-8: Check Seeded Blueprints and Pilot Mock
select results_eq(
  'select count(*)::integer from public.examination_blueprints where national_examination_id in (''TZ-CSEE'', ''KE-KCSE'')',
  ARRAY[2],
  'Should have 2 official blueprints seeded (TZ-CSEE and KE-KCSE)'
);

select results_eq(
  'select count(*)::integer from public.generated_mock_examinations where id = ''60000000-0000-0000-0000-000000000001''',
  ARRAY[1],
  'Should have pilot NECTA CSEE mock exam seeded'
);

select results_eq(
  'select count(*)::integer from public.mock_examination_items where mock_exam_id = ''60000000-0000-0000-0000-000000000001''',
  ARRAY[3],
  'Should have 3 seeded items for the pilot mock exam'
);

-- Setup test users & roles
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'b6000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'parent_p4@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"P4 Parent","country_code":"TZ"}', now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000411',
    'authenticated', 'authenticated', 'curriculum_admin_runner@learntz.com', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Curriculum Admin Runner","country_code":"TZ"}', now(), now()
  )
on conflict (id) do nothing;

insert into public.user_roles (user_id, role, country_code) values
  ('00000000-0000-0000-0000-000000000411', 'curriculum_admin', 'TZ')
on conflict do nothing;

-- Create parent profile and learner
set local role authenticated;
select set_config('request.jwt.claim.sub', 'b6000000-0000-0000-0000-000000000001', true);

select set_config(
  'test.learner_id',
  (public.create_learner(
    '50000000-0000-0000-0000-000000000006',
    'Baraka',
    null,
    'Juma',
    '2010-05-15',
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

-- Test 9: Parent starts timed exam attempt for their learner
select lives_ok(
  format($$
    select public.start_learner_exam_attempt(
      '60000000-0000-0000-0000-000000000001'::uuid,
      %L::uuid
    );
  $$, current_setting('test.learner_id')),
  'Parent should be able to start timed exam attempt for their learner'
);

-- Test 10: Verify attempt record created
select results_eq(
  format($$
    select count(*)::integer from public.learner_exam_attempts
    where learner_id = %L::uuid
      and mock_exam_id = '60000000-0000-0000-0000-000000000001'
      and status = 'in_progress'
  $$, current_setting('test.learner_id')),
  ARRAY[1],
  'Should have 1 active exam attempt in progress'
);

-- Test 11-12: Verify anti-cheating payload (stripped answers & rubrics)
select ok(
  (select (public.start_learner_exam_attempt(
    '60000000-0000-0000-0000-000000000001'::uuid,
    current_setting('test.learner_id')::uuid
  )->'questions'->0 ? 'correct_answer') = false),
  'Integrity Check: correct_answer must be stripped from exam attempt payload'
);

select ok(
  (select (public.start_learner_exam_attempt(
    '60000000-0000-0000-0000-000000000001'::uuid,
    current_setting('test.learner_id')::uuid
  )->'questions'->0 ? 'rubric_guide') = false),
  'Integrity Check: rubric_guide must be stripped from exam attempt payload'
);

-- Test 13-16: Record Response & Toggle Flag
do $$
declare
  v_attempt_id uuid;
begin
  select id into v_attempt_id
  from public.learner_exam_attempts
  where learner_id = current_setting('test.learner_id')::uuid
  order by created_at desc
  limit 1;

  perform public.record_exam_response(
    v_attempt_id,
    '50000000-0000-0000-0000-000000000001'::uuid,
    'x = 3, y = -1',
    true
  );
end;
$$;

select results_eq(
  $$
    select count(*)::integer from public.learner_exam_responses
    where learner_answer = 'x = 3, y = -1' and is_flagged = true
  $$,
  ARRAY[1],
  'Should record learner answer and flagged status'
);

-- Update response (upsert)
do $$
declare
  v_attempt_id uuid;
begin
  select id into v_attempt_id
  from public.learner_exam_attempts
  where learner_id = current_setting('test.learner_id')::uuid
  order by created_at desc
  limit 1;

  perform public.record_exam_response(
    v_attempt_id,
    '50000000-0000-0000-0000-000000000001'::uuid,
    'x = 3, y = -1 (verified by substitution)',
    false
  );
end;
$$;

select results_eq(
  $$
    select learner_answer from public.learner_exam_responses
    where question_id = '50000000-0000-0000-0000-000000000001'
  $$,
  ARRAY['x = 3, y = -1 (verified by substitution)'::text],
  'Should update existing answer on conflict'
);

select results_eq(
  $$
    select is_flagged from public.learner_exam_responses
    where question_id = '50000000-0000-0000-0000-000000000001'
  $$,
  ARRAY[false],
  'Should update flagged status to false'
);

-- Test 17: Get Learner Exam Attempt (State Resume)
select ok(
  (
    select (public.get_learner_exam_attempt(
      (select id from public.learner_exam_attempts where learner_id = current_setting('test.learner_id')::uuid order by created_at desc limit 1)
    )->'responses' ? '50000000-0000-0000-0000-000000000001')
  ),
  'get_learner_exam_attempt should return saved question response'
);

-- Test 18-20: Automated Mock Generation by Curriculum Staff
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000411', true);

select lives_ok(
  $$
    select public.generate_automated_mock_exam(
      'b1000000-0000-0000-0000-000000000001'::uuid,
      'Automated Math Test Simulation 2026'
    );
  $$,
  'Curriculum admin should be able to generate automated mock exam from blueprint'
);

select results_eq(
  $$
    select count(*)::integer from public.generated_mock_examinations
    where title = 'Automated Math Test Simulation 2026'
  $$,
  ARRAY[1],
  'New mock exam should be created and recorded'
);

select is(
  (
    select status from public.generated_mock_examinations
    where title = 'Automated Math Test Simulation 2026'
  ),
  'published',
  'Generated mock exam should be in published status'
);

-- Test 21: Check generated mock exam items count
select cmp_ok(
  (
    select count(*)::integer from public.mock_examination_items mi
    join public.generated_mock_examinations me on me.id = mi.mock_exam_id
    where me.title = 'Automated Math Test Simulation 2026'
  ),
  '>=',
  1,
  'Automated mock exam should have items dynamically populated from approved questions'
);

-- Test 22: Structure config validation
select ok(
  (
    select (structure_config->0 ? 'code') from public.examination_blueprints
    where id = 'b1000000-0000-0000-0000-000000000001'
  ),
  'Blueprint structure config must have section code'
);

select * from finish();
rollback;
