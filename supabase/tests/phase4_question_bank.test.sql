begin;

select plan(18);

-- 1. Table structure tests
select has_table('public', 'exam_extracted_questions', 'exam_extracted_questions table exists');
select has_table('public', 'exam_question_reviews', 'exam_question_reviews table exists');

-- 2. Seeded approved questions tests
select is(
  (select count(*)::integer from public.exam_extracted_questions where verification_status = 'approved'),
  5,
  '5 pilot examination questions are seeded with approved status'
);

select is(
  (select count(*)::integer from public.exam_extracted_questions where paper_id = '40000000-0000-0000-0000-000000000001'::uuid),
  4,
  '4 questions seeded for NECTA CSEE 2024 Basic Mathematics'
);

select is(
  (select count(*)::integer from public.exam_extracted_questions where section_code = 'A'),
  4,
  '4 Section A questions seeded'
);

select is(
  (select count(*)::integer from public.exam_extracted_questions where section_code = 'B'),
  1,
  '1 Section B question seeded'
);

-- 3. Test RPC get_approved_exam_questions
select is(
  (select (public.get_approved_exam_questions('40000000-0000-0000-0000-000000000001'::uuid)->>'total_count')::integer),
  4,
  'get_approved_exam_questions returns 4 questions for NECTA Math'
);

select is(
  (select (public.get_approved_exam_questions(null, null, null, null, null, 'Venn diagram')->>'total_count')::integer),
  1,
  'Search for Venn diagram finds 1 question'
);

select is(
  (select (public.get_approved_exam_questions(null, null, null, 'analysis')->>'total_count')::integer),
  1,
  'Bloom level filter analysis finds 1 question'
);

select is(
  (select (public.get_approved_exam_questions(null, null, null, null, 'hard')->>'total_count')::integer),
  2,
  'Difficulty filter hard finds 2 questions'
);

-- 4. Test RPC register_extracted_exam_question and two-party review
-- Create Curriculum Staff 1 (Verifier) and Staff 2 (Approver)
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000411',
    'authenticated', 'authenticated',
    'staff-verifier@example.test', '', now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Staff Verifier","country_code":"TZ"}',
    now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000412',
    'authenticated', 'authenticated',
    'staff-approver@example.test', '', now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Staff Approver","country_code":"TZ"}',
    now(), now()
  );

-- Grant curriculum roles
insert into public.user_roles (user_id, role, country_code) values
  ('00000000-0000-0000-0000-000000000411', 'curriculum_admin', 'TZ'),
  ('00000000-0000-0000-0000-000000000412', 'curriculum_admin', 'TZ');

-- Set context to Verifier
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000411', true);

-- Register extracted question
select isnt_empty(
  $$ select public.register_extracted_exam_question(
    '40000000-0000-0000-0000-000000000001'::uuid,
    'A',
    3,
    'Find the gradient of a straight line passing through points (2, 3) and (6, 11).',
    3.0,
    '(a)',
    null,
    'calculation',
    '[]'::jsonb,
    'm = 2',
    '[{"step": "Formula m = (y2 - y1) / (x2 - x1)", "marks": 1}, {"step": "Substitute: (11 - 3) / (6 - 2) = 8 / 4 = 2", "marks": 2}]'::jsonb
  ) $$,
  'Curriculum staff can register extracted question in draft status'
);

-- Get ID of newly registered question
create temporary table temp_new_q on commit drop as
select id from public.exam_extracted_questions
where question_number = 3 and section_code = 'A';

select is(
  (select verification_status from public.exam_extracted_questions where id = (select id from temp_new_q)),
  'draft',
  'Newly registered question has draft status'
);

-- Staff 1 verifies question
select isnt_empty(
  format('select public.review_exam_question(''%s''::uuid, ''verified'', ''Question and rubric checked'')',
    (select id from temp_new_q)),
  'Staff 1 can mark question as verified'
);

select is(
  (select verification_status from public.exam_extracted_questions where id = (select id from temp_new_q)),
  'verified',
  'Question status is now verified'
);

-- Two-party rule: Staff 1 attempts to approve own verified question (must fail)
select throws_ok(
  format('select public.review_exam_question(''%s''::uuid, ''approved'', ''Self approval attempt'')',
    (select id from temp_new_q)),
  'P0001',
  'Two-party governance violation: Question must be approved by a distinct staff member from the verifier.',
  'Two-party rule prevents same staff from verifying and approving'
);

-- Switch to Staff 2 (Approver)
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000412', true);

-- Staff 2 approves question
select isnt_empty(
  format('select public.review_exam_question(''%s''::uuid, ''approved'', ''Final approval granted'')',
    (select id from temp_new_q)),
  'Staff 2 can approve question'
);

select is(
  (select verification_status from public.exam_extracted_questions where id = (select id from temp_new_q)),
  'approved',
  'Question is now officially approved'
);

-- Reset role to verify full table
reset role;

select is(
  (select count(*)::integer from public.exam_question_reviews where question_id = (select id from temp_new_q)),
  2,
  'Audit log contains 2 review records across both staff members'
);

select * from finish();
rollback;
