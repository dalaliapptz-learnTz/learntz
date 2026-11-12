begin;

alter table public.user_roles
  drop constraint user_roles_role_check,
  add constraint user_roles_role_check check (role in (
    'super_admin', 'country_admin', 'content_admin',
    'finance_admin', 'support_admin', 'parent', 'learner',
    'curriculum_editor', 'curriculum_reviewer',
    'curriculum_approver', 'curriculum_admin'
  ));

alter table public.user_roles
  drop constraint user_roles_country_scope_check,
  add constraint user_roles_country_scope_check check (
    (role in (
      'country_admin', 'curriculum_editor', 'curriculum_reviewer',
      'curriculum_approver', 'curriculum_admin'
    ) and country_code is not null)
    or (role not in (
      'country_admin', 'curriculum_editor', 'curriculum_reviewer',
      'curriculum_approver', 'curriculum_admin'
    ))
  );

create table public.curriculum_authorities (
  id uuid primary key default gen_random_uuid(),
  country_code text not null,
  education_system_id uuid not null,
  name text not null check (char_length(btrim(name)) between 1 and 200),
  code text not null check (char_length(btrim(code)) between 1 and 60),
  website_url text check (
    website_url is null or website_url ~ '^https://[^[:space:]]+$'
  ),
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint curriculum_authorities_system_country_fk
    foreign key (education_system_id, country_code)
    references public.education_systems (id, country_code) on delete restrict,
  constraint curriculum_authorities_code_unique
    unique (education_system_id, code),
  constraint curriculum_authorities_scope_unique
    unique (id, country_code, education_system_id),
  constraint curriculum_authorities_id_system_unique
    unique (id, education_system_id)
);

alter table public.curricula
  add column authority_id uuid,
  add column description text
    check (description is null or char_length(description) <= 2000);

insert into public.curriculum_authorities (
  country_code, education_system_id, name, code, website_url
)
select
  system.country_code,
  system.id,
  'Tanzania Institute of Education',
  'TIE',
  'https://www.tie.go.tz'
from public.education_systems system
where system.country_code = 'TZ' and system.code = 'TZ_NATIONAL'
on conflict (education_system_id, code) do nothing;

update public.curricula curriculum
set authority_id = authority.id
from public.curriculum_authorities authority
where curriculum.country_code = 'TZ'
  and curriculum.code = 'TIE'
  and authority.country_code = curriculum.country_code
  and authority.education_system_id = curriculum.education_system_id
  and authority.code = 'TIE';

alter table public.curricula
  alter column authority_id set not null,
  add constraint curricula_authority_scope_fk
    foreign key (authority_id, country_code, education_system_id)
    references public.curriculum_authorities (
      id, country_code, education_system_id
    ) on delete restrict,
  add constraint curricula_id_authority_unique
    unique (id, authority_id);

create index curricula_authority_idx
  on public.curricula (authority_id, country_code);

create table public.curriculum_versions (
  id uuid primary key default gen_random_uuid(),
  curriculum_id uuid not null references public.curricula (id)
    on delete restrict,
  version_code text not null
    check (char_length(btrim(version_code)) between 1 and 80),
  display_name text not null
    check (char_length(btrim(display_name)) between 1 and 200),
  official_document_version text
    check (
      official_document_version is null
      or char_length(official_document_version) <= 120
    ),
  status text not null default 'draft'
    check (status in (
      'draft', 'under_review', 'approved', 'published', 'superseded', 'archived'
    )),
  effective_from date,
  effective_to date,
  approved_by uuid references auth.users (id) on delete restrict,
  approved_at timestamptz,
  published_by uuid references auth.users (id) on delete restrict,
  published_at timestamptz,
  created_by uuid not null references auth.users (id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint curriculum_versions_dates_check
    check (
      effective_from is null or effective_to is null
      or effective_to >= effective_from
    ),
  constraint curriculum_versions_approval_check
    check (
      (approved_by is null and approved_at is null)
      or (approved_by is not null and approved_at is not null)
    ),
  constraint curriculum_versions_publication_check
    check (
      status not in ('published', 'superseded', 'archived')
      or (published_by is not null and published_at is not null)
    ),
  constraint curriculum_versions_code_unique
    unique (curriculum_id, version_code),
  constraint curriculum_versions_scope_unique
    unique (id, curriculum_id)
);

create index curriculum_versions_curriculum_status_idx
  on public.curriculum_versions (curriculum_id, status, effective_from desc);

create table public.curriculum_version_grades (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null,
  curriculum_id uuid not null,
  education_level_id uuid not null,
  grade_id uuid not null,
  display_order integer not null check (display_order > 0),
  created_at timestamptz not null default now(),
  constraint curriculum_version_grades_version_fk
    foreign key (version_id, curriculum_id)
    references public.curriculum_versions (id, curriculum_id)
    on delete restrict,
  constraint curriculum_version_grades_grade_fk
    foreign key (grade_id, education_level_id, curriculum_id)
    references public.education_grades (
      id, education_level_id, curriculum_id
    ) on delete restrict,
  constraint curriculum_version_grades_grade_unique
    unique (version_id, grade_id),
  constraint curriculum_version_grades_order_unique
    unique (version_id, display_order)
);

create index curriculum_version_grades_level_order_idx
  on public.curriculum_version_grades (
    version_id, education_level_id, display_order
  );

create table public.curriculum_version_languages (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null,
  curriculum_id uuid not null,
  language_code text not null check (
    language_code ~ '^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$'
  ),
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  constraint curriculum_version_languages_version_fk
    foreign key (version_id, curriculum_id)
    references public.curriculum_versions (id, curriculum_id)
    on delete restrict,
  constraint curriculum_version_languages_unique
    unique (version_id, language_code)
);

create unique index curriculum_version_one_primary_language_idx
  on public.curriculum_version_languages (version_id)
  where is_primary;

create table public.curriculum_sources (
  id uuid primary key default gen_random_uuid(),
  authority_id uuid not null
    references public.curriculum_authorities (id) on delete restrict,
  document_title text not null
    check (char_length(btrim(document_title)) between 1 and 300),
  issuing_institution text not null
    check (char_length(btrim(issuing_institution)) between 1 and 200),
  document_reference text
    check (
      document_reference is null or char_length(document_reference) <= 160
    ),
  publication_date date,
  effective_date date,
  document_version text
    check (document_version is null or char_length(document_version) <= 120),
  source_url text check (
    source_url is null or source_url ~ '^https://[^[:space:]]+$'
  ),
  storage_bucket text,
  storage_object_path text,
  sha256_checksum text check (
    sha256_checksum is null or sha256_checksum ~ '^[0-9a-f]{64}$'
  ),
  usage_permissions text not null
    check (char_length(btrim(usage_permissions)) between 1 and 2000),
  verification_status text not null default 'unverified'
    check (verification_status in ('unverified', 'verified', 'rejected')),
  verified_by uuid references auth.users (id) on delete set null,
  verified_at timestamptz,
  created_by uuid not null references auth.users (id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint curriculum_sources_storage_location_check
    check (
      (storage_bucket is null and storage_object_path is null)
      or (
        storage_bucket is not null
        and storage_object_path is not null
        and char_length(btrim(storage_bucket)) between 1 and 100
        and char_length(btrim(storage_object_path)) between 1 and 1000
      )
    ),
  constraint curriculum_sources_verification_actor_check
    check (
      (verification_status = 'unverified'
        and verified_by is null and verified_at is null)
      or (verification_status in ('verified', 'rejected')
        and verified_by is not null and verified_at is not null)
    ),
  constraint curriculum_sources_verified_evidence_check
    check (
      verification_status <> 'verified'
      or (
        sha256_checksum is not null
        and (source_url is not null or storage_bucket is not null)
      )
    ),
  constraint curriculum_sources_id_authority_unique
    unique (id, authority_id)
);

create index curriculum_sources_authority_status_idx
  on public.curriculum_sources (authority_id, verification_status);

create table public.curriculum_version_sources (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null,
  curriculum_id uuid not null,
  authority_id uuid not null,
  source_id uuid not null,
  page_number integer check (page_number is null or page_number > 0),
  section_reference text check (
    section_reference is null or char_length(section_reference) <= 300
  ),
  extracted_source_text text check (
    extracted_source_text is null
    or char_length(extracted_source_text) <= 20000
  ),
  created_by uuid not null references auth.users (id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint curriculum_version_sources_version_fk
    foreign key (version_id, curriculum_id)
    references public.curriculum_versions (id, curriculum_id)
    on delete restrict,
  constraint curriculum_version_sources_authority_fk
    foreign key (curriculum_id, authority_id)
    references public.curricula (id, authority_id)
    on delete restrict,
  constraint curriculum_version_sources_source_fk
    foreign key (source_id, authority_id)
    references public.curriculum_sources (id, authority_id)
    on delete restrict
);

create unique index curriculum_version_sources_location_unique_idx
  on public.curriculum_version_sources (
    version_id,
    source_id,
    coalesce(page_number, 0),
    coalesce(section_reference, '')
  );
create index curriculum_version_sources_source_idx
  on public.curriculum_version_sources (source_id, version_id);

create table public.curriculum_source_review_history (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null
    references public.curriculum_sources (id) on delete restrict,
  verification_status text not null
    check (verification_status in ('verified', 'rejected')),
  reviewer_user_id uuid references auth.users (id) on delete set null,
  note text check (note is null or char_length(note) <= 2000),
  created_at timestamptz not null default now()
);

create index curriculum_source_review_history_idx
  on public.curriculum_source_review_history (source_id, created_at desc);

create table public.curriculum_version_review_history (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null
    references public.curriculum_versions (id) on delete restrict,
  from_status text check (from_status is null or from_status in (
    'draft', 'under_review', 'approved', 'published', 'superseded', 'archived'
  )),
  to_status text not null check (to_status in (
    'draft', 'under_review', 'approved', 'published', 'superseded', 'archived'
  )),
  actor_user_id uuid references auth.users (id) on delete set null,
  note text check (note is null or char_length(note) <= 2000),
  created_at timestamptz not null default now()
);

create index curriculum_version_review_history_idx
  on public.curriculum_version_review_history (version_id, created_at desc);

create trigger curriculum_authorities_set_updated_at
  before update on public.curriculum_authorities
  for each row execute function public.set_updated_at();
create trigger curriculum_versions_set_updated_at
  before update on public.curriculum_versions
  for each row execute function public.set_updated_at();
create trigger curriculum_sources_set_updated_at
  before update on public.curriculum_sources
  for each row execute function public.set_updated_at();

create function public.has_curriculum_role(
  p_country_code text,
  p_roles text[]
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_roles assignment
    where assignment.user_id = (select auth.uid())
      and (
        assignment.role = 'super_admin'
        or (
          assignment.country_code = p_country_code
          and assignment.role = any(p_roles)
        )
      )
  );
$$;

revoke all on function public.has_curriculum_role(text, text[])
  from public, anon;
grant execute on function public.has_curriculum_role(text, text[])
  to authenticated;

create function public.curriculum_version_country(p_version_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select curriculum.country_code
  from public.curriculum_versions version
  join public.curricula curriculum on curriculum.id = version.curriculum_id
  where version.id = p_version_id;
$$;

revoke all on function public.curriculum_version_country(uuid)
  from public, anon;
grant execute on function public.curriculum_version_country(uuid)
  to authenticated;

create function public.create_curriculum_version(
  p_curriculum_id uuid,
  p_version_code text,
  p_display_name text,
  p_official_document_version text default null,
  p_effective_from date default null,
  p_effective_to date default null
)
returns public.curriculum_versions
language plpgsql
security definer
set search_path = ''
as $$
declare
  curriculum_country text;
  created_version public.curriculum_versions;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  select country_code into curriculum_country
  from public.curricula
  where id = p_curriculum_id and is_enabled;
  if not found then
    raise exception 'The curriculum is unavailable'
      using errcode = '22023';
  end if;
  if not public.has_curriculum_role(
    curriculum_country,
    array['curriculum_editor', 'curriculum_admin']
  ) then
    raise exception 'Curriculum editor authorization is required'
      using errcode = '42501';
  end if;
  if p_version_code is null
     or char_length(btrim(p_version_code)) not between 1 and 80
     or p_display_name is null
     or char_length(btrim(p_display_name)) not between 1 and 200 then
    raise exception 'A valid curriculum version code and name are required'
      using errcode = '22023';
  end if;
  if p_effective_from is not null and p_effective_to is not null
     and p_effective_to < p_effective_from then
    raise exception 'The effective date range is invalid'
      using errcode = '22023';
  end if;

  insert into public.curriculum_versions (
    curriculum_id, version_code, display_name, official_document_version,
    effective_from, effective_to, created_by
  )
  values (
    p_curriculum_id, btrim(p_version_code), btrim(p_display_name),
    nullif(btrim(coalesce(p_official_document_version, '')), ''),
    p_effective_from, p_effective_to, auth.uid()
  )
  returning * into created_version;

  insert into public.curriculum_version_review_history (
    version_id, from_status, to_status, actor_user_id, note
  )
  values (
    created_version.id, null, 'draft', auth.uid(), 'Version created'
  );
  return created_version;
end;
$$;

revoke all on function public.create_curriculum_version(
  uuid, text, text, text, date, date
) from public, anon;
grant execute on function public.create_curriculum_version(
  uuid, text, text, text, date, date
) to authenticated;

create function public.verify_curriculum_source(
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
  where id = p_source_id and verification_status = 'unverified'
  returning * into source_record;
  if not found then
    raise exception 'Only unverified sources can be reviewed'
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

revoke all on function public.verify_curriculum_source(uuid, boolean, text)
  from public, anon;
grant execute on function public.verify_curriculum_source(uuid, boolean, text)
  to authenticated;

create function public.transition_curriculum_version(
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

  select version.*
  into current_version
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

  if p_target_status in ('approved', 'published') and not exists (
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
    p_version_id, current_version.status, p_target_status,
    auth.uid(), nullif(btrim(coalesce(p_note, '')), '')
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

alter table public.curriculum_authorities enable row level security;
alter table public.curriculum_versions enable row level security;
alter table public.curriculum_version_grades enable row level security;
alter table public.curriculum_version_languages enable row level security;
alter table public.curriculum_sources enable row level security;
alter table public.curriculum_version_sources enable row level security;
alter table public.curriculum_source_review_history enable row level security;
alter table public.curriculum_version_review_history enable row level security;

revoke all on public.curriculum_authorities, public.curriculum_versions,
  public.curriculum_version_grades, public.curriculum_version_languages,
  public.curriculum_sources, public.curriculum_version_sources,
  public.curriculum_source_review_history,
  public.curriculum_version_review_history from public, anon, authenticated;

grant select on public.curriculum_authorities, public.curriculum_versions,
  public.curriculum_version_grades, public.curriculum_version_languages,
  public.curriculum_sources, public.curriculum_version_sources,
  public.curriculum_source_review_history,
  public.curriculum_version_review_history to authenticated;
grant insert, update, delete on public.curriculum_authorities
  to authenticated;
grant insert, update, delete on public.curriculum_version_grades,
  public.curriculum_version_languages, public.curriculum_sources,
  public.curriculum_version_sources to authenticated;

create policy "Users can read enabled curriculum authorities"
  on public.curriculum_authorities for select to authenticated
  using (
    is_enabled and exists (
      select 1 from public.countries country
      where country.country_code = curriculum_authorities.country_code
        and country.is_enabled
    )
    or public.has_curriculum_role(
      country_code,
      array[
        'curriculum_editor', 'curriculum_reviewer',
        'curriculum_approver', 'curriculum_admin', 'country_admin'
      ]
    )
  );
create policy "Authorized administrators manage curriculum authorities"
  on public.curriculum_authorities for all to authenticated
  using (public.has_curriculum_role(
    country_code, array['curriculum_admin', 'country_admin']
  ))
  with check (public.has_curriculum_role(
    country_code, array['curriculum_admin', 'country_admin']
  ));

create policy "Published versions and curriculum staff can read versions"
  on public.curriculum_versions for select to authenticated
  using (exists (
    select 1 from public.curricula curriculum
    where curriculum.id = curriculum_versions.curriculum_id
      and (
        curriculum_versions.status = 'published'
        or public.has_curriculum_role(
          curriculum.country_code,
          array[
            'curriculum_editor', 'curriculum_reviewer',
            'curriculum_approver', 'curriculum_admin', 'country_admin'
          ]
        )
      )
  ));

create policy "Published version grades and authorized staff can read"
  on public.curriculum_version_grades for select to authenticated
  using (exists (
    select 1
    from public.curriculum_versions version
    join public.curricula curriculum on curriculum.id = version.curriculum_id
    where version.id = curriculum_version_grades.version_id
      and (
        version.status = 'published'
        or public.has_curriculum_role(
          curriculum.country_code,
          array[
            'curriculum_editor', 'curriculum_reviewer',
            'curriculum_approver', 'curriculum_admin', 'country_admin'
          ]
        )
      )
  ));
create policy "Editors manage draft curriculum version grades"
  on public.curriculum_version_grades for all to authenticated
  using (
    exists (
      select 1
      from public.curriculum_versions version
      join public.curricula curriculum on curriculum.id = version.curriculum_id
      where version.id = curriculum_version_grades.version_id
        and version.status = 'draft'
        and public.has_curriculum_role(
          curriculum.country_code,
          array['curriculum_editor', 'curriculum_admin', 'country_admin']
        )
    )
  )
  with check (
    exists (
      select 1
      from public.curriculum_versions version
      join public.curricula curriculum on curriculum.id = version.curriculum_id
      where version.id = curriculum_version_grades.version_id
        and version.status = 'draft'
        and public.has_curriculum_role(
          curriculum.country_code,
          array['curriculum_editor', 'curriculum_admin', 'country_admin']
        )
    )
  );

create policy "Published version languages and authorized staff can read"
  on public.curriculum_version_languages for select to authenticated
  using (exists (
    select 1
    from public.curriculum_versions version
    join public.curricula curriculum on curriculum.id = version.curriculum_id
    where version.id = curriculum_version_languages.version_id
      and (
        version.status = 'published'
        or public.has_curriculum_role(
          curriculum.country_code,
          array[
            'curriculum_editor', 'curriculum_reviewer',
            'curriculum_approver', 'curriculum_admin', 'country_admin'
          ]
        )
      )
  ));
create policy "Editors manage draft curriculum version languages"
  on public.curriculum_version_languages for all to authenticated
  using (
    exists (
      select 1
      from public.curriculum_versions version
      join public.curricula curriculum on curriculum.id = version.curriculum_id
      where version.id = curriculum_version_languages.version_id
        and version.status = 'draft'
        and public.has_curriculum_role(
          curriculum.country_code,
          array['curriculum_editor', 'curriculum_admin', 'country_admin']
        )
    )
  )
  with check (
    exists (
      select 1
      from public.curriculum_versions version
      join public.curricula curriculum on curriculum.id = version.curriculum_id
      where version.id = curriculum_version_languages.version_id
        and version.status = 'draft'
        and public.has_curriculum_role(
          curriculum.country_code,
          array['curriculum_editor', 'curriculum_admin', 'country_admin']
        )
    )
  );

create policy "Curriculum staff can read source provenance"
  on public.curriculum_sources for select to authenticated
  using (exists (
    select 1 from public.curriculum_authorities authority
    where authority.id = curriculum_sources.authority_id
      and public.has_curriculum_role(
        authority.country_code,
        array[
          'curriculum_editor', 'curriculum_reviewer',
          'curriculum_approver', 'curriculum_admin', 'country_admin'
        ]
      )
  ));
create policy "Editors create unverified curriculum sources"
  on public.curriculum_sources for insert to authenticated
  with check (
    verification_status = 'unverified'
    and created_by = (select auth.uid())
    and exists (
      select 1 from public.curriculum_authorities authority
      where authority.id = curriculum_sources.authority_id
        and public.has_curriculum_role(
          authority.country_code,
          array['curriculum_editor', 'curriculum_admin', 'country_admin']
        )
    )
  );
create policy "Editors update unverified curriculum sources"
  on public.curriculum_sources for update to authenticated
  using (
    verification_status = 'unverified'
    and exists (
      select 1 from public.curriculum_authorities authority
      where authority.id = curriculum_sources.authority_id
        and public.has_curriculum_role(
          authority.country_code,
          array['curriculum_editor', 'curriculum_admin', 'country_admin']
        )
    )
  )
  with check (
    verification_status = 'unverified'
    and created_by = (select auth.uid())
    and exists (
      select 1 from public.curriculum_authorities authority
      where authority.id = curriculum_sources.authority_id
        and public.has_curriculum_role(
          authority.country_code,
          array['curriculum_editor', 'curriculum_admin', 'country_admin']
        )
    )
  );
create policy "Editors delete unverified curriculum sources"
  on public.curriculum_sources for delete to authenticated
  using (
    verification_status = 'unverified'
    and exists (
      select 1 from public.curriculum_authorities authority
      where authority.id = curriculum_sources.authority_id
        and public.has_curriculum_role(
          authority.country_code,
          array['curriculum_editor', 'curriculum_admin', 'country_admin']
        )
    )
  );

create policy "Curriculum staff can read version source references"
  on public.curriculum_version_sources for select to authenticated
  using (exists (
    select 1
    from public.curriculum_versions version
    join public.curricula curriculum on curriculum.id = version.curriculum_id
    where version.id = curriculum_version_sources.version_id
      and public.has_curriculum_role(
        curriculum.country_code,
        array[
          'curriculum_editor', 'curriculum_reviewer',
          'curriculum_approver', 'curriculum_admin', 'country_admin'
        ]
      )
  ));
create policy "Editors manage draft version source references"
  on public.curriculum_version_sources for all to authenticated
  using (exists (
    select 1
    from public.curriculum_versions version
    join public.curricula curriculum on curriculum.id = version.curriculum_id
    where version.id = curriculum_version_sources.version_id
      and version.status = 'draft'
      and public.has_curriculum_role(
        curriculum.country_code,
        array['curriculum_editor', 'curriculum_admin', 'country_admin']
      )
  ))
  with check (
    created_by = (select auth.uid())
    and exists (
      select 1
      from public.curriculum_versions version
      join public.curricula curriculum on curriculum.id = version.curriculum_id
      where version.id = curriculum_version_sources.version_id
        and version.status = 'draft'
        and public.has_curriculum_role(
          curriculum.country_code,
          array['curriculum_editor', 'curriculum_admin', 'country_admin']
        )
    )
  );

create policy "Curriculum staff can read version review history"
  on public.curriculum_version_review_history for select to authenticated
  using (exists (
    select 1
    from public.curriculum_versions version
    join public.curricula curriculum on curriculum.id = version.curriculum_id
    where version.id = curriculum_version_review_history.version_id
      and public.has_curriculum_role(
        curriculum.country_code,
        array[
          'curriculum_editor', 'curriculum_reviewer',
          'curriculum_approver', 'curriculum_admin', 'country_admin'
        ]
      )
  ));

create policy "Curriculum staff can read source review history"
  on public.curriculum_source_review_history for select to authenticated
  using (exists (
    select 1
    from public.curriculum_sources source
    join public.curriculum_authorities authority
      on authority.id = source.authority_id
    where source.id = curriculum_source_review_history.source_id
      and public.has_curriculum_role(
        authority.country_code,
        array[
          'curriculum_editor', 'curriculum_reviewer',
          'curriculum_approver', 'curriculum_admin', 'country_admin'
        ]
      )
  ));

create function public.protect_curriculum_version()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if row(
    new.curriculum_id,
    new.version_code,
    new.display_name,
    new.official_document_version,
    new.effective_from,
    new.effective_to,
    new.created_by
  ) is distinct from row(
    old.curriculum_id,
    old.version_code,
    old.display_name,
    old.official_document_version,
    old.effective_from,
    old.effective_to,
    old.created_by
  ) and old.status <> 'draft' then
    raise exception 'Curriculum versions cannot be edited after leaving draft'
      using errcode = '55000';
  end if;
  if old.status in ('published', 'superseded', 'archived')
     and new.status not in ('superseded', 'archived') then
    raise exception 'Published curriculum versions are immutable'
      using errcode = '55000';
  end if;
  return new;
end;
$$;

revoke all on function public.protect_curriculum_version()
  from public, anon, authenticated;
create trigger curriculum_versions_protect
  before update on public.curriculum_versions
  for each row execute function public.protect_curriculum_version();

create function public.protect_curriculum_authority_assignment()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.authority_id is distinct from old.authority_id
     and exists (
       select 1 from public.curriculum_versions version
       where version.curriculum_id = old.id
     ) then
    raise exception 'A curriculum authority cannot change after versioning begins'
      using errcode = '55000';
  end if;
  return new;
end;
$$;

revoke all on function public.protect_curriculum_authority_assignment()
  from public, anon, authenticated;
create trigger curricula_protect_authority_assignment
  before update on public.curricula
  for each row execute function public.protect_curriculum_authority_assignment();

insert into public.audit_logs (
  actor_user_id, target_user_id, action, details
)
select
  null, null, 'curriculum.foundation_configured',
  jsonb_build_object(
    'authority_code', 'TIE',
    'curriculum_code', 'TIE',
    'source_verified', false
  )
where exists (
  select 1 from public.curriculum_authorities authority
  where authority.code = 'TIE'
);

commit;
