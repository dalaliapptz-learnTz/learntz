begin;

alter table public.curriculum_versions
  add column requires_reviewed_import boolean not null default false,
  alter column created_by drop not null;

alter table public.curriculum_version_grades
  add constraint curriculum_version_grades_id_version_unique
    unique (id, version_id);

alter table public.curriculum_version_sources
  alter column created_by drop not null;

alter table public.curriculum_sources
  alter column created_by drop not null,
  add column document_format text check (
    document_format is null
    or document_format in ('application/pdf', 'text/plain')
  ),
  add column language_code text check (
    language_code is null
    or language_code ~ '^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$'
  ),
  add column acquired_on date,
  add column usage_rights_status text not null default 'unknown'
    check (usage_rights_status in (
      'unknown', 'permission_pending', 'authorized', 'public_domain',
      'restricted'
    )),
  add column usage_rights_reviewed_by uuid
    references auth.users (id) on delete set null,
  add column usage_rights_reviewed_at timestamptz,
  add column usage_rights_evidence_url text check (
    usage_rights_evidence_url is null
    or usage_rights_evidence_url ~ '^https://[^[:space:]]+$'
  ),
  add column usage_rights_note text check (
    usage_rights_note is null or char_length(usage_rights_note) <= 2000
  ),
  add constraint curriculum_sources_rights_review_check
    check (
      usage_rights_status not in ('authorized', 'public_domain', 'restricted')
      or (
        usage_rights_reviewed_by is not null
        and usage_rights_reviewed_at is not null
        and (
          usage_rights_evidence_url is not null
          or nullif(btrim(usage_rights_note), '') is not null
        )
      )
    );

create unique index curriculum_sources_authority_checksum_unique_idx
  on public.curriculum_sources (authority_id, sha256_checksum)
  where sha256_checksum is not null;

create table public.curriculum_source_rights_history (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null
    references public.curriculum_sources (id) on delete restrict,
  usage_rights_status text not null
    check (usage_rights_status in (
      'permission_pending', 'authorized', 'public_domain', 'restricted'
    )),
  reviewer_user_id uuid references auth.users (id) on delete set null,
  evidence_url text check (
    evidence_url is null or evidence_url ~ '^https://[^[:space:]]+$'
  ),
  note text not null check (char_length(btrim(note)) between 1 and 2000),
  created_at timestamptz not null default now()
);

create index curriculum_source_rights_history_idx
  on public.curriculum_source_rights_history (source_id, created_at desc);

create table public.curriculum_import_jobs (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null,
  curriculum_id uuid not null,
  source_id uuid not null,
  authority_id uuid not null,
  file_sha256 text not null check (file_sha256 ~ '^[0-9a-f]{64}$'),
  storage_bucket text not null default 'curriculum-source-documents'
    check (storage_bucket = 'curriculum-source-documents'),
  storage_object_path text not null unique
    check (storage_object_path ~ '^TZ/[0-9a-f-]{36}/[0-9a-f-]{36}\.pdf$'),
  status text not null default 'queued' check (status in (
    'queued', 'extracted', 'validation_failed', 'in_review', 'reviewed',
    'failed'
  )),
  validation_errors jsonb not null default '[]'::jsonb
    check (jsonb_typeof(validation_errors) = 'array'),
  attempt_count integer not null default 1 check (attempt_count > 0),
  last_error text check (last_error is null or char_length(last_error) <= 1000),
  created_by uuid not null references auth.users (id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  constraint curriculum_import_jobs_version_fk
    foreign key (version_id, curriculum_id)
    references public.curriculum_versions (id, curriculum_id)
    on delete restrict,
  constraint curriculum_import_jobs_source_fk
    foreign key (source_id, authority_id)
    references public.curriculum_sources (id, authority_id)
    on delete restrict,
  constraint curriculum_import_jobs_curriculum_authority_fk
    foreign key (curriculum_id, authority_id)
    references public.curricula (id, authority_id)
    on delete restrict,
  constraint curriculum_import_jobs_scope_unique
    unique (id, version_id, curriculum_id),
  constraint curriculum_import_jobs_id_source_version_unique
    unique (id, source_id, version_id),
  constraint curriculum_import_jobs_idempotency_unique
    unique (version_id, source_id, file_sha256)
);

create index curriculum_import_jobs_version_status_idx
  on public.curriculum_import_jobs (version_id, status, created_at desc);
create index curriculum_import_jobs_source_idx
  on public.curriculum_import_jobs (source_id, created_at desc);

create table public.curriculum_import_job_history (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null
    references public.curriculum_import_jobs (id) on delete restrict,
  from_status text check (from_status is null or from_status in (
    'queued', 'extracted', 'validation_failed', 'in_review', 'reviewed',
    'failed'
  )),
  to_status text not null check (to_status in (
    'queued', 'extracted', 'validation_failed', 'in_review', 'reviewed',
    'failed'
  )),
  actor_user_id uuid references auth.users (id) on delete set null,
  note text check (note is null or char_length(note) <= 1000),
  created_at timestamptz not null default now()
);

create index curriculum_import_job_history_idx
  on public.curriculum_import_job_history (job_id, created_at desc);

create table public.curriculum_import_pages (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null,
  version_id uuid not null,
  curriculum_id uuid not null,
  page_number integer not null check (page_number > 0),
  extracted_text text not null
    check (char_length(extracted_text) <= 100000),
  extracted_text_sha256 text not null
    check (extracted_text_sha256 ~ '^[0-9a-f]{64}$'),
  created_at timestamptz not null default now(),
  constraint curriculum_import_pages_job_fk
    foreign key (job_id, version_id, curriculum_id)
    references public.curriculum_import_jobs (id, version_id, curriculum_id)
    on delete restrict,
  constraint curriculum_import_pages_idempotency_unique
    unique (job_id, page_number),
  constraint curriculum_import_pages_id_job_version_unique
    unique (id, job_id, version_id)
);

create index curriculum_import_pages_version_idx
  on public.curriculum_import_pages (version_id, job_id, page_number);

create table public.curriculum_import_items (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null,
  version_id uuid not null,
  curriculum_id uuid not null,
  import_page_id uuid not null,
  version_grade_id uuid,
  parent_item_id uuid,
  item_type text not null check (item_type in (
    'subject', 'learning_area', 'topic', 'strand', 'subtopic', 'sub_strand',
    'competency', 'learning_outcome', 'assessment_guidance',
    'teaching_guidance', 'other'
  )),
  official_term text check (
    official_term is null or char_length(official_term) <= 300
  ),
  source_text text not null
    check (char_length(btrim(source_text)) between 1 and 20000),
  normalized_text text not null
    check (char_length(btrim(normalized_text)) between 1 and 20000),
  normalized_fingerprint text not null
    check (normalized_fingerprint ~ '^[0-9a-f]{64}$'),
  review_status text not null default 'pending'
    check (review_status in ('pending', 'approved', 'rejected')),
  created_by uuid not null references auth.users (id) on delete restrict,
  reviewed_by uuid references auth.users (id) on delete set null,
  reviewed_at timestamptz,
  review_note text check (review_note is null or char_length(review_note) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint curriculum_import_items_job_fk
    foreign key (job_id, version_id, curriculum_id)
    references public.curriculum_import_jobs (id, version_id, curriculum_id)
    on delete restrict,
  constraint curriculum_import_items_page_fk
    foreign key (import_page_id, job_id, version_id)
    references public.curriculum_import_pages (id, job_id, version_id)
    on delete restrict,
  constraint curriculum_import_items_grade_fk
    foreign key (version_grade_id, version_id)
    references public.curriculum_version_grades (id, version_id)
    on delete restrict,
  constraint curriculum_import_items_parent_fk
    foreign key (parent_item_id, job_id, version_id)
    references public.curriculum_import_items (id, job_id, version_id)
    on delete restrict,
  constraint curriculum_import_items_id_job_version_unique
    unique (id, job_id, version_id),
  constraint curriculum_import_items_review_check
    check (
      (review_status = 'pending' and reviewed_by is null and reviewed_at is null)
      or (
        review_status in ('approved', 'rejected')
        and reviewed_by is not null
        and reviewed_at is not null
      )
    )
);

create index curriculum_import_items_version_type_idx
  on public.curriculum_import_items (
    version_id, item_type, version_grade_id, review_status
  );
create index curriculum_import_items_job_review_idx
  on public.curriculum_import_items (job_id, review_status, created_at);
create unique index curriculum_import_items_no_duplicates_idx
  on public.curriculum_import_items (
    version_id,
    item_type,
    coalesce(version_grade_id, '00000000-0000-0000-0000-000000000000'::uuid),
    normalized_fingerprint
  );

create table public.curriculum_import_item_review_history (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null
    references public.curriculum_import_items (id) on delete restrict,
  decision text not null check (decision in ('approved', 'rejected')),
  reviewer_user_id uuid references auth.users (id) on delete set null,
  note text check (note is null or char_length(note) <= 2000),
  created_at timestamptz not null default now()
);

create index curriculum_import_item_review_history_idx
  on public.curriculum_import_item_review_history (item_id, created_at desc);

create trigger curriculum_import_jobs_set_updated_at
  before update on public.curriculum_import_jobs
  for each row execute function public.set_updated_at();
create trigger curriculum_import_items_set_updated_at
  before update on public.curriculum_import_items
  for each row execute function public.set_updated_at();

create function public.set_curriculum_item_fingerprint()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.normalized_fingerprint := encode(
    extensions.digest(
      convert_to(
        lower(regexp_replace(btrim(new.normalized_text), '\s+', ' ', 'g')),
        'UTF8'
      ),
      'sha256'
    ),
    'hex'
  );
  return new;
end;
$$;

revoke all on function public.set_curriculum_item_fingerprint()
  from public, anon, authenticated;
create trigger curriculum_import_items_set_fingerprint
  before insert or update of normalized_text
  on public.curriculum_import_items
  for each row execute function public.set_curriculum_item_fingerprint();

insert into public.curriculum_sources (
  authority_id,
  document_title,
  issuing_institution,
  document_reference,
  source_url,
  sha256_checksum,
  usage_permissions,
  verification_status,
  created_by,
  document_format,
  language_code,
  acquired_on,
  usage_rights_status
)
select
  authority.id,
  'Mtaala wa Elimu ya Msingi',
  authority.name,
  'TIE official listing labels the curriculum "(Mpya)"; publication/version and effective dates are not stated.',
  'https://www.tie.go.tz/uploads/documents/sw-1724244732-MTAALA%20ELIMU%20%20YA%20MSINGI-FINAL.pdf',
  '20c75d2071d4a1726187af6c097125137ef4b0971d7a7b3834d030d5295b3591',
  'Rights not established. Do not reproduce, store, or publish extracted source text until TIE usage permission is documented.',
  'unverified',
  null,
  'application/pdf',
  'sw',
  date '2026-11-11',
  'permission_pending'
from public.curriculum_authorities authority
where authority.code = 'TIE'
  and authority.country_code = 'TZ'
  and not exists (
    select 1
    from public.curriculum_sources source
    where source.authority_id = authority.id
      and source.sha256_checksum =
        '20c75d2071d4a1726187af6c097125137ef4b0971d7a7b3834d030d5295b3591'
  );

insert into public.curriculum_source_rights_history (
  source_id, usage_rights_status, reviewer_user_id, note
)
select
  source.id,
  'permission_pending',
  null,
  'No reproduction or usage permission was found on the official listing; human rights review is required.'
from public.curriculum_sources source
where source.sha256_checksum =
  '20c75d2071d4a1726187af6c097125137ef4b0971d7a7b3834d030d5295b3591'
  and not exists (
    select 1
    from public.curriculum_source_rights_history history
    where history.source_id = source.id
  );

insert into public.curriculum_versions (
  curriculum_id,
  version_code,
  display_name,
  status,
  requires_reviewed_import,
  created_by
)
select
  curriculum.id,
  'tie-primary-pilot-source-review-1',
  'TIE Primary Pilot - Source and rights review pending',
  'draft',
  true,
  null
from public.curricula curriculum
where curriculum.code = 'TIE'
  and curriculum.country_code = 'TZ'
  and not exists (
    select 1 from public.curriculum_versions version
    where version.curriculum_id = curriculum.id
      and version.version_code = 'tie-primary-pilot-source-review-1'
  );

insert into public.curriculum_version_grades (
  version_id, curriculum_id, education_level_id, grade_id, display_order
)
select
  version.id,
  curriculum.id,
  grade.education_level_id,
  grade.id,
  grade.sequence
from public.curriculum_versions version
join public.curricula curriculum on curriculum.id = version.curriculum_id
join public.education_levels level
  on level.curriculum_id = curriculum.id and level.code = 'PRIMARY'
join public.education_grades grade
  on grade.education_level_id = level.id
where version.version_code = 'tie-primary-pilot-source-review-1'
  and not exists (
    select 1
    from public.curriculum_version_grades version_grade
    where version_grade.version_id = version.id
      and version_grade.grade_id = grade.id
  );

insert into public.curriculum_version_sources (
  version_id,
  curriculum_id,
  authority_id,
  source_id,
  section_reference,
  created_by
)
select
  version.id,
  curriculum.id,
  curriculum.authority_id,
  source.id,
  'Official TIE listing; edition, effective dates, and usage permission pending verification.',
  null
from public.curriculum_versions version
join public.curricula curriculum on curriculum.id = version.curriculum_id
join public.curriculum_sources source
  on source.authority_id = curriculum.authority_id
  and source.sha256_checksum =
    '20c75d2071d4a1726187af6c097125137ef4b0971d7a7b3834d030d5295b3591'
where version.version_code = 'tie-primary-pilot-source-review-1'
  and not exists (
    select 1
    from public.curriculum_version_sources version_source
    where version_source.version_id = version.id
      and version_source.source_id = source.id
  );

insert into public.curriculum_version_review_history (
  version_id, from_status, to_status, actor_user_id, note
)
select
  version.id,
  null,
  'draft',
  null,
  'Primary pilot seeded for source and rights review; no curriculum content imported.'
from public.curriculum_versions version
where version.version_code = 'tie-primary-pilot-source-review-1'
  and not exists (
    select 1
    from public.curriculum_version_review_history history
    where history.version_id = version.id
  );

insert into public.audit_logs (
  actor_user_id, target_user_id, action, details
)
select
  null,
  null,
  'curriculum.primary_pilot_seeded',
  jsonb_build_object(
    'version_code', 'tie-primary-pilot-source-review-1',
    'source_checksum',
    '20c75d2071d4a1726187af6c097125137ef4b0971d7a7b3834d030d5295b3591',
    'content_imported', false,
    'usage_rights_status', 'permission_pending'
  )
where exists (
  select 1 from public.curriculum_versions version
  where version.version_code = 'tie-primary-pilot-source-review-1'
)
and not exists (
  select 1 from public.audit_logs log
  where log.action = 'curriculum.primary_pilot_seeded'
    and log.details ->> 'version_code' =
      'tie-primary-pilot-source-review-1'
);

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'curriculum-source-documents',
  'curriculum-source-documents',
  false,
  26214400,
  array['application/pdf']
)
on conflict (id) do update
  set public = false,
      file_size_limit = 26214400,
      allowed_mime_types = array['application/pdf'];

create policy "Curriculum staff read private source documents"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'curriculum-source-documents'
    and public.has_curriculum_role(
      split_part(name, '/', 1),
      array[
        'curriculum_editor', 'curriculum_reviewer',
        'curriculum_approver', 'curriculum_admin', 'country_admin'
      ]
    )
  );
create policy "Authorized editors upload private source documents"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'curriculum-source-documents'
    and name ~ '^TZ/[0-9a-f-]{36}/[0-9a-f-]{36}\.pdf$'
    and exists (
      select 1
      from public.curriculum_import_jobs job
      join public.curriculum_sources source
        on source.id = job.source_id
      where job.storage_object_path = storage.objects.name
        and job.status in ('queued', 'failed')
        and job.created_by = (select auth.uid())
        and source.verification_status = 'verified'
        and source.usage_rights_status in ('authorized', 'public_domain')
        and public.has_curriculum_role(
          'TZ', array['curriculum_editor', 'curriculum_admin']
        )
    )
    and public.has_curriculum_role(
      split_part(name, '/', 1),
      array['curriculum_editor', 'curriculum_admin']
    )
  );
create policy "Authorized editors replace unprocessed source documents"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'curriculum-source-documents'
    and exists (
      select 1
      from public.curriculum_import_jobs job
      join public.curriculum_sources source
        on source.id = job.source_id
      where job.storage_object_path = storage.objects.name
        and job.status in ('queued', 'failed')
        and job.created_by = (select auth.uid())
        and source.verification_status = 'verified'
        and source.usage_rights_status in ('authorized', 'public_domain')
        and public.has_curriculum_role(
          'TZ', array['curriculum_editor', 'curriculum_admin']
        )
    )
  )
  with check (
    bucket_id = 'curriculum-source-documents'
    and exists (
      select 1
      from public.curriculum_import_jobs job
      join public.curriculum_sources source
        on source.id = job.source_id
      where job.storage_object_path = storage.objects.name
        and job.status in ('queued', 'failed')
        and job.created_by = (select auth.uid())
        and source.verification_status = 'verified'
        and source.usage_rights_status in ('authorized', 'public_domain')
        and public.has_curriculum_role(
          'TZ', array['curriculum_editor', 'curriculum_admin']
        )
    )
  );
create policy "Curriculum administrators delete private source documents"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'curriculum-source-documents'
    and public.has_curriculum_role(
      split_part(name, '/', 1),
      array['curriculum_admin']
    )
  );

alter table public.curriculum_source_rights_history enable row level security;
alter table public.curriculum_import_jobs enable row level security;
alter table public.curriculum_import_job_history enable row level security;
alter table public.curriculum_import_pages enable row level security;
alter table public.curriculum_import_items enable row level security;
alter table public.curriculum_import_item_review_history
  enable row level security;

revoke all on public.curriculum_source_rights_history,
  public.curriculum_import_jobs, public.curriculum_import_job_history,
  public.curriculum_import_pages, public.curriculum_import_items,
  public.curriculum_import_item_review_history
  from public, anon, authenticated;

grant select on public.curriculum_source_rights_history,
  public.curriculum_import_jobs, public.curriculum_import_job_history,
  public.curriculum_import_pages, public.curriculum_import_items,
  public.curriculum_import_item_review_history to authenticated;

revoke insert, update, delete on public.curriculum_sources
  from authenticated;
grant insert (
  authority_id, document_title, issuing_institution, document_reference,
  publication_date, effective_date, document_version, source_url,
  storage_bucket, storage_object_path, sha256_checksum, usage_permissions,
  created_by, document_format, language_code, acquired_on
) on public.curriculum_sources to authenticated;
grant update (
  document_title, issuing_institution, document_reference, publication_date,
  effective_date, document_version, source_url, storage_bucket,
  storage_object_path, sha256_checksum, usage_permissions, document_format,
  language_code, acquired_on
) on public.curriculum_sources to authenticated;
grant delete on public.curriculum_sources to authenticated;

grant insert (
  job_id, version_id, curriculum_id, import_page_id, version_grade_id,
  parent_item_id, item_type, official_term, source_text, normalized_text,
  normalized_fingerprint, created_by
) on public.curriculum_import_items to authenticated;
grant update (
  import_page_id, version_grade_id, parent_item_id, item_type, official_term,
  source_text, normalized_text, normalized_fingerprint
) on public.curriculum_import_items to authenticated;
grant delete on public.curriculum_import_items to authenticated;

create policy "Curriculum staff read source rights history"
  on public.curriculum_source_rights_history for select to authenticated
  using (exists (
    select 1
    from public.curriculum_sources source
    join public.curriculum_authorities authority
      on authority.id = source.authority_id
    where source.id = curriculum_source_rights_history.source_id
      and public.has_curriculum_role(
        authority.country_code,
        array[
          'curriculum_editor', 'curriculum_reviewer',
          'curriculum_approver', 'curriculum_admin', 'country_admin'
        ]
      )
  ));

create policy "Curriculum staff read import jobs"
  on public.curriculum_import_jobs for select to authenticated
  using (public.has_curriculum_role(
    public.curriculum_version_country(version_id),
    array[
      'curriculum_editor', 'curriculum_reviewer',
      'curriculum_approver', 'curriculum_admin', 'country_admin'
    ]
  ));
create policy "Curriculum staff read import job history"
  on public.curriculum_import_job_history for select to authenticated
  using (exists (
    select 1
    from public.curriculum_import_jobs job
    where job.id = curriculum_import_job_history.job_id
      and public.has_curriculum_role(
        public.curriculum_version_country(job.version_id),
        array[
          'curriculum_editor', 'curriculum_reviewer',
          'curriculum_approver', 'curriculum_admin', 'country_admin'
        ]
      )
  ));
create policy "Curriculum staff read imported pages"
  on public.curriculum_import_pages for select to authenticated
  using (public.has_curriculum_role(
    public.curriculum_version_country(version_id),
    array[
      'curriculum_editor', 'curriculum_reviewer',
      'curriculum_approver', 'curriculum_admin', 'country_admin'
    ]
  ));
create policy "Staff and published learners read curriculum items"
  on public.curriculum_import_items for select to authenticated
  using (
    (
      review_status = 'approved'
      and exists (
        select 1 from public.curriculum_versions version
        where version.id = curriculum_import_items.version_id
          and version.status = 'published'
      )
    )
    or public.has_curriculum_role(
      public.curriculum_version_country(version_id),
      array[
        'curriculum_editor', 'curriculum_reviewer',
        'curriculum_approver', 'curriculum_admin', 'country_admin'
      ]
    )
  );
create policy "Editors manage pending items in extracted imports"
  on public.curriculum_import_items for all to authenticated
  using (
    review_status = 'pending'
    and exists (
      select 1
      from public.curriculum_import_jobs job
      where job.id = curriculum_import_items.job_id
        and job.status in ('extracted', 'validation_failed')
        and public.has_curriculum_role(
          public.curriculum_version_country(job.version_id),
          array['curriculum_editor', 'curriculum_admin', 'country_admin']
        )
    )
  )
  with check (
    review_status = 'pending'
    and created_by = (select auth.uid())
    and exists (
      select 1
      from public.curriculum_import_jobs job
      where job.id = curriculum_import_items.job_id
        and job.status in ('extracted', 'validation_failed')
        and public.has_curriculum_role(
          public.curriculum_version_country(job.version_id),
          array['curriculum_editor', 'curriculum_admin', 'country_admin']
        )
    )
  );

create policy "Curriculum staff read import item reviews"
  on public.curriculum_import_item_review_history for select to authenticated
  using (exists (
    select 1
    from public.curriculum_import_items item
    where item.id = curriculum_import_item_review_history.item_id
      and public.has_curriculum_role(
        public.curriculum_version_country(item.version_id),
        array[
          'curriculum_editor', 'curriculum_reviewer',
          'curriculum_approver', 'curriculum_admin', 'country_admin'
        ]
      )
  ));

create function public.review_curriculum_source_rights(
  p_source_id uuid,
  p_status text,
  p_note text,
  p_evidence_url text default null
)
returns public.curriculum_sources
language plpgsql
security definer
set search_path = ''
as $$
declare
  source_record public.curriculum_sources;
  source_country text;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if p_status is null or p_status not in (
    'permission_pending', 'authorized', 'public_domain', 'restricted'
  ) or char_length(btrim(coalesce(p_note, ''))) not between 1 and 2000 then
    raise exception 'A valid rights decision and review note are required'
      using errcode = '22023';
  end if;
  if p_evidence_url is not null
     and p_evidence_url !~ '^https://[^[:space:]]+$' then
    raise exception 'The rights evidence URL must use HTTPS'
      using errcode = '22023';
  end if;

  select authority.country_code into source_country
  from public.curriculum_sources source
  join public.curriculum_authorities authority
    on authority.id = source.authority_id
  where source.id = p_source_id;
  if not found then
    raise exception 'The curriculum source is unavailable'
      using errcode = '22023';
  end if;
  if not public.has_curriculum_role(
    source_country,
    array['curriculum_reviewer', 'curriculum_admin']
  ) then
    raise exception 'Curriculum reviewer authorization is required'
      using errcode = '42501';
  end if;

  update public.curriculum_sources
  set usage_rights_status = p_status,
      usage_rights_reviewed_by = auth.uid(),
      usage_rights_reviewed_at = now(),
      usage_rights_evidence_url = p_evidence_url,
      usage_rights_note = btrim(p_note)
  where id = p_source_id
    and verification_status = 'verified'
    and verified_by <> auth.uid()
    and (created_by is null or created_by <> auth.uid())
  returning * into source_record;
  if not found then
    raise exception 'Only a source verified by another user can receive a rights decision'
      using errcode = '55000';
  end if;

  insert into public.curriculum_source_rights_history (
    source_id, usage_rights_status, reviewer_user_id, evidence_url, note
  )
  values (
    p_source_id, p_status, auth.uid(), p_evidence_url, btrim(p_note)
  );
  perform public.write_audit_log(
    auth.uid(),
    null,
    'curriculum.source_rights_reviewed',
    jsonb_build_object(
      'source_id', p_source_id,
      'usage_rights_status', p_status
    )
  );
  return source_record;
end;
$$;

revoke all on function public.review_curriculum_source_rights(
  uuid, text, text, text
) from public, anon;
grant execute on function public.review_curriculum_source_rights(
  uuid, text, text, text
) to authenticated;

create function public.register_curriculum_import(
  p_version_id uuid,
  p_source_id uuid,
  p_file_sha256 text
)
returns public.curriculum_import_jobs
language plpgsql
security definer
set search_path = ''
as $$
declare
  version_record public.curriculum_versions;
  source_record public.curriculum_sources;
  source_authority_id uuid;
  country text;
  import_record public.curriculum_import_jobs;
  new_job boolean := false;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if p_file_sha256 is null or p_file_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception 'A lowercase SHA-256 checksum is required'
      using errcode = '22023';
  end if;

  select version.* into version_record
  from public.curriculum_versions version
  where version.id = p_version_id
  for update;
  if not found or version_record.status <> 'draft'
     or not version_record.requires_reviewed_import then
    raise exception 'A draft curriculum pilot version is required'
      using errcode = '55000';
  end if;
  select curriculum.country_code, curriculum.authority_id
  into country, source_authority_id
  from public.curricula curriculum
  where curriculum.id = version_record.curriculum_id;
  if not public.has_curriculum_role(
    country, array['curriculum_editor', 'curriculum_admin']
  ) then
    raise exception 'Curriculum editor authorization is required'
      using errcode = '42501';
  end if;

  select source.* into source_record
  from public.curriculum_sources source
  where source.id = p_source_id
    and source.authority_id = source_authority_id;
  if not found or source_record.sha256_checksum <> p_file_sha256 then
    raise exception 'The file checksum does not match the registered source'
      using errcode = '22023';
  end if;
  if source_record.verification_status <> 'verified'
     or source_record.usage_rights_status not in ('authorized', 'public_domain') then
    raise exception 'Verified source and documented usage rights are required before import'
      using errcode = '42501';
  end if;
  if not exists (
    select 1
    from public.curriculum_version_sources version_source
    where version_source.version_id = p_version_id
      and version_source.source_id = p_source_id
  ) then
    raise exception 'The source must be attached to the curriculum version'
      using errcode = '23514';
  end if;

  insert into public.curriculum_import_jobs (
    version_id,
    curriculum_id,
    source_id,
    authority_id,
    file_sha256,
    storage_object_path,
    created_by
  )
  values (
    p_version_id,
    version_record.curriculum_id,
    p_source_id,
    source_authority_id,
    p_file_sha256,
    format('TZ/%s/%s.pdf', p_source_id, gen_random_uuid()),
    auth.uid()
  )
  on conflict (version_id, source_id, file_sha256) do nothing
  returning * into import_record;

  if found then
    new_job := true;
  else
    select * into import_record
    from public.curriculum_import_jobs job
    where job.version_id = p_version_id
      and job.source_id = p_source_id
      and job.file_sha256 = p_file_sha256
    for update;
  end if;

  if new_job then
    update public.curriculum_import_jobs
    set storage_object_path = format(
      'TZ/%s/%s.pdf', p_source_id, import_record.id
    )
    where id = import_record.id
    returning * into import_record;

    insert into public.curriculum_import_job_history (
      job_id, from_status, to_status, actor_user_id, note
    )
    values (
      import_record.id, null, 'queued', auth.uid(), 'Import registered'
    );
    perform public.write_audit_log(
      auth.uid(),
      null,
      'curriculum.import_registered',
      jsonb_build_object(
        'job_id', import_record.id,
        'source_id', p_source_id,
        'sha256', p_file_sha256
      )
    );
  end if;
  return import_record;
end;
$$;

revoke all on function public.register_curriculum_import(uuid, uuid, text)
  from public, anon;
grant execute on function public.register_curriculum_import(uuid, uuid, text)
  to authenticated;

create function public.complete_curriculum_import(
  p_job_id uuid,
  p_pages jsonb
)
returns public.curriculum_import_jobs
language plpgsql
security definer
set search_path = ''
as $$
declare
  import_record public.curriculum_import_jobs;
  country text;
  page_record jsonb;
  page_number integer;
  page_text text;
  page_total integer;
  total_characters bigint := 0;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if p_pages is null or jsonb_typeof(p_pages) <> 'array'
     or jsonb_array_length(p_pages) not between 1 and 500 then
    raise exception 'The PDF extraction must include between 1 and 500 pages'
      using errcode = '22023';
  end if;

  select job.* into import_record
  from public.curriculum_import_jobs job
  where job.id = p_job_id
  for update;
  if not found then
    raise exception 'The curriculum import job is unavailable'
      using errcode = '22023';
  end if;
  country := public.curriculum_version_country(import_record.version_id);
  if not public.has_curriculum_role(
    country, array['curriculum_editor', 'curriculum_admin']
  ) then
    raise exception 'Curriculum editor authorization is required'
      using errcode = '42501';
  end if;
  if import_record.status in (
    'extracted', 'validation_failed', 'in_review', 'reviewed'
  ) then
    return import_record;
  end if;
  if import_record.status not in ('queued', 'failed') then
    raise exception 'The import job is not ready for extraction'
      using errcode = '55000';
  end if;
  if not exists (
    select 1
    from public.curriculum_sources source
    where source.id = import_record.source_id
      and source.sha256_checksum = import_record.file_sha256
      and source.verification_status = 'verified'
      and source.usage_rights_status in ('authorized', 'public_domain')
  ) then
    raise exception 'Verified source and documented usage rights are required before extraction'
      using errcode = '42501';
  end if;
  if not exists (
    select 1 from storage.objects object
    where object.bucket_id = import_record.storage_bucket
      and object.name = import_record.storage_object_path
  ) then
    raise exception 'The private source document must be uploaded before extraction'
      using errcode = '23514';
  end if;

  for page_record in
    select value from jsonb_array_elements(p_pages)
  loop
    page_number := (page_record ->> 'page_number')::integer;
    page_text := coalesce(page_record ->> 'extracted_text', '');
    if page_number < 1 or char_length(page_text) > 100000 then
      raise exception 'An extracted page is invalid or too large'
        using errcode = '22023';
    end if;
    total_characters := total_characters + char_length(page_text);
  end loop;
  page_total := jsonb_array_length(p_pages);
  if total_characters > 3000000 then
    raise exception 'The extracted document exceeds the text storage limit'
      using errcode = '22023';
  end if;

  delete from public.curriculum_import_pages page
  where page.job_id = p_job_id;
  insert into public.curriculum_import_pages (
    job_id, version_id, curriculum_id, page_number, extracted_text,
    extracted_text_sha256
  )
  select
    import_record.id,
    import_record.version_id,
    import_record.curriculum_id,
    (page.value ->> 'page_number')::integer,
    coalesce(page.value ->> 'extracted_text', ''),
    encode(
      extensions.digest(
        convert_to(coalesce(page.value ->> 'extracted_text', ''), 'UTF8'),
        'sha256'
      ),
      'hex'
    )
  from jsonb_array_elements(p_pages) page(value);

  update public.curriculum_import_jobs
  set status = 'extracted',
      validation_errors = '[]'::jsonb,
      last_error = null,
      attempt_count = case
        when status = 'failed' then attempt_count + 1
        else attempt_count
      end,
      completed_at = now()
  where id = p_job_id
  returning * into import_record;

  insert into public.curriculum_import_job_history (
    job_id, from_status, to_status, actor_user_id, note
  )
  values (
    p_job_id,
    case when import_record.attempt_count > 1 then 'failed' else 'queued' end,
    'extracted',
    auth.uid(),
    format('%s PDF pages extracted', page_total)
  );
  perform public.write_audit_log(
    auth.uid(),
    null,
    'curriculum.import_extracted',
    jsonb_build_object('job_id', p_job_id, 'page_count', page_total)
  );
  return import_record;
end;
$$;

revoke all on function public.complete_curriculum_import(uuid, jsonb)
  from public, anon;
grant execute on function public.complete_curriculum_import(uuid, jsonb)
  to authenticated;

create function public.fail_curriculum_import(
  p_job_id uuid,
  p_error text
)
returns public.curriculum_import_jobs
language plpgsql
security definer
set search_path = ''
as $$
declare
  import_record public.curriculum_import_jobs;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if char_length(btrim(coalesce(p_error, ''))) not between 1 and 1000 then
    raise exception 'A safe extraction failure description is required'
      using errcode = '22023';
  end if;

  select job.* into import_record
  from public.curriculum_import_jobs job
  where job.id = p_job_id
  for update;
  if not found or import_record.status not in ('queued', 'failed') then
    raise exception 'The import job cannot be marked failed'
      using errcode = '55000';
  end if;
  if not public.has_curriculum_role(
    public.curriculum_version_country(import_record.version_id),
    array['curriculum_editor', 'curriculum_admin']
  ) then
    raise exception 'Curriculum editor authorization is required'
      using errcode = '42501';
  end if;

  update public.curriculum_import_jobs
  set status = 'failed',
      last_error = btrim(p_error),
      completed_at = now()
  where id = p_job_id
  returning * into import_record;
  insert into public.curriculum_import_job_history (
    job_id, from_status, to_status, actor_user_id, note
  )
  values (
    p_job_id, 'queued', 'failed', auth.uid(), btrim(p_error)
  );
  perform public.write_audit_log(
    auth.uid(),
    null,
    'curriculum.import_failed',
    jsonb_build_object('job_id', p_job_id, 'error', btrim(p_error))
  );
  return import_record;
end;
$$;

revoke all on function public.fail_curriculum_import(uuid, text)
  from public, anon;
grant execute on function public.fail_curriculum_import(uuid, text)
  to authenticated;

create function public.validate_curriculum_import(p_job_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  import_record public.curriculum_import_jobs;
  source_record public.curriculum_sources;
  errors jsonb := '[]'::jsonb;
  final_status text;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  select job.* into import_record
  from public.curriculum_import_jobs job
  where job.id = p_job_id
  for update;
  if not found or import_record.status not in ('extracted', 'validation_failed') then
    raise exception 'The import job is not ready for validation'
      using errcode = '55000';
  end if;
  if not public.has_curriculum_role(
    public.curriculum_version_country(import_record.version_id),
    array['curriculum_editor', 'curriculum_admin']
  ) then
    raise exception 'Curriculum editor authorization is required'
      using errcode = '42501';
  end if;

  select source.* into source_record
  from public.curriculum_sources source
  where source.id = import_record.source_id;
  if source_record.verification_status <> 'verified'
     or source_record.usage_rights_status not in ('authorized', 'public_domain')
     or source_record.sha256_checksum <> import_record.file_sha256 then
    errors := errors || jsonb_build_array(
      'The registered source, checksum, or usage rights are not verified.'
    );
  end if;
  if not exists (
    select 1 from public.curriculum_import_pages page
    where page.job_id = p_job_id
      and char_length(btrim(page.extracted_text)) > 0
  ) then
    errors := errors || jsonb_build_array(
      'No selectable PDF text was extracted; add a text source or use an authorized manual transcription workflow.'
    );
  end if;
  if not exists (
    select 1 from public.curriculum_import_items item
    where item.job_id = p_job_id
  ) then
    errors := errors || jsonb_build_array(
      'No curriculum items have been normalized for human review.'
    );
  end if;
  if exists (
    select 1
    from public.curriculum_import_items item
    where item.job_id = p_job_id
      and (
        char_length(btrim(item.source_text)) = 0
        or char_length(btrim(item.normalized_text)) = 0
        or item.review_status <> 'pending'
      )
  ) then
    errors := errors || jsonb_build_array(
      'Each imported item must have separate source text and normalized text and must await human review.'
    );
  end if;
  if exists (
    select 1
    from public.curriculum_import_items item
    left join public.curriculum_import_pages page
      on page.id = item.import_page_id
      and page.job_id = item.job_id
      and page.version_id = item.version_id
    where item.job_id = p_job_id and page.id is null
  ) then
    errors := errors || jsonb_build_array(
      'An imported item is missing a source page reference.'
    );
  end if;

  final_status := case
    when jsonb_array_length(errors) = 0 then 'in_review'
    else 'validation_failed'
  end;
  update public.curriculum_import_jobs
  set status = final_status,
      validation_errors = errors,
      last_error = null,
      completed_at = now()
  where id = p_job_id;
  insert into public.curriculum_import_job_history (
    job_id, from_status, to_status, actor_user_id, note
  )
  values (
    p_job_id,
    import_record.status,
    final_status,
    auth.uid(),
    case when jsonb_array_length(errors) = 0
      then 'Validation passed; human review required'
      else 'Validation errors recorded' end
  );
  return jsonb_build_object('status', final_status, 'errors', errors);
end;
$$;

revoke all on function public.validate_curriculum_import(uuid)
  from public, anon;
grant execute on function public.validate_curriculum_import(uuid)
  to authenticated;

create function public.create_tie_primary_pilot_version(
  p_version_code text,
  p_display_name text,
  p_source_id uuid
)
returns public.curriculum_versions
language plpgsql
security definer
set search_path = ''
as $$
declare
  curriculum_record public.curricula;
  source_record public.curriculum_sources;
  version_record public.curriculum_versions;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  select * into curriculum_record
  from public.curricula
  where code = 'TIE' and country_code = 'TZ' and is_enabled;
  if not found or not public.has_curriculum_role(
    'TZ', array['curriculum_editor', 'curriculum_admin']
  ) then
    raise exception 'TIE curriculum editor authorization is required'
      using errcode = '42501';
  end if;
  if p_version_code is null
     or char_length(btrim(p_version_code)) not between 1 and 80
     or p_display_name is null
     or char_length(btrim(p_display_name)) not between 1 and 200 then
    raise exception 'A valid pilot version code and name are required'
      using errcode = '22023';
  end if;

  select * into source_record
  from public.curriculum_sources
  where id = p_source_id and authority_id = curriculum_record.authority_id;
  if not found then
    raise exception 'A TIE source record is required'
      using errcode = '22023';
  end if;

  insert into public.curriculum_versions (
    curriculum_id,
    version_code,
    display_name,
    status,
    requires_reviewed_import,
    created_by
  )
  values (
    curriculum_record.id,
    btrim(p_version_code),
    btrim(p_display_name),
    'draft',
    true,
    auth.uid()
  )
  returning * into version_record;

  insert into public.curriculum_version_grades (
    version_id, curriculum_id, education_level_id, grade_id, display_order
  )
  select
    version_record.id,
    curriculum_record.id,
    grade.education_level_id,
    grade.id,
    grade.sequence
  from public.education_levels level
  join public.education_grades grade
    on grade.education_level_id = level.id
  where level.curriculum_id = curriculum_record.id
    and level.code = 'PRIMARY';

  insert into public.curriculum_version_sources (
    version_id, curriculum_id, authority_id, source_id,
    section_reference, created_by
  )
  values (
    version_record.id,
    curriculum_record.id,
    curriculum_record.authority_id,
    source_record.id,
    'Primary pilot source; verify edition and rights before import.',
    auth.uid()
  );
  insert into public.curriculum_version_review_history (
    version_id, from_status, to_status, actor_user_id, note
  )
  values (
    version_record.id, null, 'draft', auth.uid(),
    'TIE primary pilot created; content requires source-backed review.'
  );
  return version_record;
end;
$$;

revoke all on function public.create_tie_primary_pilot_version(
  text, text, uuid
) from public, anon;
grant execute on function public.create_tie_primary_pilot_version(
  text, text, uuid
) to authenticated;

create function public.review_curriculum_import_item(
  p_item_id uuid,
  p_decision text,
  p_note text default null
)
returns public.curriculum_import_items
language plpgsql
security definer
set search_path = ''
as $$
declare
  item_record public.curriculum_import_items;
  job_record public.curriculum_import_jobs;
  actor_country text;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if p_decision is null or p_decision not in ('approved', 'rejected')
     or char_length(coalesce(p_note, '')) > 2000 then
    raise exception 'A valid review decision is required'
      using errcode = '22023';
  end if;

  select item.* into item_record
  from public.curriculum_import_items item
  where item.id = p_item_id
  for update;
  if not found then
    raise exception 'The curriculum item is unavailable'
      using errcode = '22023';
  end if;
  select job.* into job_record
  from public.curriculum_import_jobs job
  where job.id = item_record.job_id
  for update;
  actor_country := public.curriculum_version_country(item_record.version_id);
  if not public.has_curriculum_role(
    actor_country, array['curriculum_reviewer', 'curriculum_admin']
  ) then
    raise exception 'Curriculum reviewer authorization is required'
      using errcode = '42501';
  end if;
  if job_record.status <> 'in_review'
     or item_record.review_status <> 'pending'
     or item_record.created_by = auth.uid() then
    raise exception 'Only another user''s pending item in an in-review job can be reviewed'
      using errcode = '55000';
  end if;
  if p_decision = 'rejected'
     and char_length(btrim(coalesce(p_note, ''))) = 0 then
    raise exception 'A rejection note is required'
      using errcode = '22023';
  end if;

  update public.curriculum_import_items
  set review_status = p_decision,
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      review_note = nullif(btrim(coalesce(p_note, '')), '')
  where id = p_item_id
  returning * into item_record;

  insert into public.curriculum_import_item_review_history (
    item_id, decision, reviewer_user_id, note
  )
  values (
    p_item_id, p_decision, auth.uid(),
    nullif(btrim(coalesce(p_note, '')), '')
  );
  if not exists (
    select 1
    from public.curriculum_import_items item
    where item.job_id = job_record.id
      and item.review_status = 'pending'
  ) then
    update public.curriculum_import_jobs
    set status = 'reviewed', completed_at = now()
    where id = job_record.id;
    insert into public.curriculum_import_job_history (
      job_id, from_status, to_status, actor_user_id, note
    )
    values (
      job_record.id, 'in_review', 'reviewed', auth.uid(),
      'All extracted items have a human decision'
    );
  end if;
  perform public.write_audit_log(
    auth.uid(),
    null,
    'curriculum.import_item_reviewed',
    jsonb_build_object(
      'item_id', p_item_id,
      'decision', p_decision,
      'job_id', job_record.id
    )
  );
  return item_record;
end;
$$;

revoke all on function public.review_curriculum_import_item(
  uuid, text, text
) from public, anon;
grant execute on function public.review_curriculum_import_item(
  uuid, text, text
) to authenticated;

create or replace function public.verify_curriculum_source(
  p_source_id uuid,
  p_verified boolean,
  p_note text default null
)
returns public.curriculum_sources
language plpgsql
security definer
set search_path = ''
as $$
declare
  source_record public.curriculum_sources;
  source_country text;
  target_status text;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if char_length(coalesce(p_note, '')) > 2000 then
    raise exception 'The review note is too long' using errcode = '22023';
  end if;
  if p_verified is null then
    raise exception 'A source verification decision is required'
      using errcode = '22023';
  end if;

  select authority.country_code into source_country
  from public.curriculum_sources source
  join public.curriculum_authorities authority
    on authority.id = source.authority_id
  where source.id = p_source_id;
  if not found then
    raise exception 'The curriculum source is unavailable'
      using errcode = '22023';
  end if;
  if not public.has_curriculum_role(
    source_country,
    array['curriculum_reviewer', 'curriculum_admin']
  ) then
    raise exception 'Curriculum reviewer authorization is required'
      using errcode = '42501';
  end if;

  target_status := case when p_verified then 'verified' else 'rejected' end;
  update public.curriculum_sources
  set verification_status = target_status,
      verified_by = auth.uid(),
      verified_at = now()
  where id = p_source_id
    and verification_status = 'unverified'
    and (created_by is null or created_by <> auth.uid())
    and sha256_checksum is not null
    and (source_url is not null or storage_bucket is not null)
  returning * into source_record;
  if not found then
    raise exception 'Only a checksum-backed source submitted by another user can be verified'
      using errcode = '55000';
  end if;

  insert into public.curriculum_source_review_history (
    source_id, verification_status, reviewer_user_id, note
  )
  values (
    p_source_id, target_status, auth.uid(),
    nullif(btrim(coalesce(p_note, '')), '')
  );
  return source_record;
end;
$$;

create or replace function public.transition_curriculum_version(
  p_version_id uuid,
  p_target_status text,
  p_note text default null
)
returns public.curriculum_versions
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_version public.curriculum_versions;
  updated_version public.curriculum_versions;
  version_country text;
  permitted boolean := false;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if p_target_status is null or p_target_status not in (
    'draft', 'under_review', 'approved', 'published', 'superseded', 'archived'
  ) then
    raise exception 'The requested lifecycle status is invalid'
      using errcode = '22023';
  end if;
  if char_length(coalesce(p_note, '')) > 2000 then
    raise exception 'The review note is too long' using errcode = '22023';
  end if;

  select version.* into current_version
  from public.curriculum_versions version
  where version.id = p_version_id
  for update;
  if not found then
    raise exception 'The curriculum version is unavailable'
      using errcode = '22023';
  end if;
  select curriculum.country_code into version_country
  from public.curricula curriculum
  where curriculum.id = current_version.curriculum_id;

  if current_version.status = 'draft'
     and p_target_status = 'under_review' then
    permitted := public.has_curriculum_role(
      version_country, array['curriculum_editor', 'curriculum_admin']
    );
  elsif current_version.status = 'under_review'
        and p_target_status = 'draft' then
    permitted := public.has_curriculum_role(
      version_country, array['curriculum_editor', 'curriculum_admin']
    );
  elsif current_version.status = 'under_review'
        and p_target_status = 'approved' then
    permitted := public.has_curriculum_role(
      version_country, array['curriculum_approver', 'curriculum_admin']
    );
  elsif current_version.status = 'approved'
        and p_target_status = 'published' then
    permitted := public.has_curriculum_role(
      version_country, array['curriculum_approver', 'curriculum_admin']
    );
  elsif current_version.status = 'published'
        and p_target_status = 'superseded' then
    permitted := public.has_curriculum_role(
      version_country, array['curriculum_approver', 'curriculum_admin']
    ) and exists (
      select 1 from public.curriculum_versions replacement
      where replacement.curriculum_id = current_version.curriculum_id
        and replacement.id <> current_version.id
        and replacement.status = 'published'
    );
  elsif current_version.status = 'superseded'
        and p_target_status = 'archived' then
    permitted := public.has_curriculum_role(
      version_country, array['curriculum_admin']
    );
  end if;

  if not permitted then
    raise exception 'The requested curriculum lifecycle transition is not authorized'
      using errcode = '42501';
  end if;

  if current_version.requires_reviewed_import
     and p_target_status in ('under_review', 'approved', 'published') then
    if not exists (
      select 1
      from public.curriculum_version_sources version_source
      join public.curriculum_sources source
        on source.id = version_source.source_id
      where version_source.version_id = p_version_id
        and source.verification_status = 'verified'
        and source.usage_rights_status in ('authorized', 'public_domain')
    ) or exists (
      select 1
      from public.curriculum_version_sources version_source
      join public.curriculum_sources source
        on source.id = version_source.source_id
      where version_source.version_id = p_version_id
        and (
          source.verification_status <> 'verified'
          or source.usage_rights_status not in ('authorized', 'public_domain')
        )
    ) then
      raise exception 'Every attached source must be verified and cleared for use'
        using errcode = '23514';
    end if;
  end if;

  if current_version.requires_reviewed_import
     and p_target_status = 'approved'
     and exists (
       select 1
       from public.curriculum_import_items item
       where item.version_id = p_version_id
         and item.review_status = 'approved'
         and item.reviewed_by = auth.uid()
     ) then
    raise exception 'A curriculum item reviewer cannot approve the same version'
      using errcode = '42501';
  end if;

  if current_version.requires_reviewed_import
     and p_target_status in ('under_review', 'approved', 'published') then
    if exists (
      select 1 from public.curriculum_import_jobs job
      where job.version_id = p_version_id and job.status <> 'reviewed'
    ) then
      raise exception 'All curriculum imports must complete independent human review'
        using errcode = '23514';
    end if;
    if p_target_status in ('approved', 'published') and (
      not exists (
        select 1
        from public.curriculum_import_items item
        where item.version_id = p_version_id
          and item.review_status = 'approved'
      )
      or not exists (
        select 1 from public.curriculum_import_jobs job
        where job.version_id = p_version_id and job.status = 'reviewed'
      )
    ) then
      raise exception 'At least one human-reviewed curriculum item is required'
        using errcode = '23514';
    end if;
  end if;

  if not current_version.requires_reviewed_import
     and p_target_status in ('approved', 'published')
     and not exists (
       select 1
       from public.curriculum_version_sources version_source
       join public.curriculum_sources source
         on source.id = version_source.source_id
       where version_source.version_id = p_version_id
         and source.verification_status = 'verified'
     ) then
    raise exception 'Verified source evidence is required for approval and publication'
      using errcode = '23514';
  end if;

  update public.curriculum_versions
  set status = p_target_status,
      approved_by = case when p_target_status = 'approved'
        then auth.uid() else approved_by end,
      approved_at = case when p_target_status = 'approved'
        then now() else approved_at end,
      published_by = case when p_target_status = 'published'
        then auth.uid() else published_by end,
      published_at = case when p_target_status = 'published'
        then now() else published_at end
  where id = p_version_id
  returning * into updated_version;

  insert into public.curriculum_version_review_history (
    version_id, from_status, to_status, actor_user_id, note
  )
  values (
    p_version_id,
    current_version.status,
    p_target_status,
    auth.uid(),
    nullif(btrim(coalesce(p_note, '')), '')
  );
  perform public.write_audit_log(
    auth.uid(),
    null,
    'curriculum.version_transitioned',
    jsonb_build_object(
      'version_id', p_version_id,
      'from_status', current_version.status,
      'to_status', p_target_status
    )
  );
  return updated_version;
end;
$$;

revoke all on function public.transition_curriculum_version(
  uuid, text, text
) from public, anon;
grant execute on function public.transition_curriculum_version(
  uuid, text, text
) to authenticated;

insert into public.audit_logs (
  actor_user_id, target_user_id, action, details
)
values (
  null,
  null,
  'curriculum.primary_pilot_source_catalogued',
  jsonb_build_object(
    'source_url',
    'https://www.tie.go.tz/publications/mtaala-wa-elimu-ya-msingi',
    'source_sha256',
    '20c75d2071d4a1726187af6c097125137ef4b0971d7a7b3834d030d5295b3591',
    'verification_status', 'unverified',
    'usage_rights_status', 'permission_pending',
    'content_imported', false
  )
);

commit;
