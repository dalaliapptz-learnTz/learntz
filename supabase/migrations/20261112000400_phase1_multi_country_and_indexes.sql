begin;

-- 1. Generalize storage object path constraint for any 2-letter uppercase ISO country code
alter table public.curriculum_import_jobs
  drop constraint curriculum_import_jobs_storage_object_path_check,
  add constraint curriculum_import_jobs_storage_object_path_check check (
    storage_object_path ~
      '^[A-Z]{2}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|docx|xlsx|csv|json)$'
  );

-- 2. Update register_curriculum_import_document to format storage_object_path with curriculum country
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
    format('%s/%s/%s.%s', country, p_source_id, gen_random_uuid(), extension), auth.uid()
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
grant execute on function public.register_curriculum_import_document(
  uuid, uuid, text, text, text, bigint
) to authenticated;

-- 3. Generalize storage.objects upload and replace policies
drop policy if exists "Authorized editors upload private source documents" on storage.objects;
drop policy if exists "Authorized editors replace unprocessed source documents" on storage.objects;

create policy "Authorized editors upload private source documents"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'curriculum-source-documents'
    and name ~ '^[A-Z]{2}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|docx|xlsx|csv|json)$'
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
          split_part(storage.objects.name, '/', 1),
          array['curriculum_editor', 'curriculum_admin', 'country_admin']
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
          split_part(storage.objects.name, '/', 1),
          array['curriculum_editor', 'curriculum_admin', 'country_admin']
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
          split_part(storage.objects.name, '/', 1),
          array['curriculum_editor', 'curriculum_admin', 'country_admin']
        )
    )
  );

-- 4. Performance Indexes for Foreign Keys
create index if not exists parent_accounts_country_idx
  on public.parent_accounts (country_code);

create index if not exists learners_education_system_idx
  on public.learners (education_system_id);

create index if not exists learners_curriculum_idx
  on public.learners (curriculum_id);

create index if not exists learners_education_level_idx
  on public.learners (education_level_id);

create index if not exists learners_school_idx
  on public.learners (school_id);

commit;
