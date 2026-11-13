-- ============================================================================
-- Test Suite: phase3_tiered_communities.test.sql
-- Description: Tests hierarchical communities (national, school, class, subject),
--              auto-enrollment, channels, messages, and child safety.
-- ============================================================================

begin;
select plan(15);

-- 1. Table and Functions existence
select has_table('public', 'communities', 'communities table should exist');
select has_table('public', 'community_memberships', 'community_memberships table should exist');
select has_table('public', 'community_channels', 'community_channels table should exist');
select has_table('public', 'channel_messages', 'channel_messages table should exist');

select has_function('public', 'get_learner_communities', ARRAY['uuid'], 'get_learner_communities should exist');
select has_function('public', 'get_discoverable_communities', ARRAY['uuid', 'text'], 'get_discoverable_communities should exist');
select has_function('public', 'join_community', ARRAY['uuid', 'uuid'], 'join_community should exist');
select has_function('public', 'leave_community', ARRAY['uuid', 'uuid'], 'leave_community should exist');
select has_function('public', 'get_community_channels', ARRAY['uuid'], 'get_community_channels should exist');
select has_function('public', 'send_channel_message', ARRAY['uuid', 'uuid', 'text'], 'send_channel_message should exist');
select has_function('public', 'get_channel_messages', ARRAY['uuid', 'uuid', 'integer'], 'get_channel_messages should exist');

-- 2. Verify National Community Seeds
select isnt_empty(
  $$ select * from public.communities where community_tier = 'national' and country_code = 'TZ' $$,
  'Tanzania National Learning Community is seeded'
);

-- 3. Setup Test User and Learner with School
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'b3000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'parent_comm@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Comm Parent","country_code":"TZ"}', now(), now()
  )
on conflict (id) do nothing;

insert into public.schools (id, country_code, education_system_id, name)
values (
  '80000000-0000-0000-0000-000000000001',
  'TZ',
  '20000000-0000-0000-0000-000000000001',
  'Mlimani Primary School'
) on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'b3000000-0000-0000-0000-000000000001', true);

select set_config(
  'test.learner_id',
  (public.create_learner(
    '70000000-0000-0000-0000-000000000001',
    'Upendo',
    null,
    'Shao',
    '2016-09-10',
    null,
    'TZ',
    '20000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    (select id from public.education_grades where code = 'STANDARD_1'),
    '80000000-0000-0000-0000-000000000001'::uuid
  )).id::text,
  true
);

-- 4. Verify Auto-Enrollment into National, School, and Class Communities
select is(
  jsonb_array_length(public.get_learner_communities(current_setting('test.learner_id')::uuid)),
  3,
  'Learner was auto-enrolled into class, school, and national communities'
);

-- 5. Test Channel Creation and Child Safety in Channel Messages
select set_config(
  'test.channel_id',
  (select id::text from public.community_channels where name = 'general' limit 1),
  true
);

select throws_ok(
  format(
    'select public.send_channel_message(%L::uuid, %L::uuid, %L)',
    current_setting('test.channel_id'),
    current_setting('test.learner_id'),
    'Hey text me at 0788123456!'
  ),
  '23514',
  'Content contains prohibited contact details or external links for child safety',
  'Messages with phone numbers are rejected'
);

-- Valid message sends and increments messages
select lives_ok(
  format(
    'select public.send_channel_message(%L::uuid, %L::uuid, %L)',
    current_setting('test.channel_id'),
    current_setting('test.learner_id'),
    'Hello classmates! Looking forward to revising together.'
  ),
  'Valid channel message is sent successfully'
);

select * from finish();
rollback;
