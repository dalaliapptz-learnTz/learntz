-- ============================================================================
-- Test Suite: phase3_moderation_and_notifications.test.sql
-- Description: Tests child protection moderation queue, report resolution,
--              and real-time educational notifications.
-- ============================================================================

begin;
select plan(14);

-- 1. Table and Functions existence
select has_table('public', 'social_moderation_reports', 'social_moderation_reports table should exist');
select has_table('public', 'social_notifications', 'social_notifications table should exist');

select has_function('public', 'report_social_content', ARRAY['uuid', 'text', 'uuid', 'text', 'text'], 'report_social_content should exist');
select has_function('public', 'get_moderation_queue', ARRAY['text', 'integer'], 'get_moderation_queue should exist');
select has_function('public', 'review_moderation_report', ARRAY['uuid', 'text', 'text'], 'review_moderation_report should exist');
select has_function('public', 'get_learner_social_notifications', ARRAY['uuid', 'boolean', 'integer'], 'get_learner_social_notifications should exist');
select has_function('public', 'mark_notifications_read', ARRAY['uuid', 'uuid[]'], 'mark_notifications_read should exist');

-- 2. Setup Test Parents, Learners, and Post
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'b5000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'parent_mod_1@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Mod Parent 1","country_code":"TZ"}', now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'b5000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'parent_mod_2@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Mod Parent 2","country_code":"TZ"}', now(), now()
  )
on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'b5000000-0000-0000-0000-000000000001', true);

select set_config(
  'test.learner_1',
  (public.create_learner(
    '90000000-0000-0000-0000-000000000001',
    'Tumaini',
    null,
    'Massawe',
    '2016-07-15',
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

select set_config(
  'test.post_id',
  (public.create_social_post(
    current_setting('test.learner_1')::uuid,
    'question',
    'Is gravity different on the moon?',
    'I want to compare Earth gravity and Moon gravity.'
  )).id::text,
  true
);

select set_config('request.jwt.claim.sub', 'b5000000-0000-0000-0000-000000000002', true);

select set_config(
  'test.learner_2',
  (public.create_learner(
    '90000000-0000-0000-0000-000000000002',
    'Rehema',
    null,
    'Kimaro',
    '2016-09-18',
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

-- 3. Reaction triggers Notification
select lives_ok(
  format(
    'select public.toggle_post_reaction(%L::uuid, %L::uuid, %L)',
    current_setting('test.post_id'),
    current_setting('test.learner_2'),
    'insightful'
  ),
  'Learner 2 reacts to post'
);

select set_config('request.jwt.claim.sub', 'b5000000-0000-0000-0000-000000000001', true);

select is(
  jsonb_array_length(public.get_learner_social_notifications(current_setting('test.learner_1')::uuid)),
  1,
  'Learner 1 received reaction notification'
);

select is(
  (public.get_learner_social_notifications(current_setting('test.learner_1')::uuid) -> 0 ->> 'notification_type'),
  'reaction_received',
  'Notification type is reaction_received'
);

-- Mark notification read
select is(
  public.mark_notifications_read(current_setting('test.learner_1')::uuid),
  1,
  '1 notification marked as read'
);

-- 4. Test Reporting Content
select set_config('request.jwt.claim.sub', 'b5000000-0000-0000-0000-000000000002', true);

select set_config(
  'test.report_id',
  (public.report_social_content(
    current_setting('test.learner_2')::uuid,
    'post',
    current_setting('test.post_id')::uuid,
    'misinformation',
    'Question needs clarification'
  )).id::text,
  true
);

select isnt_empty(
  format('select * from public.social_moderation_reports where id = %L::uuid', current_setting('test.report_id')),
  'Report record was created in pending status'
);

-- 5. Test Staff Moderation Review
reset role;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'b5000000-0000-0000-0000-000000000099',
    'authenticated', 'authenticated', 'staff_mod@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Staff Mod","country_code":"TZ"}', now(), now()
  )
on conflict (id) do nothing;

insert into public.user_roles (user_id, role)
values ('b5000000-0000-0000-0000-000000000099', 'super_admin')
on conflict (user_id, role, coalesce(country_code, '')) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'b5000000-0000-0000-0000-000000000099', true);

select lives_ok(
  format(
    'select public.review_moderation_report(%L::uuid, %L, %L)',
    current_setting('test.report_id'),
    'dismissed',
    'Question is scientifically valid educational inquiry'
  ),
  'Staff can review and resolve moderation report'
);

select is(
  (select status from public.social_moderation_reports where id = current_setting('test.report_id')::uuid),
  'resolved_dismissed',
  'Report status updated to resolved_dismissed'
);

select * from finish();
rollback;
