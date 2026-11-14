begin;
select plan(16);

-- Test 1: Check Table Definition
select has_table('public', 'learner_exam_results', 'Table learner_exam_results should exist');
select has_function('public', 'submit_and_grade_exam_attempt', ARRAY['uuid'], 'submit_and_grade_exam_attempt should exist');
select has_function('public', 'get_exam_attempt_results', ARRAY['uuid'], 'get_exam_attempt_results should exist');

-- Setup test users, learner, and attempt
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'b7000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'parent_p4_marking@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"P4 Marking Parent","country_code":"TZ"}', now(), now()
  )
on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'b7000000-0000-0000-0000-000000000001', true);

-- Create Learner
select set_config(
  'test.learner_id',
  (public.create_learner(
    '50000000-0000-0000-0000-000000000007',
    'Amani',
    null,
    'Bakari',
    '2010-02-10',
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

-- Start Exam Attempt
select set_config(
  'test.attempt_id',
  (
    select (public.start_learner_exam_attempt(
      '60000000-0000-0000-0000-000000000001'::uuid,
      current_setting('test.learner_id')::uuid
    )->>'attempt_id')
  ),
  true
);

-- Record Responses: Q1 correct, Q2 incorrect
select lives_ok(
  format($$
    select public.record_exam_response(
      %L::uuid,
      '50000000-0000-0000-0000-000000000001'::uuid,
      'x = 3, y = -1',
      false
    );
  $$, current_setting('test.attempt_id')),
  'Should record learner response for Q1'
);

select lives_ok(
  format($$
    select public.record_exam_response(
      %L::uuid,
      '50000000-0000-0000-0000-000000000002'::uuid,
      'x = 99',
      false
    );
  $$, current_setting('test.attempt_id')),
  'Should record learner response for Q2'
);

-- Test submit_and_grade_exam_attempt
select lives_ok(
  format($$
    select public.submit_and_grade_exam_attempt(%L::uuid);
  $$, current_setting('test.attempt_id')),
  'Parent should be able to submit and grade attempt'
);

-- Test 7: Verify Attempt status updated to completed
select results_eq(
  format($$
    select status from public.learner_exam_attempts
    where id = %L::uuid
  $$, current_setting('test.attempt_id')),
  ARRAY['completed'::text],
  'Attempt status should be transitioned to completed'
);

-- Test 8: Verify Attempt submitted_at is recorded
select isnt_empty(
  format($$
    select submitted_at from public.learner_exam_attempts
    where id = %L::uuid and submitted_at is not null
  $$, current_setting('test.attempt_id')),
  'Attempt submitted_at should be populated'
);

-- Test 9: Verify learner_exam_results entry created
select results_eq(
  format($$
    select count(*)::integer from public.learner_exam_results
    where attempt_id = %L::uuid
  $$, current_setting('test.attempt_id')),
  ARRAY[1],
  'Should have 1 learner_exam_results record created'
);

-- Test 10: Percentage is between 0 and 100
select ok(
  (
    select percentage >= 0 and percentage <= 100
    from public.learner_exam_results
    where attempt_id = current_setting('test.attempt_id')::uuid
  ),
  'Score percentage must be between 0 and 100'
);

-- Test 11: Predicted division or grade is generated
select isnt_empty(
  format($$
    select predicted_division_or_grade from public.learner_exam_results
    where attempt_id = %L::uuid and predicted_division_or_grade like 'Division%%'
  $$, current_setting('test.attempt_id')),
  'Predicted division should follow NECTA Division standard'
);

-- Test 12: Section breakdown is an array with entries
select ok(
  (
    select jsonb_array_length(section_breakdown) >= 1
    from public.learner_exam_results
    where attempt_id = current_setting('test.attempt_id')::uuid
  ),
  'Section breakdown should contain at least 1 section'
);

-- Test 13: get_exam_attempt_results returns full analytics payload
select ok(
  (
    select (public.get_exam_attempt_results(current_setting('test.attempt_id')::uuid) ? 'total_score')
  ),
  'get_exam_attempt_results should return total_score'
);

-- Test 14: get_exam_attempt_results includes questions_review array
select ok(
  (
    select (public.get_exam_attempt_results(current_setting('test.attempt_id')::uuid) ? 'questions_review')
  ),
  'get_exam_attempt_results should return itemized questions_review'
);

-- Test 15: questions_review contains learner answer and correct answer
select ok(
  (
    select (public.get_exam_attempt_results(current_setting('test.attempt_id')::uuid)->'questions_review'->0 ? 'correct_answer')
  ),
  'Post-submission review reveals correct_answer for learner review'
);

-- Test 16: Idempotent resubmission handles gracefully
select lives_ok(
  format($$
    select public.submit_and_grade_exam_attempt(%L::uuid);
  $$, current_setting('test.attempt_id')),
  'Submitting an already graded attempt should update gracefully on conflict'
);

select * from finish();
rollback;
