begin;

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
  source_authority_id uuid;
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
  into country, source_authority_id
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
    and source.authority_id = source_authority_id
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
    p_version_id, version_record.curriculum_id, p_source_id,
    source_authority_id, p_file_sha256, p_document_format,
    p_original_filename, p_file_size_bytes,
    format('TZ/%s/%s.%s', p_source_id, gen_random_uuid(), extension), auth.uid()
  )
  on conflict (version_id, source_id, file_sha256) do nothing
  returning * into job_record;

  if found then
    inserted := true;
  else
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
    ) values (
      job_record.id, null, 'queued', auth.uid(), 'Import document registered'
    );
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

create or replace function public.claim_curriculum_import_job()
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
        processing_lease_expires_at = null,
        completed_at = now()
    where id = job_record.id;
    insert into public.curriculum_import_errors (
      job_id, stage, error_code, message
    ) values (
      job_record.id, 'file_validation', 'source_rights_revoked',
      'Source rights are no longer cleared for processing.'
    );
    insert into public.curriculum_import_job_history (
      job_id, from_status, to_status, note
    ) values (
      job_record.id, previous_status, 'failed',
      'Processing stopped because source rights were revoked'
    );
    return null;
  end if;

  select document.* into document_record
  from public.curriculum_import_documents document
  where document.job_id = job_record.id;
  if not found then
    update public.curriculum_import_jobs
    set status = 'failed',
        last_error = 'Registered document metadata is missing',
        processing_started_at = null,
        processing_lease_expires_at = null,
        completed_at = now()
    where id = job_record.id;
    insert into public.curriculum_import_errors (
      job_id, stage, error_code, message
    ) values (
      job_record.id, 'metadata', 'document_metadata_missing',
      'Registered document metadata is missing.'
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

create or replace function public.validate_curriculum_import_stage3_3(
  p_job_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  base_report jsonb;
  errors jsonb;
  warnings jsonb := '[]'::jsonb;
  final_status text;
  version_id uuid;
  error_count integer;
begin
  perform public.detect_curriculum_import_duplicates(p_job_id);
  base_report := public.validate_curriculum_import(p_job_id);
  errors := coalesce(base_report -> 'errors', '[]'::jsonb);
  final_status := base_report ->> 'status';

  select job.version_id into version_id
  from public.curriculum_import_jobs job
  where job.id = p_job_id;
  if version_id is null then
    raise exception 'The curriculum import is unavailable'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from public.curriculum_import_items item
    join public.curriculum_import_pages page
      on page.id = item.import_page_id
     and page.job_id = item.job_id
    where item.job_id = p_job_id
      and item.source_page_revision <> page.page_revision
  ) then
    errors := errors || jsonb_build_array(
      'An imported item refers to a superseded page extraction and must be checked against the current source page.'
    );
  end if;
  if exists (
    select 1 from public.curriculum_import_items item
    where item.job_id = p_job_id
      and item.item_type in ('subtopic', 'sub_strand', 'learning_outcome')
      and item.parent_item_id is null
  ) then
    errors := errors || jsonb_build_array(
      'A subordinate curriculum item is missing its parent relationship.'
    );
  end if;
  if exists (
    select 1 from public.curriculum_duplicate_matches match
    where match.job_id = p_job_id
      and match.decision in ('pending', 'deferred')
  ) then
    errors := errors || jsonb_build_array(
      'Possible duplicate matches require a reviewer decision.'
    );
  end if;
  if exists (
    select 1
    from public.curriculum_duplicate_matches match
    join public.curriculum_import_items item
      on item.id = match.import_item_id
    where match.job_id = p_job_id
      and match.decision = 'confirmed_duplicate'
      and item.review_status <> 'rejected'
  ) then
    errors := errors || jsonb_build_array(
      'A confirmed duplicate must be excluded from this import.'
    );
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'page_number', page.page_number,
    'warning', warning.value
  )), '[]'::jsonb)
  into warnings
  from public.curriculum_import_pages page
  cross join lateral jsonb_array_elements_text(page.extraction_warnings) warning(value)
  where page.job_id = p_job_id;
  warnings := warnings || coalesce((
    select jsonb_agg(jsonb_build_object(
      'page_number', page.page_number,
      'warning', 'low_ocr_confidence',
      'confidence', page.ocr_confidence
    ))
    from public.curriculum_import_pages page
    where page.job_id = p_job_id
      and page.ocr_confidence is not null
      and page.ocr_confidence < 0.6
  ), '[]'::jsonb);

  error_count := jsonb_array_length(errors);
  if error_count > 0 then
    final_status := 'validation_failed';
    update public.curriculum_import_jobs
    set status = final_status,
        validation_errors = errors,
        completed_at = now()
    where id = p_job_id
      and status in ('in_review', 'validation_failed');
    if found then
      insert into public.curriculum_import_job_history (
        job_id, from_status, to_status, actor_user_id, note
      ) values (
        p_job_id, 'in_review', 'validation_failed', auth.uid(),
        'Stage 3.3 validation checks failed'
      );
    end if;
  end if;

  insert into public.curriculum_validation_results (
    job_id, validator_version, passed, error_count, warning_count,
    report, created_by
  ) values (
    p_job_id, 'database-stage3.3.2',
    error_count = 0, error_count, jsonb_array_length(warnings),
    jsonb_build_object(
      'status', final_status,
      'errors', errors,
      'warnings', warnings,
      'checked_at', now()
    ),
    auth.uid()
  );

  return jsonb_build_object(
    'status', final_status,
    'errors', errors,
    'warnings', warnings
  );
end;
$$;

revoke all on function public.validate_curriculum_import_stage3_3(uuid)
  from public, anon;
grant execute on function public.validate_curriculum_import_stage3_3(uuid)
  to authenticated;

create function public.require_duplicate_review_before_job_complete()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status = 'reviewed' and old.status is distinct from new.status
     and exists (
       select 1 from public.curriculum_duplicate_matches match
       where match.job_id = new.id
         and match.decision in ('pending', 'deferred')
     ) then
    raise exception 'Duplicate candidates must be resolved before item review completes'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

revoke all on function public.require_duplicate_review_before_job_complete()
  from public, anon, authenticated;
create trigger curriculum_import_duplicate_review_gate
  before update of status on public.curriculum_import_jobs
  for each row execute function public.require_duplicate_review_before_job_complete();

commit;
