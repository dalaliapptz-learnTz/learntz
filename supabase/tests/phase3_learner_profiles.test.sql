-- ============================================================================
-- Test Suite: phase3_learner_profiles.test.sql
-- Description: Tests learner social profiles, automatic provisioning,
--              child-safe restrictions, and privacy visibility controls.
-- ============================================================================

begin;
select plan(15);

-- 1. Table and Functions existence
select has_table('public', 'learner_social_profiles', 'learner_social_profiles table should exist');
select has_function('public', 'get_or_create_learner_social_profile', ARRAY['uuid'], 'get_or_create_learner_social_profile should exist');
select has_function('public', 'update_learner_social_profile', ARRAY['uuid', 'text', 'text', 'text', 'text[]', 'text', 'boolean', 'boolean', 'boolean'], 'update_learner_social_profile should exist');
select has_function('public', 'get_public_learner_social_profile', ARRAY['uuid', 'uuid'], 'get_public_learner_social_profile should exist');

-- 2. Setup Test Users
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'b1000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'parent_p3@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"P3 Parent","country_code":"TZ"}', now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'b1000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'stranger_p3@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Stranger P3","country_code":"TZ"}', now(), now()
  )
on conflict (id) do nothing;

-- 3. Create Learner as Parent
set local role authenticated;
select set_config('request.jwt.claim.sub', 'b1000000-0000-0000-0000-000000000001', true);

select set_config(
  'test.learner_id',
  (public.create_learner(
    '50000000-0000-0000-0000-000000000001',
    'Zawadi',
    null,
    'Kassim',
    '2016-08-20',
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

-- 4. Verify Automatic Social Profile Provisioning
select isnt_empty(
  format('select * from public.learner_social_profiles where learner_id = %L::uuid', current_setting('test.learner_id')),
  'Social profile was auto-provisioned upon learner creation'
);

select is(
  (select display_name from public.learner_social_profiles where learner_id = current_setting('test.learner_id')::uuid),
  'Zawadi K.',
  'Auto-provisioned display name uses safe pseudonymous initial'
);

select is(
  (select avatar_preset from public.learner_social_profiles where learner_id = current_setting('test.learner_id')::uuid),
  'owl_scholar',
  'Default avatar is owl_scholar'
);

-- 5. Test Stranger Access Blocks
select set_config('request.jwt.claim.sub', 'b1000000-0000-0000-0000-000000000002', true);

select throws_ok(
  format('select public.get_or_create_learner_social_profile(%L::uuid)', current_setting('test.learner_id')),
  '42501',
  'Unauthorized to access learner social profile',
  'Stranger cannot access learner social profile'
);

select throws_ok(
  format('select public.update_learner_social_profile(%L::uuid, %L, %L)', current_setting('test.learner_id'), 'Hacker', 'lion_reader'),
  '42501',
  'Unauthorized to update learner social profile',
  'Stranger cannot update learner social profile'
);

-- 6. Test Authorized Parent Profile Update
select set_config('request.jwt.claim.sub', 'b1000000-0000-0000-0000-000000000001', true);

select lives_ok(
  format(
    'select public.update_learner_social_profile(%L::uuid, %L, %L, %L, %L::text[], %L, true, true, true)',
    current_setting('test.learner_id'),
    'MathWizard',
    'lion_reader',
    'I love science and numbers!',
    ARRAY['Mathematics', 'Science'],
    'public'
  ),
  'Parent can update social profile with valid values'
);

select is(
  (select display_name from public.learner_social_profiles where learner_id = current_setting('test.learner_id')::uuid),
  'MathWizard',
  'Display name updated to MathWizard'
);

-- 7. Test Child Safety Rejections (Prohibited Contact Info)
select throws_ok(
  format(
    'select public.update_learner_social_profile(%L::uuid, %L, %L)',
    current_setting('test.learner_id'),
    'CallMe 0712345678',
    'lion_reader'
  ),
  '23514',
  'Display name contains prohibited contact or link patterns',
  'Display name containing phone numbers is rejected'
);

select throws_ok(
  format(
    'select public.update_learner_social_profile(%L::uuid, %L, %L, %L)',
    current_setting('test.learner_id'),
    'CoolKid',
    'lion_reader',
    'Check out https://scamsite.com for free games'
  ),
  '23514',
  'Bio contains prohibited contact details or external links'
);

-- 8. Test get_public_learner_social_profile
select is(
  (public.get_public_learner_social_profile(current_setting('test.learner_id')::uuid) ->> 'display_name'),
  'MathWizard',
  'Public profile returns safe display name'
);

-- Update to private and test stranger perspective
select public.update_learner_social_profile(
  current_setting('test.learner_id')::uuid,
  'MathWizard',
  'lion_reader',
  'Private bio',
  ARRAY['Mathematics'],
  'private'
);

select set_config('request.jwt.claim.sub', 'b1000000-0000-0000-0000-000000000002', true);

select is(
  (public.get_public_learner_social_profile(current_setting('test.learner_id')::uuid) ->> 'is_private'),
  'true',
  'Stranger viewing private profile gets is_private: true'
);

select * from finish();
rollback;
