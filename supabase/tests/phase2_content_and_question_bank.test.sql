begin;
select plan(16);

-- 1. Schema structure checks
select has_column('public', 'lessons', 'content_blocks', 'lessons has content_blocks column');
select has_column('public', 'lessons', 'summary', 'lessons has summary column');
select has_table('public', 'question_bank', 'question_bank table exists');
select has_table('public', 'learner_topic_mastery', 'learner_topic_mastery table exists');
select has_table('public', 'learner_assessment_attempts', 'learner_assessment_attempts table exists');

-- 2. Verify seeded question bank items exist
select is(
  (select count(*)::integer from public.question_bank where topic_id = '30000000-0000-0000-0000-000000000201'),
  5,
  '5 questions seeded across 5 types for Kiswahili topic'
);

select is(
  (select count(*)::integer from public.question_bank where topic_id = '30000000-0000-0000-0000-000000000202'),
  5,
  '5 questions seeded across 5 types for Hisabati topic'
);

-- 3. Test setup: Auth users
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'b1000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'parent_content@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Content Parent","country_code":"TZ"}', now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'b1000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'stranger_content@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Stranger Parent","country_code":"TZ"}', now(), now()
  )
on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'b1000000-0000-0000-0000-000000000001', true);

-- Free preview lesson can be fetched
select is(
  (public.get_lesson_interactive_content('30000000-0000-0000-0000-000000000301') ->> 'title'),
  'Sauti za Irabu na Silabi Sahili',
  'get_lesson_interactive_content returns correct lesson title'
);

select cmp_ok(
  jsonb_array_length(public.get_lesson_interactive_content('30000000-0000-0000-0000-000000000301') -> 'content_blocks'),
  '>=',
  4,
  'get_lesson_interactive_content returns rich content blocks array'
);

-- 4. Test get_topic_assessment_questions sanitizes answers
select is(
  (public.get_topic_assessment_questions('30000000-0000-0000-0000-000000000201') -> 0 ->> 'correct_answer'),
  null,
  'get_topic_assessment_questions strips correct_answer from client payload'
);

select is(
  jsonb_array_length(public.get_topic_assessment_questions('30000000-0000-0000-0000-000000000201')),
  5,
  'get_topic_assessment_questions returns all 5 seeded questions'
);

-- 5. Create learner as authorized parent
select set_config(
  'test.learner_id',
  (public.create_learner(
    '50000000-0000-0000-0000-000000000001',
    'Khadija',
    null,
    'Tester',
    '2017-04-10',
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

-- 6. Submit 100% correct answers for all 5 questions
select lives_ok(
  format(
    $$
      select public.submit_assessment_attempt(
        %L::uuid,
        '30000000-0000-0000-0000-000000000201'::uuid,
        '[
          {"question_id": "40000000-0000-0000-0000-000000000101", "answer": 1},
          {"question_id": "40000000-0000-0000-0000-000000000102", "answer": true},
          {"question_id": "40000000-0000-0000-0000-000000000103", "answer": "ba"},
          {"question_id": "40000000-0000-0000-0000-000000000104", "answer": {"p1": "r1", "p2": "r2", "p3": "r3"}},
          {"question_id": "40000000-0000-0000-0000-000000000105", "answer": "mama"}
        ]'::jsonb
      );
    $$,
    current_setting('test.learner_id')
  ),
  'submit_assessment_attempt successfully grades all 5 question types'
);

-- Check results of submission
select is(
  (
    select score_percent
    from public.learner_assessment_attempts
    where learner_id = current_setting('test.learner_id')::uuid
    order by created_at desc limit 1
  ),
  100,
  'Assessment attempt recorded 100% score'
);

select is(
  (
    select mastery_status
    from public.learner_topic_mastery
    where learner_id = current_setting('test.learner_id')::uuid
      and topic_id = '30000000-0000-0000-0000-000000000201'
  ),
  'proficient',
  'First 100% attempt sets topic status to proficient'
);

-- Second attempt elevates to mastered
select lives_ok(
  format(
    $$
      select public.submit_assessment_attempt(
        %L::uuid,
        '30000000-0000-0000-0000-000000000201'::uuid,
        '[
          {"question_id": "40000000-0000-0000-0000-000000000101", "answer": 1},
          {"question_id": "40000000-0000-0000-0000-000000000102", "answer": true},
          {"question_id": "40000000-0000-0000-0000-000000000103", "answer": "ba"},
          {"question_id": "40000000-0000-0000-0000-000000000104", "answer": {"p1": "r1", "p2": "r2", "p3": "r3"}},
          {"question_id": "40000000-0000-0000-0000-000000000105", "answer": "mama"}
        ]'::jsonb
      );
    $$,
    current_setting('test.learner_id')
  ),
  'Second attempt executes successfully'
);

select is(
  (
    select mastery_status
    from public.learner_topic_mastery
    where learner_id = current_setting('test.learner_id')::uuid
      and topic_id = '30000000-0000-0000-0000-000000000201'
  ),
  'mastered',
  'Second 100% attempt elevates topic status to mastered'
);

select * from finish();
rollback;
