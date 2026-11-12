begin;

select plan(38);

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
    '00000000-0000-0000-0000-000000000301',
    'authenticated',
    'authenticated',
    'curriculum-parent@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Curriculum Parent","country_code":"TZ"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000302',
    'authenticated',
    'authenticated',
    'curriculum-editor@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Curriculum Editor","country_code":"TZ"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000303',
    'authenticated',
    'authenticated',
    'curriculum-reviewer@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Curriculum Reviewer","country_code":"TZ"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000304',
    'authenticated',
    'authenticated',
    'curriculum-approver@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Curriculum Approver","country_code":"TZ"}',
    now(),
    now()
  );

insert into public.user_roles (user_id, role, country_code)
values
  (
    '00000000-0000-0000-0000-000000000302',
    'curriculum_editor',
    'TZ'
  ),
  (
    '00000000-0000-0000-0000-000000000303',
    'curriculum_reviewer',
    'TZ'
  ),
  (
    '00000000-0000-0000-0000-000000000304',
    'curriculum_approver',
    'TZ'
  );

select is(
  (select count(*)::integer from public.curriculum_authorities where country_code = 'TZ'),
  1,
  'only the existing TIE curriculum authority is registered'
);
select is(
  (select count(*)::integer
    from public.curricula curriculum
    join public.curriculum_authorities authority
      on authority.id = curriculum.authority_id
    where curriculum.code = 'TIE'
      and authority.code = 'TIE'
      and authority.country_code = 'TZ'),
  1,
  'existing TIE curriculum is linked to its issuing authority'
);
select is(
  (select count(*)::integer
    from public.curriculum_authorities authority
    where authority.country_code not in ('TZ', 'KE', 'UG')),
  0,
  'no unverified authorities are invented for other countries'
);
select is(
  (select count(*)::integer from public.curriculum_versions
    where version_code <> 'tie-primary-pilot-source-review-1'),
  0,
  'no unsupported official curriculum versions are seeded beyond the Stage 3.2 draft'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000301',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (select count(*)::integer from public.curriculum_authorities
    where code = 'TIE'),
  1,
  'parents can read enabled curriculum authority metadata'
);
select is(
  (select count(*)::integer from public.curriculum_versions where status = 'draft'),
  0,
  'parents cannot read draft curriculum versions'
);
select throws_ok(
  $$select public.create_curriculum_version(
    (select id from public.curricula where code = 'TIE'),
    'unauthorized',
    'Unauthorized version'
  )$$,
  '42501',
  null,
  'parents cannot create curriculum versions'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000302',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select ok(
  public.has_curriculum_role(
    'TZ',
    array['curriculum_editor']
  ),
  'curriculum editor role is scoped to the assigned country'
);
select ok(
  not public.has_curriculum_role(
    'KE',
    array['curriculum_editor']
  ),
  'curriculum editor role does not grant access to another country'
);
select set_config(
  'test.version_id',
  (public.create_curriculum_version(
    (select id from public.curricula where code = 'TIE'),
    'foundation-test-v1',
    'Foundation test version'
  )).id::text,
  true
);
select is(
  (select status from public.curriculum_versions
    where id = current_setting('test.version_id')::uuid),
  'draft',
  'curriculum versions are created in draft status'
);
select lives_ok(
  $$insert into public.curriculum_version_grades (
    version_id, curriculum_id, education_level_id, grade_id, display_order
  )
  select
    current_setting('test.version_id')::uuid,
    curriculum.id,
    grade.education_level_id,
    grade.id,
    1
  from public.curricula curriculum
  join public.education_grades grade on grade.code = 'STANDARD_1'
  where curriculum.code = 'TIE'$$,
  'editors can map an existing grade into a draft curriculum version'
);
select lives_ok(
  $$insert into public.curriculum_version_languages (
    version_id, curriculum_id, language_code, is_primary
  )
  select current_setting('test.version_id')::uuid, id, 'sw', true
  from public.curricula where code = 'TIE'$$,
  'editors can define the primary language for a draft version'
);
select lives_ok(
  $$insert into public.curriculum_version_languages (
    version_id, curriculum_id, language_code, is_primary
  )
  select current_setting('test.version_id')::uuid, id, 'en', false
  from public.curricula where code = 'TIE'$$,
  'editors can define additional version languages'
);
select lives_ok(
  $$insert into public.curriculum_sources (
    authority_id, document_title, issuing_institution, source_url,
    sha256_checksum, usage_permissions, created_by
  )
  select
    authority.id,
    'Test source document',
    authority.name,
    'https://example.test/tie-curriculum.pdf',
    repeat('a', 64),
    'Test-only provenance fixture; not official curriculum material.',
    auth.uid()
  from public.curriculum_authorities authority
  where authority.code = 'TIE'$$,
  'editors can register an unverified source with traceable provenance'
);
select set_config(
  'test.source_id',
  (select id::text from public.curriculum_sources
    where document_title = 'Test source document'),
  true
);
select lives_ok(
  $$insert into public.curriculum_version_sources (
    version_id, curriculum_id, authority_id, source_id,
    page_number, section_reference, extracted_source_text, created_by
  )
  select
    current_setting('test.version_id')::uuid,
    curriculum.id,
    curriculum.authority_id,
    current_setting('test.source_id')::uuid,
    1,
    'Test-only section',
    'Fixture text only.',
    auth.uid()
  from public.curricula curriculum
  where curriculum.code = 'TIE'$$,
  'editors can attach page-level source references to a draft version'
);
select lives_ok(
  $$select public.transition_curriculum_version(
    current_setting('test.version_id')::uuid,
    'under_review',
    'Ready for review'
  )$$,
  'editors can submit a draft version for review'
);
select is(
  (select count(*)::integer from public.curriculum_version_review_history
    where version_id = current_setting('test.version_id')::uuid),
  2,
  'version creation and submission are recorded in review history'
);
select throws_ok(
  $$select public.verify_curriculum_source(
    current_setting('test.source_id')::uuid,
    true,
    'Editor cannot verify'
  )$$,
  '42501',
  null,
  'editors cannot verify their own curriculum sources'
);
select throws_ok(
  $$select public.transition_curriculum_version(
    current_setting('test.version_id')::uuid,
    'approved',
    'Editor cannot approve'
  )$$,
  '42501',
  null,
  'editors cannot approve curriculum versions'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000303',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$select public.verify_curriculum_source(
    current_setting('test.source_id')::uuid,
    true,
    'Verified in test fixture'
  )$$,
  'authorized reviewers can verify sources with checksum and usage evidence'
);
select is(
  (select verification_status from public.curriculum_sources
    where id = current_setting('test.source_id')::uuid),
  'verified',
  'source verification status is stored'
);
select is(
  (select count(*)::integer from public.curriculum_source_review_history
    where source_id = current_setting('test.source_id')::uuid
      and verification_status = 'verified'),
  1,
  'source verification decisions are audited'
);
select throws_ok(
  $$select public.transition_curriculum_version(
    current_setting('test.version_id')::uuid,
    'approved',
    'Reviewer cannot approve'
  )$$,
  '42501',
  null,
  'reviewers cannot publish or approve curriculum versions'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000304',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$select public.transition_curriculum_version(
    current_setting('test.version_id')::uuid,
    'approved',
    'Approved in test fixture'
  )$$,
  'authorized approvers can approve a version with verified evidence'
);
select is(
  (select status from public.curriculum_versions
    where id = current_setting('test.version_id')::uuid),
  'approved',
  'approval records the lifecycle status'
);
select lives_ok(
  $$select public.transition_curriculum_version(
    current_setting('test.version_id')::uuid,
    'published',
    'Published in test fixture'
  )$$,
  'authorized approvers can publish an approved version'
);
select is(
  (select count(*)::integer from public.curriculum_version_review_history
    where version_id = current_setting('test.version_id')::uuid
      and to_status = 'published'),
  1,
  'publication is recorded in immutable review history'
);

reset role;
select throws_ok(
  $$update public.curriculum_versions
  set display_name = 'Tampered published version'
  where id = current_setting('test.version_id')::uuid$$,
  '55000',
  null,
  'published curriculum version content cannot be modified'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000301',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (select count(*)::integer from public.curriculum_versions
    where id = current_setting('test.version_id')::uuid),
  1,
  'parents can read published curriculum versions'
);
select is(
  (select count(*)::integer from public.curriculum_version_grades
    where version_id = current_setting('test.version_id')::uuid),
  1,
  'parents can read published version grade mappings'
);
select is(
  (select count(*)::integer from public.curriculum_version_languages
    where version_id = current_setting('test.version_id')::uuid),
  2,
  'parents can read published version languages'
);
select is(
  (select count(*)::integer from public.curriculum_sources),
  0,
  'parents cannot read restricted source-document provenance'
);
select is(
  (select count(*)::integer from public.curriculum_version_review_history),
  0,
  'parents cannot read internal curriculum review history'
);
select throws_ok(
  $$insert into public.curriculum_version_languages (
    version_id, curriculum_id, language_code
  )
  select current_setting('test.version_id')::uuid, id, 'fr'
  from public.curricula where code = 'TIE'$$,
  '42501',
  null,
  'parents cannot modify published curriculum configuration'
);
select throws_ok(
  $$select public.create_curriculum_version(
    (select id from public.curricula where code = 'TIE'),
    'parent-version',
    'Parent version'
  )$$,
  '42501',
  null,
  'parents cannot create curriculum versions'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000302',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$select public.transition_curriculum_version(
    current_setting('test.version_id')::uuid,
    'draft',
    'Published versions cannot return to draft'
  )$$,
  '42501',
  null,
  'published versions cannot return to draft'
);
select set_config(
  'test.second_version_id',
  (public.create_curriculum_version(
    (select id from public.curricula where code = 'TIE'),
    'foundation-test-v2',
    'Second foundation test version'
  )).id::text,
  true
);
select lives_ok(
  $$select public.transition_curriculum_version(
    current_setting('test.second_version_id')::uuid,
    'under_review',
    'Submit without source evidence'
  )$$,
  'a second draft can enter review before evidence is complete'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000304',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$select public.transition_curriculum_version(
    current_setting('test.second_version_id')::uuid,
    'approved',
    'No verified sources'
  )$$,
  '23514',
  null,
  'versions cannot be approved without verified source evidence'
);

select * from finish();
rollback;
