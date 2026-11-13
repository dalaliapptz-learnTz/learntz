-- ============================================================================
-- Test Suite: phase3_social_feed.test.sql
-- Description: Tests educational posts, reactions, comments, bookmarks,
--              child safety filters, following, and blocking.
-- ============================================================================

begin;
select plan(19);

-- 1. Table and Functions existence
select has_table('public', 'social_posts', 'social_posts table should exist');
select has_table('public', 'social_post_reactions', 'social_post_reactions table should exist');
select has_table('public', 'social_post_comments', 'social_post_comments table should exist');
select has_table('public', 'saved_posts', 'saved_posts table should exist');
select has_table('public', 'learner_follows', 'learner_follows table should exist');
select has_table('public', 'learner_blocks', 'learner_blocks table should exist');

select has_function('public', 'create_social_post', ARRAY['uuid', 'text', 'text', 'text', 'uuid', 'uuid', 'text[]'], 'create_social_post should exist');
select has_function('public', 'toggle_post_reaction', ARRAY['uuid', 'uuid', 'text'], 'toggle_post_reaction should exist');
select has_function('public', 'add_post_comment', ARRAY['uuid', 'uuid', 'text', 'uuid'], 'add_post_comment should exist');
select has_function('public', 'toggle_save_post', ARRAY['uuid', 'uuid'], 'toggle_save_post should exist');
select has_function('public', 'toggle_follow_learner', ARRAY['uuid', 'uuid'], 'toggle_follow_learner should exist');
select has_function('public', 'block_learner', ARRAY['uuid', 'uuid', 'text'], 'block_learner should exist');
select has_function('public', 'get_social_feed', ARRAY['uuid', 'text', 'uuid', 'integer', 'integer'], 'get_social_feed should exist');

-- 2. Setup Test Parents and Learners
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'b2000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'parent_feed_1@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Feed Parent 1","country_code":"TZ"}', now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'b2000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'parent_feed_2@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Feed Parent 2","country_code":"TZ"}', now(), now()
  )
on conflict (id) do nothing;

-- 3. Create Learners
set local role authenticated;
select set_config('request.jwt.claim.sub', 'b2000000-0000-0000-0000-000000000001', true);

select set_config(
  'test.learner_1',
  (public.create_learner(
    '60000000-0000-0000-0000-000000000001',
    'Amani',
    null,
    'Bakari',
    '2016-01-15',
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

select set_config('request.jwt.claim.sub', 'b2000000-0000-0000-0000-000000000002', true);

select set_config(
  'test.learner_2',
  (public.create_learner(
    '60000000-0000-0000-0000-000000000002',
    'Neema',
    null,
    'Mussa',
    '2016-04-12',
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

-- 4. Test Child Safety Trigger on Post Creation
select set_config('request.jwt.claim.sub', 'b2000000-0000-0000-0000-000000000001', true);

select throws_ok(
  format(
    'select public.create_social_post(%L::uuid, %L, %L, %L)',
    current_setting('test.learner_1'),
    'question',
    'Call me at 0755123456 please',
    'I need help with homework call me'
  ),
  '23514',
  'Title contains prohibited contact details or external links for child safety',
  'Posts with phone numbers are blocked'
);

-- 5. Create Valid Post and Verify Counters & Points
select set_config(
  'test.post_1',
  (public.create_social_post(
    current_setting('test.learner_1')::uuid,
    'question',
    'How do plants photosynthesize in winter?',
    'I want to understand chlorophyll and light absorption.'
  )).id::text,
  true
);

select is(
  (select points from public.learner_social_profiles where learner_id = current_setting('test.learner_1')::uuid),
  10,
  'Author received 10 points for publishing post'
);

-- 6. Test Reactions and Counter Triggers
select set_config('request.jwt.claim.sub', 'b2000000-0000-0000-0000-000000000002', true);

select lives_ok(
  format(
    'select public.toggle_post_reaction(%L::uuid, %L::uuid, %L)',
    current_setting('test.post_1'),
    current_setting('test.learner_2'),
    'helpful'
  ),
  'Learner 2 can react to Learner 1 post'
);

select is(
  (select likes_count from public.social_posts where id = current_setting('test.post_1')::uuid),
  1,
  'Likes count incremented to 1'
);

-- 7. Test Blocking and Exclusion from Feed
select lives_ok(
  format(
    'select public.block_learner(%L::uuid, %L::uuid, %L)',
    current_setting('test.learner_2'),
    current_setting('test.learner_1'),
    'Spam'
  ),
  'Learner 2 can block Learner 1'
);

select is(
  jsonb_array_length(public.get_social_feed(current_setting('test.learner_2')::uuid)),
  0,
  'Blocked author posts are excluded from learner 2 feed'
);

select * from finish();
rollback;
