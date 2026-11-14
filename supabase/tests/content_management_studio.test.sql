begin;
select plan(12);

-- 1. Check functions exist
select has_function('public', 'get_content_studio_metrics', ARRAY['text'], 'get_content_studio_metrics function exists');
select has_function('public', 'get_content_studio_catalog', ARRAY['text', 'text'], 'get_content_studio_catalog function exists');
select has_function('public', 'upsert_studio_lesson', ARRAY['uuid', 'text', 'text', 'text', 'integer', 'boolean', 'text', 'jsonb', 'uuid'], 'upsert_studio_lesson function exists');
select has_function('public', 'submit_lesson_review', ARRAY['uuid', 'text', 'text'], 'submit_lesson_review function exists');

-- Create a test super_admin user
insert into auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  aud,
  role
) values (
  '00000000-0000-0000-0000-000000000951',
  'content_studio_tester@learntz.test',
  '',
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"full_name":"Content Studio Staff Tester"}'::jsonb,
  now(),
  now(),
  'authenticated',
  'authenticated'
) on conflict (id) do nothing;

insert into public.user_roles (user_id, role, country_code)
values ('00000000-0000-0000-0000-000000000951', 'super_admin', null)
on conflict do nothing;

-- 2. Test unauthenticated throws 42501
select throws_matching(
  $$ select public.get_content_studio_metrics('TZ') $$,
  'Authentication required',
  'Unauthenticated query to content studio metrics fails'
);

-- Set authenticated session for super admin
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000951', true);

-- 3. Test metrics query
select lives_ok(
  $$ select public.get_content_studio_metrics('TZ') $$,
  'Super admin can query content studio metrics'
);

select cmp_ok(
  ((public.get_content_studio_metrics('TZ')->>'total_subjects')::integer),
  '>=',
  1,
  'Content studio reports at least 1 subject in TZ'
);

-- 4. Test catalog query
select lives_ok(
  $$ select public.get_content_studio_catalog('TZ') $$,
  'Super admin can query hierarchical studio catalog'
);

-- 5. Test authoring a new lesson via upsert_studio_lesson
select lives_ok(
  $$
    select public.upsert_studio_lesson(
      (select id from public.topics limit 1),
      'Misingi ya Uhandisi wa Programu na Kanuni za Usanifu',
      '# Utangulizi\n\nSomo hili linafafanua misingi ya programu na mtiririko wa kanuni.',
      'Somo la utangulizi kuhusu programu.',
      15,
      true,
      'draft',
      '[{"type": "concept", "data": {"title": "Kanuni Kuu", "body": "Uchambuzi makini"}}]'::jsonb
    );
  $$,
  'Super admin can create a draft lesson in studio'
);

-- 6. Verify revision snapshot was created
select cmp_ok(
  (select count(*)::integer from public.lesson_revisions where title = 'Misingi ya Uhandisi wa Programu na Kanuni za Usanifu'),
  '>=',
  1,
  'Lesson revision record was created in version history'
);

-- 7. Test submitting for review and publishing
select lives_ok(
  $$
    select public.submit_lesson_review(
      (select id from public.lessons where title = 'Misingi ya Uhandisi wa Programu na Kanuni za Usanifu' limit 1),
      'submit_for_review',
      'Tayari kwa ukaguzi wa kiufundi'
    );
  $$,
  'Can submit lesson for review'
);

select lives_ok(
  $$
    select public.submit_lesson_review(
      (select id from public.lessons where title = 'Misingi ya Uhandisi wa Programu na Kanuni za Usanifu' limit 1),
      'approve_and_publish',
      'Imeidhinishwa na kuchapishwa kikamilifu'
    );
  $$,
  'Curriculum admin can approve and publish lesson'
);

select * from finish();
rollback;
