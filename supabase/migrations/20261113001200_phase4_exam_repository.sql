-- LearnTZ Phase 4 — Examination and Mock Examination Intelligence Platform
-- Sub-Stage 1: National Examination Centre, Historical Paper Repository & Multi-Tier Mock Upload Centre
-- Tasks: TASK-401, TASK-402, TASK-403

begin;

-- ============================================================================
-- 1. Table: examination_authorities
-- ============================================================================
create table if not exists public.examination_authorities (
  id text primary key, -- 'NECTA', 'KNEC', 'UNEB'
  country_code text not null references public.countries (country_code) on delete restrict,
  name text not null check (char_length(btrim(name)) between 2 and 200),
  description text not null default '',
  website_url text,
  logo_url text,
  is_accredited boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists examination_authorities_country_idx
  on public.examination_authorities (country_code, is_accredited);

create trigger examination_authorities_set_updated_at
  before update on public.examination_authorities
  for each row execute function public.set_updated_at();

alter table public.examination_authorities enable row level security;
revoke all on public.examination_authorities from public, anon, authenticated;
grant select on public.examination_authorities to anon, authenticated;
grant insert, update, delete on public.examination_authorities to authenticated;

create policy "Anyone reads examination authorities"
  on public.examination_authorities for select
  using (true);

create policy "Super admins manage examination authorities"
  on public.examination_authorities for all to authenticated
  using (public.has_role('super_admin'))
  with check (public.has_role('super_admin'));

-- ============================================================================
-- 2. Table: national_examinations
-- ============================================================================
create table if not exists public.national_examinations (
  id text primary key, -- 'TZ-PSLE', 'TZ-CSEE', 'TZ-ACSEE', 'KE-KCSE', 'UG-UCE'
  authority_id text not null references public.examination_authorities (id) on delete cascade,
  country_code text not null references public.countries (country_code) on delete restrict,
  education_level_id uuid references public.education_levels (id) on delete set null,
  code text not null check (char_length(btrim(code)) between 1 and 40),
  title text not null check (char_length(btrim(title)) between 2 and 200),
  education_level text not null,
  grading_system text not null default 'division' check (grading_system in ('division', 'mean_grade', 'aggregates', 'cbc_performance')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists national_examinations_auth_country_idx
  on public.national_examinations (authority_id, country_code, is_active);

create trigger national_examinations_set_updated_at
  before update on public.national_examinations
  for each row execute function public.set_updated_at();

alter table public.national_examinations enable row level security;
revoke all on public.national_examinations from public, anon, authenticated;
grant select on public.national_examinations to anon, authenticated;
grant insert, update, delete on public.national_examinations to authenticated;

create policy "Anyone reads active national examinations"
  on public.national_examinations for select
  using (is_active or public.has_role('super_admin'));

create policy "Admins manage national examinations"
  on public.national_examinations for all to authenticated
  using (
    public.has_role('super_admin')
    or public.has_role('curriculum_admin', national_examinations.country_code)
  )
  with check (
    public.has_role('super_admin')
    or public.has_role('curriculum_admin', national_examinations.country_code)
  );

-- ============================================================================
-- 3. Table: examination_papers
-- ============================================================================
create table if not exists public.examination_papers (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries (country_code) on delete restrict,
  national_examination_id text references public.national_examinations (id) on delete set null,
  authority_id text not null references public.examination_authorities (id) on delete cascade,
  subject_id uuid references public.subjects (id) on delete set null,
  subject_name text not null check (char_length(btrim(subject_name)) between 1 and 100),
  paper_number integer not null default 1 check (paper_number between 1 and 10),
  paper_title text not null check (char_length(btrim(paper_title)) between 2 and 250),
  year integer not null check (year between 1990 and 2050),
  paper_type text not null check (paper_type in ('official_national', 'regional_mock', 'district_mock', 'school_mock', 'curated_practice')),
  tier text not null check (tier in ('national', 'regional', 'district', 'school')),
  region text,
  district text,
  school_name text,
  term integer check (term is null or term between 1 and 3),
  duration_minutes integer not null default 150 check (duration_minutes between 15 and 360),
  total_marks numeric not null default 100 check (total_marks between 1 and 500),
  instructions text,
  sections_config jsonb not null default '[]'::jsonb,
  pdf_storage_path text,
  marking_scheme_storage_path text,
  is_published boolean not null default true,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists examination_papers_filter_idx
  on public.examination_papers (country_code, authority_id, national_examination_id, year, tier, is_published);

create index if not exists examination_papers_subject_idx
  on public.examination_papers (subject_name, year, is_published);

create trigger examination_papers_set_updated_at
  before update on public.examination_papers
  for each row execute function public.set_updated_at();

alter table public.examination_papers enable row level security;
revoke all on public.examination_papers from public, anon, authenticated;
grant select on public.examination_papers to anon, authenticated;
grant insert, update, delete on public.examination_papers to authenticated;

create policy "Anyone reads published examination papers"
  on public.examination_papers for select
  using (
    is_published
    or public.has_role('super_admin')
    or public.has_role('curriculum_admin', examination_papers.country_code)
  );

create policy "Staff manages examination papers"
  on public.examination_papers for all to authenticated
  using (
    public.has_role('super_admin')
    or public.has_role('curriculum_admin', examination_papers.country_code)
  )
  with check (
    public.has_role('super_admin')
    or public.has_role('curriculum_admin', examination_papers.country_code)
  );

-- ============================================================================
-- 4. Table: examination_paper_uploads
-- ============================================================================
create table if not exists public.examination_paper_uploads (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries (country_code) on delete restrict,
  uploaded_by uuid not null references auth.users (id) on delete cascade,
  authority_id text references public.examination_authorities (id) on delete set null,
  title text not null check (char_length(btrim(title)) between 2 and 200),
  year integer not null check (year between 1990 and 2050),
  tier text not null check (tier in ('national', 'regional', 'district', 'school')),
  region text,
  district text,
  school_name text,
  file_url text not null,
  file_size_bytes bigint check (file_size_bytes is null or file_size_bytes > 0),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'processed')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists examination_paper_uploads_status_idx
  on public.examination_paper_uploads (country_code, status, uploaded_by);

create trigger examination_paper_uploads_set_updated_at
  before update on public.examination_paper_uploads
  for each row execute function public.set_updated_at();

alter table public.examination_paper_uploads enable row level security;
revoke all on public.examination_paper_uploads from public, anon, authenticated;
grant select, insert on public.examination_paper_uploads to authenticated;
grant update, delete on public.examination_paper_uploads to authenticated;

create policy "Users read own uploads or admins read all"
  on public.examination_paper_uploads for select to authenticated
  using (
    uploaded_by = auth.uid()
    or public.has_role('super_admin')
    or public.has_role('curriculum_admin', examination_paper_uploads.country_code)
  );

create policy "Authenticated users insert uploads"
  on public.examination_paper_uploads for insert to authenticated
  with check (uploaded_by = auth.uid());

create policy "Staff updates upload status"
  on public.examination_paper_uploads for update to authenticated
  using (
    public.has_role('super_admin')
    or public.has_role('curriculum_admin', examination_paper_uploads.country_code)
  )
  with check (
    public.has_role('super_admin')
    or public.has_role('curriculum_admin', examination_paper_uploads.country_code)
  );

-- ============================================================================
-- 5. Storage Bucket: examination-papers
-- ============================================================================
insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'examination-papers',
  'examination-papers',
  true,
  52428800,
  array['application/pdf', 'image/png', 'image/jpeg']
)
on conflict (id) do update
  set public = true,
      file_size_limit = 52428800,
      allowed_mime_types = array['application/pdf', 'image/png', 'image/jpeg'];

-- ============================================================================
-- 6. RPC: get_national_examination_centre_catalog
-- ============================================================================
create or replace function public.get_national_examination_centre_catalog(
  p_country_code text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_authorities jsonb;
  v_examinations jsonb;
  v_recent_papers jsonb;
  v_tier_counts jsonb;
begin
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', ea.id,
        'country_code', ea.country_code,
        'name', ea.name,
        'description', ea.description,
        'website_url', ea.website_url,
        'logo_url', ea.logo_url,
        'is_accredited', ea.is_accredited
      ) order by ea.id
    ),
    '[]'::jsonb
  ) into v_authorities
  from public.examination_authorities ea
  where p_country_code is null or ea.country_code = p_country_code;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', ne.id,
        'authority_id', ne.authority_id,
        'country_code', ne.country_code,
        'code', ne.code,
        'title', ne.title,
        'education_level', ne.education_level,
        'grading_system', ne.grading_system,
        'is_active', ne.is_active
      ) order by ne.code
    ),
    '[]'::jsonb
  ) into v_examinations
  from public.national_examinations ne
  where (p_country_code is null or ne.country_code = p_country_code)
    and ne.is_active = true;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', ep.id,
        'country_code', ep.country_code,
        'national_examination_id', ep.national_examination_id,
        'authority_id', ep.authority_id,
        'subject_name', ep.subject_name,
        'paper_number', ep.paper_number,
        'paper_title', ep.paper_title,
        'year', ep.year,
        'paper_type', ep.paper_type,
        'tier', ep.tier,
        'region', ep.region,
        'district', ep.district,
        'school_name', ep.school_name,
        'duration_minutes', ep.duration_minutes,
        'total_marks', ep.total_marks,
        'pdf_storage_path', ep.pdf_storage_path,
        'marking_scheme_storage_path', ep.marking_scheme_storage_path,
        'created_at', ep.created_at
      ) order by ep.year desc, ep.created_at desc
    ),
    '[]'::jsonb
  ) into v_recent_papers
  from (
    select *
    from public.examination_papers
    where (p_country_code is null or country_code = p_country_code)
      and is_published = true
    order by year desc, created_at desc
    limit 20
  ) ep;

  select jsonb_build_object(
    'national', count(*) filter (where tier = 'national'),
    'regional', count(*) filter (where tier = 'regional'),
    'district', count(*) filter (where tier = 'district'),
    'school', count(*) filter (where tier = 'school')
  ) into v_tier_counts
  from public.examination_papers
  where (p_country_code is null or country_code = p_country_code)
    and is_published = true;

  return jsonb_build_object(
    'authorities', v_authorities,
    'examinations', v_examinations,
    'recent_papers', v_recent_papers,
    'tier_counts', v_tier_counts
  );
end;
$$;

grant execute on function public.get_national_examination_centre_catalog(text) to anon, authenticated;

-- ============================================================================
-- 7. RPC: list_examination_papers
-- ============================================================================
create or replace function public.list_examination_papers(
  p_country_code text default null,
  p_national_examination_id text default null,
  p_authority_id text default null,
  p_subject_name text default null,
  p_tier text default null,
  p_year integer default null,
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_results jsonb;
  v_total_count integer;
begin
  select count(*)
  into v_total_count
  from public.examination_papers ep
  where (p_country_code is null or ep.country_code = p_country_code)
    and (p_national_examination_id is null or ep.national_examination_id = p_national_examination_id)
    and (p_authority_id is null or ep.authority_id = p_authority_id)
    and (p_subject_name is null or lower(ep.subject_name) = lower(p_subject_name))
    and (p_tier is null or ep.tier = p_tier)
    and (p_year is null or ep.year = p_year)
    and (
      p_search is null
      or p_search = ''
      or ep.paper_title ilike '%' || p_search || '%'
      or ep.subject_name ilike '%' || p_search || '%'
      or coalesce(ep.region, '') ilike '%' || p_search || '%'
      or coalesce(ep.district, '') ilike '%' || p_search || '%'
      or coalesce(ep.school_name, '') ilike '%' || p_search || '%'
    )
    and ep.is_published = true;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', ep.id,
        'country_code', ep.country_code,
        'national_examination_id', ep.national_examination_id,
        'authority_id', ep.authority_id,
        'subject_id', ep.subject_id,
        'subject_name', ep.subject_name,
        'paper_number', ep.paper_number,
        'paper_title', ep.paper_title,
        'year', ep.year,
        'paper_type', ep.paper_type,
        'tier', ep.tier,
        'region', ep.region,
        'district', ep.district,
        'school_name', ep.school_name,
        'term', ep.term,
        'duration_minutes', ep.duration_minutes,
        'total_marks', ep.total_marks,
        'instructions', ep.instructions,
        'sections_config', ep.sections_config,
        'pdf_storage_path', ep.pdf_storage_path,
        'marking_scheme_storage_path', ep.marking_scheme_storage_path,
        'created_at', ep.created_at
      ) order by ep.year desc, ep.created_at desc
    ),
    '[]'::jsonb
  ) into v_results
  from (
    select *
    from public.examination_papers ep
    where (p_country_code is null or ep.country_code = p_country_code)
      and (p_national_examination_id is null or ep.national_examination_id = p_national_examination_id)
      and (p_authority_id is null or ep.authority_id = p_authority_id)
      and (p_subject_name is null or lower(ep.subject_name) = lower(p_subject_name))
      and (p_tier is null or ep.tier = p_tier)
      and (p_year is null or ep.year = p_year)
      and (
        p_search is null
        or p_search = ''
        or ep.paper_title ilike '%' || p_search || '%'
        or ep.subject_name ilike '%' || p_search || '%'
        or coalesce(ep.region, '') ilike '%' || p_search || '%'
        or coalesce(ep.district, '') ilike '%' || p_search || '%'
        or coalesce(ep.school_name, '') ilike '%' || p_search || '%'
      )
      and ep.is_published = true
    order by ep.year desc, ep.created_at desc
    limit coalesce(p_limit, 50)
    offset coalesce(p_offset, 0)
  ) ep;

  return jsonb_build_object(
    'papers', v_results,
    'total_count', v_total_count,
    'limit', coalesce(p_limit, 50),
    'offset', coalesce(p_offset, 0)
  );
end;
$$;

grant execute on function public.list_examination_papers(text, text, text, text, text, integer, text, integer, integer) to anon, authenticated;

-- ============================================================================
-- 8. RPC: upload_examination_paper
-- ============================================================================
create or replace function public.upload_examination_paper(
  p_country_code text,
  p_authority_id text,
  p_title text,
  p_year integer,
  p_tier text,
  p_region text default null,
  p_district text default null,
  p_school_name text default null,
  p_file_url text default '',
  p_file_size_bytes bigint default null,
  p_notes text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid;
  v_upload_id uuid;
  v_result jsonb;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required to upload examination papers';
  end if;

  if p_title is null or length(btrim(p_title)) < 2 then
    raise exception 'Valid title is required';
  end if;

  if p_tier not in ('national', 'regional', 'district', 'school') then
    raise exception 'Invalid tier: %', p_tier;
  end if;

  insert into public.examination_paper_uploads (
    country_code,
    uploaded_by,
    authority_id,
    title,
    year,
    tier,
    region,
    district,
    school_name,
    file_url,
    file_size_bytes,
    notes
  ) values (
    p_country_code,
    v_uid,
    p_authority_id,
    p_title,
    p_year,
    p_tier,
    p_region,
    p_district,
    p_school_name,
    p_file_url,
    p_file_size_bytes,
    p_notes
  )
  returning id into v_upload_id;

  select jsonb_build_object(
    'id', epu.id,
    'country_code', epu.country_code,
    'title', epu.title,
    'year', epu.year,
    'tier', epu.tier,
    'status', epu.status,
    'created_at', epu.created_at
  ) into v_result
  from public.examination_paper_uploads epu
  where epu.id = v_upload_id;

  return v_result;
end;
$$;

grant execute on function public.upload_examination_paper(text, text, text, integer, text, text, text, text, text, bigint, text) to authenticated;

-- ============================================================================
-- 9. RPC: get_examination_paper_details
-- ============================================================================
create or replace function public.get_examination_paper_details(
  p_paper_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_paper jsonb;
begin
  select jsonb_build_object(
    'id', ep.id,
    'country_code', ep.country_code,
    'national_examination_id', ep.national_examination_id,
    'authority_id', ep.authority_id,
    'authority_name', ea.name,
    'examination_title', coalesce(ne.title, ep.paper_title),
    'subject_id', ep.subject_id,
    'subject_name', ep.subject_name,
    'paper_number', ep.paper_number,
    'paper_title', ep.paper_title,
    'year', ep.year,
    'paper_type', ep.paper_type,
    'tier', ep.tier,
    'region', ep.region,
    'district', ep.district,
    'school_name', ep.school_name,
    'term', ep.term,
    'duration_minutes', ep.duration_minutes,
    'total_marks', ep.total_marks,
    'instructions', ep.instructions,
    'sections_config', ep.sections_config,
    'pdf_storage_path', ep.pdf_storage_path,
    'marking_scheme_storage_path', ep.marking_scheme_storage_path,
    'created_at', ep.created_at
  ) into v_paper
  from public.examination_papers ep
  left join public.examination_authorities ea on ea.id = ep.authority_id
  left join public.national_examinations ne on ne.id = ep.national_examination_id
  where ep.id = p_paper_id
    and (
      ep.is_published = true
      or public.has_role('super_admin')
      or public.has_role('curriculum_admin', ep.country_code)
    );

  return v_paper;
end;
$$;

grant execute on function public.get_examination_paper_details(uuid) to anon, authenticated;

-- ============================================================================
-- 10. Seed Initial Multi-Country Authorities, Examinations & Papers
-- ============================================================================

-- Authorities
insert into public.examination_authorities (
  id, country_code, name, description, website_url, is_accredited
) values
  ('NECTA', 'TZ', 'National Examinations Council of Tanzania', 'The national agency responsible for all national examinations in Tanzania Mainland.', 'https://www.necta.go.tz', true),
  ('KNEC', 'KE', 'Kenya National Examinations Council', 'The national body responsible for administering national examinations in Kenya.', 'https://www.knec.ac.ke', true),
  ('UNEB', 'UG', 'Uganda National Examinations Board', 'The national assessment body for primary and secondary education in Uganda.', 'https://uneb.ac.ug', true)
on conflict (id) do update set
  name = excluded.name,
  description = excluded.description,
  website_url = excluded.website_url;

-- National Examinations
insert into public.national_examinations (
  id, authority_id, country_code, education_level_id, code, title, education_level, grading_system, is_active
) values
  ('TZ-PSLE', 'NECTA', 'TZ', '20000000-0000-0000-0000-000000000010', 'PSLE', 'Primary School Leaving Examination', 'Primary', 'division', true),
  ('TZ-CSEE', 'NECTA', 'TZ', '20000000-0000-0000-0000-000000000011', 'CSEE', 'Certificate of Secondary Education Examination', 'O-Level', 'division', true),
  ('TZ-ACSEE', 'NECTA', 'TZ', '20000000-0000-0000-0000-000000000012', 'ACSEE', 'Advanced Certificate of Secondary Education Examination', 'A-Level', 'division', true),
  ('KE-KPSEA', 'KNEC', 'KE', '20000000-0000-0000-0000-000000000031', 'KPSEA', 'Kenya Primary School Education Assessment', 'Primary', 'cbc_performance', true),
  ('KE-KCSE', 'KNEC', 'KE', '20000000-0000-0000-0000-000000000033', 'KCSE', 'Kenya Certificate of Secondary Education', 'Senior Secondary', 'mean_grade', true),
  ('UG-PLE', 'UNEB', 'UG', '20000000-0000-0000-0000-000000000060', 'PLE', 'Primary Leaving Examination', 'Primary', 'aggregates', true),
  ('UG-UCE', 'UNEB', 'UG', '20000000-0000-0000-0000-000000000061', 'UCE', 'Uganda Certificate of Education', 'Lower Secondary', 'aggregates', true)
on conflict (id) do update set
  title = excluded.title,
  education_level = excluded.education_level,
  grading_system = excluded.grading_system;

-- Examination Papers Across Tiers (National, Regional, District, School)
insert into public.examination_papers (
  id, country_code, national_examination_id, authority_id, subject_id, subject_name,
  paper_number, paper_title, year, paper_type, tier, region, district, school_name,
  term, duration_minutes, total_marks, instructions, sections_config, is_published
) values
  -- 1. Tanzania NECTA CSEE 2024 Basic Mathematics
  (
    '40000000-0000-0000-0000-000000000001',
    'TZ',
    'TZ-CSEE',
    'NECTA',
    '30000000-0000-0000-0000-000000000102',
    'Basic Mathematics',
    1,
    'NECTA CSEE 2024 Basic Mathematics Paper 1',
    2024,
    'official_national',
    'national',
    null,
    null,
    null,
    null,
    180,
    100,
    'This paper consists of sections A and B with a total of 14 questions. Answer ALL questions in Section A and FOUR (4) questions from Section B.',
    '[{"code": "A", "name": "Section A", "total_questions": 10, "required_questions": 10, "marks_per_question": 6, "total_marks": 60}, {"code": "B", "name": "Section B", "total_questions": 4, "required_questions": 4, "marks_per_question": 10, "total_marks": 40}]'::jsonb,
    true
  ),
  -- 2. Tanzania NECTA CSEE 2024 Kiswahili
  (
    '40000000-0000-0000-0000-000000000002',
    'TZ',
    'TZ-CSEE',
    'NECTA',
    '30000000-0000-0000-0000-000000000101',
    'Kiswahili',
    1,
    'NECTA CSEE 2024 Kiswahili Paper 1',
    2024,
    'official_national',
    'national',
    null,
    null,
    null,
    null,
    180,
    100,
    'Karatasi hii ina sehemu A, B na C zenye jumla ya maswali kumi na moja (11). Jibu maswali yote katika sehemu A na B, na maswali matatu (3) kutoka sehemu C.',
    '[{"code": "A", "name": "Sehemu A", "total_questions": 2, "required_questions": 2, "marks_per_question": 8, "total_marks": 16}, {"code": "B", "name": "Sehemu B", "total_questions": 6, "required_questions": 6, "marks_per_question": 9, "total_marks": 54}, {"code": "C", "name": "Sehemu C", "total_questions": 3, "required_questions": 3, "marks_per_question": 10, "total_marks": 30}]'::jsonb,
    true
  ),
  -- 3. Tanzania Dar es Salaam Regional Mock 2024 Basic Mathematics
  (
    '40000000-0000-0000-0000-000000000003',
    'TZ',
    'TZ-CSEE',
    'NECTA',
    '30000000-0000-0000-0000-000000000102',
    'Basic Mathematics',
    1,
    'Dar es Salaam Regional Mock 2024 Basic Mathematics',
    2024,
    'regional_mock',
    'regional',
    'Dar es Salaam',
    null,
    null,
    2,
    180,
    100,
    'Dar es Salaam Region Inter-District Mock Joint Examination. Section A (60 Marks) and Section B (40 Marks).',
    '[{"code": "A", "name": "Section A", "total_questions": 10, "required_questions": 10, "marks_per_question": 6, "total_marks": 60}, {"code": "B", "name": "Section B", "total_questions": 4, "required_questions": 4, "marks_per_question": 10, "total_marks": 40}]'::jsonb,
    true
  ),
  -- 4. Tanzania Mwanza Regional Mock 2024 Kiswahili
  (
    '40000000-0000-0000-0000-000000000004',
    'TZ',
    'TZ-CSEE',
    'NECTA',
    '30000000-0000-0000-0000-000000000101',
    'Kiswahili',
    1,
    'Mwanza Regional Mock 2024 Kiswahili',
    2024,
    'regional_mock',
    'regional',
    'Mwanza',
    null,
    null,
    2,
    180,
    100,
    'Mtihani wa Utimilifu Mkoa wa Mwanza (Mock 2024).',
    '[{"code": "A", "name": "Sehemu A", "total_questions": 2, "required_questions": 2, "marks_per_question": 8, "total_marks": 16}, {"code": "B", "name": "Sehemu B", "total_questions": 6, "required_questions": 6, "marks_per_question": 9, "total_marks": 54}, {"code": "C", "name": "Sehemu C", "total_questions": 3, "required_questions": 3, "marks_per_question": 10, "total_marks": 30}]'::jsonb,
    true
  ),
  -- 5. Tanzania Ilala District Mock 2024 Science
  (
    '40000000-0000-0000-0000-000000000005',
    'TZ',
    'TZ-PSLE',
    'NECTA',
    '30000000-0000-0000-0000-000000000103',
    'Sayansi na Teknolojia',
    1,
    'Ilala District Mock 2024 Sayansi na Teknolojia',
    2024,
    'district_mock',
    'district',
    'Dar es Salaam',
    'Ilala',
    null,
    2,
    120,
    50,
    'Mtihani wa Majaribio Wilaya ya Ilala Darasa la Saba.',
    '[{"code": "A", "name": "Sehemu A", "total_questions": 40, "required_questions": 40, "marks_per_question": 1, "total_marks": 40}, {"code": "B", "name": "Sehemu B", "total_questions": 5, "required_questions": 5, "marks_per_question": 2, "total_marks": 10}]'::jsonb,
    true
  ),
  -- 6. Kenya KNEC KCSE 2024 Mathematics
  (
    '40000000-0000-0000-0000-000000000006',
    'KE',
    'KE-KCSE',
    'KNEC',
    null,
    'Mathematics Alternative A',
    1,
    'KNEC KCSE 2024 Mathematics Alt A Paper 1',
    2024,
    'official_national',
    'national',
    null,
    null,
    null,
    null,
    150,
    100,
    'This paper consists of TWO sections: Section I (50 marks) and Section II (50 marks). Answer ALL questions in Section I and ANY FIVE from Section II.',
    '[{"code": "I", "name": "Section I", "total_questions": 16, "required_questions": 16, "marks_per_question": 3, "total_marks": 50}, {"code": "II", "name": "Section II", "total_questions": 8, "required_questions": 5, "marks_per_question": 10, "total_marks": 50}]'::jsonb,
    true
  ),
  -- 7. Kenya Nairobi County Mock 2024 Chemistry
  (
    '40000000-0000-0000-0000-000000000007',
    'KE',
    'KE-KCSE',
    'KNEC',
    null,
    'Chemistry',
    1,
    'Nairobi County Joint Mock 2024 Chemistry Paper 1',
    2024,
    'regional_mock',
    'regional',
    'Nairobi',
    null,
    null,
    2,
    120,
    80,
    'Nairobi County Mock Examinations. Answer ALL questions in the spaces provided.',
    '[{"code": "A", "name": "Section A", "total_questions": 28, "required_questions": 28, "marks_per_question": 3, "total_marks": 80}]'::jsonb,
    true
  ),
  -- 8. Uganda UNEB UCE 2024 Physics
  (
    '40000000-0000-0000-0000-000000000008',
    'UG',
    'UG-UCE',
    'UNEB',
    null,
    'Physics',
    1,
    'UNEB UCE 2024 Physics Paper 1',
    2024,
    'official_national',
    'national',
    null,
    null,
    null,
    null,
    135,
    100,
    'Uganda National Examinations Board UCE Examination. Section A (MCQs 40 Marks) and Section B (Structured 60 Marks).',
    '[{"code": "A", "name": "Section A", "total_questions": 40, "required_questions": 40, "marks_per_question": 1, "total_marks": 40}, {"code": "B", "name": "Section B", "total_questions": 10, "required_questions": 10, "marks_per_question": 6, "total_marks": 60}]'::jsonb,
    true
  )
on conflict (id) do update set
  paper_title = excluded.paper_title,
  instructions = excluded.instructions,
  sections_config = excluded.sections_config;

commit;
