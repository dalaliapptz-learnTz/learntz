begin;

create extension if not exists pg_trgm with schema extensions;

alter table public.curriculum_sources
  drop constraint curriculum_sources_document_format_check,
  add constraint curriculum_sources_document_format_check check (
    document_format is null
    or document_format in (
      'application/pdf',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/csv',
      'application/json',
      'text/plain'
    )
  );

alter table public.curriculum_import_jobs
  drop constraint curriculum_import_jobs_status_check,
  drop constraint curriculum_import_jobs_storage_object_path_check,
  add constraint curriculum_import_jobs_status_check check (status in (
    'queued', 'processing', 'extracted', 'validation_failed', 'in_review',
    'reviewed', 'failed'
  )),
  add constraint curriculum_import_jobs_storage_object_path_check check (
    storage_object_path ~
      '^TZ/[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|docx|xlsx|csv|json)$'
  ),
  add column document_format text not null default 'application/pdf'
    check (document_format in (
      'application/pdf',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/csv',
      'application/json'
    )),
  add column original_filename text
    check (original_filename is null or (
      char_length(original_filename) between 1 and 255
      and original_filename !~ '[[:cntrl:]/\\]'
    )),
  add column file_size_bytes bigint
    check (file_size_bytes is null or file_size_bytes between 1 and 26214400),
  add column upload_complete boolean not null default false,
  add column processing_started_at timestamptz,
  add column processing_lease_expires_at timestamptz,
  add column next_attempt_at timestamptz not null default now(),
  add column processing_page_number integer
    check (processing_page_number is null or processing_page_number > 0),
  add column page_count integer check (page_count is null or page_count between 1 and 500),
  add column extraction_engine text,
  add column extraction_engine_version text;

alter table public.curriculum_import_jobs
  add constraint curriculum_import_jobs_id_checksum_unique unique (id, file_sha256),
  add constraint curriculum_import_jobs_id_format_unique unique (id, document_format);

alter table public.curriculum_import_job_history
  drop constraint curriculum_import_job_history_from_status_check,
  drop constraint curriculum_import_job_history_to_status_check,
  add constraint curriculum_import_job_history_from_status_check
    check (from_status is null or from_status in (
      'queued', 'processing', 'extracted', 'validation_failed', 'in_review',
      'reviewed', 'failed'
    )),
  add constraint curriculum_import_job_history_to_status_check
    check (to_status in (
      'queued', 'processing', 'extracted', 'validation_failed', 'in_review',
      'reviewed', 'failed'
    ));

create index curriculum_import_jobs_queue_idx
  on public.curriculum_import_jobs (next_attempt_at, created_at)
  where status in ('queued', 'processing', 'failed');

create table public.curriculum_import_documents (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null unique
    references public.curriculum_import_jobs (id) on delete restrict,
  original_filename text not null
    check (char_length(original_filename) between 1 and 255),
  declared_content_type text not null,
  detected_content_type text,
  file_size_bytes bigint not null
    check (file_size_bytes between 1 and 26214400),
  file_sha256 text not null check (file_sha256 ~ '^[0-9a-f]{64}$'),
  document_metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(document_metadata) = 'object'),
  registered_by uuid not null references auth.users (id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint curriculum_import_documents_job_sha_fk
    foreign key (job_id, file_sha256)
    references public.curriculum_import_jobs (id, file_sha256)
    on delete restrict,
  constraint curriculum_import_documents_job_format_fk
    foreign key (job_id, declared_content_type)
    references public.curriculum_import_jobs (id, document_format)
    on delete restrict
);

create table public.curriculum_import_errors (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null
    references public.curriculum_import_jobs (id) on delete restrict,
  page_number integer check (page_number is null or page_number > 0),
  stage text not null check (stage in (
    'upload', 'file_validation', 'metadata', 'extraction', 'ocr',
    'normalization', 'duplicate_detection', 'validation', 'database'
  )),
  error_code text not null check (error_code ~ '^[a-z][a-z0-9_]{1,79}$'),
  message text not null check (char_length(btrim(message)) between 1 and 1000),
  retryable boolean not null default false,
  details jsonb not null default '{}'::jsonb
    check (jsonb_typeof(details) = 'object'),
  created_at timestamptz not null default now()
);

create index curriculum_import_errors_job_idx
  on public.curriculum_import_errors (job_id, created_at desc);

alter table public.curriculum_import_pages
  add column extraction_method text not null default 'selectable_text'
    check (extraction_method in (
      'selectable_text', 'ocr', 'mixed', 'structured_data', 'manual'
    )),
  add column extraction_engine text not null default 'stage3_2_client',
  add column extraction_engine_version text,
  add column ocr_confidence numeric(5, 4)
    check (ocr_confidence is null or ocr_confidence between 0 and 1),
  add column page_metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(page_metadata) = 'object'),
  add column extraction_warnings jsonb not null default '[]'::jsonb
    check (jsonb_typeof(extraction_warnings) = 'array'),
  add column page_revision integer not null default 1
    check (page_revision > 0),
  add column section_path jsonb not null default '[]'::jsonb
    check (jsonb_typeof(section_path) = 'array'),
  add column extracted_at timestamptz not null default now();

alter table public.curriculum_import_items
  drop constraint curriculum_import_items_item_type_check,
  add constraint curriculum_import_items_item_type_check check (item_type in (
    'subject', 'learning_area', 'topic', 'strand', 'subtopic', 'sub_strand',
    'competency', 'learning_outcome', 'assessment_guidance',
    'teaching_guidance', 'other'
  )),
  add column section_reference text
    check (section_reference is null or char_length(section_reference) <= 500),
  add column source_page_revision integer not null default 1
    check (source_page_revision > 0);

create function public.set_curriculum_item_source_page_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  select page.page_revision into new.source_page_revision
  from public.curriculum_import_pages page
  where page.id = new.import_page_id
    and page.job_id = new.job_id
    and page.version_id = new.version_id;
  if new.source_page_revision is null then
    raise exception 'An imported item must reference an extracted source page'
      using errcode = '23503';
  end if;
  return new;
end;
$$;

revoke all on function public.set_curriculum_item_source_page_revision()
  from public, anon, authenticated;
create trigger curriculum_import_item_page_revision
  before insert or update of import_page_id, source_text, normalized_text
  on public.curriculum_import_items
  for each row execute function public.set_curriculum_item_source_page_revision();

create table public.curriculum_validation_results (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null
    references public.curriculum_import_jobs (id) on delete restrict,
  validator_version text not null,
  passed boolean not null,
  error_count integer not null check (error_count >= 0),
  warning_count integer not null check (warning_count >= 0),
  report jsonb not null check (jsonb_typeof(report) = 'object'),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create index curriculum_validation_results_job_idx
  on public.curriculum_validation_results (job_id, created_at desc);

create function public.record_curriculum_validation_result()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  error_count integer;
begin
  if new.status in ('validation_failed', 'in_review')
     and (
       old.status is distinct from new.status
       or old.validation_errors is distinct from new.validation_errors
     ) then
    error_count := jsonb_array_length(new.validation_errors);
    insert into public.curriculum_validation_results (
      job_id, validator_version, passed, error_count, warning_count,
      report, created_by
    ) values (
      new.id, 'database-stage3.3.1',
      new.status = 'in_review', error_count, 0,
      jsonb_build_object(
        'status', new.status,
        'errors', new.validation_errors,
        'warnings', '[]'::jsonb,
        'checked_at', now()
      ),
      auth.uid()
    );
  end if;
  return new;
end;
$$;

revoke all on function public.record_curriculum_validation_result()
  from public, anon, authenticated;
create trigger curriculum_import_validation_result
  after update of status, validation_errors
  on public.curriculum_import_jobs
  for each row execute function public.record_curriculum_validation_result();

create table public.curriculum_duplicate_matches (
  id uuid primary key default gen_random_uuid(),
  import_item_id uuid not null,
  candidate_item_id uuid not null,
  job_id uuid not null,
  candidate_job_id uuid not null,
  version_id uuid not null,
  match_type text not null check (match_type in ('exact_duplicate', 'possible_duplicate')),
  similarity numeric(5, 4) not null check (similarity between 0 and 1),
  decision text not null default 'pending'
    check (decision in ('pending', 'confirmed_duplicate', 'not_duplicate', 'deferred')),
  reviewer_user_id uuid references auth.users (id) on delete set null,
  review_note text check (review_note is null or char_length(review_note) <= 2000),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  constraint curriculum_duplicate_matches_source_fk
    foreign key (import_item_id, job_id, version_id)
    references public.curriculum_import_items (id, job_id, version_id)
    on delete restrict,
  constraint curriculum_duplicate_matches_candidate_fk
    foreign key (candidate_item_id, candidate_job_id, version_id)
    references public.curriculum_import_items (id, job_id, version_id)
    on delete restrict,
  constraint curriculum_duplicate_matches_not_self
    check (import_item_id <> candidate_item_id),
  constraint curriculum_duplicate_matches_pair_unique
    unique (import_item_id, candidate_item_id),
  constraint curriculum_duplicate_matches_review_check
    check (
      (decision = 'pending' and reviewer_user_id is null and reviewed_at is null)
      or (decision <> 'pending' and reviewer_user_id is not null and reviewed_at is not null)
    )
);

create index curriculum_duplicate_matches_pending_idx
  on public.curriculum_duplicate_matches (version_id, decision, created_at desc);

create or replace function public.register_curriculum_import_document(
  p_version_id uuid,
  p_source_id uuid,
  p_file_sha256 text,
  p_document_format text,
  p_original_filename text,
  p_file_size_bytes bigint
)
returns public.curriculum_import_jobs
language plpgsql
security definer
set search_path = ''
as $$
declare
  version_record public.curriculum_versions;
  source_record public.curriculum_sources;
  authority_id uuid;
  country text;
  extension text;
  job_record public.curriculum_import_jobs;
  inserted boolean := false;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if p_file_sha256 is null or p_file_sha256 !~ '^[0-9a-f]{64}$'
     or p_document_format not in (
       'application/pdf',
       'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
       'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
       'text/csv', 'application/json'
     )
     or char_length(coalesce(p_original_filename, '')) not between 1 and 255
     or p_original_filename ~ '[[:cntrl:]/\\]'
     or p_file_size_bytes not between 1 and 26214400 then
    raise exception 'The document metadata or file size is invalid'
      using errcode = '22023';
  end if;

  extension := case p_document_format
    when 'application/pdf' then 'pdf'
    when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' then 'docx'
    when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' then 'xlsx'
    when 'text/csv' then 'csv'
    when 'application/json' then 'json'
  end;
  if lower(split_part(p_original_filename, '.', -1)) <> extension then
    raise exception 'The file extension does not match the declared format'
      using errcode = '22023';
  end if;

  select version.* into version_record
  from public.curriculum_versions version
  where version.id = p_version_id
  for update;
  if not found or version_record.status <> 'draft'
     or not version_record.requires_reviewed_import then
    raise exception 'A draft curriculum import version is required'
      using errcode = '55000';
  end if;
  select curriculum.country_code, curriculum.authority_id
  into country, authority_id
  from public.curricula curriculum
  where curriculum.id = version_record.curriculum_id;
  if not public.has_curriculum_role(
    country, array['curriculum_editor', 'curriculum_admin', 'country_admin']
  ) then
    raise exception 'Curriculum editor authorization is required'
      using errcode = '42501';
  end if;

  select source.* into source_record
  from public.curriculum_sources source
  where source.id = p_source_id
    and source.authority_id = authority_id
  for update;
  if not found
     or source_record.sha256_checksum <> p_file_sha256
     or source_record.document_format is distinct from p_document_format
     or source_record.verification_status <> 'verified'
     or source_record.usage_rights_status not in ('authorized', 'public_domain')
     or source_record.verified_by = auth.uid()
     or source_record.usage_rights_reviewed_by = auth.uid() then
    raise exception 'A matching independently verified source with cleared usage rights is required'
      using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.curriculum_version_sources version_source
    where version_source.version_id = p_version_id
      and version_source.source_id = p_source_id
  ) then
    raise exception 'The source must be attached to the curriculum version'
      using errcode = '23514';
  end if;

  insert into public.curriculum_import_jobs (
    version_id, curriculum_id, source_id, authority_id, file_sha256,
    document_format, original_filename, file_size_bytes, storage_object_path,
    created_by
  )
  values (
    p_version_id, version_record.curriculum_id, p_source_id, authority_id,
    p_file_sha256, p_document_format, p_original_filename, p_file_size_bytes,
    format('TZ/%s/%s.%s', p_source_id, gen_random_uuid(), extension), auth.uid()
  )
  on conflict (version_id, source_id, file_sha256) do nothing
  returning * into job_record;

  if found then
    inserted := true;
  else
    with exhausted as (
      update public.curriculum_import_jobs job
      set status = 'failed',
          last_error = 'Processing attempts exhausted after worker lease expiry',
          processing_started_at = null,
          processing_lease_expires_at = null,
          completed_at = now()
      where job.status = 'processing'
        and job.processing_lease_expires_at < now()
        and job.attempt_count >= 5
      returning job.id
    )
    insert into public.curriculum_import_job_history (
      job_id, from_status, to_status, note
    )
    select id, 'processing', 'failed', 'Worker lease expired after maximum attempts'
    from exhausted;

    select job.* into job_record
    from public.curriculum_import_jobs job
    where job.version_id = p_version_id
      and job.source_id = p_source_id
      and job.file_sha256 = p_file_sha256
    for update;
    if job_record.document_format <> p_document_format
       or job_record.original_filename <> p_original_filename
       or job_record.file_size_bytes <> p_file_size_bytes then
      raise exception 'An idempotent retry must use the original document metadata'
        using errcode = '23505';
    end if;
    if job_record.status not in ('failed', 'queued') then
      return job_record;
    end if;
    if job_record.created_by <> auth.uid() then
      raise exception 'Only the original importer can retry a pending upload'
        using errcode = '42501';
    end if;
  end if;

  insert into public.curriculum_import_documents (
    job_id, original_filename, declared_content_type, file_size_bytes,
    file_sha256, registered_by
  )
  values (
    job_record.id, p_original_filename, p_document_format, p_file_size_bytes,
    p_file_sha256, auth.uid()
  )
  on conflict (job_id) do nothing;

  if inserted then
    insert into public.curriculum_import_job_history (
      job_id, from_status, to_status, actor_user_id, note
    )
    values (job_record.id, null, 'queued', auth.uid(), 'Import document registered');
    perform public.write_audit_log(
      auth.uid(), null, 'curriculum.import_registered',
      jsonb_build_object(
        'job_id', job_record.id,
        'source_id', p_source_id,
        'sha256', p_file_sha256,
        'document_format', p_document_format
      )
    );
  end if;
  return job_record;
end;
$$;

revoke all on function public.register_curriculum_import_document(
  uuid, uuid, text, text, text, bigint
) from public, anon;
revoke all on function public.register_curriculum_import(uuid, uuid, text)
  from public, anon, authenticated;
grant execute on function public.register_curriculum_import_document(
  uuid, uuid, text, text, text, bigint
) to authenticated;

create function public.claim_curriculum_import_job()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  job_record public.curriculum_import_jobs;
  document_record public.curriculum_import_documents;
  previous_status text;
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'Worker authorization is required' using errcode = '42501';
  end if;

  with exhausted as (
    update public.curriculum_import_jobs job
    set status = 'failed',
        last_error = 'Processing attempts exhausted after worker lease expiry',
        processing_started_at = null,
        processing_lease_expires_at = null,
        completed_at = now()
    where job.status = 'processing'
      and job.processing_lease_expires_at < now()
      and job.attempt_count >= 5
    returning job.id
  )
  insert into public.curriculum_import_job_history (
    job_id, from_status, to_status, note
  )
  select id, 'processing', 'failed', 'Worker lease expired after maximum attempts'
  from exhausted;

  select job.* into job_record
  from public.curriculum_import_jobs job
  where job.attempt_count < 5
    and job.upload_complete
    and ((
      job.status = 'queued' and job.next_attempt_at <= now()
    ) or (
      job.status = 'processing' and job.processing_lease_expires_at < now()
    ))
  order by job.next_attempt_at, job.created_at
  for update skip locked
  limit 1;
  if not found then
    return null;
  end if;
  previous_status := job_record.status;
  if not exists (
    select 1 from public.curriculum_sources source
    where source.id = job_record.source_id
      and source.sha256_checksum = job_record.file_sha256
      and source.verification_status = 'verified'
      and source.usage_rights_status in ('authorized', 'public_domain')
  ) then
    update public.curriculum_import_jobs
    set status = 'failed',
        last_error = 'Source rights are no longer cleared',
        processing_started_at = null,
        processing_lease_expires_at = null
    where id = job_record.id;
    insert into public.curriculum_import_errors (
      job_id, stage, error_code, message
    ) values (
      job_record.id, 'file_validation', 'source_rights_revoked',
      'Source rights are no longer cleared for processing.'
    );
    return null;
  end if;

  update public.curriculum_import_jobs
  set status = 'processing',
      attempt_count = attempt_count + 1,
      processing_started_at = now(),
      processing_lease_expires_at = now() + interval '20 minutes',
      last_error = null
  where id = job_record.id
  returning * into job_record;

  select document.* into document_record
  from public.curriculum_import_documents document
  where document.job_id = job_record.id;
  if not found then
    update public.curriculum_import_jobs
    set status = 'failed',
        last_error = 'Registered document metadata is missing',
        processing_started_at = null,
        processing_lease_expires_at = null
    where id = job_record.id;
    return null;
  end if;

  insert into public.curriculum_import_job_history (
    job_id, from_status, to_status, note
  ) values (job_record.id, previous_status, 'processing', 'Claimed by import worker');

  return jsonb_build_object(
    'id', job_record.id,
    'source_id', job_record.source_id,
    'version_id', job_record.version_id,
    'curriculum_id', job_record.curriculum_id,
    'file_sha256', job_record.file_sha256,
    'storage_bucket', job_record.storage_bucket,
    'storage_object_path', job_record.storage_object_path,
    'document_format', job_record.document_format,
    'original_filename', document_record.original_filename,
    'declared_content_type', document_record.declared_content_type,
    'file_size_bytes', document_record.file_size_bytes,
    'processing_page_number', job_record.processing_page_number,
    'attempt_count', job_record.attempt_count
  );
end;
$$;

revoke all on function public.claim_curriculum_import_job()
  from public, anon, authenticated;
grant execute on function public.claim_curriculum_import_job()
  to service_role;

create function public.renew_curriculum_import_lease(p_job_id uuid)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  lease_expires timestamptz;
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'Worker authorization is required' using errcode = '42501';
  end if;
  update public.curriculum_import_jobs
  set processing_lease_expires_at = now() + interval '20 minutes'
  where id = p_job_id
    and status = 'processing'
    and processing_lease_expires_at > now()
  returning processing_lease_expires_at into lease_expires;
  if lease_expires is null then
    raise exception 'The worker lease expired or was lost' using errcode = '55000';
  end if;
  return lease_expires;
end;
$$;

revoke all on function public.renew_curriculum_import_lease(uuid)
  from public, anon, authenticated;
grant execute on function public.renew_curriculum_import_lease(uuid)
  to service_role;

create function public.mark_curriculum_import_uploaded(p_job_id uuid)
returns public.curriculum_import_jobs
language plpgsql
security definer
set search_path = ''
as $$
declare
  job_record public.curriculum_import_jobs;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  select job.* into job_record
  from public.curriculum_import_jobs job
  where job.id = p_job_id
  for update;
  if not found or job_record.status not in ('queued', 'failed')
     or job_record.attempt_count >= 5
     or job_record.created_by <> auth.uid()
     or not public.has_curriculum_role(
       public.curriculum_version_country(job_record.version_id),
       array['curriculum_editor', 'curriculum_admin']
     ) then
    raise exception 'The import upload is unavailable to this user'
      using errcode = '42501';
  end if;
  if not exists (
    select 1 from storage.objects object
    where object.bucket_id = job_record.storage_bucket
      and object.name = job_record.storage_object_path
      and (
        object.metadata ->> 'size' is null
        or (object.metadata ->> 'size')::bigint = job_record.file_size_bytes
      )
  ) then
    raise exception 'The uploaded object is missing or has an invalid size'
      using errcode = '23514';
  end if;
  if not exists (
    select 1 from public.curriculum_sources source
    where source.id = job_record.source_id
      and source.verification_status = 'verified'
      and source.usage_rights_status in ('authorized', 'public_domain')
      and source.sha256_checksum = job_record.file_sha256
  ) then
    raise exception 'Verified source and documented usage rights are required'
      using errcode = '42501';
  end if;
  update public.curriculum_import_jobs
  set upload_complete = true,
      status = 'queued',
      next_attempt_at = now(),
      last_error = null,
      completed_at = null
  where id = p_job_id
  returning * into job_record;
  insert into public.curriculum_import_job_history (
    job_id, from_status, to_status, actor_user_id, note
  ) values (p_job_id, 'queued', 'queued', auth.uid(), 'Private document upload completed');
  return job_record;
end;
$$;

revoke all on function public.mark_curriculum_import_uploaded(uuid)
  from public, anon;
grant execute on function public.mark_curriculum_import_uploaded(uuid)
  to authenticated;

create or replace function public.complete_curriculum_import(
  p_job_id uuid,
  p_pages jsonb,
  p_metadata jsonb default '{}'::jsonb
)
returns public.curriculum_import_jobs
language plpgsql
security definer
set search_path = ''
as $$
declare
  import_record public.curriculum_import_jobs;
  page_record jsonb;
  page_number integer;
  page_text text;
  page_total integer;
  total_characters bigint := 0;
  prior_status text;
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'Worker authorization is required' using errcode = '42501';
  end if;
  if p_pages is null or jsonb_typeof(p_pages) <> 'array'
     or jsonb_array_length(p_pages) not between 1 and 500
     or p_metadata is null or jsonb_typeof(p_metadata) <> 'object' then
    raise exception 'Worker extraction output is invalid' using errcode = '22023';
  end if;

  select job.* into import_record
  from public.curriculum_import_jobs job
  where job.id = p_job_id
  for update;
  if not found or import_record.status <> 'processing'
     or import_record.processing_lease_expires_at < now() then
    raise exception 'The import job is not actively leased to a worker'
      using errcode = '55000';
  end if;
  if not exists (
    select 1 from public.curriculum_sources source
    where source.id = import_record.source_id
      and source.sha256_checksum = import_record.file_sha256
      and source.verification_status = 'verified'
      and source.usage_rights_status in ('authorized', 'public_domain')
  ) then
    raise exception 'Verified source and documented usage rights are required'
      using errcode = '42501';
  end if;

  prior_status := import_record.status;
  for page_record in select value from jsonb_array_elements(p_pages)
  loop
    page_number := (page_record ->> 'page_number')::integer;
    page_text := coalesce(page_record ->> 'extracted_text', '');
    if page_number < 1 or page_number > 500
       or char_length(page_text) > 100000
       or jsonb_typeof(page_record -> 'page_metadata') not in ('object', 'null')
       or jsonb_typeof(page_record -> 'extraction_warnings') not in ('array', 'null') then
      raise exception 'An extracted page is invalid or too large'
        using errcode = '22023';
    end if;
    total_characters := total_characters + char_length(page_text);
  end loop;
  page_total := jsonb_array_length(p_pages);
  if total_characters > 3000000
     or exists (
       select 1 from jsonb_array_elements(p_pages) value
       group by (value ->> 'page_number') having count(*) > 1
     ) then
    raise exception 'The extracted document has duplicate pages or exceeds the text limit'
      using errcode = '22023';
  end if;
  if import_record.processing_page_number is null and exists (
    select 1 from generate_series(1, page_total) expected(number)
    where not exists (
      select 1 from jsonb_array_elements(p_pages) value
      where (value ->> 'page_number')::integer = expected.number
    )
  ) then
    raise exception 'Full-document extraction must include sequential page numbers'
      using errcode = '22023';
  end if;
  if import_record.processing_page_number is not null and (
    page_total <> 1
    or (p_pages -> 0 ->> 'page_number')::integer
      <> import_record.processing_page_number
  ) then
    raise exception 'Page reprocessing must return only the requested page'
      using errcode = '22023';
  end if;

  insert into public.curriculum_import_pages (
    job_id, version_id, curriculum_id, page_number, extracted_text,
    extracted_text_sha256, extraction_method, extraction_engine,
    extraction_engine_version, ocr_confidence, page_metadata,
    extraction_warnings
  )
  select
    import_record.id,
    import_record.version_id,
    import_record.curriculum_id,
    (page.value ->> 'page_number')::integer,
    coalesce(page.value ->> 'extracted_text', ''),
    encode(extensions.digest(
      convert_to(coalesce(page.value ->> 'extracted_text', ''), 'UTF8'),
      'sha256'
    ), 'hex'),
    coalesce(page.value ->> 'extraction_method', 'selectable_text'),
    coalesce(p_metadata ->> 'engine', 'learntz-curriculum-worker'),
    p_metadata ->> 'engine_version',
    nullif(page.value ->> 'ocr_confidence', '')::numeric,
    coalesce(page.value -> 'page_metadata', '{}'::jsonb),
    coalesce(page.value -> 'extraction_warnings', '[]'::jsonb)
  from jsonb_array_elements(p_pages) page(value)
  on conflict (job_id, page_number) do update
  set extracted_text = excluded.extracted_text,
      extracted_text_sha256 = excluded.extracted_text_sha256,
      extraction_method = excluded.extraction_method,
      extraction_engine = excluded.extraction_engine,
      extraction_engine_version = excluded.extraction_engine_version,
      ocr_confidence = excluded.ocr_confidence,
      page_metadata = excluded.page_metadata,
      extraction_warnings = excluded.extraction_warnings,
      section_path = coalesce(excluded.page_metadata -> 'section_path', '[]'::jsonb),
      page_revision = case
        when public.curriculum_import_pages.extracted_text_sha256
          is distinct from excluded.extracted_text_sha256
        then public.curriculum_import_pages.page_revision + 1
        else public.curriculum_import_pages.page_revision
      end,
      extracted_at = now();

  update public.curriculum_import_items item
  set review_status = 'pending',
      reviewed_by = null,
      reviewed_at = null,
      review_note = null
  from public.curriculum_import_pages page
  where page.job_id = p_job_id
    and item.import_page_id = page.id
    and item.source_page_revision <> page.page_revision
    and item.review_status <> 'pending';

  update public.curriculum_import_documents
  set detected_content_type = p_metadata ->> 'detected_content_type',
      document_metadata = coalesce(p_metadata -> 'document_metadata', '{}'::jsonb)
  where job_id = p_job_id;
  update public.curriculum_import_jobs
  set status = 'extracted',
      page_count = coalesce(page_count, nullif(p_metadata ->> 'page_count', '')::integer, page_total),
      extraction_engine = coalesce(p_metadata ->> 'engine', 'learntz-curriculum-worker'),
      extraction_engine_version = p_metadata ->> 'engine_version',
      processing_started_at = null,
      processing_lease_expires_at = null,
      processing_page_number = null,
      validation_errors = '[]'::jsonb,
      last_error = null,
      completed_at = now()
  where id = p_job_id
  returning * into import_record;

  insert into public.curriculum_import_job_history (
    job_id, from_status, to_status, note
  ) values (
    p_job_id, prior_status, 'extracted',
    format('%s document pages processed', page_total)
  );
  perform public.write_audit_log(
    null, null, 'curriculum.import_extracted',
    jsonb_build_object(
      'job_id', p_job_id, 'page_count', page_total,
      'engine', p_metadata ->> 'engine'
    )
  );
  return import_record;
end;
$$;

revoke all on function public.complete_curriculum_import(uuid, jsonb)
  from public, anon, authenticated;
revoke all on function public.complete_curriculum_import(uuid, jsonb, jsonb)
  from public, anon, authenticated;
grant execute on function public.complete_curriculum_import(uuid, jsonb, jsonb)
  to service_role;

create or replace function public.fail_curriculum_import(
  p_job_id uuid,
  p_error text,
  p_error_code text default 'processing_failed',
  p_retryable boolean default true,
  p_page_number integer default null,
  p_details jsonb default '{}'::jsonb
)
returns public.curriculum_import_jobs
language plpgsql
security definer
set search_path = ''
as $$
declare
  import_record public.curriculum_import_jobs;
  next_status text;
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'Worker authorization is required' using errcode = '42501';
  end if;
  if char_length(btrim(coalesce(p_error, ''))) not between 1 and 1000
     or p_error_code !~ '^[a-z][a-z0-9_]{1,79}$'
     or jsonb_typeof(coalesce(p_details, '{}'::jsonb)) <> 'object' then
    raise exception 'A safe processing error is required' using errcode = '22023';
  end if;
  select job.* into import_record
  from public.curriculum_import_jobs job
  where job.id = p_job_id and job.status = 'processing'
  for update;
  if not found then
    raise exception 'The import job is not actively processing'
      using errcode = '55000';
  end if;

  next_status := case
    when p_retryable and import_record.attempt_count < 5 then 'queued'
    else 'failed'
  end;
  update public.curriculum_import_jobs
  set status = next_status,
      last_error = btrim(p_error),
      processing_started_at = null,
      processing_lease_expires_at = null,
      next_attempt_at = case when next_status = 'queued'
        then now() + make_interval(secs => least(3600, power(2, attempt_count)::integer * 15))
        else next_attempt_at end,
      completed_at = case when next_status = 'failed' then now() else null end
  where id = p_job_id
  returning * into import_record;
  insert into public.curriculum_import_errors (
    job_id, page_number, stage, error_code, message, retryable, details
  ) values (
    p_job_id, p_page_number, 'extraction', p_error_code, btrim(p_error),
    p_retryable and import_record.attempt_count < 5,
    coalesce(p_details, '{}'::jsonb)
  );
  insert into public.curriculum_import_job_history (
    job_id, from_status, to_status, note
  ) values (p_job_id, 'processing', next_status, btrim(p_error));
  perform public.write_audit_log(
    null, null, 'curriculum.import_failed',
    jsonb_build_object('job_id', p_job_id, 'error_code', p_error_code)
  );
  return import_record;
end;
$$;

revoke all on function public.fail_curriculum_import(uuid, text)
  from public, anon, authenticated;
revoke all on function public.fail_curriculum_import(uuid, text, text, boolean, integer, jsonb)
  from public, anon, authenticated;
grant execute on function public.fail_curriculum_import(
  uuid, text, text, boolean, integer, jsonb
) to service_role;

create function public.request_curriculum_page_reprocess(
  p_job_id uuid,
  p_page_number integer
)
returns public.curriculum_import_jobs
language plpgsql
security definer
set search_path = ''
as $$
declare
  job_record public.curriculum_import_jobs;
  country text;
  previous_status text;
begin
  if auth.uid() is null or p_page_number < 1 then
    raise exception 'Authentication and a valid page number are required'
      using errcode = '22023';
  end if;
  select job.* into job_record
  from public.curriculum_import_jobs job
  where job.id = p_job_id
  for update;
  if not found or job_record.status not in ('extracted', 'validation_failed', 'in_review') then
    raise exception 'The import job is not available for page reprocessing'
      using errcode = '55000';
  end if;
  country := public.curriculum_version_country(job_record.version_id);
  if not public.has_curriculum_role(
    country, array['curriculum_editor', 'curriculum_admin']
  ) then
    raise exception 'Curriculum editor authorization is required'
      using errcode = '42501';
  end if;
  if p_page_number > coalesce(job_record.page_count, 0)
     or not exists (
       select 1 from public.curriculum_sources source
       where source.id = job_record.source_id
         and source.verification_status = 'verified'
         and source.usage_rights_status in ('authorized', 'public_domain')
     ) then
    raise exception 'The requested page or source authorization is unavailable'
      using errcode = '42501';
  end if;
  previous_status := job_record.status;
  update public.curriculum_import_jobs
  set status = 'queued',
      processing_page_number = p_page_number,
      attempt_count = 1,
      next_attempt_at = now(),
      validation_errors = '[]'::jsonb,
      completed_at = null
  where id = p_job_id
  returning * into job_record;
  insert into public.curriculum_import_job_history (
    job_id, from_status, to_status, actor_user_id, note
  ) values (
    p_job_id, previous_status, 'queued', auth.uid(),
    format('Requested reprocessing of page %s', p_page_number)
  );
  return job_record;
end;
$$;

revoke all on function public.request_curriculum_page_reprocess(uuid, integer)
  from public, anon;
grant execute on function public.request_curriculum_page_reprocess(uuid, integer)
  to authenticated;

create function public.retry_curriculum_import(
  p_job_id uuid,
  p_note text
)
returns public.curriculum_import_jobs
language plpgsql
security definer
set search_path = ''
as $$
declare
  job_record public.curriculum_import_jobs;
begin
  if auth.uid() is null or char_length(btrim(coalesce(p_note, ''))) not between 1 and 1000 then
    raise exception 'Authentication and a retry note are required'
      using errcode = '22023';
  end if;
  select job.* into job_record
  from public.curriculum_import_jobs job
  where job.id = p_job_id and job.status = 'failed'
  for update;
  if not found or not public.has_curriculum_role(
    public.curriculum_version_country(job_record.version_id),
    array['curriculum_admin', 'country_admin']
  ) then
    raise exception 'Curriculum administrator authorization is required'
      using errcode = '42501';
  end if;
  update public.curriculum_import_jobs
  set status = 'queued',
      attempt_count = 1,
      upload_complete = false,
      next_attempt_at = now(),
      processing_started_at = null,
      processing_lease_expires_at = null,
      last_error = null,
      completed_at = null
  where id = p_job_id
  returning * into job_record;
  insert into public.curriculum_import_job_history (
    job_id, from_status, to_status, actor_user_id, note
  ) values (p_job_id, 'failed', 'queued', auth.uid(), btrim(p_note));
  perform public.write_audit_log(
    auth.uid(), null, 'curriculum.import_retry_authorized',
    jsonb_build_object('job_id', p_job_id)
  );
  return job_record;
end;
$$;

revoke all on function public.retry_curriculum_import(uuid, text)
  from public, anon;
grant execute on function public.retry_curriculum_import(uuid, text)
  to authenticated;

create or replace function public.set_curriculum_item_fingerprint()
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

create function public.detect_curriculum_import_duplicates(p_job_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  job_record public.curriculum_import_jobs;
  country text;
  match_count integer;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  select job.* into job_record
  from public.curriculum_import_jobs job
  where job.id = p_job_id and job.status in ('extracted', 'validation_failed')
  for update;
  if not found then
    raise exception 'The import job is not ready for duplicate detection'
      using errcode = '55000';
  end if;
  country := public.curriculum_version_country(job_record.version_id);
  if not public.has_curriculum_role(
    country, array['curriculum_editor', 'curriculum_admin']
  ) then
    raise exception 'Curriculum editor authorization is required'
      using errcode = '42501';
  end if;

  insert into public.curriculum_duplicate_matches (
    import_item_id, candidate_item_id, job_id, candidate_job_id, version_id,
    match_type, similarity
  )
  select item.id, candidate.id, item.job_id, candidate.job_id, item.version_id,
    case when item.normalized_fingerprint = candidate.normalized_fingerprint
      then 'exact_duplicate' else 'possible_duplicate' end,
    case when item.normalized_fingerprint = candidate.normalized_fingerprint
      then 1
      else extensions.similarity(
        lower(regexp_replace(btrim(item.normalized_text), '\s+', ' ', 'g')),
        lower(regexp_replace(btrim(candidate.normalized_text), '\s+', ' ', 'g'))
      ) end
  from public.curriculum_import_items item
  join public.curriculum_import_items candidate
    on candidate.version_id = item.version_id
    and candidate.id <> item.id
    and candidate.item_type = item.item_type
  where item.job_id = p_job_id
    and (
      item.normalized_fingerprint = candidate.normalized_fingerprint
      or extensions.similarity(
        lower(regexp_replace(btrim(item.normalized_text), '\s+', ' ', 'g')),
        lower(regexp_replace(btrim(candidate.normalized_text), '\s+', ' ', 'g'))
      ) >= 0.72
    )
    and not exists (
      select 1 from public.curriculum_duplicate_matches existing
      where existing.import_item_id = item.id
        and existing.candidate_item_id = candidate.id
    )
  on conflict (import_item_id, candidate_item_id) do nothing;
  get diagnostics match_count = row_count;
  return match_count;
end;
$$;

revoke all on function public.detect_curriculum_import_duplicates(uuid)
  from public, anon;
grant execute on function public.detect_curriculum_import_duplicates(uuid)
  to authenticated;

create function public.review_curriculum_duplicate_match(
  p_match_id uuid,
  p_decision text,
  p_note text default null
)
returns public.curriculum_duplicate_matches
language plpgsql
security definer
set search_path = ''
as $$
declare
  match_record public.curriculum_duplicate_matches;
begin
  if auth.uid() is null or p_decision not in (
    'confirmed_duplicate', 'not_duplicate', 'deferred'
  ) or char_length(coalesce(p_note, '')) > 2000 then
    raise exception 'A valid duplicate review decision is required'
      using errcode = '22023';
  end if;
  select match.* into match_record
  from public.curriculum_duplicate_matches match
  where match.id = p_match_id and match.decision = 'pending'
  for update;
  if not found or not public.has_curriculum_role(
    public.curriculum_version_country(match_record.version_id),
    array['curriculum_reviewer', 'curriculum_admin']
  ) then
    raise exception 'Curriculum reviewer authorization is required'
      using errcode = '42501';
  end if;
  update public.curriculum_duplicate_matches
  set decision = p_decision, reviewer_user_id = auth.uid(),
      reviewed_at = now(), review_note = nullif(btrim(p_note), '')
  where id = p_match_id
  returning * into match_record;
  perform public.write_audit_log(
    auth.uid(), null, 'curriculum.duplicate_match_reviewed',
    jsonb_build_object('match_id', p_match_id, 'decision', p_decision)
  );
  return match_record;
end;
$$;

revoke all on function public.review_curriculum_duplicate_match(uuid, text, text)
  from public, anon;
grant execute on function public.review_curriculum_duplicate_match(uuid, text, text)
  to authenticated;

alter table public.curriculum_import_documents enable row level security;
alter table public.curriculum_import_errors enable row level security;
alter table public.curriculum_validation_results enable row level security;
alter table public.curriculum_duplicate_matches enable row level security;

revoke all on public.curriculum_import_documents,
  public.curriculum_import_errors, public.curriculum_validation_results,
  public.curriculum_duplicate_matches
  from public, anon, authenticated;
grant select on public.curriculum_import_documents,
  public.curriculum_import_errors, public.curriculum_validation_results,
  public.curriculum_duplicate_matches to authenticated;

create policy "Curriculum staff read import documents"
  on public.curriculum_import_documents for select to authenticated
  using (exists (
    select 1 from public.curriculum_import_jobs job
    where job.id = curriculum_import_documents.job_id
      and public.has_curriculum_role(
        public.curriculum_version_country(job.version_id),
        array[
          'curriculum_editor', 'curriculum_reviewer',
          'curriculum_approver', 'curriculum_admin', 'country_admin'
        ]
      )
  ));
create policy "Curriculum staff read import errors"
  on public.curriculum_import_errors for select to authenticated
  using (exists (
    select 1 from public.curriculum_import_jobs job
    where job.id = curriculum_import_errors.job_id
      and public.has_curriculum_role(
        public.curriculum_version_country(job.version_id),
        array[
          'curriculum_editor', 'curriculum_reviewer',
          'curriculum_approver', 'curriculum_admin', 'country_admin'
        ]
      )
  ));
create policy "Curriculum staff read validation results"
  on public.curriculum_validation_results for select to authenticated
  using (exists (
    select 1 from public.curriculum_import_jobs job
    where job.id = curriculum_validation_results.job_id
      and public.has_curriculum_role(
        public.curriculum_version_country(job.version_id),
        array[
          'curriculum_editor', 'curriculum_reviewer',
          'curriculum_approver', 'curriculum_admin', 'country_admin'
        ]
      )
  ));
create policy "Curriculum staff read duplicate matches"
  on public.curriculum_duplicate_matches for select to authenticated
  using (public.has_curriculum_role(
    public.curriculum_version_country(version_id),
    array[
      'curriculum_editor', 'curriculum_reviewer',
      'curriculum_approver', 'curriculum_admin', 'country_admin'
    ]
  ));

update storage.buckets
set allowed_mime_types = array[
  'application/pdf',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'text/csv',
  'application/json'
]
where id = 'curriculum-source-documents';

drop policy "Authorized editors upload private source documents" on storage.objects;
drop policy "Authorized editors replace unprocessed source documents" on storage.objects;

create policy "Authorized editors upload private source documents"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'curriculum-source-documents'
    and name ~ '^TZ/[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|docx|xlsx|csv|json)$'
    and exists (
      select 1
      from public.curriculum_import_jobs job
      join public.curriculum_sources source on source.id = job.source_id
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

create policy "Authorized editors replace unprocessed source documents"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'curriculum-source-documents'
    and exists (
      select 1 from public.curriculum_import_jobs job
      join public.curriculum_sources source on source.id = job.source_id
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
      select 1 from public.curriculum_import_jobs job
      join public.curriculum_sources source on source.id = job.source_id
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

commit;
