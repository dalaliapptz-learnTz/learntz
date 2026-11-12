begin;

select plan(34);

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
    '00000000-0000-0000-0000-000000000501',
    'authenticated',
    'authenticated',
    'stage33-parent@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Stage 3.3 Parent","country_code":"TZ"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000502',
    'authenticated',
    'authenticated',
    'stage33-tz-editor@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Stage 3.3 TZ Editor","country_code":"TZ"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000503',
    'authenticated',
    'authenticated',
    'stage33-tz-verifier@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Stage 3.3 Verifier","country_code":"TZ"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000504',
    'authenticated',
    'authenticated',
    'stage33-tz-reviewer@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Stage 3.3 Reviewer","country_code":"TZ"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000505',
    'authenticated',
    'authenticated',
    'stage33-ke-editor@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Stage 3.3 KE Editor","country_code":"KE"}',
    now(),
    now()
  );

insert into public.user_roles (user_id, role, country_code)
values
  ('00000000-0000-0000-0000-000000000502', 'curriculum_editor', 'TZ'),
  ('00000000-0000-0000-0000-000000000503', 'curriculum_reviewer', 'TZ'),
  ('00000000-0000-0000-0000-000000000504', 'curriculum_reviewer', 'TZ'),
  ('00000000-0000-0000-0000-000000000505', 'curriculum_editor', 'KE'),
  ('00000000-0000-0000-0000-000000000503', 'curriculum_reviewer', 'KE'),
  ('00000000-0000-0000-0000-000000000504', 'curriculum_reviewer', 'KE');

-- Resolve seeded TZ curriculum & version fixtures
select set_config(
  'test.tz_version_id',
  (
    select id::text from public.curriculum_versions
    where version_code = 'tie-primary-pilot-source-review-1'
  ),
  true
);
select set_config(
  'test.tz_curriculum_id',
  (
    select curriculum_id::text from public.curriculum_versions
    where id = current_setting('test.tz_version_id')::uuid
  ),
  true
);
select set_config(
  'test.tz_authority_id',
  (
    select authority_id::text from public.curricula
    where id = current_setting('test.tz_curriculum_id')::uuid
  ),
  true
);

-- Provision verified & usage-rights-cleared TZ sources for each supported MIME format
insert into public.curriculum_sources (
  id, authority_id, document_title, issuing_institution,
  source_url, document_format, sha256_checksum, usage_permissions,
  verification_status, verified_by, verified_at,
  usage_rights_status, usage_rights_reviewed_by, usage_rights_reviewed_at,
  usage_rights_note, usage_rights_evidence_url, created_by
)
values
  (
    '70000000-0000-0000-0000-000000000001',
    current_setting('test.tz_authority_id')::uuid,
    'Stage 3.3 PDF Test Fixture',
    'Tanzania Institute of Education',
    'https://example.test/stage33-pdf-source',
    'application/pdf',
    repeat('1', 64),
    'Test fixture only',
    'verified', '00000000-0000-0000-0000-000000000503', now(),
    'authorized', '00000000-0000-0000-0000-000000000504', now(),
    'Cleared test fixture', 'https://example.test/stage33-pdf',
    '00000000-0000-0000-0000-000000000502'
  ),
  (
    '70000000-0000-0000-0000-000000000002',
    current_setting('test.tz_authority_id')::uuid,
    'Stage 3.3 DOCX Test Fixture',
    'Tanzania Institute of Education',
    'https://example.test/stage33-docx-source',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    repeat('2', 64),
    'Test fixture only',
    'verified', '00000000-0000-0000-0000-000000000503', now(),
    'authorized', '00000000-0000-0000-0000-000000000504', now(),
    'Cleared test fixture', 'https://example.test/stage33-docx',
    '00000000-0000-0000-0000-000000000502'
  ),
  (
    '70000000-0000-0000-0000-000000000003',
    current_setting('test.tz_authority_id')::uuid,
    'Stage 3.3 XLSX Test Fixture',
    'Tanzania Institute of Education',
    'https://example.test/stage33-xlsx-source',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    repeat('3', 64),
    'Test fixture only',
    'verified', '00000000-0000-0000-0000-000000000503', now(),
    'authorized', '00000000-0000-0000-0000-000000000504', now(),
    'Cleared test fixture', 'https://example.test/stage33-xlsx',
    '00000000-0000-0000-0000-000000000502'
  ),
  (
    '70000000-0000-0000-0000-000000000004',
    current_setting('test.tz_authority_id')::uuid,
    'Stage 3.3 CSV Test Fixture',
    'Tanzania Institute of Education',
    'https://example.test/stage33-csv-source',
    'text/csv',
    repeat('4', 64),
    'Test fixture only',
    'verified', '00000000-0000-0000-0000-000000000503', now(),
    'authorized', '00000000-0000-0000-0000-000000000504', now(),
    'Cleared test fixture', 'https://example.test/stage33-csv',
    '00000000-0000-0000-0000-000000000502'
  ),
  (
    '70000000-0000-0000-0000-000000000005',
    current_setting('test.tz_authority_id')::uuid,
    'Stage 3.3 JSON Test Fixture',
    'Tanzania Institute of Education',
    'https://example.test/stage33-json-source',
    'application/json',
    repeat('5', 64),
    'Test fixture only',
    'verified', '00000000-0000-0000-0000-000000000503', now(),
    'authorized', '00000000-0000-0000-0000-000000000504', now(),
    'Cleared test fixture', 'https://example.test/stage33-json',
    '00000000-0000-0000-0000-000000000502'
  );

insert into public.curriculum_version_sources (
  version_id, curriculum_id, authority_id, source_id, created_by
)
values
  (
    current_setting('test.tz_version_id')::uuid,
    current_setting('test.tz_curriculum_id')::uuid,
    current_setting('test.tz_authority_id')::uuid,
    '70000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000502'
  ),
  (
    current_setting('test.tz_version_id')::uuid,
    current_setting('test.tz_curriculum_id')::uuid,
    current_setting('test.tz_authority_id')::uuid,
    '70000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000502'
  ),
  (
    current_setting('test.tz_version_id')::uuid,
    current_setting('test.tz_curriculum_id')::uuid,
    current_setting('test.tz_authority_id')::uuid,
    '70000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000502'
  ),
  (
    current_setting('test.tz_version_id')::uuid,
    current_setting('test.tz_curriculum_id')::uuid,
    current_setting('test.tz_authority_id')::uuid,
    '70000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000502'
  ),
  (
    current_setting('test.tz_version_id')::uuid,
    current_setting('test.tz_curriculum_id')::uuid,
    current_setting('test.tz_authority_id')::uuid,
    '70000000-0000-0000-0000-000000000005',
    '00000000-0000-0000-0000-000000000502'
  );

-- Provision Kenya (KE) multi-country test fixtures for Storage RLS testing
insert into public.education_systems (id, country_code, name, code, is_enabled)
values ('80000000-0000-0000-0000-000000000001', 'KE', 'Kenya CBC System', 'KE_CBC_TEST', true);

insert into public.curriculum_authorities (
  id, country_code, education_system_id, name, code, website_url, is_enabled
)
values (
  '80000000-0000-0000-0000-000000000002',
  'KE',
  '80000000-0000-0000-0000-000000000001',
  'Kenya Institute of Curriculum Development',
  'KICD_TEST',
  'https://kicd.ac.ke',
  true
);

insert into public.curricula (
  id, country_code, education_system_id, authority_id, name, code, is_enabled
)
values (
  '80000000-0000-0000-0000-000000000003',
  'KE',
  '80000000-0000-0000-0000-000000000001',
  '80000000-0000-0000-0000-000000000002',
  'KICD Competency Based Curriculum',
  'KICD_CBC',
  true
);

insert into public.curriculum_versions (
  id, curriculum_id, version_code, display_name, status,
  requires_reviewed_import, created_by
)
values (
  '80000000-0000-0000-0000-000000000004',
  '80000000-0000-0000-0000-000000000003',
  'kicd-primary-stage33-test',
  'KICD Primary Stage 3.3 Test Version',
  'draft',
  true,
  '00000000-0000-0000-0000-000000000505'
);

insert into public.curriculum_sources (
  id, authority_id, document_title, issuing_institution,
  source_url, document_format, sha256_checksum, usage_permissions,
  verification_status, verified_by, verified_at,
  usage_rights_status, usage_rights_reviewed_by, usage_rights_reviewed_at,
  usage_rights_note, usage_rights_evidence_url, created_by
)
values (
  '80000000-0000-0000-0000-000000000005',
  '80000000-0000-0000-0000-000000000002',
  'Stage 3.3 KE PDF Fixture',
  'Kenya Institute of Curriculum Development',
  'https://example.test/stage33-ke-pdf-source',
  'application/pdf',
  repeat('6', 64),
  'Test fixture only',
  'verified', '00000000-0000-0000-0000-000000000503', now(),
  'authorized', '00000000-0000-0000-0000-000000000504', now(),
  'Cleared test fixture', 'https://example.test/stage33-ke-pdf',
  '00000000-0000-0000-0000-000000000505'
);

insert into public.curriculum_version_sources (
  version_id, curriculum_id, authority_id, source_id, created_by
)
values (
  '80000000-0000-0000-0000-000000000004',
  '80000000-0000-0000-0000-000000000003',
  '80000000-0000-0000-0000-000000000002',
  '80000000-0000-0000-0000-000000000005',
  '00000000-0000-0000-0000-000000000505'
);

-- 1. Document format and size validation (Assertions 1-9)
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000502', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$select public.register_curriculum_import_document(
    current_setting('test.tz_version_id')::uuid,
    '70000000-0000-0000-0000-000000000001',
    repeat('1', 64), 'text/plain', 'syllabus.txt', 1200
  )$$,
  '22023', null,
  'unsupported text/plain format is rejected'
);

select throws_ok(
  $$select public.register_curriculum_import_document(
    current_setting('test.tz_version_id')::uuid,
    '70000000-0000-0000-0000-000000000001',
    repeat('1', 64), 'application/pdf', 'syllabus.txt', 1200
  )$$,
  '22023', null,
  'mismatched filename extension is rejected'
);

select throws_ok(
  $$select public.register_curriculum_import_document(
    current_setting('test.tz_version_id')::uuid,
    '70000000-0000-0000-0000-000000000001',
    repeat('1', 64), 'application/pdf', 'oversized.pdf', 26214401
  )$$,
  '22023', null,
  'files over 25 MiB are rejected'
);

select set_config(
  'test.tz_pdf_job_id',
  (public.register_curriculum_import_document(
    current_setting('test.tz_version_id')::uuid,
    '70000000-0000-0000-0000-000000000001',
    repeat('1', 64), 'application/pdf', 'syllabus.pdf', 2048
  )).id::text,
  true
);
select isnt(
  current_setting('test.tz_pdf_job_id'), '',
  'application/pdf document registers successfully'
);

select set_config(
  'test.tz_pdf_path',
  (select storage_object_path from public.curriculum_import_jobs
    where id = current_setting('test.tz_pdf_job_id')::uuid),
  true
);
select ok(
  current_setting('test.tz_pdf_path') like 'TZ/%',
  'TZ import path uses TZ country prefix'
);

select lives_ok(
  $$select public.register_curriculum_import_document(
    current_setting('test.tz_version_id')::uuid,
    '70000000-0000-0000-0000-000000000002',
    repeat('2', 64),
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'syllabus.docx', 4096
  )$$,
  'docx document format registers successfully'
);

select lives_ok(
  $$select public.register_curriculum_import_document(
    current_setting('test.tz_version_id')::uuid,
    '70000000-0000-0000-0000-000000000003',
    repeat('3', 64),
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'syllabus.xlsx', 4096
  )$$,
  'xlsx document format registers successfully'
);

select lives_ok(
  $$select public.register_curriculum_import_document(
    current_setting('test.tz_version_id')::uuid,
    '70000000-0000-0000-0000-000000000004',
    repeat('4', 64),
    'text/csv', 'syllabus.csv', 1024
  )$$,
  'csv document format registers successfully'
);

select lives_ok(
  $$select public.register_curriculum_import_document(
    current_setting('test.tz_version_id')::uuid,
    '70000000-0000-0000-0000-000000000005',
    repeat('5', 64),
    'application/json', 'syllabus.json', 1024
  )$$,
  'json document format registers successfully'
);

-- 2. Storage RLS upload & cross-country checks on TZ editor (Assertions 10-11)
select lives_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
  values (
    'curriculum-source-documents',
    current_setting('test.tz_pdf_path'),
    auth.uid(),
    '{"mimetype":"application/pdf","size":2048}'
  )$$,
  'TZ editor can upload registered TZ source document'
);

select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
  values (
    'curriculum-source-documents',
    'KE/80000000-0000-0000-0000-000000000005/80000000-0000-0000-0000-000000000099.pdf',
    auth.uid(),
    '{"mimetype":"application/pdf","size":2048}'
  )$$,
  '42501', null,
  'TZ editor cannot upload to KE storage prefix'
);

select public.mark_curriculum_import_uploaded(current_setting('test.tz_pdf_job_id')::uuid);

-- 3. Authenticated users blocked from worker-only RPCs (Assertions 12-14)
select throws_ok(
  $$select public.claim_curriculum_import_job()$$,
  '42501', null,
  'authenticated users cannot claim worker import jobs'
);
select throws_ok(
  $$select public.renew_curriculum_import_lease(current_setting('test.tz_pdf_job_id')::uuid)$$,
  '42501', null,
  'authenticated users cannot renew worker leases'
);
select throws_ok(
  $$select public.fail_curriculum_import(
    current_setting('test.tz_pdf_job_id')::uuid, 'nope', 'processing_failed', true, null, '{}'::jsonb
  )$$,
  '42501', null,
  'authenticated users cannot fail worker jobs'
);

-- 4. Worker job claiming, lease renewal, lease expiry recovery & exhaustion (Assertions 15-22)
reset role;
set local role service_role;
select set_config('request.jwt.claim.role', 'service_role', true);

select set_config(
  'test.claimed_payload',
  public.claim_curriculum_import_job()::text,
  true
);
select is(
  (current_setting('test.claimed_payload')::jsonb ->> 'id')::uuid,
  current_setting('test.tz_pdf_job_id')::uuid,
  'service_role claims uploaded queued job'
);
select is(
  (current_setting('test.claimed_payload')::jsonb ->> 'attempt_count')::integer,
  2,
  'first claim increments attempt_count from default 1 to 2'
);
select is(
  public.claim_curriculum_import_job(),
  null::jsonb,
  'active processing job with valid lease is not double-claimed (SKIP LOCKED / lease guard)'
);
select lives_ok(
  $$select public.renew_curriculum_import_lease(current_setting('test.tz_pdf_job_id')::uuid)$$,
  'worker can renew an active processing lease'
);

-- Simulate worker crash / lease expiry
reset role;
update public.curriculum_import_jobs
set processing_lease_expires_at = now() - interval '1 minute'
where id = current_setting('test.tz_pdf_job_id')::uuid;

set local role service_role;
select set_config('request.jwt.claim.role', 'service_role', true);

select throws_ok(
  $$select public.renew_curriculum_import_lease(current_setting('test.tz_pdf_job_id')::uuid)$$,
  '55000', null,
  'renewing an expired lease raises 55000'
);
select throws_ok(
  $$select public.complete_curriculum_import(
    current_setting('test.tz_pdf_job_id')::uuid,
    '[{"page_number":1,"extracted_text":"Stale worker output","extraction_method":"selectable_text","page_metadata":{},"extraction_warnings":[]}]'::jsonb,
    '{"engine":"worker","engine_version":"1"}'::jsonb
  )$$,
  '55000', null,
  'stale worker with expired lease cannot complete the import'
);

select set_config(
  'test.recovered_payload',
  public.claim_curriculum_import_job()::text,
  true
);
select is(
  (current_setting('test.recovered_payload')::jsonb ->> 'attempt_count')::integer,
  3,
  'secondary worker recovers expired job and increments attempt_count to 3'
);

-- Verify attempt exhaustion marks processing job as failed on next claim
reset role;
update public.curriculum_import_jobs
set attempt_count = 5,
    processing_lease_expires_at = now() - interval '1 minute'
where id = current_setting('test.tz_pdf_job_id')::uuid;

set local role service_role;
select set_config('request.jwt.claim.role', 'service_role', true);
select is(
  public.claim_curriculum_import_job(),
  null::jsonb,
  'claim_curriculum_import_job does not re-claim jobs at max attempts'
);
select is(
  (select status from public.curriculum_import_jobs
    where id = current_setting('test.tz_pdf_job_id')::uuid),
  'failed',
  'exhausted processing job is transitioned to failed on lease expiry sweep'
);

-- Reset job lease to complete extraction for duplicate gate testing (Assertions 23-29)
reset role;
update public.curriculum_import_jobs
set status = 'processing',
    attempt_count = 2,
    processing_lease_expires_at = now() + interval '15 minutes',
    completed_at = null,
    last_error = null
where id = current_setting('test.tz_pdf_job_id')::uuid;

set local role service_role;
select set_config('request.jwt.claim.role', 'service_role', true);
select is(
  (public.complete_curriculum_import(
    current_setting('test.tz_pdf_job_id')::uuid,
    '[{"page_number":1,"extracted_text":"Standard 1 Counting Objects","extraction_method":"selectable_text","page_metadata":{},"extraction_warnings":[]}]'::jsonb,
    '{"engine":"learntz-curriculum-worker","engine_version":"1.0.0","detected_content_type":"application/pdf"}'::jsonb
  )).status,
  'extracted',
  'active worker completes extraction and transitions job to extracted'
);

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000502', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

with target_grade as (
  select version.id as version_id,
    version.curriculum_id,
    page.id as import_page_id,
    version_grade.id as version_grade_id
  from public.curriculum_versions version
  join public.curriculum_version_grades version_grade
    on version_grade.version_id = version.id
  join public.curriculum_import_pages page
    on page.job_id = current_setting('test.tz_pdf_job_id')::uuid
  where version.id = current_setting('test.tz_version_id')::uuid
  order by version_grade.id, page.page_number
  limit 1
)
insert into public.curriculum_import_items (
  job_id, version_id, curriculum_id, import_page_id, version_grade_id,
  item_type, official_term, source_text, normalized_text,
  normalized_fingerprint, created_by
)
select
  current_setting('test.tz_pdf_job_id')::uuid,
  target_grade.version_id,
  target_grade.curriculum_id,
  target_grade.import_page_id,
  target_grade.version_grade_id,
  'topic',
  seed.term_name,
  seed.source_text,
  seed.normalized_val,
  repeat('0', 64),
  auth.uid()
from target_grade
cross join (
  values
    ('Counting objects 1 to 10', 'Counting objects 1 to 10', 'Counting whole numbers from 1 to 10 in primary mathematics'),
    ('Counting objects 1 to 9', 'Counting objects 1 to 9', 'Counting whole numbers from 1 to 9 in primary mathematics')
) as seed(term_name, source_text, normalized_val);

select ok(
  public.detect_curriculum_import_duplicates(current_setting('test.tz_pdf_job_id')::uuid) >= 1,
  'duplicate detection identifies similar candidate items (pg_trgm >= 0.72)'
);

select is(
  public.validate_curriculum_import_stage3_3(current_setting('test.tz_pdf_job_id')::uuid) ->> 'status',
  'validation_failed',
  'validation flags unresolved duplicate candidates before review completes'
);

-- Verify duplicate review trigger blocks reviewed transition until resolved
reset role;
select throws_ok(
  $$update public.curriculum_import_jobs
  set status = 'reviewed'
  where id = current_setting('test.tz_pdf_job_id')::uuid$$,
  '23514', null,
  'trigger blocks transition to reviewed while duplicate matches remain pending'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000503', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select set_config(
  'test.dup_match_id',
  (select id::text from public.curriculum_duplicate_matches
    where job_id = current_setting('test.tz_pdf_job_id')::uuid
    order by created_at limit 1),
  true
);

select public.review_curriculum_duplicate_match(
  current_setting('test.dup_match_id')::uuid,
  'deferred',
  'Needs follow-up check'
);

reset role;
select throws_ok(
  $$update public.curriculum_import_jobs
  set status = 'reviewed'
  where id = current_setting('test.tz_pdf_job_id')::uuid$$,
  '23514', null,
  'trigger still blocks transition to reviewed while a match is deferred'
);

update public.curriculum_duplicate_matches
set decision = 'confirmed_duplicate',
    reviewer_user_id = '00000000-0000-0000-0000-000000000503',
    reviewed_at = now()
where job_id = current_setting('test.tz_pdf_job_id')::uuid;

select lives_ok(
  $$update public.curriculum_import_jobs
  set status = 'reviewed'
  where id = current_setting('test.tz_pdf_job_id')::uuid$$,
  'trigger permits reviewed status after all duplicate candidates are resolved'
);

-- 5. Multi-country Storage RLS upload and replace checks on KE editor (Assertions 29-34)
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000505', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select set_config(
  'test.ke_job_id',
  (public.register_curriculum_import_document(
    '80000000-0000-0000-0000-000000000004',
    '80000000-0000-0000-0000-000000000005',
    repeat('6', 64),
    'application/pdf', 'kicd_primary.pdf', 3072
  )).id::text,
  true
);
select set_config(
  'test.ke_job_path',
  (select storage_object_path from public.curriculum_import_jobs
    where id = current_setting('test.ke_job_id')::uuid),
  true
);

select ok(
  current_setting('test.ke_job_path') like 'KE/%',
  'KE import registration generates KE-prefixed storage_object_path'
);

select lives_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
  values (
    'curriculum-source-documents',
    current_setting('test.ke_job_path'),
    auth.uid(),
    '{"mimetype":"application/pdf","size":3072}'
  )$$,
  'KE editor can upload source document to KE storage path'
);

select lives_ok(
  $$update storage.objects
  set metadata = '{"mimetype":"application/pdf","size":3072,"replaced":true}'
  where bucket_id = 'curriculum-source-documents'
    and name = current_setting('test.ke_job_path')$$,
  'KE editor can replace unprocessed queued document in storage'
);

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000501', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
  values (
    'curriculum-source-documents',
    current_setting('test.ke_job_path'),
    auth.uid(),
    '{"mimetype":"application/pdf","size":3072}'
  )$$,
  '42501', null,
  'non-staff parents cannot upload to curriculum storage bucket'
);

reset role;
update public.curriculum_import_jobs
set status = 'extracted'
where id = current_setting('test.ke_job_id')::uuid;

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000505', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

update storage.objects
set metadata = '{"mimetype":"application/pdf","size":3072,"tampered":true}'
where bucket_id = 'curriculum-source-documents'
  and name = current_setting('test.ke_job_path');

reset role;
select ok(
  not exists (
    select 1 from storage.objects
    where bucket_id = 'curriculum-source-documents'
      and name = current_setting('test.ke_job_path')
      and metadata ->> 'tampered' = 'true'
  ),
  'storage replace policy blocks overwriting document once job is extracted'
);

select * from finish();
rollback;
