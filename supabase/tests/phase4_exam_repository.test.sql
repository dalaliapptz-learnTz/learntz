begin;

select plan(21);

-- 1. Table structure tests
select has_table('public', 'examination_authorities', 'examination_authorities table exists');
select has_table('public', 'national_examinations', 'national_examinations table exists');
select has_table('public', 'examination_papers', 'examination_papers table exists');
select has_table('public', 'examination_paper_uploads', 'examination_paper_uploads table exists');

-- 2. Seeded examination authorities test
select is(
  (select count(*)::integer from public.examination_authorities where id in ('NECTA', 'KNEC', 'UNEB')),
  3,
  'East African examination authorities (NECTA, KNEC, UNEB) are seeded'
);

-- 3. Seeded national examinations test
select is(
  (select count(*)::integer from public.national_examinations where country_code = 'TZ'),
  3,
  'Tanzania national examinations (PSLE, CSEE, ACSEE) are seeded'
);

select is(
  (select count(*)::integer from public.national_examinations where country_code = 'KE'),
  2,
  'Kenya national examinations (KPSEA, KCSE) are seeded'
);

select is(
  (select count(*)::integer from public.national_examinations where country_code = 'UG'),
  2,
  'Uganda national examinations (PLE, UCE) are seeded'
);

-- 4. Multi-tier examination papers test
select is(
  (select count(*)::integer from public.examination_papers where tier = 'national'),
  4,
  'National tier official papers are seeded'
);

select is(
  (select count(*)::integer from public.examination_papers where tier = 'regional'),
  3,
  'Regional mock examination papers are seeded'
);

select is(
  (select count(*)::integer from public.examination_papers where tier = 'district'),
  1,
  'District mock examination papers are seeded'
);

-- 5. Test RPC get_national_examination_centre_catalog for Tanzania
select is(
  (select jsonb_array_length((public.get_national_examination_centre_catalog('TZ')->'authorities'))::integer),
  1,
  'Catalog returns 1 authority for TZ (NECTA)'
);

select is(
  (select jsonb_array_length((public.get_national_examination_centre_catalog('TZ')->'examinations'))::integer),
  3,
  'Catalog returns 3 national examinations for TZ'
);

select isnt_empty(
  'select public.get_national_examination_centre_catalog(''TZ'')',
  'Catalog for TZ executes successfully'
);

-- 6. Test RPC list_examination_papers with various filters
select is(
  (select (public.list_examination_papers('TZ', null, null, null, null, 2024, null, 10, 0)->>'total_count')::integer),
  5,
  'list_examination_papers finds 5 TZ papers for year 2024'
);

select is(
  (select (public.list_examination_papers('TZ', null, null, null, 'regional', null, null, 10, 0)->>'total_count')::integer),
  2,
  'list_examination_papers finds 2 regional mock papers for TZ'
);

select is(
  (select (public.list_examination_papers(null, null, null, null, null, null, 'Mathematics', 10, 0)->>'total_count')::integer),
  3,
  'list_examination_papers search finds 3 Mathematics papers across regions'
);

-- 7. Test RPC get_examination_paper_details
select is(
  (select public.get_examination_paper_details('40000000-0000-0000-0000-000000000001'::uuid)->>'subject_name'),
  'Basic Mathematics',
  'get_examination_paper_details returns Basic Mathematics paper'
);

select is(
  (select public.get_examination_paper_details('40000000-0000-0000-0000-000000000001'::uuid)->>'authority_id'),
  'NECTA',
  'get_examination_paper_details returns authority NECTA'
);

-- 8. Test RPC upload_examination_paper
-- Create test user
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-0000-0000-000000000401',
  'authenticated', 'authenticated',
  'teacher-exam@example.test', '', now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Exam Teacher","country_code":"TZ"}',
  now(), now()
);

-- Set user context
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000401', true);

select isnt_empty(
  $$ select public.upload_examination_paper(
    'TZ',
    'NECTA',
    'Arusha Regional Mock 2024 Physics',
    2024,
    'regional',
    'Arusha',
    'Arusha City',
    null,
    'https://storage.learntz.test/arusha_mock_2024.pdf',
    2048576,
    'Teacher submitted regional mock'
  ) $$,
  'Authenticated teacher can upload mock examination paper'
);

-- Verify upload record
reset role;
select is(
  (select count(*)::integer from public.examination_paper_uploads where uploaded_by = '00000000-0000-0000-0000-000000000401'::uuid),
  1,
  'Uploaded paper is recorded in examination_paper_uploads table'
);

select * from finish();
rollback;
