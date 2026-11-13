-- LearnTZ Phase 2 Migration: Revision Centre and Learning Resource Library
-- Sub-Stage 4 (Stages 2.7 & 2.9 / TASK-208 & TASK-210)

begin;

-- ============================================================================
-- 1. Create table public.flashcard_decks & public.flashcards
-- ============================================================================

create table if not exists public.flashcard_decks (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries (country_code),
  curriculum_id uuid not null references public.curricula (id) on delete cascade,
  subject_id uuid not null references public.subjects (id) on delete cascade,
  topic_id uuid references public.topics (id) on delete set null,
  title text not null check (char_length(btrim(title)) between 1 and 200),
  description text,
  card_count integer not null default 0 check (card_count >= 0),
  estimated_minutes integer not null default 5 check (estimated_minutes between 1 and 180),
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists flashcard_decks_subject_topic_idx
  on public.flashcard_decks (subject_id, topic_id, is_published);

create trigger flashcard_decks_set_updated_at
  before update on public.flashcard_decks
  for each row execute function public.set_updated_at();

alter table public.flashcard_decks enable row level security;
revoke all on public.flashcard_decks from public, anon, authenticated;
grant select on public.flashcard_decks to authenticated;
grant insert, update, delete on public.flashcard_decks to authenticated;

create policy "Authenticated users read published flashcard decks"
  on public.flashcard_decks for select to authenticated
  using (is_published or public.has_role('super_admin'));

create policy "Content admins manage flashcard decks"
  on public.flashcard_decks for all to authenticated
  using (
    public.has_role('super_admin')
    or public.has_role('content_admin', flashcard_decks.country_code)
    or public.has_role('curriculum_admin', flashcard_decks.country_code)
  )
  with check (
    public.has_role('super_admin')
    or public.has_role('content_admin', flashcard_decks.country_code)
    or public.has_role('curriculum_admin', flashcard_decks.country_code)
  );

create table if not exists public.flashcards (
  id uuid primary key default gen_random_uuid(),
  deck_id uuid not null references public.flashcard_decks (id) on delete cascade,
  front_prompt text not null check (char_length(btrim(front_prompt)) >= 1),
  back_solution text not null check (char_length(btrim(back_solution)) >= 1),
  hint text,
  explanation text,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists flashcards_deck_idx
  on public.flashcards (deck_id, display_order);

create trigger flashcards_set_updated_at
  before update on public.flashcards
  for each row execute function public.set_updated_at();

create or replace function public.sync_flashcard_deck_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    update public.flashcard_decks
    set card_count = (select count(*) from public.flashcards where deck_id = new.deck_id)
    where id = new.deck_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.flashcard_decks
    set card_count = (select count(*) from public.flashcards where deck_id = old.deck_id)
    where id = old.deck_id;
    return old;
  elsif tg_op = 'UPDATE' then
    if new.deck_id <> old.deck_id then
      update public.flashcard_decks
      set card_count = (select count(*) from public.flashcards where deck_id = old.deck_id)
      where id = old.deck_id;
      update public.flashcard_decks
      set card_count = (select count(*) from public.flashcards where deck_id = new.deck_id)
      where id = new.deck_id;
    end if;
    return new;
  end if;
  return null;
end;
$$;

create trigger flashcards_sync_deck_count
  after insert or delete or update of deck_id on public.flashcards
  for each row execute function public.sync_flashcard_deck_count();

alter table public.flashcards enable row level security;
revoke all on public.flashcards from public, anon, authenticated;
grant select on public.flashcards to authenticated;
grant insert, update, delete on public.flashcards to authenticated;

create policy "Authenticated users read flashcards"
  on public.flashcards for select to authenticated
  using (
    exists (
      select 1 from public.flashcard_decks d
      where d.id = flashcards.deck_id
        and (d.is_published or public.has_role('super_admin'))
    )
  );

create policy "Content admins manage flashcards"
  on public.flashcards for all to authenticated
  using (
    public.has_role('super_admin')
    or exists (
      select 1 from public.flashcard_decks d
      where d.id = flashcards.deck_id
        and (
          public.has_role('content_admin', d.country_code)
          or public.has_role('curriculum_admin', d.country_code)
        )
    )
  )
  with check (
    public.has_role('super_admin')
    or exists (
      select 1 from public.flashcard_decks d
      where d.id = flashcards.deck_id
        and (
          public.has_role('content_admin', d.country_code)
          or public.has_role('curriculum_admin', d.country_code)
        )
    )
  );

-- ============================================================================
-- 2. Create table public.learning_resources
-- ============================================================================

create table if not exists public.learning_resources (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries (country_code),
  curriculum_id uuid not null references public.curricula (id) on delete cascade,
  education_level_id uuid references public.education_levels (id) on delete set null,
  grade_id uuid references public.education_grades (id) on delete set null,
  subject_id uuid not null references public.subjects (id) on delete cascade,
  topic_id uuid references public.topics (id) on delete set null,
  title text not null check (char_length(btrim(title)) between 1 and 255),
  description text,
  resource_type text not null check (
    resource_type in (
      'textbook',
      'study_guide',
      'worksheet',
      'audio_lesson',
      'video_guide',
      'past_paper',
      'revision_summary'
    )
  ),
  file_url text not null,
  file_format text not null default 'pdf' check (
    file_format in ('pdf', 'mp3', 'mp4', 'epub', 'html')
  ),
  file_size_bytes bigint check (file_size_bytes is null or file_size_bytes >= 0),
  duration_seconds integer check (duration_seconds is null or duration_seconds >= 0),
  author_or_publisher text not null default 'LearnTZ Editorial',
  is_official boolean not null default true,
  is_downloadable boolean not null default true,
  is_premium boolean not null default false,
  is_published boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists learning_resources_lookup_idx
  on public.learning_resources (country_code, curriculum_id, subject_id, resource_type, is_published);

create trigger learning_resources_set_updated_at
  before update on public.learning_resources
  for each row execute function public.set_updated_at();

alter table public.learning_resources enable row level security;
revoke all on public.learning_resources from public, anon, authenticated;
grant select on public.learning_resources to authenticated;
grant insert, update, delete on public.learning_resources to authenticated;

create policy "Authenticated users read published learning resources"
  on public.learning_resources for select to authenticated
  using (is_published or public.has_role('super_admin'));

create policy "Content admins manage learning resources"
  on public.learning_resources for all to authenticated
  using (
    public.has_role('super_admin')
    or public.has_role('content_admin', learning_resources.country_code)
    or public.has_role('curriculum_admin', learning_resources.country_code)
  )
  with check (
    public.has_role('super_admin')
    or public.has_role('content_admin', learning_resources.country_code)
    or public.has_role('curriculum_admin', learning_resources.country_code)
  );

-- ============================================================================
-- 3. Revision Centre & Resource Library RPCs
-- ============================================================================

-- A) Revision Overview for Learner
create or replace function public.get_learner_revision_overview(
  p_learner_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_learner record;
  v_readiness_index integer := 0;
  v_total_topics integer := 0;
  v_proficient_topics integer := 0;
  v_mastered_topics integer := 0;
  v_weak_topics jsonb := '[]'::jsonb;
  v_flashcard_decks_count integer := 0;
  v_resources_count integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Authorized parent access is required for this learner' using errcode = '42501';
  end if;

  select l.id, l.country_code, l.curriculum_id, l.education_level_id, l.grade_id
  into v_learner
  from public.learners l
  where l.id = p_learner_id;

  if not found then
    raise exception 'Learner not found' using errcode = 'P0002';
  end if;

  -- 1. Topics total and mastery counts for learner's curriculum
  select count(distinct t.id)
  into v_total_topics
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.curriculum_id = v_learner.curriculum_id
    and s.is_published
    and t.is_published;

  select
    coalesce(count(distinct case when m.mastery_status = 'proficient' then m.topic_id end), 0),
    coalesce(count(distinct case when m.mastery_status = 'mastered' then m.topic_id end), 0)
  into v_proficient_topics, v_mastered_topics
  from public.learner_topic_mastery m
  join public.topics t on t.id = m.topic_id
  join public.subjects s on s.id = t.subject_id
  where m.learner_id = p_learner_id
    and s.curriculum_id = v_learner.curriculum_id;

  if v_total_topics > 0 then
    v_readiness_index := round(
      ((v_proficient_topics * 0.70 + v_mastered_topics * 1.0) / v_total_topics::numeric) * 100.0
    )::integer;
    v_readiness_index := least(100, greatest(0, v_readiness_index));
  end if;

  -- 2. Identify weak topics (accuracy < 75% or non-mastered topics with attempts)
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'topic_id', w.topic_id,
        'topic_title', w.topic_title,
        'subject_id', w.subject_id,
        'subject_name', w.subject_name,
        'accuracy_rate', w.accuracy_rate,
        'quizzes_attempted', w.quizzes_attempted,
        'mastery_status', w.mastery_status
      ) order by w.accuracy_rate asc, w.quizzes_attempted asc
    ),
    '[]'::jsonb
  ) into v_weak_topics
  from (
    select
      t.id as topic_id,
      t.title as topic_title,
      s.id as subject_id,
      s.name as subject_name,
      coalesce(m.accuracy_rate, 0.00) as accuracy_rate,
      coalesce(m.quizzes_attempted, 0) as quizzes_attempted,
      coalesce(m.mastery_status, 'not_started') as mastery_status
    from public.topics t
    join public.subjects s on s.id = t.subject_id
    left join public.learner_topic_mastery m on m.topic_id = t.id and m.learner_id = p_learner_id
    where s.curriculum_id = v_learner.curriculum_id
      and s.is_published
      and t.is_published
      and (m.mastery_status is null or m.mastery_status in ('in_progress', 'proficient') or m.accuracy_rate < 75.00)
    order by coalesce(m.accuracy_rate, 0.00) asc, coalesce(m.quizzes_attempted, 0) asc
    limit 10
  ) w;

  -- 3. Flashcard decks available
  select count(*)
  into v_flashcard_decks_count
  from public.flashcard_decks fd
  join public.subjects s on s.id = fd.subject_id
  where fd.curriculum_id = v_learner.curriculum_id
    and fd.is_published;

  -- 4. Learning resources available
  select count(*)
  into v_resources_count
  from public.learning_resources lr
  where lr.curriculum_id = v_learner.curriculum_id
    and lr.is_published;

  return jsonb_build_object(
    'learner_id', p_learner_id,
    'curriculum_id', v_learner.curriculum_id,
    'readiness_index', v_readiness_index,
    'total_curriculum_topics', v_total_topics,
    'proficient_topics_count', v_proficient_topics,
    'mastered_topics_count', v_mastered_topics,
    'weak_topics', v_weak_topics,
    'flashcard_decks_count', v_flashcard_decks_count,
    'learning_resources_count', v_resources_count
  );
end;
$$;

revoke all on function public.get_learner_revision_overview(uuid) from public, anon;
grant execute on function public.get_learner_revision_overview(uuid) to authenticated;

-- B) Fetch Weak-Topic Drill Questions (Answers omitted for test integrity)
create or replace function public.get_weak_topic_drill_questions(
  p_learner_id uuid,
  p_limit integer default 10
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_learner record;
  v_questions jsonb;
  v_limit integer;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Authorized parent access is required for this learner' using errcode = '42501';
  end if;

  select l.id, l.curriculum_id
  into v_learner
  from public.learners l
  where l.id = p_learner_id;

  if not found then
    raise exception 'Learner not found' using errcode = 'P0002';
  end if;

  v_limit := least(greatest(1, coalesce(p_limit, 10)), 50);

  with weak_topics as (
    select t.id as topic_id
    from public.topics t
    join public.subjects s on s.id = t.subject_id
    left join public.learner_topic_mastery m on m.topic_id = t.id and m.learner_id = p_learner_id
    where s.curriculum_id = v_learner.curriculum_id
      and s.is_published
      and t.is_published
    order by coalesce(m.accuracy_rate, 0.0) asc, coalesce(m.quizzes_attempted, 0) asc
    limit 5
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', q.id,
        'topic_id', q.topic_id,
        'lesson_id', q.lesson_id,
        'question_type', q.question_type,
        'difficulty_level', q.difficulty_level,
        'question_text', q.question_text,
        'options', q.options,
        'cognitive_tier', q.cognitive_tier,
        'display_order', q.display_order
      ) order by q.display_order, q.created_at
    ),
    '[]'::jsonb
  ) into v_questions
  from (
    select qb.*
    from public.question_bank qb
    join weak_topics wt on wt.topic_id = qb.topic_id
    where qb.is_published
    order by qb.display_order, qb.created_at
    limit v_limit
  ) q;

  return v_questions;
end;
$$;

revoke all on function public.get_weak_topic_drill_questions(uuid, integer) from public, anon;
grant execute on function public.get_weak_topic_drill_questions(uuid, integer) to authenticated;

-- C) Fetch Flashcard Decks
create or replace function public.get_flashcard_decks(
  p_learner_id uuid default null,
  p_subject_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_curriculum_id uuid;
  v_decks jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  if p_learner_id is not null then
    if not public.is_authorized_learner_parent(p_learner_id) then
      raise exception 'Authorized parent access is required for this learner' using errcode = '42501';
    end if;

    select l.curriculum_id into v_curriculum_id
    from public.learners l
    where l.id = p_learner_id;
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', d.id,
        'country_code', d.country_code,
        'curriculum_id', d.curriculum_id,
        'subject_id', d.subject_id,
        'subject_name', s.name,
        'topic_id', d.topic_id,
        'topic_title', t.title,
        'title', d.title,
        'description', d.description,
        'card_count', d.card_count,
        'estimated_minutes', d.estimated_minutes,
        'created_at', d.created_at
      ) order by d.created_at desc
    ),
    '[]'::jsonb
  ) into v_decks
  from public.flashcard_decks d
  join public.subjects s on s.id = d.subject_id
  left join public.topics t on t.id = d.topic_id
  where d.is_published
    and (v_curriculum_id is null or d.curriculum_id = v_curriculum_id)
    and (p_subject_id is null or d.subject_id = p_subject_id);

  return v_decks;
end;
$$;

revoke all on function public.get_flashcard_decks(uuid, uuid) from public, anon;
grant execute on function public.get_flashcard_decks(uuid, uuid) to authenticated;

-- D) Fetch Cards for a Flashcard Deck
create or replace function public.get_deck_flashcards(
  p_deck_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cards jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', c.id,
        'deck_id', c.deck_id,
        'front_prompt', c.front_prompt,
        'back_solution', c.back_solution,
        'hint', c.hint,
        'explanation', c.explanation,
        'display_order', c.display_order
      ) order by c.display_order asc, c.created_at asc
    ),
    '[]'::jsonb
  ) into v_cards
  from public.flashcards c
  where c.deck_id = p_deck_id;

  return v_cards;
end;
$$;

revoke all on function public.get_deck_flashcards(uuid) from public, anon;
grant execute on function public.get_deck_flashcards(uuid) to authenticated;

-- E) Fetch Learning Resources
create or replace function public.get_learning_resources(
  p_country_code text,
  p_curriculum_id uuid default null,
  p_subject_id uuid default null,
  p_resource_type text default null,
  p_limit integer default 50
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_resources jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', r.id,
        'country_code', r.country_code,
        'curriculum_id', r.curriculum_id,
        'education_level_id', r.education_level_id,
        'grade_id', r.grade_id,
        'subject_id', r.subject_id,
        'subject_name', s.name,
        'topic_id', r.topic_id,
        'topic_title', t.title,
        'title', r.title,
        'description', r.description,
        'resource_type', r.resource_type,
        'file_url', r.file_url,
        'file_format', r.file_format,
        'file_size_bytes', r.file_size_bytes,
        'duration_seconds', r.duration_seconds,
        'author_or_publisher', r.author_or_publisher,
        'is_official', r.is_official,
        'is_downloadable', r.is_downloadable,
        'is_premium', r.is_premium,
        'metadata', r.metadata,
        'created_at', r.created_at
      ) order by r.is_official desc, r.created_at desc
    ),
    '[]'::jsonb
  ) into v_resources
  from (
    select r.*
    from public.learning_resources r
    join public.subjects s on s.id = r.subject_id
    left join public.topics t on t.id = r.topic_id
    where r.country_code = p_country_code
      and r.is_published
      and (p_curriculum_id is null or r.curriculum_id = p_curriculum_id)
      and (p_subject_id is null or r.subject_id = p_subject_id)
      and (p_resource_type is null or r.resource_type = p_resource_type)
    order by r.is_official desc, r.created_at desc
    limit least(greatest(1, coalesce(p_limit, 50)), 100)
  ) r
  join public.subjects s on s.id = r.subject_id
  left join public.topics t on t.id = r.topic_id;

  return v_resources;
end;
$$;

revoke all on function public.get_learning_resources(text, uuid, uuid, text, integer) from public, anon;
grant execute on function public.get_learning_resources(text, uuid, uuid, text, integer) to authenticated;

-- ============================================================================
-- 4. Seed sample flashcard decks, cards and learning resources
-- ============================================================================

-- Deck 1: Kiswahili Irabu na Silabi
insert into public.flashcard_decks (
  id, country_code, curriculum_id, subject_id, topic_id,
  title, description, estimated_minutes, is_published
)
values (
  '30000000-0000-0000-0000-000000000501',
  'TZ',
  '20000000-0000-0000-0000-000000000002',
  '30000000-0000-0000-0000-000000000101',
  '30000000-0000-0000-0000-000000000201',
  'Irabu na Silabi za Kiswahili',
  'Kadi za kurudia irabu 5 za msingi na silabi rahisi za Kiswahili.',
  5,
  true
)
on conflict (id) do nothing;

insert into public.flashcards (
  id, deck_id, front_prompt, back_solution, hint, explanation, display_order
)
values
  (
    '30000000-0000-0000-0000-000000000511',
    '30000000-0000-0000-0000-000000000501',
    'Taja irabu zote tano za lugha ya Kiswahili.',
    'A, E, I, O, U',
    'Kuna sauti tano za msingi.',
    'Irabu katika Kiswahili ndio msingi wa kila silabi: a, e, i, o, u.',
    1
  ),
  (
    '30000000-0000-0000-0000-000000000512',
    '30000000-0000-0000-0000-000000000501',
    'Unganisha konsonanti "B" na irabu "A". Unapata nini?',
    'BA',
    'Tamka sauti ya b ikifuatiwa na a.',
    'B + A = BA (kama katika neno BABA au BATA).',
    2
  ),
  (
    '30000000-0000-0000-0000-000000000513',
    '30000000-0000-0000-0000-000000000501',
    'Unganisha konsonanti "M" na irabu "A". Unapata nini?',
    'MA',
    'Kama neno la kwanza la mtoto.',
    'M + A = MA (kama katika neno MAMA).',
    3
  ),
  (
    '30000000-0000-0000-0000-000000000514',
    '30000000-0000-0000-0000-000000000501',
    'Neno "KITI" lina silabi ngapi?',
    'Silabi 2 (KI na TI)',
    'Hesabu mikupuo ya sauti unapotamka "KI-TI".',
    'Kiti kinaundwa na silabi mbili: KI na TI.',
    4
  )
on conflict (id) do nothing;

-- Deck 2: Hisabati - Dhana ya Namba
insert into public.flashcard_decks (
  id, country_code, curriculum_id, subject_id, topic_id,
  title, description, estimated_minutes, is_published
)
values (
  '30000000-0000-0000-0000-000000000502',
  'TZ',
  '20000000-0000-0000-0000-000000000002',
  '30000000-0000-0000-0000-000000000102',
  '30000000-0000-0000-0000-000000000202',
  'Kujumlisha na Kutoa Namba Sahili',
  'Kadi za mazoezi ya haraka ya kujumlisha na kutoa kwa Darasa la Kwanza.',
  6,
  true
)
on conflict (id) do nothing;

insert into public.flashcards (
  id, deck_id, front_prompt, back_solution, hint, explanation, display_order
)
values
  (
    '30000000-0000-0000-0000-000000000521',
    '30000000-0000-0000-0000-000000000502',
    '2 + 3 = ?',
    '5',
    'Hesabu vidole vitatu baada ya viwili.',
    'Ukichukua vitu viwili na kuongeza vitatu unapata vitu vitano jumla.',
    1
  ),
  (
    '30000000-0000-0000-0000-000000000522',
    '30000000-0000-0000-0000-000000000502',
    '5 - 2 = ?',
    '3',
    'Punguza viwili kutoka vitano.',
    'Ukiondoa 2 kutoka 5 unabakiwa na 3.',
    2
  ),
  (
    '30000000-0000-0000-0000-000000000523',
    '30000000-0000-0000-0000-000000000502',
    'Ni namba gani inayofuata baada ya 9?',
    '10',
    'Namba ya kwanza ya tarakimu mbili.',
    'Mfuatano wa namba: 7, 8, 9, 10.',
    3
  )
on conflict (id) do nothing;

-- Learning Resources Seed
insert into public.learning_resources (
  id, country_code, curriculum_id, education_level_id, subject_id, topic_id,
  title, description, resource_type, file_url, file_format, file_size_bytes,
  author_or_publisher, is_official, is_downloadable, is_premium, is_published
)
values
  (
    '30000000-0000-0000-0000-000000000601',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    '30000000-0000-0000-0000-000000000101',
    '30000000-0000-0000-0000-000000000201',
    'Kitabu cha Mwanafunzi: Kiswahili Darasa la 1 (TIE)',
    'Kitabu rasmi cha kiada cha Taasisi ya Elimu Tanzania kinachofundisha Kusoma na Kuandika.',
    'textbook',
    'https://cdn.learntz.org/resources/tz/tie_kiswahili_std1_textbook.pdf',
    'pdf',
    14829000,
    'Taasisi ya Elimu Tanzania (TIE)',
    true,
    true,
    false,
    true
  ),
  (
    '30000000-0000-0000-0000-000000000602',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    '30000000-0000-0000-0000-000000000101',
    '30000000-0000-0000-0000-000000000201',
    'Mwongozo wa Kurudia: Silabi na Msamiati wa Msingi',
    'Muhtasari wa haraka wa silabi zote na mifano ya maneno kwa ajili ya kurudia kabla ya mitihani.',
    'revision_summary',
    'https://cdn.learntz.org/resources/tz/tie_kiswahili_revision_guide.pdf',
    'pdf',
    3450000,
    'LearnTZ Editorial',
    true,
    true,
    false,
    true
  ),
  (
    '30000000-0000-0000-0000-000000000603',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    '30000000-0000-0000-0000-000000000102',
    '30000000-0000-0000-0000-000000000202',
    'Karatasi ya Mazoezi: Kujumlisha na Kutoa',
    'Mazoezi 50 ya vitendo kwa ajili ya kupima uelewa wa namba na hesabu za haraka.',
    'worksheet',
    'https://cdn.learntz.org/resources/tz/hisabati_std1_mazoezi_worksheet.pdf',
    'pdf',
    1240000,
    'LearnTZ Editorial',
    true,
    true,
    false,
    true
  ),
  (
    '30000000-0000-0000-0000-000000000604',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    '30000000-0000-0000-0000-000000000101',
    '30000000-0000-0000-0000-000000000201',
    'Sauti za Kiswahili: Mwongozo wa Sauti (Audio Podcast)',
    'Kipindi cha sauti kinachotamka irabu na silabi kwa usahihi kwa wanaoanza kujifunza.',
    'audio_lesson',
    'https://cdn.learntz.org/resources/tz/kiswahili_irabu_pronunciation.mp3',
    'mp3',
    8920000,
    'LearnTZ Studio',
    true,
    true,
    false,
    true
  )
on conflict (id) do nothing;

commit;
