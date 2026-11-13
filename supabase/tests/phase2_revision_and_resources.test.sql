begin;
select plan(17);

-- 1. Schema structure checks
select has_table('public', 'flashcard_decks', 'flashcard_decks table exists');
select has_table('public', 'flashcards', 'flashcards table exists');
select has_table('public', 'learning_resources', 'learning_resources table exists');
select has_column('public', 'learning_resources', 'resource_type', 'learning_resources has resource_type');
select has_column('public', 'flashcard_decks', 'card_count', 'flashcard_decks has card_count');

-- 2. Test setup: Auth users
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'd1000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'parent_revision@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Revision Parent","country_code":"TZ"}', now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'd1000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'stranger_revision@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Stranger Revision","country_code":"TZ"}', now(), now()
  )
on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'd1000000-0000-0000-0000-000000000001', true);

-- Create learner
select set_config(
  'test.learner_id',
  (public.create_learner(
    '60000000-0000-0000-0000-000000000002',
    'Juma',
    null,
    'Revise',
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

-- Stranger cannot access revision overview or weak topic drill
select set_config('request.jwt.claim.sub', 'd1000000-0000-0000-0000-000000000002', true);

select throws_ok(
  format('select public.get_learner_revision_overview(%L::uuid)', current_setting('test.learner_id')),
  '42501',
  'Authorized parent access is required for this learner',
  'Stranger cannot access learner revision overview'
);

select throws_ok(
  format('select public.get_weak_topic_drill_questions(%L::uuid)', current_setting('test.learner_id')),
  '42501',
  'Authorized parent access is required for this learner',
  'Stranger cannot access learner weak topic drill'
);

-- Switch back to authorized parent
select set_config('request.jwt.claim.sub', 'd1000000-0000-0000-0000-000000000001', true);

-- Test 8: Revision overview returns valid JSON structure
select is(
  (public.get_learner_revision_overview(current_setting('test.learner_id')::uuid) ->> 'learner_id'),
  current_setting('test.learner_id'),
  'get_learner_revision_overview returns correct learner_id'
);

select isnt(
  (public.get_learner_revision_overview(current_setting('test.learner_id')::uuid) ->> 'flashcard_decks_count')::integer,
  0,
  'Flashcard decks count is greater than 0'
);

select isnt(
  (public.get_learner_revision_overview(current_setting('test.learner_id')::uuid) ->> 'learning_resources_count')::integer,
  0,
  'Learning resources count is greater than 0'
);

-- Test 11: Weak topic drill questions returns questions
select is(
  (select count(*) from jsonb_array_elements(
    public.get_weak_topic_drill_questions(current_setting('test.learner_id')::uuid, 5)
  )) > 0,
  true,
  'Weak topic drill returns question items'
);

-- Test 12: Flashcard decks retrieval
select is(
  (select count(*) from jsonb_array_elements(
    public.get_flashcard_decks(current_setting('test.learner_id')::uuid)
  )) >= 2,
  true,
  'get_flashcard_decks returns at least 2 decks'
);

-- Test 13: Fetch cards from deck 1
select is(
  (select count(*) from jsonb_array_elements(
    public.get_deck_flashcards('30000000-0000-0000-0000-000000000501'::uuid)
  ))::integer,
  4,
  'Kiswahili deck has 4 flashcards'
);

-- Test 14: Ordinary user cannot insert flashcards (RLS check)
select throws_ok(
  $$insert into public.flashcards (
    id, deck_id, front_prompt, back_solution, display_order
  ) values (
    '30000000-0000-0000-0000-000000000599',
    '30000000-0000-0000-0000-000000000501',
    'Konsonanti Z + A = ?',
    'ZA',
    5
  )$$,
  '42501',
  null,
  'Ordinary authenticated users cannot insert flashcards'
);

-- Test 15: Card count trigger sync as super_admin / postgres
reset role;

insert into public.flashcards (
  id, deck_id, front_prompt, back_solution, display_order
) values (
  '30000000-0000-0000-0000-000000000599',
  '30000000-0000-0000-0000-000000000501',
  'Konsonanti Z + A = ?',
  'ZA',
  5
);

select is(
  (select card_count from public.flashcard_decks where id = '30000000-0000-0000-0000-000000000501'),
  5,
  'Trigger automatically increments deck card_count to 5'
);

delete from public.flashcards where id = '30000000-0000-0000-0000-000000000599';

select is(
  (select card_count from public.flashcard_decks where id = '30000000-0000-0000-0000-000000000501'),
  4,
  'Trigger automatically decrements deck card_count back to 4'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', 'd1000000-0000-0000-0000-000000000001', true);

-- Test 17: Learning resources retrieval & filter
select is(
  (select count(*) from jsonb_array_elements(
    public.get_learning_resources('TZ', null, null, 'worksheet')
  ))::integer,
  1,
  'Filtered learning resources returns exactly 1 worksheet'
);

select * from finish();
rollback;
