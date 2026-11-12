begin;

select plan(52);

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
    '00000000-0000-0000-0000-000000000401',
    'authenticated',
    'authenticated',
    'curriculum-pilot-parent@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Pilot Parent","country_code":"TZ"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000402',
    'authenticated',
    'authenticated',
    'curriculum-pilot-editor@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Pilot Editor","country_code":"TZ"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000403',
    'authenticated',
    'authenticated',
    'curriculum-pilot-reviewer@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Pilot Reviewer","country_code":"TZ"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000404',
    'authenticated',
    'authenticated',
    'curriculum-pilot-approver@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Pilot Approver","country_code":"TZ"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000405',
    'authenticated',
    'authenticated',
    'curriculum-pilot-rights-reviewer@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Pilot Rights Reviewer","country_code":"TZ"}',
    now(),
    now()
  );

insert into public.user_roles (user_id, role, country_code)
values
  (
    '00000000-0000-0000-0000-000000000402',
    'curriculum_editor',
    'TZ'
  ),
  (
    '00000000-0000-0000-0000-000000000403',
    'curriculum_reviewer',
    'TZ'
  ),
  (
    '00000000-0000-0000-0000-000000000403',
    'curriculum_approver',
    'TZ'
  ),
  (
    '00000000-0000-0000-0000-000000000404',
    'curriculum_approver',
    'TZ'
  ),
  (
    '00000000-0000-0000-0000-000000000405',
    'curriculum_reviewer',
    'TZ'
  );

select set_config(
  'test.version_id',
  (
    select id::text from public.curriculum_versions
    where version_code = 'tie-primary-pilot-source-review-1'
  ),
  true
);
select set_config(
  'test.source_id',
  (
    select id::text from public.curriculum_sources
    where sha256_checksum =
      '20c75d2071d4a1726187af6c097125137ef4b0971d7a7b3834d030d5295b3591'
  ),
  true
);

select is(
  (select count(*)::integer from public.curriculum_versions),
  1,
  'the TIE primary source-review pilot version is seeded once'
);
select is(
  (select status from public.curriculum_versions
    where id = current_setting('test.version_id')::uuid),
  'draft',
  'the pilot is not published'
);
select ok(
  (select requires_reviewed_import from public.curriculum_versions
    where id = current_setting('test.version_id')::uuid),
  'the pilot requires a human-reviewed import before approval'
);
select is(
  (select count(*)::integer from public.curriculum_version_grades
    where version_id = current_setting('test.version_id')::uuid),
  7,
  'the pilot maps existing Tanzania primary grades without duplicating them'
);
select is(
  (select count(*)::integer from public.curriculum_import_pages)
    + (select count(*)::integer from public.curriculum_import_items),
  0,
  'no curriculum text is imported while usage rights are pending'
);
select is(
  (select usage_rights_status from public.curriculum_sources
    where id = current_setting('test.source_id')::uuid),
  'permission_pending',
  'the TIE source remains blocked until its rights are reviewed'
);
select is(
  (select verification_status from public.curriculum_sources
    where id = current_setting('test.source_id')::uuid),
  'unverified',
  'the TIE source is not treated as independently verified'
);
select is(
  (select count(*)::integer from public.curriculum_version_sources
    where version_id = current_setting('test.version_id')::uuid),
  1,
  'the pilot retains a source-provenance reference'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000401',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (select count(*)::integer from public.curriculum_import_jobs),
  0,
  'parents cannot read curriculum import jobs'
);
select is(
  (select count(*)::integer from public.curriculum_source_rights_history),
  0,
  'parents cannot read internal source rights history'
);
select throws_ok(
  $$select public.register_curriculum_import_document(
    current_setting('test.version_id')::uuid,
    current_setting('test.source_id')::uuid,
    '20c75d2071d4a1726187af6c097125137ef4b0971d7a7b3834d030d5295b3591',
    'application/pdf', 'test.pdf', 1234
  )$$,
  '42501',
  null,
  'parents cannot register a curriculum import'
);
select throws_ok(
  $$update public.curriculum_sources
  set usage_rights_status = 'authorized'
  where id = current_setting('test.source_id')::uuid$$,
  '42501',
  null,
  'parents cannot clear source usage rights directly'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000402',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$select public.register_curriculum_import_document(
    current_setting('test.version_id')::uuid,
    current_setting('test.source_id')::uuid,
    '20c75d2071d4a1726187af6c097125137ef4b0971d7a7b3834d030d5295b3591',
    'application/pdf', 'test.pdf', 1234
  )$$,
  '42501',
  null,
  'editors cannot import a source whose usage rights are pending'
);
select throws_ok(
  $$select public.verify_curriculum_source(
    current_setting('test.source_id')::uuid,
    true,
    'An editor cannot verify a source'
  )$$,
  '42501',
  null,
  'editors cannot verify curriculum sources'
);
select is(
  (select verification_status from public.curriculum_sources
    where id = current_setting('test.source_id')::uuid),
  'unverified',
  'a source remains unverified until a reviewer acts'
);
select throws_ok(
  $$select public.review_curriculum_source_rights(
    current_setting('test.source_id')::uuid,
    'authorized',
    'Editor cannot clear source usage rights',
    'https://example.test/rights-evidence'
  )$$,
  '42501',
  null,
  'editors cannot make the source usage-rights decision'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000403',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$select public.verify_curriculum_source(
    current_setting('test.source_id')::uuid,
    true,
    'Fixture source verification'
  )$$,
  'an authorized reviewer can verify the registered source'
);
select throws_ok(
  $$select public.review_curriculum_source_rights(
    current_setting('test.source_id')::uuid,
    'authorized',
    'A source verifier cannot decide usage rights',
    'https://example.test/rights-evidence'
  )$$,
  '55000',
  null,
  'a source verifier cannot make the source usage-rights decision'
);
select ok(
  not public.has_curriculum_role('TZ', array['curriculum_editor']),
  'the reviewer cannot edit source imports'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000405',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$select public.review_curriculum_source_rights(
    current_setting('test.source_id')::uuid,
    'authorized',
    'Test-only rights fixture; this does not assert TIE permission.',
    'https://example.test/rights-evidence'
  )$$,
  'a separate reviewer can record a rights decision with evidence'
);
select is(
  (select usage_rights_status from public.curriculum_sources
    where id = current_setting('test.source_id')::uuid),
  'authorized',
  'the source rights decision is stored'
);
select is(
  (select count(*)::integer from public.curriculum_source_rights_history
    where source_id = current_setting('test.source_id')::uuid
      and usage_rights_status = 'authorized'),
  1,
  'source rights decisions are auditable'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000402',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select set_config(
  'test.job_id',
  (
    public.register_curriculum_import_document(
      current_setting('test.version_id')::uuid,
      current_setting('test.source_id')::uuid,
      '20c75d2071d4a1726187af6c097125137ef4b0971d7a7b3834d030d5295b3591',
      'application/pdf', 'test.pdf', 1234
    )
  ).id::text,
  true
);
select set_config(
  'test.job_path',
  (
    select storage_object_path from public.curriculum_import_jobs
    where id = current_setting('test.job_id')::uuid
  ),
  true
);
select is(
  (select status from public.curriculum_import_jobs
    where id = current_setting('test.job_id')::uuid),
  'queued',
  'an authorized editor can register an import'
);
select is(
  (
    public.register_curriculum_import_document(
      current_setting('test.version_id')::uuid,
      current_setting('test.source_id')::uuid,
      '20c75d2071d4a1726187af6c097125137ef4b0971d7a7b3834d030d5295b3591',
      'application/pdf', 'test.pdf', 1234
    )
  ).id,
  current_setting('test.job_id')::uuid,
  'repeated registration is idempotent for a source checksum'
);
select throws_ok(
  $$select public.complete_curriculum_import(
    current_setting('test.job_id')::uuid,
    '[{"page_number":1,"extracted_text":"Test-only fixture"}]'::jsonb,
    '{}'::jsonb
  )$$,
  '42501',
  null,
  'authenticated editors cannot submit extracted pages from the client'
);
select throws_ok(
  $$select public.claim_curriculum_import_job()$$,
  '42501',
  null,
  'authenticated editors cannot claim worker jobs'
);

reset role;
update public.curriculum_sources
set usage_rights_status = 'permission_pending'
where id = current_setting('test.source_id')::uuid;

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000402',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
  values (
    'curriculum-source-documents',
    current_setting('test.job_path'),
    auth.uid(),
    '{"mimetype":"application/pdf","size":1234}'
  )$$,
  '42501',
  null,
  'storage policy blocks uploads when source rights are no longer cleared'
);
select throws_ok(
  $$select public.complete_curriculum_import(
    current_setting('test.job_id')::uuid,
    '[{"page_number":1,"extracted_text":"Test-only fixture"}]'::jsonb,
    '{}'::jsonb
  )$$,
  '42501',
  null,
  'authenticated editors cannot submit extracted pages directly'
);

reset role;
update public.curriculum_sources
set usage_rights_status = 'authorized'
where id = current_setting('test.source_id')::uuid;

insert into storage.objects (bucket_id, name, owner_id, metadata)
values (
  'curriculum-source-documents',
  current_setting('test.job_path'),
  '00000000-0000-0000-0000-000000000402',
  '{"mimetype":"application/pdf","size":1234}'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000402',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select public.mark_curriculum_import_uploaded(
  current_setting('test.job_id')::uuid
);

set local role service_role;
select set_config('request.jwt.claim.role', 'service_role', true);
select is(
  (public.claim_curriculum_import_job() ->> 'id')::uuid,
  current_setting('test.job_id')::uuid,
  'only the service worker can claim an uploaded import'
);
select is(
  (public.complete_curriculum_import(
    current_setting('test.job_id')::uuid,
    '[{"page_number":1,"extracted_text":"Test-only fixture text","extraction_method":"selectable_text","page_metadata":{},"extraction_warnings":[]}]'::jsonb,
    '{"engine":"test-worker","engine_version":"1","page_count":1,"detected_content_type":"application/pdf","document_metadata":{}}'::jsonb
  )).status,
  'extracted',
  'the service worker extracts the test fixture after upload is complete'
);
reset role;
set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select is(
  (select count(*)::integer from public.curriculum_import_pages
    where job_id = current_setting('test.job_id')::uuid),
  1,
  'extracted pages are retained for source traceability'
);
select set_config(
  'test.page_id',
  (
    select id::text from public.curriculum_import_pages
    where job_id = current_setting('test.job_id')::uuid
  ),
  true
);
select lives_ok(
  $$insert into public.curriculum_import_items (
    job_id, version_id, curriculum_id, import_page_id, version_grade_id,
    item_type, official_term, source_text, normalized_text,
    normalized_fingerprint, created_by
  )
  select
    current_setting('test.job_id')::uuid,
    version.id,
    version.curriculum_id,
    current_setting('test.page_id')::uuid,
    version_grade.id,
    'topic',
    'Test fixture item',
    'Test fixture source text',
    'Fixture normalized text',
    repeat('0', 64),
    auth.uid()
  from public.curriculum_versions version
  join public.curriculum_version_grades version_grade
    on version_grade.version_id = version.id
  where version.id = current_setting('test.version_id')::uuid
  limit 1$$,
  'editors can normalize a source-linked item for human review'
);
select ok(
  (select normalized_fingerprint <> repeat('0', 64)
    from public.curriculum_import_items
    where job_id = current_setting('test.job_id')::uuid),
  'the database calculates the normalized-item fingerprint'
);
select throws_ok(
  $$insert into public.curriculum_import_items (
    job_id, version_id, curriculum_id, import_page_id, version_grade_id,
    item_type, official_term, source_text, normalized_text,
    normalized_fingerprint, created_by
  )
  select
    current_setting('test.job_id')::uuid,
    version.id,
    version.curriculum_id,
    current_setting('test.page_id')::uuid,
    version_grade.id,
    'topic',
    'Duplicate fixture item',
    'Duplicate fixture source',
    ' fixture   NORMALIZED text ',
    repeat('0', 64),
    auth.uid()
  from public.curriculum_versions version
  join public.curriculum_version_grades version_grade
    on version_grade.version_id = version.id
  where version.id = current_setting('test.version_id')::uuid
  limit 1$$,
  '23505',
  null,
  'normalized duplicate curriculum items are rejected'
);
select is(
  public.validate_curriculum_import_stage3_3(
    current_setting('test.job_id')::uuid
  ) ->> 'status',
  'in_review',
  'Stage 3.3 validation sends eligible imports to human review'
);
select ok(
  exists (
    select 1 from public.curriculum_validation_results
    where job_id = current_setting('test.job_id')::uuid
      and validator_version = 'database-stage3.3.2'
      and passed
  ),
  'Stage 3.3 validation persists its machine-readable result'
);
select throws_ok(
  $$select public.review_curriculum_import_item(
    (select id from public.curriculum_import_items
      where job_id = current_setting('test.job_id')::uuid),
    'approved',
    'Editor cannot review own import'
  )$$,
  '42501',
  null,
  'an editor cannot review an item they imported'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000403',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (select count(*)::integer from public.curriculum_import_items
    where job_id = current_setting('test.job_id')::uuid),
  1,
  'authorized reviewers can inspect draft import items'
);
select is(
  (public.review_curriculum_import_item(
    (select id from public.curriculum_import_items
      where job_id = current_setting('test.job_id')::uuid),
    'approved',
    'Test-only reviewer decision'
  )).review_status,
  'approved',
  'a separate reviewer can approve a pending source-linked item'
);
select is(
  (select status from public.curriculum_import_jobs
    where id = current_setting('test.job_id')::uuid),
  'reviewed',
  'completed independent review closes the import job'
);
select is(
  (select count(*)::integer from public.curriculum_import_item_review_history
    where item_id = (
      select id from public.curriculum_import_items
      where job_id = current_setting('test.job_id')::uuid
    )),
  1,
  'item review decisions are recorded in history'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000402',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$select public.transition_curriculum_version(
    current_setting('test.version_id')::uuid,
    'under_review',
    'Test-only import is ready for version review'
  )$$,
  'editors can submit a completed import for version review'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000403',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$select public.transition_curriculum_version(
    current_setting('test.version_id')::uuid,
    'approved',
    'A reviewer cannot approve their own reviewed version'
  )$$,
  '42501',
  null,
  'an item reviewer cannot approve the version they reviewed'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000404',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$select public.transition_curriculum_version(
    current_setting('test.version_id')::uuid,
    'approved',
    'Test-only independent approver'
  )$$,
  'a separate authorized approver can approve a reviewed version'
);
select lives_ok(
  $$select public.transition_curriculum_version(
    current_setting('test.version_id')::uuid,
    'published',
    'Test-only publication'
  )$$,
  'the independently approved test version can be published'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000401',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (select count(*)::integer from public.curriculum_import_items
    where job_id = current_setting('test.job_id')::uuid
      and review_status = 'approved'),
  1,
  'parents can read only approved items from a published version'
);
select is(
  (select count(*)::integer from public.curriculum_import_pages),
  0,
  'parents cannot read imported source pages'
);
select is(
  (select count(*)::integer from public.curriculum_import_item_review_history),
  0,
  'parents cannot read internal item-review history'
);
select is(
  (select count(*)::integer from public.curriculum_validation_results),
  0,
  'parents cannot read internal validation reports'
);
select is(
  (select count(*)::integer from public.curriculum_duplicate_matches),
  0,
  'parents cannot read internal duplicate-match reviews'
);
select lives_ok(
  $$delete from public.curriculum_import_items
  where job_id = current_setting('test.job_id')::uuid$$,
  'parents cannot alter curriculum import items'
);
select is(
  (select count(*)::integer from public.curriculum_import_items
    where job_id = current_setting('test.job_id')::uuid),
  1,
  'row-level security prevents parent deletion of curriculum items'
);

select * from finish();
rollback;
