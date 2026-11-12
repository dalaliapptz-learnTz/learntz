begin;

create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries (country_code)
    on delete restrict,
  curriculum_id uuid not null,
  education_level_id uuid not null,
  grade_id uuid,
  curriculum_item_id uuid references public.curriculum_import_items (id)
    on delete set null,
  code text not null check (char_length(btrim(code)) between 1 and 60),
  name text not null check (char_length(btrim(name)) between 1 and 140),
  description text not null default '',
  display_order integer not null default 1 check (display_order > 0),
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint subjects_level_curriculum_fk
    foreign key (education_level_id, curriculum_id)
    references public.education_levels (id, curriculum_id)
    on delete restrict,
  constraint subjects_grade_fk
    foreign key (grade_id, education_level_id, curriculum_id)
    references public.education_grades (id, education_level_id, curriculum_id)
    on delete restrict
);

create unique index subjects_scope_code_unique_idx
  on public.subjects (
    curriculum_id,
    education_level_id,
    coalesce(grade_id, '00000000-0000-0000-0000-000000000000'::uuid),
    code
  );
create index subjects_country_published_idx
  on public.subjects (country_code, is_published, display_order);

create table public.topics (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects (id) on delete cascade,
  curriculum_item_id uuid references public.curriculum_import_items (id)
    on delete set null,
  title text not null check (char_length(btrim(title)) between 1 and 180),
  summary text not null default '',
  display_order integer not null default 1 check (display_order > 0),
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index topics_subject_order_idx
  on public.topics (subject_id, is_published, display_order);

create table public.lessons (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.topics (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 200),
  body_markdown text not null
    check (char_length(btrim(body_markdown)) between 1 and 50000),
  estimated_minutes integer not null default 10
    check (estimated_minutes between 1 and 180),
  is_free_preview boolean not null default false,
  display_order integer not null default 1 check (display_order > 0),
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index lessons_topic_order_idx
  on public.lessons (topic_id, is_published, display_order);

create table public.quizzes (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null unique references public.lessons (id)
    on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 200),
  pass_score_percent integer not null default 70
    check (pass_score_percent between 1 and 100),
  questions jsonb not null check (
    jsonb_typeof(questions) = 'array' and jsonb_array_length(questions) between 1 and 30
  ),
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.learner_progress (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references public.learners (id) on delete cascade,
  lesson_id uuid not null references public.lessons (id) on delete cascade,
  status text not null default 'not_started'
    check (status in ('not_started', 'in_progress', 'completed')),
  reading_progress_percent integer not null default 0
    check (reading_progress_percent between 0 and 100),
  best_quiz_score_percent integer
    check (best_quiz_score_percent is null or best_quiz_score_percent between 0 and 100),
  last_quiz_answers jsonb not null default '[]'::jsonb
    check (jsonb_typeof(last_quiz_answers) = 'array'),
  attempts_count integer not null default 0 check (attempts_count >= 0),
  completed_at timestamptz,
  last_accessed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint learner_progress_learner_lesson_unique unique (learner_id, lesson_id)
);

create index learner_progress_learner_idx
  on public.learner_progress (learner_id, status, last_accessed_at desc);

create trigger subjects_set_updated_at
  before update on public.subjects
  for each row execute function public.set_updated_at();
create trigger topics_set_updated_at
  before update on public.topics
  for each row execute function public.set_updated_at();
create trigger lessons_set_updated_at
  before update on public.lessons
  for each row execute function public.set_updated_at();
create trigger quizzes_set_updated_at
  before update on public.quizzes
  for each row execute function public.set_updated_at();
create trigger learner_progress_set_updated_at
  before update on public.learner_progress
  for each row execute function public.set_updated_at();

alter table public.subjects enable row level security;
alter table public.topics enable row level security;
alter table public.lessons enable row level security;
alter table public.quizzes enable row level security;
alter table public.learner_progress enable row level security;

revoke all on public.subjects, public.topics, public.lessons, public.quizzes, public.learner_progress
  from public, anon, authenticated;

grant select on public.subjects, public.topics, public.lessons to authenticated;
grant insert, update, delete on public.subjects, public.topics, public.lessons, public.quizzes
  to authenticated;
grant select on public.quizzes to authenticated;
grant select on public.learner_progress to authenticated;

create or replace function public.can_access_learning_lesson(p_lesson_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.lessons l
    join public.topics t on t.id = l.topic_id
    join public.subjects s on s.id = t.subject_id
    where l.id = p_lesson_id
      and (
        (
          l.is_published and t.is_published and s.is_published
          and (l.is_free_preview or public.has_active_parent_subscription(auth.uid()))
        )
        or public.has_role('super_admin')
        or public.has_role('content_admin', s.country_code)
        or public.has_role('curriculum_admin', s.country_code)
      )
  );
$$;

revoke all on function public.can_access_learning_lesson(uuid) from public, anon;
grant execute on function public.can_access_learning_lesson(uuid) to authenticated, service_role;

create policy "Authenticated users read published subjects and admins manage"
  on public.subjects for select to authenticated
  using (
    is_published
    or public.has_role('super_admin')
    or public.has_role('content_admin', country_code)
    or public.has_role('curriculum_admin', country_code)
  );

create policy "Content admins manage subjects"
  on public.subjects for all to authenticated
  using (
    public.has_role('super_admin')
    or public.has_role('content_admin', country_code)
    or public.has_role('curriculum_admin', country_code)
  )
  with check (
    public.has_role('super_admin')
    or public.has_role('content_admin', country_code)
    or public.has_role('curriculum_admin', country_code)
  );

create policy "Authenticated users read published topics"
  on public.topics for select to authenticated
  using (
    exists (
      select 1 from public.subjects s
      where s.id = topics.subject_id
        and (
          (topics.is_published and s.is_published)
          or public.has_role('super_admin')
          or public.has_role('content_admin', s.country_code)
          or public.has_role('curriculum_admin', s.country_code)
        )
    )
  );

create policy "Content admins manage topics"
  on public.topics for all to authenticated
  using (
    exists (
      select 1 from public.subjects s
      where s.id = topics.subject_id
        and (
          public.has_role('super_admin')
          or public.has_role('content_admin', s.country_code)
          or public.has_role('curriculum_admin', s.country_code)
        )
    )
  )
  with check (
    exists (
      select 1 from public.subjects s
      where s.id = topics.subject_id
        and (
          public.has_role('super_admin')
          or public.has_role('content_admin', s.country_code)
          or public.has_role('curriculum_admin', s.country_code)
        )
    )
  );

create policy "Entitled users read accessible lessons"
  on public.lessons for select to authenticated
  using ((select public.can_access_learning_lesson(id)));

create policy "Content admins manage lessons"
  on public.lessons for all to authenticated
  using (
    exists (
      select 1
      from public.topics t
      join public.subjects s on s.id = t.subject_id
      where t.id = lessons.topic_id
        and (
          public.has_role('super_admin')
          or public.has_role('content_admin', s.country_code)
          or public.has_role('curriculum_admin', s.country_code)
        )
    )
  )
  with check (
    exists (
      select 1
      from public.topics t
      join public.subjects s on s.id = t.subject_id
      where t.id = lessons.topic_id
        and (
          public.has_role('super_admin')
          or public.has_role('content_admin', s.country_code)
          or public.has_role('curriculum_admin', s.country_code)
        )
    )
  );

-- Direct table access on quizzes is restricted to admins so answer keys stay server-side;
-- learners fetch sanitized questions through get_lesson_practice_quiz().
create policy "Only content admins read raw quiz definitions"
  on public.quizzes for select to authenticated
  using (
    exists (
      select 1
      from public.lessons l
      join public.topics t on t.id = l.topic_id
      join public.subjects s on s.id = t.subject_id
      where l.id = quizzes.lesson_id
        and (
          public.has_role('super_admin')
          or public.has_role('content_admin', s.country_code)
          or public.has_role('curriculum_admin', s.country_code)
        )
    )
  );

create policy "Content admins manage quizzes"
  on public.quizzes for all to authenticated
  using (
    exists (
      select 1
      from public.lessons l
      join public.topics t on t.id = l.topic_id
      join public.subjects s on s.id = t.subject_id
      where l.id = quizzes.lesson_id
        and (
          public.has_role('super_admin')
          or public.has_role('content_admin', s.country_code)
          or public.has_role('curriculum_admin', s.country_code)
        )
    )
  )
  with check (
    exists (
      select 1
      from public.lessons l
      join public.topics t on t.id = l.topic_id
      join public.subjects s on s.id = t.subject_id
      where l.id = quizzes.lesson_id
        and (
          public.has_role('super_admin')
          or public.has_role('content_admin', s.country_code)
          or public.has_role('curriculum_admin', s.country_code)
        )
    )
  );

create policy "Authorized parents read their learner progress"
  on public.learner_progress for select to authenticated
  using ((select public.is_authorized_learner_parent(learner_id)));

create or replace function public.get_lesson_practice_quiz(
  p_learner_id uuid,
  p_lesson_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_quiz public.quizzes;
  v_sanitized jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Authorized parent access is required for this learner' using errcode = '42501';
  end if;
  if not public.can_access_learning_lesson(p_lesson_id) then
    raise exception 'Lesson subscription or preview access is required' using errcode = '42501';
  end if;

  select * into v_quiz
  from public.quizzes
  where lesson_id = p_lesson_id
    and is_published;

  if not found then
    return null;
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', q ->> 'id',
      'prompt', q ->> 'prompt',
      'options', q -> 'options'
    )
  ), '[]'::jsonb)
  into v_sanitized
  from jsonb_array_elements(v_quiz.questions) q;

  return jsonb_build_object(
    'id', v_quiz.id,
    'lesson_id', v_quiz.lesson_id,
    'title', v_quiz.title,
    'pass_score_percent', v_quiz.pass_score_percent,
    'questions', v_sanitized
  );
end;
$$;

revoke all on function public.get_lesson_practice_quiz(uuid, uuid) from public, anon;
grant execute on function public.get_lesson_practice_quiz(uuid, uuid) to authenticated;

create or replace function public.upsert_learner_lesson_progress(
  p_learner_id uuid,
  p_lesson_id uuid,
  p_reading_progress_percent integer,
  p_mark_completed boolean default false
)
returns public.learner_progress
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_progress public.learner_progress;
  v_clamped integer := least(100, greatest(0, coalesce(p_reading_progress_percent, 0)));
  v_effective_pct integer := case when coalesce(p_mark_completed, false) then 100 else v_clamped end;
  v_next_status text;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Authorized parent access is required for this learner' using errcode = '42501';
  end if;
  if not public.can_access_learning_lesson(p_lesson_id) then
    raise exception 'Lesson subscription or preview access is required' using errcode = '42501';
  end if;

  v_next_status := case
    when coalesce(p_mark_completed, false) then 'completed'
    when v_effective_pct > 0 then 'in_progress'
    else 'not_started'
  end;

  insert into public.learner_progress (
    learner_id, lesson_id, status, reading_progress_percent, completed_at, last_accessed_at
  ) values (
    p_learner_id,
    p_lesson_id,
    v_next_status,
    v_effective_pct,
    case when v_next_status = 'completed' then now() else null end,
    now()
  )
  on conflict (learner_id, lesson_id) do update
  set reading_progress_percent = greatest(
        public.learner_progress.reading_progress_percent,
        excluded.reading_progress_percent
      ),
      status = case
        when public.learner_progress.status = 'completed' or excluded.status = 'completed' then 'completed'
        when greatest(public.learner_progress.reading_progress_percent, excluded.reading_progress_percent) > 0 then 'in_progress'
        else 'not_started'
      end,
      completed_at = case
        when public.learner_progress.completed_at is not null then public.learner_progress.completed_at
        when excluded.status = 'completed' then now()
        else null
      end,
      last_accessed_at = now()
  returning * into v_progress;

  return v_progress;
end;
$$;

revoke all on function public.upsert_learner_lesson_progress(uuid, uuid, integer, boolean) from public, anon;
grant execute on function public.upsert_learner_lesson_progress(uuid, uuid, integer, boolean) to authenticated;

create or replace function public.submit_learner_quiz_attempt(
  p_learner_id uuid,
  p_quiz_id uuid,
  p_selected_indices integer[]
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_quiz public.quizzes;
  v_total integer;
  v_correct integer := 0;
  v_idx integer := 0;
  v_question jsonb;
  v_selected integer;
  v_expected integer;
  v_score_percent integer;
  v_passed boolean;
  v_progress public.learner_progress;
  v_results jsonb := '[]'::jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Authorized parent access is required for this learner' using errcode = '42501';
  end if;

  select * into v_quiz
  from public.quizzes
  where id = p_quiz_id
    and is_published;
  if not found then
    raise exception 'Quiz is unavailable' using errcode = '22023';
  end if;

  if not public.can_access_learning_lesson(v_quiz.lesson_id) then
    raise exception 'Lesson subscription or preview access is required' using errcode = '42501';
  end if;

  v_total := jsonb_array_length(v_quiz.questions);
  if p_selected_indices is null or array_length(p_selected_indices, 1) is distinct from v_total then
    raise exception 'All quiz questions must be answered' using errcode = '22023';
  end if;

  for v_idx in 1..v_total loop
    v_question := v_quiz.questions -> (v_idx - 1);
    v_selected := p_selected_indices[v_idx];
    v_expected := (v_question ->> 'correct_index')::integer;
    if v_selected = v_expected then
      v_correct := v_correct + 1;
    end if;
    v_results := v_results || jsonb_build_object(
      'question_id', v_question ->> 'id',
      'selected_index', v_selected,
      'correct_index', v_expected,
      'is_correct', (v_selected = v_expected),
      'explanation', coalesce(v_question ->> 'explanation', '')
    );
  end loop;

  v_score_percent := round((v_correct::numeric * 100.0) / v_total)::integer;
  v_passed := v_score_percent >= v_quiz.pass_score_percent;

  insert into public.learner_progress (
    learner_id,
    lesson_id,
    status,
    reading_progress_percent,
    best_quiz_score_percent,
    last_quiz_answers,
    attempts_count,
    completed_at,
    last_accessed_at
  ) values (
    p_learner_id,
    v_quiz.lesson_id,
    case when v_passed then 'completed' else 'in_progress' end,
    case when v_passed then 100 else 50 end,
    v_score_percent,
    to_jsonb(p_selected_indices),
    1,
    case when v_passed then now() else null end,
    now()
  )
  on conflict (learner_id, lesson_id) do update
  set best_quiz_score_percent = greatest(
        coalesce(public.learner_progress.best_quiz_score_percent, 0),
        excluded.best_quiz_score_percent
      ),
      last_quiz_answers = excluded.last_quiz_answers,
      attempts_count = public.learner_progress.attempts_count + 1,
      reading_progress_percent = case
        when v_passed then 100
        else greatest(public.learner_progress.reading_progress_percent, 50)
      end,
      status = case
        when public.learner_progress.status = 'completed' or v_passed then 'completed'
        else 'in_progress'
      end,
      completed_at = case
        when public.learner_progress.completed_at is not null then public.learner_progress.completed_at
        when v_passed then now()
        else null
      end,
      last_accessed_at = now()
  returning * into v_progress;

  perform public.write_audit_log(
    auth.uid(),
    null,
    'learning.quiz_submitted',
    jsonb_build_object(
      'learner_id', p_learner_id,
      'quiz_id', v_quiz.id,
      'lesson_id', v_quiz.lesson_id,
      'score_percent', v_score_percent,
      'passed', v_passed
    )
  );

  return jsonb_build_object(
    'quiz_id', v_quiz.id,
    'lesson_id', v_quiz.lesson_id,
    'score_percent', v_score_percent,
    'correct_count', v_correct,
    'total_questions', v_total,
    'passed', v_passed,
    'pass_score_percent', v_quiz.pass_score_percent,
    'best_quiz_score_percent', v_progress.best_quiz_score_percent,
    'lesson_status', v_progress.status,
    'attempts_count', v_progress.attempts_count,
    'results', v_results
  );
end;
$$;

revoke all on function public.submit_learner_quiz_attempt(uuid, uuid, integer[]) from public, anon;
grant execute on function public.submit_learner_quiz_attempt(uuid, uuid, integer[]) to authenticated;

create or replace function public.get_learner_learning_summary(p_learner_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_learner public.learners;
  v_total_lessons integer := 0;
  v_completed_lessons integer := 0;
  v_in_progress_lessons integer := 0;
  v_avg_quiz numeric := 0;
  v_mastery_percent integer := 0;
  v_has_sub boolean := false;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Authorized parent access is required for this learner' using errcode = '42501';
  end if;

  select * into v_learner
  from public.learners
  where id = p_learner_id;

  select count(*)::integer into v_total_lessons
  from public.lessons l
  join public.topics t on t.id = l.topic_id
  join public.subjects s on s.id = t.subject_id
  where l.is_published and t.is_published and s.is_published
    and s.curriculum_id = v_learner.curriculum_id
    and s.education_level_id = v_learner.education_level_id
    and (s.grade_id is null or s.grade_id = v_learner.grade_id);

  select
    count(*) filter (where lp.status = 'completed')::integer,
    count(*) filter (where lp.status = 'in_progress')::integer,
    coalesce(avg(lp.best_quiz_score_percent) filter (where lp.best_quiz_score_percent is not null), 0)
  into v_completed_lessons, v_in_progress_lessons, v_avg_quiz
  from public.learner_progress lp
  join public.lessons l on l.id = lp.lesson_id
  join public.topics t on t.id = l.topic_id
  join public.subjects s on s.id = t.subject_id
  where lp.learner_id = p_learner_id
    and l.is_published and t.is_published and s.is_published
    and s.curriculum_id = v_learner.curriculum_id
    and s.education_level_id = v_learner.education_level_id
    and (s.grade_id is null or s.grade_id = v_learner.grade_id);

  if v_total_lessons > 0 then
    v_mastery_percent := round((v_completed_lessons::numeric * 100.0) / v_total_lessons)::integer;
  end if;

  v_has_sub := public.has_active_parent_subscription(auth.uid());

  return jsonb_build_object(
    'learner_id', p_learner_id,
    'total_lessons', v_total_lessons,
    'completed_lessons', v_completed_lessons,
    'in_progress_lessons', v_in_progress_lessons,
    'average_quiz_score_percent', round(v_avg_quiz)::integer,
    'mastery_percent', v_mastery_percent,
    'has_active_subscription', v_has_sub
  );
end;
$$;

revoke all on function public.get_learner_learning_summary(uuid) from public, anon;
grant execute on function public.get_learner_learning_summary(uuid) to authenticated;

-- Seed initial Tanzania Primary (TIE Mtaala wa Elimu ya Msingi) learning content.
insert into public.subjects (
  id, country_code, curriculum_id, education_level_id, grade_id,
  code, name, description, display_order, is_published
)
values
  (
    '30000000-0000-0000-0000-000000000101',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    null,
    'tie-kiswahili',
    'Kiswahili',
    'Kusoma, kuandika, na mawasiliano kwa ufasaha kwa Elimu ya Msingi.',
    1,
    true
  ),
  (
    '30000000-0000-0000-0000-000000000102',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    null,
    'tie-hisabati',
    'Hisabati',
    'Dhana ya namba, matendo ya kihisabati, na utatuzi wa matatizo ya kila siku.',
    2,
    true
  ),
  (
    '30000000-0000-0000-0000-000000000103',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    null,
    'tie-sayansi',
    'Sayansi',
    'Misingi ya uchunguzi wa kisayansi, nishati, na TEHAMA katika maisha ya kila siku.',
    3,
    true
  );

insert into public.topics (
  id, subject_id, title, summary, display_order, is_published
)
values
  (
    '30000000-0000-0000-0000-000000000201',
    '30000000-0000-0000-0000-000000000101',
    'Kusoma na Kuelewa Matini',
    'Kutambua sauti za herufi, silabi, na kusoma habari fupi kwa ufahamu.',
    1,
    true
  ),
  (
    '30000000-0000-0000-0000-000000000202',
    '30000000-0000-0000-0000-000000000102',
    'Dhana ya Namba na Matendo ya Kihisabati',
    'Kujumlisha, kutoa, na kutumia namba katika miktadha halisi.',
    1,
    true
  ),
  (
    '30000000-0000-0000-0000-000000000203',
    '30000000-0000-0000-0000-000000000103',
    'Uchunguzi Sahili wa Kisayansi',
    'Kutumia uchunguzi sahili kuchunguza vitu vilivyomo katika mazingira.',
    1,
    true
  );

insert into public.lessons (
  id, topic_id, title, body_markdown, estimated_minutes, is_free_preview, display_order, is_published
)
values
  (
    '30000000-0000-0000-0000-000000000301',
    '30000000-0000-0000-0000-000000000201',
    'Sauti za Irabu na Silabi Sahili',
    E'# Sauti za Irabu na Silabi Sahili\n\nKatika Kiswahili kuna irabu tano za msingi: **a, e, i, o, u**.\n\nTunapounganisha konsonanti na irabu tunapata silabi, kwa mfano:\n- **b + a = ba**\n- **m + a = ma**\n- **k + i = ki**\n\n### Zoezi la Kusoma\nSoma maneno yafuatayo kwa sauti: *mama, baba, kiti, bata*.',
    8,
    true,
    1,
    true
  ),
  (
    '30000000-0000-0000-0000-000000000302',
    '30000000-0000-0000-0000-000000000202',
    'Matendo ya Namba Katika Maisha ya Kila Siku',
    E'# Matendo ya Namba\n\nHisabati hutusaidia kuhesabu vitu nyumbani na sokoni.\n\n### Mfano\nAmani alinunua machungwa **12** na Juma akampa machungwa **5** zaidi.\nJumla ya machungwa ni: **12 + 5 = 17**.\n\nKutoa hutusaidia kujua kilichobaki baada ya kutumia au kugawa.',
    10,
    true,
    1,
    true
  ),
  (
    '30000000-0000-0000-0000-000000000303',
    '30000000-0000-0000-0000-000000000203',
    'Vyanzo vya Nishati na Matumizi Yake',
    E'# Vyanzo vya Nishati\n\nNishati huwezesha kufanyika kwa kazi mbalimbali.\n\nMifano ya nishati katika mazingira yetu:\n1. **Nishati ya jua** — hutoa mwanga na joto.\n2. **Nishati ya umeme** — huwasha taa na vifaa vya TEHAMA.\n3. **Nishati ya upepo** — huendesha vinu vya upepo.',
    12,
    false,
    1,
    true
  );

insert into public.quizzes (
  id, lesson_id, title, pass_score_percent, questions, is_published
)
values
  (
    '30000000-0000-0000-0000-000000000401',
    '30000000-0000-0000-0000-000000000301',
    'Jaribio: Irabu na Silabi za Kiswahili',
    70,
    '[
      {
        "id": "q1",
        "prompt": "Kuna irabu ngapi za msingi katika lugha ya Kiswahili?",
        "options": ["Tatu (3)", "Tano (5)", "Saba (7)"],
        "correct_index": 1,
        "explanation": "Irabu tano za Kiswahili ni a, e, i, o, u."
      },
      {
        "id": "q2",
        "prompt": "Tukichanganya konsonanti m na irabu a tunapata silabi ipi?",
        "options": ["ma", "me", "mi"],
        "correct_index": 0,
        "explanation": "m + a huunda silabi ma."
      }
    ]'::jsonb,
    true
  ),
  (
    '30000000-0000-0000-0000-000000000402',
    '30000000-0000-0000-0000-000000000302',
    'Jaribio: Kujumlisha na Kutoa',
    70,
    '[
      {
        "id": "q1",
        "prompt": "12 + 5 ni sawa na ngapi?",
        "options": ["16", "17", "18"],
        "correct_index": 1,
        "explanation": "12 ukijumlisha na 5 unapata 17."
      },
      {
        "id": "q2",
        "prompt": "Ukiwa na kalamu 9 ukatoa 4, unabaki na ngapi?",
        "options": ["5", "6", "4"],
        "correct_index": 0,
        "explanation": "9 - 4 = 5."
      }
    ]'::jsonb,
    true
  ),
  (
    '30000000-0000-0000-0000-000000000403',
    '30000000-0000-0000-0000-000000000303',
    'Jaribio: Vyanzo vya Nishati',
    70,
    '[
      {
        "id": "q1",
        "prompt": "Chanzo kipi cha asili hutoa mwanga na joto duniani?",
        "options": ["Jua", "Chuma", "Mchanga"],
        "correct_index": 0,
        "explanation": "Jua ni chanzo kikuu cha asili cha mwanga na joto."
      }
    ]'::jsonb,
    true
  );

commit;
