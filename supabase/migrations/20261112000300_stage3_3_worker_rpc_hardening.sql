begin;

drop function public.complete_curriculum_import(uuid, jsonb);
drop function public.fail_curriculum_import(uuid, text);

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
  page_number_value integer;
  page_text text;
  page_total integer;
  total_characters bigint := 0;
  total_metadata_bytes bigint := 0;
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
    page_number_value := (page_record ->> 'page_number')::integer;
    page_text := coalesce(page_record ->> 'extracted_text', '');
    if page_number_value < 1 or page_number_value > 500
       or char_length(page_text) > 100000
       or jsonb_typeof(page_record -> 'page_metadata') not in ('object', 'null')
       or jsonb_typeof(page_record -> 'extraction_warnings') not in ('array', 'null') then
      raise exception 'An extracted page is invalid or too large'
        using errcode = '22023';
    end if;
    total_characters := total_characters + char_length(page_text);
    total_metadata_bytes := total_metadata_bytes
      + octet_length(coalesce(page_record -> 'page_metadata', '{}'::jsonb)::text)
      + octet_length(coalesce(page_record -> 'extraction_warnings', '[]'::jsonb)::text);
  end loop;
  page_total := jsonb_array_length(p_pages);
  total_metadata_bytes := total_metadata_bytes + octet_length(p_metadata::text);
  if total_characters > 3000000
     or total_metadata_bytes > 3000000
     or exists (
       select 1 from jsonb_array_elements(p_pages) value
       group by (value ->> 'page_number') having count(*) > 1
     ) then
    raise exception 'The extracted document has duplicate pages or exceeds storage limits'
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
  on conflict on constraint curriculum_import_pages_idempotency_unique do update
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
      page_count = coalesce(
        page_count, nullif(p_metadata ->> 'page_count', '')::integer, page_total
      ),
      extraction_engine = coalesce(
        p_metadata ->> 'engine', 'learntz-curriculum-worker'
      ),
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

revoke all on function public.complete_curriculum_import(uuid, jsonb, jsonb)
  from public, anon, authenticated;
grant execute on function public.complete_curriculum_import(uuid, jsonb, jsonb)
  to service_role;

commit;
