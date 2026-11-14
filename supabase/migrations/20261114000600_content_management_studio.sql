-- ============================================================================
-- LearnTZ Content Management Studio (CMS)
-- Curriculum Authoring, Interactive Lesson Editor, Versioning & Two-Party Review
-- ============================================================================

-- 1. Extend lessons table with editorial workflow columns
alter table public.lessons
  add column if not exists status text not null default 'draft'
    check (status in ('draft', 'in_review', 'approved', 'published', 'archived')),
  add column if not exists author_id uuid references auth.users (id) on delete set null,
  add column if not exists reviewer_id uuid references auth.users (id) on delete set null,
  add column if not exists review_notes text,
  add column if not exists version_number integer not null default 1 check (version_number > 0),
  add column if not exists published_at timestamptz;

-- Synchronize status with is_published for pre-existing lessons
update public.lessons
set status = 'published', published_at = coalesce(published_at, updated_at)
where is_published = true and status = 'draft';

create index if not exists lessons_status_idx
  on public.lessons (status, is_published);

-- 2. Table: lesson_revisions (Version History & Audit)
create table if not exists public.lesson_revisions (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons (id) on delete cascade,
  version_number integer not null check (version_number > 0),
  title text not null,
  summary text,
  body_markdown text not null,
  content_blocks jsonb not null default '[]'::jsonb,
  changed_by_user_id uuid references auth.users (id) on delete set null,
  change_summary text,
  created_at timestamptz not null default now(),
  constraint lesson_revisions_lesson_version_unique unique (lesson_id, version_number)
);

create index if not exists lesson_revisions_lesson_idx
  on public.lesson_revisions (lesson_id, version_number desc);

alter table public.lesson_revisions enable row level security;
revoke all on public.lesson_revisions from public, anon, authenticated;
grant select on public.lesson_revisions to authenticated;
grant insert on public.lesson_revisions to authenticated;

drop policy if exists "Staff can view lesson revisions" on public.lesson_revisions;
create policy "Staff can view lesson revisions"
  on public.lesson_revisions for select to authenticated
  using (
    public.has_role('super_admin')
    or exists (
      select 1 from public.lessons l
      join public.topics t on l.topic_id = t.id
      join public.subjects s on t.subject_id = s.id
      where l.id = lesson_id
        and (public.has_role('content_admin', s.country_code) or public.has_role('curriculum_admin', s.country_code))
    )
  );

drop policy if exists "Staff can record lesson revisions" on public.lesson_revisions;
create policy "Staff can record lesson revisions"
  on public.lesson_revisions for insert to authenticated
  with check (
    public.has_role('super_admin')
    or exists (
      select 1 from public.lessons l
      join public.topics t on l.topic_id = t.id
      join public.subjects s on t.subject_id = s.id
      where l.id = lesson_id
        and (public.has_role('content_admin', s.country_code) or public.has_role('curriculum_admin', s.country_code))
    )
  );

-- 3. Table: content_media_assets
create table if not exists public.content_media_assets (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 2 and 180),
  country_code text not null references public.countries (country_code) on delete restrict,
  subject_id uuid references public.subjects (id) on delete set null,
  media_type text not null check (media_type in ('image', 'audio', 'video', 'document', 'diagram')),
  file_url text not null,
  file_size_bytes bigint not null default 0 check (file_size_bytes >= 0),
  alt_text text,
  uploaded_by_user_id uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists content_media_country_type_idx
  on public.content_media_assets (country_code, media_type);

alter table public.content_media_assets enable row level security;
revoke all on public.content_media_assets from public, anon, authenticated;
grant select, insert on public.content_media_assets to authenticated;

drop policy if exists "Anyone authenticated can view media assets" on public.content_media_assets;
create policy "Anyone authenticated can view media assets"
  on public.content_media_assets for select to authenticated
  using (true);

drop policy if exists "Staff can upload media assets" on public.content_media_assets;
create policy "Staff can upload media assets"
  on public.content_media_assets for insert to authenticated
  with check (
    public.has_role('super_admin')
    or public.has_role('content_admin', country_code)
    or public.has_role('curriculum_admin', country_code)
  );

-- Seed sample diagrams in media assets
insert into public.content_media_assets (
  id,
  title,
  country_code,
  media_type,
  file_url,
  file_size_bytes,
  alt_text
) values
  (
    'a0000000-0000-0000-0000-000000000031',
    'Structure of the Plant Cell (Biologia Kidato cha 1)',
    'TZ',
    'diagram',
    'https://assets.learntz.org/diagrams/tz-biology-plant-cell.png',
    245760,
    'Annotated plant cell showing cell wall, chloroplasts, and vacuole'
  ),
  (
    'a0000000-0000-0000-0000-000000000032',
    'Pythagorean Theorem Geometric Proof',
    'TZ',
    'diagram',
    'https://assets.learntz.org/diagrams/math-pythagoras-proof.svg',
    65400,
    'Geometric square dissection proof of a^2 + b^2 = c^2'
  )
on conflict (id) do nothing;

-- ============================================================================
-- 4. RPC: get_content_studio_metrics
-- ============================================================================
create or replace function public.get_content_studio_metrics(p_country_code text default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_total_subjects integer;
  v_total_topics integer;
  v_total_lessons integer;
  v_published_lessons integer;
  v_draft_lessons integer;
  v_in_review_lessons integer;
  v_total_media_assets integer;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  -- 1. Total Subjects
  select count(*)::integer into v_total_subjects
  from public.subjects s
  where (p_country_code is null or s.country_code = p_country_code);

  -- 2. Total Topics
  select count(*)::integer into v_total_topics
  from public.topics t
  join public.subjects s on t.subject_id = s.id
  where (p_country_code is null or s.country_code = p_country_code);

  -- 3. Lesson Metrics by Status
  select
    count(*)::integer,
    count(*) filter (where l.status = 'published')::integer,
    count(*) filter (where l.status = 'draft')::integer,
    count(*) filter (where l.status = 'in_review')::integer
  into v_total_lessons, v_published_lessons, v_draft_lessons, v_in_review_lessons
  from public.lessons l
  join public.topics t on l.topic_id = t.id
  join public.subjects s on t.subject_id = s.id
  where (p_country_code is null or s.country_code = p_country_code);

  -- 4. Total Media Assets
  select count(*)::integer into v_total_media_assets
  from public.content_media_assets m
  where (p_country_code is null or m.country_code = p_country_code);

  v_result := jsonb_build_object(
    'country_code', coalesce(p_country_code, 'ALL'),
    'total_subjects', v_total_subjects,
    'total_topics', v_total_topics,
    'total_lessons', v_total_lessons,
    'published_lessons', v_published_lessons,
    'draft_lessons', v_draft_lessons,
    'in_review_lessons', v_in_review_lessons,
    'total_media_assets', v_total_media_assets
  );

  return v_result;
end;
$$;

-- ============================================================================
-- 5. RPC: get_content_studio_catalog
-- ============================================================================
create or replace function public.get_content_studio_catalog(
  p_country_code text default null,
  p_search text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(s_rec), '[]'::jsonb) into v_result
  from (
    select
      s.id as subject_id,
      s.name as subject_name,
      s.code as subject_code,
      s.country_code,
      s.display_order as subject_order,
      (
        select coalesce(jsonb_agg(t_rec), '[]'::jsonb)
        from (
          select
            t.id as topic_id,
            t.title as topic_title,
            t.summary as topic_summary,
            t.display_order as topic_order,
            t.is_published as topic_is_published,
            (
              select coalesce(jsonb_agg(l_rec), '[]'::jsonb)
              from (
                select
                  l.id as lesson_id,
                  l.title as lesson_title,
                  l.summary as lesson_summary,
                  l.estimated_minutes,
                  l.is_free_preview,
                  l.display_order as lesson_order,
                  l.status as lesson_status,
                  l.is_published as lesson_is_published,
                  l.version_number,
                  l.updated_at
                from public.lessons l
                where l.topic_id = t.id
                order by l.display_order asc, l.created_at asc
              ) l_rec
            ) as lessons
          from public.topics t
          where t.subject_id = s.id
            and (p_search is null or t.title ilike '%' || p_search || '%')
          order by t.display_order asc, t.created_at asc
        ) t_rec
      ) as topics
    from public.subjects s
    where (p_country_code is null or s.country_code = p_country_code)
      and (
        p_search is null
        or s.name ilike '%' || p_search || '%'
        or s.code ilike '%' || p_search || '%'
        or exists (
          select 1 from public.topics t
          where t.subject_id = s.id and t.title ilike '%' || p_search || '%'
        )
      )
    order by s.country_code asc, s.display_order asc, s.name asc
  ) s_rec;

  return v_result;
end;
$$;

-- ============================================================================
-- 6. RPC: upsert_studio_lesson
-- ============================================================================
create or replace function public.upsert_studio_lesson(
  p_topic_id uuid,
  p_title text,
  p_body_markdown text,
  p_summary text default null,
  p_estimated_minutes integer default 10,
  p_is_free_preview boolean default false,
  p_status text default 'draft',
  p_content_blocks jsonb default '[]'::jsonb,
  p_lesson_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_country text;
  v_target_id uuid;
  v_new_version integer := 1;
  v_is_pub boolean;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  -- Resolve subject country
  select s.country_code into v_country
  from public.topics t
  join public.subjects s on t.subject_id = s.id
  where t.id = p_topic_id;

  if v_country is null then
    raise exception 'Target topic % not found', p_topic_id using errcode = '22023';
  end if;

  -- Check authorized staff role
  if not (
    public.has_role('super_admin')
    or public.has_role('content_admin', v_country)
    or public.has_role('curriculum_admin', v_country)
    or exists (
      select 1 from public.organization_memberships m
      where m.user_id = v_user_id
        and m.status = 'active'
        and m.role in ('institutional_admin', 'school_principal', 'head_of_department', 'teacher', 'curriculum_analyst')
    )
  ) then
    raise exception 'Permission denied: cannot author or edit lesson' using errcode = '42501';
  end if;

  v_is_pub := (p_status = 'published');

  if p_lesson_id is not null then
    -- Updating existing lesson
    select version_number + 1 into v_new_version
    from public.lessons
    where id = p_lesson_id;

    if v_new_version is null then
      v_new_version := 2;
    end if;

    update public.lessons
    set
      title = btrim(p_title),
      summary = p_summary,
      body_markdown = p_body_markdown,
      content_blocks = coalesce(p_content_blocks, '[]'::jsonb),
      estimated_minutes = coalesce(p_estimated_minutes, 10),
      is_free_preview = coalesce(p_is_free_preview, false),
      status = p_status,
      is_published = v_is_pub,
      version_number = v_new_version,
      published_at = case when v_is_pub then coalesce(published_at, now()) else null end,
      updated_at = now()
    where id = p_lesson_id
    returning id into v_target_id;
  else
    -- Inserting new lesson
    insert into public.lessons (
      topic_id,
      title,
      summary,
      body_markdown,
      content_blocks,
      estimated_minutes,
      is_free_preview,
      status,
      is_published,
      version_number,
      author_id,
      published_at
    ) values (
      p_topic_id,
      btrim(p_title),
      p_summary,
      p_body_markdown,
      coalesce(p_content_blocks, '[]'::jsonb),
      coalesce(p_estimated_minutes, 10),
      coalesce(p_is_free_preview, false),
      p_status,
      v_is_pub,
      1,
      v_user_id,
      case when v_is_pub then now() else null end
    )
    returning id into v_target_id;
  end if;

  -- Create revision history snapshot
  insert into public.lesson_revisions (
    lesson_id,
    version_number,
    title,
    summary,
    body_markdown,
    content_blocks,
    changed_by_user_id,
    change_summary
  ) values (
    v_target_id,
    v_new_version,
    btrim(p_title),
    p_summary,
    p_body_markdown,
    coalesce(p_content_blocks, '[]'::jsonb),
    v_user_id,
    'Updated in Content Management Studio'
  );

  v_result := jsonb_build_object(
    'id', v_target_id,
    'title', btrim(p_title),
    'status', p_status,
    'version_number', v_new_version,
    'is_published', v_is_pub,
    'updated_at', now()
  );

  return v_result;
end;
$$;

-- ============================================================================
-- 7. RPC: submit_lesson_review
-- ============================================================================
create or replace function public.submit_lesson_review(
  p_lesson_id uuid,
  p_action text,
  p_feedback text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_country text;
  v_new_status text;
  v_is_pub boolean;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select s.country_code into v_country
  from public.lessons l
  join public.topics t on l.topic_id = t.id
  join public.subjects s on t.subject_id = s.id
  where l.id = p_lesson_id;

  if v_country is null then
    raise exception 'Lesson % not found', p_lesson_id using errcode = '22023';
  end if;

  -- State machine mapping
  case p_action
    when 'submit_for_review' then
      v_new_status := 'in_review';
      v_is_pub := false;
    when 'approve_and_publish' then
      if not (public.has_role('super_admin') or public.has_role('curriculum_admin', v_country)) then
        raise exception 'Only curriculum administrators can approve and publish content' using errcode = '42501';
      end if;
      v_new_status := 'published';
      v_is_pub := true;
    when 'reject_to_draft' then
      v_new_status := 'draft';
      v_is_pub := false;
    when 'archive' then
      v_new_status := 'archived';
      v_is_pub := false;
    else
      raise exception 'Invalid review action %', p_action using errcode = '22023';
  end case;

  update public.lessons
  set
    status = v_new_status,
    is_published = v_is_pub,
    reviewer_id = case when p_action = 'approve_and_publish' then v_user_id else reviewer_id end,
    review_notes = coalesce(p_feedback, review_notes),
    published_at = case when v_is_pub then now() else published_at end,
    updated_at = now()
  where id = p_lesson_id;

  return jsonb_build_object(
    'id', p_lesson_id,
    'status', v_new_status,
    'is_published', v_is_pub,
    'action', p_action,
    'updated_at', now()
  );
end;
$$;
