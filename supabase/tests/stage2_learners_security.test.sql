begin;

select plan(35);

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000101',
    'authenticated',
    'authenticated',
    'learner-parent-one@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Learner Parent One","country_code":"TZ"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000102',
    'authenticated',
    'authenticated',
    'learner-parent-two@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Learner Parent Two","country_code":"TZ"}',
    now(),
    now()
  );

insert into public.user_roles (user_id, role, country_code)
values (
  '00000000-0000-0000-0000-000000000102',
  'country_admin',
  'TZ'
);

select is(
  (select count(*)::integer from public.education_systems where country_code = 'TZ'),
  1,
  'only Tanzania has an enabled education system in stage 2'
);
select is(
  (select count(*)::integer from public.curricula where country_code = 'TZ'),
  1,
  'Tanzania Institute of Education is configured once'
);
select is(
  (select count(*)::integer from public.education_levels l join public.curricula c on c.id = l.curriculum_id where c.country_code = 'TZ'),
  3,
  'TIE primary, ordinary, and advanced levels are configured'
);
select is(
  (select count(*)::integer from public.education_grades g join public.curricula c on c.id = g.curriculum_id where c.country_code = 'TZ'),
  13,
  'TIE has seven primary standards and six secondary forms'
);
select is(
  (select count(*)::integer from public.promotion_policies where enabled),
  0,
  'automatic promotion remains disabled until configured and approved'
);
select is(
  (select count(*)::integer from public.academic_calendars),
  0,
  'no unverified academic calendar is seeded'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000101',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select set_config(
  'test.learner_one',
  (public.create_learner(
    '30000000-0000-0000-0000-000000000001',
    'Amani',
    null,
    'Mushi',
    '2015-04-12',
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
select isnt(
  current_setting('test.learner_one'),
  '',
  'parent can register one learner'
);
select is(
  (public.create_learner(
    '30000000-0000-0000-0000-000000000001',
    'Amani',
    null,
    'Mushi',
    '2015-04-12',
    null,
    'TZ',
    '20000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    (select id from public.education_grades where code = 'STANDARD_1'),
    null
  )).id::text,
  current_setting('test.learner_one'),
  'repeated registration request is idempotent'
);
select is(
  (select count(*)::integer from public.learners),
  1,
  'parent can read the newly registered learner'
);

select set_config(
  'test.learner_two',
  (public.create_learner(
    '30000000-0000-0000-0000-000000000002',
    'Neema',
    'Rehema',
    'Mushi',
    '2017-09-20',
    'female',
    'TZ',
    '20000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    (select id from public.education_grades where code = 'STANDARD_2'),
    null
  )).id::text,
  true
);
select is(
  (select count(*)::integer from public.learners),
  2,
  'one parent can register multiple independent learners'
);
select throws_ok(
  $$select public.create_learner(
    '30000000-0000-0000-0000-000000000003',
    'Invalid', null, 'Country', '2015-04-12', null, 'KE',
    '20000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    (select id from public.education_grades where code = 'STANDARD_1'),
    null
  )$$,
  '22023',
  null,
  'country and education system mismatches are rejected'
);
select throws_ok(
  $$select public.create_learner(
    '30000000-0000-0000-0000-000000000004',
    'Invalid', null, 'Grade', '2015-04-12', null, 'TZ',
    '20000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    (select id from public.education_grades where code = 'FORM_1'),
    null
  )$$,
  '22023',
  null,
  'a grade outside the selected education level is rejected'
);
select throws_ok(
  $$insert into public.learners (
    first_name, last_name, date_of_birth, country_code,
    education_system_id, curriculum_id, education_level_id, grade_id,
    created_by_parent_user_id, registration_request_id
  ) values (
    'Forged', 'Owner', '2015-04-12', 'TZ',
    '20000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    (select id from public.education_grades where code = 'STANDARD_1'),
    '00000000-0000-0000-0000-000000000101',
    '30000000-0000-0000-0000-000000000099'
  )$$,
  '42501',
  null,
  'parents cannot forge learner ownership through direct table inserts'
);
select lives_ok(
  $$update public.education_grades set name = 'Parent edit'
    where code = 'STANDARD_1'$$,
  'parents cannot modify education configuration'
);
select is(
  (select name from public.education_grades where code = 'STANDARD_1'),
  'Standard 1',
  'unauthorized configuration update is filtered by RLS'
);

select is(
  (public.update_learner(
    current_setting('test.learner_one')::uuid,
    'Amani Updated',
    null,
    'Mushi',
    '2015-04-12',
    null,
    'TZ',
    '20000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    (select id from public.education_grades where code = 'STANDARD_1'),
    null
  )).first_name,
  'Amani Updated',
  'parent can edit an authorized learner profile'
);
select is(
  (select count(*)::integer from public.learner_change_history
    where learner_id = current_setting('test.learner_one')::uuid
      and changed_fields ? 'first_name'),
  1,
  'learner profile changes are audited'
);
select set_config(
  'test.relationship_id',
  (public.invite_learner_guardian(
    current_setting('test.learner_one')::uuid,
    '00000000-0000-0000-0000-000000000102'
  )).id::text,
  true
);
select is(
  (select count(*)::integer from public.parent_learners
    where id = current_setting('test.relationship_id')::uuid
      and relationship_status = 'pending'),
  1,
  'additional guardian access requires invitation acceptance'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000102',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (select count(*)::integer from public.learners),
  0,
  'pending guardian cannot read learner data'
);
select lives_ok(
  $$select public.accept_learner_guardian_invitation(
    current_setting('test.relationship_id')::uuid
  )$$,
  'invited parent can accept a guardian relationship'
);
select is(
  (select count(*)::integer from public.learners),
  1,
  'authorized guardian can read the shared learner'
);
select is(
  (select count(*)::integer from public.learners
    where id = current_setting('test.learner_two')::uuid),
  0,
  'guardian cannot read an unrelated learner'
);
select throws_ok(
  $$select public.deactivate_learner(
    current_setting('test.learner_two')::uuid
  )$$,
  '42501',
  null,
  'guardian cannot mutate an unrelated learner'
);
select throws_ok(
  $$insert into public.parent_learners (
    learner_id, parent_user_id, relationship_role,
    relationship_status, created_by_parent_user_id
  ) values (
    current_setting('test.learner_two')::uuid,
    '00000000-0000-0000-0000-000000000102',
    'guardian', 'active',
    '00000000-0000-0000-0000-000000000102'
  )$$,
  '42501',
  null,
  'parents cannot forge parent-learner relationships'
);
select lives_ok(
  $$select public.record_learner_promotion(
    current_setting('test.learner_one')::uuid,
    'TZ',
    '20000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    (select id from public.education_grades where code = 'STANDARD_2'),
    null,
    'promoted',
    current_date,
    null,
    'Manual promotion test'
  )$$,
  'authorized guardian can record a configured manual promotion'
);
select is(
  (select count(*)::integer from public.learner_promotions
    where learner_id = current_setting('test.learner_one')::uuid),
  1,
  'manual promotion history is visible to an authorized guardian'
);
select is(
  (select grade_id from public.learners
    where id = current_setting('test.learner_one')::uuid),
  (select id from public.education_grades where code = 'STANDARD_2'),
  'manual promotion updates the active learner grade'
);
select lives_ok(
  $$update public.education_systems
    set name = 'Tanzania system updated by administrator'
    where id = '20000000-0000-0000-0000-000000000001'$$,
  'authorized country administrator can manage country education configuration'
);
select is(
  (select name from public.education_systems
    where id = '20000000-0000-0000-0000-000000000001'),
  'Tanzania system updated by administrator',
  'authorized education system update is persisted'
);
select lives_ok(
  $$insert into public.promotion_policies (
    country_code, education_system_id, promotion_month, promotion_day, enabled
  ) values (
    'TZ',
    '20000000-0000-0000-0000-000000000001',
    1,
    1,
    true
  )$$,
  'authorized administrator can explicitly configure annual promotion'
);
select is(
  (select count(*)::integer from public.promotion_policies
    where enabled
      and approved_by = '00000000-0000-0000-0000-000000000102'
      and approved_at is not null),
  1,
  'enabling promotion policy records the approving administrator'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000101',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (public.deactivate_learner(
    current_setting('test.learner_one')::uuid
  )).status,
  'inactive',
  'parent can deactivate an authorized learner'
);
select ok(
  exists (
    select 1 from public.learner_status_history
    where learner_id = current_setting('test.learner_one')::uuid
      and status = 'inactive'
  ),
  'learner deactivation creates an immutable status history entry'
);
select is(
  (public.request_learner_deletion(
    current_setting('test.learner_two')::uuid
  )).status,
  'deletion_requested',
  'parent can request deletion without hard-deleting the profile'
);
select ok(
  exists (
    select 1 from public.learner_status_history
    where learner_id = current_setting('test.learner_two')::uuid
      and status = 'deletion_requested'
  ),
  'deletion request is recorded in status history'
);

select * from finish();
rollback;
