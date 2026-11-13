-- ============================================================================
-- Test Suite: phase3_challenges_and_leaderboards.test.sql
-- Description: Tests academic challenges, competitions, submission,
--              badge awards, and educational leaderboards.
-- ============================================================================

begin;
select plan(14);

-- 1. Table and Functions existence
select has_table('public', 'academic_challenges', 'academic_challenges table should exist');
select has_table('public', 'challenge_participants', 'challenge_participants table should exist');
select has_table('public', 'achievement_badges', 'achievement_badges table should exist');
select has_table('public', 'learner_badges', 'learner_badges table should exist');

select has_function('public', 'get_active_challenges', ARRAY['uuid'], 'get_active_challenges should exist');
select has_function('public', 'participate_in_challenge', ARRAY['uuid', 'uuid'], 'participate_in_challenge should exist');
select has_function('public', 'submit_challenge_attempt', ARRAY['uuid', 'uuid', 'integer', 'integer', 'jsonb'], 'submit_challenge_attempt should exist');
select has_function('public', 'get_community_leaderboard', ARRAY['text', 'text', 'integer'], 'get_community_leaderboard should exist');

-- 2. Verify Sample Challenge & Badges Seed
select isnt_empty(
  $$ select * from public.achievement_badges where badge_key = 'math_champion' $$,
  'Math Champion badge is seeded'
);

select isnt_empty(
  $$ select * from public.academic_challenges where challenge_type = 'speed_math' and country_code = 'TZ' $$,
  'Sample speed math challenge is seeded'
);

-- 3. Setup Test Parent and Learner
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'b4000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'parent_champ@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Champ Parent","country_code":"TZ"}', now(), now()
  )
on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'b4000000-0000-0000-0000-000000000001', true);

select set_config(
  'test.learner_id',
  (public.create_learner(
    '80000000-0000-0000-0000-000000000002',
    'Faraja',
    null,
    'Juma',
    '2016-03-25',
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

-- 4. Query Active Challenges
select set_config(
  'test.challenge_id',
  (select id::text from public.academic_challenges where challenge_type = 'speed_math' and country_code = 'TZ' limit 1),
  true
);

select isnt_empty(
  format('select * from public.get_active_challenges(%L::uuid)', current_setting('test.learner_id')),
  'Active challenges found for learner'
);

-- 5. Submit Attempt & Verify Points & Badge
select lives_ok(
  format(
    'select public.submit_challenge_attempt(%L::uuid, %L::uuid, 100, 45, %L::jsonb)',
    current_setting('test.challenge_id'),
    current_setting('test.learner_id'),
    '[1, 2, 2, 1, 2]'
  ),
  'Submitting 100% score challenge succeeds'
);

select is(
  (select badges_count from public.learner_social_profiles where learner_id = current_setting('test.learner_id')::uuid),
  1,
  'Learner received Math Champion badge'
);

-- 6. Leaderboard Verification
select is(
  (public.get_community_leaderboard('national', 'TZ', 10) -> 0 ->> 'display_name'),
  'Faraja J.',
  'Leaderboard returns Faraja J. as top rank'
);

select * from finish();
rollback;
