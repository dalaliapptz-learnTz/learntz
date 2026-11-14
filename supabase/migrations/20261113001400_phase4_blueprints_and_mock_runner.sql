-- LearnTZ Phase 4 — Examination and Mock Examination Intelligence Platform
-- Sub-Stage 3: Blueprint Engine, Automated Mock Generator & Timed Exam Runner
-- Tasks: TASK-408, TASK-409, TASK-410, TASK-411

begin;

-- ============================================================================
-- 1. Table: examination_blueprints
-- ============================================================================
create table if not exists public.examination_blueprints (
  id uuid primary key default gen_random_uuid(),
  national_examination_id text not null references public.national_examinations (id) on delete cascade,
  subject_id uuid references public.subjects (id) on delete set null,
  title text not null check (char_length(btrim(title)) >= 3),
  total_marks numeric not null check (total_marks > 0 and total_marks <= 200),
  duration_minutes integer not null check (duration_minutes between 30 and 360),
  structure_config jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists examination_blueprints_exam_subject_idx
  on public.examination_blueprints (national_examination_id, subject_id, is_active);

drop trigger if exists examination_blueprints_set_updated_at on public.examination_blueprints;
create trigger examination_blueprints_set_updated_at
  before update on public.examination_blueprints
  for each row execute function public.set_updated_at();

alter table public.examination_blueprints enable row level security;
revoke all on public.examination_blueprints from public, anon, authenticated;
grant select on public.examination_blueprints to anon, authenticated;
grant insert, update, delete on public.examination_blueprints to authenticated;

drop policy if exists "Anyone reads active blueprints" on public.examination_blueprints;
create policy "Anyone reads active blueprints"
  on public.examination_blueprints for select
  using (is_active = true or public.has_role('super_admin') or public.has_role('curriculum_admin'));

drop policy if exists "Staff manages blueprints" on public.examination_blueprints;
create policy "Staff manages blueprints"
  on public.examination_blueprints for all to authenticated
  using (public.has_role('super_admin') or public.has_role('curriculum_admin'))
  with check (public.has_role('super_admin') or public.has_role('curriculum_admin'));

-- ============================================================================
-- 2. Table: generated_mock_examinations
-- ============================================================================
create table if not exists public.generated_mock_examinations (
  id uuid primary key default gen_random_uuid(),
  blueprint_id uuid not null references public.examination_blueprints (id) on delete cascade,
  title text not null check (char_length(btrim(title)) >= 3),
  academic_year integer not null default 2026 check (academic_year between 2000 and 2100),
  total_marks numeric not null check (total_marks > 0),
  duration_minutes integer not null check (duration_minutes > 0),
  curated_by uuid references auth.users (id) on delete set null,
  status text not null default 'published' check (status in ('draft', 'published', 'archived')),
  created_at timestamptz not null default now()
);

create index if not exists generated_mock_examinations_blueprint_idx
  on public.generated_mock_examinations (blueprint_id, status);

alter table public.generated_mock_examinations enable row level security;
revoke all on public.generated_mock_examinations from public, anon, authenticated;
grant select on public.generated_mock_examinations to anon, authenticated;
grant insert, update, delete on public.generated_mock_examinations to authenticated;

drop policy if exists "Anyone reads published mock exams" on public.generated_mock_examinations;
create policy "Anyone reads published mock exams"
  on public.generated_mock_examinations for select
  using (status = 'published' or public.has_role('super_admin') or public.has_role('curriculum_admin'));

drop policy if exists "Staff manages mock exams" on public.generated_mock_examinations;
create policy "Staff manages mock exams"
  on public.generated_mock_examinations for all to authenticated
  using (public.has_role('super_admin') or public.has_role('curriculum_admin'))
  with check (public.has_role('super_admin') or public.has_role('curriculum_admin'));

-- ============================================================================
-- 3. Table: mock_examination_items
-- ============================================================================
create table if not exists public.mock_examination_items (
  id uuid primary key default gen_random_uuid(),
  mock_exam_id uuid not null references public.generated_mock_examinations (id) on delete cascade,
  question_id uuid not null references public.exam_extracted_questions (id) on delete cascade,
  section_code text not null check (char_length(btrim(section_code)) >= 1),
  order_index integer not null check (order_index > 0),
  marks numeric not null check (marks > 0),
  constraint uq_mock_item_order unique (mock_exam_id, section_code, order_index)
);

create index if not exists mock_examination_items_lookup_idx
  on public.mock_examination_items (mock_exam_id, section_code, order_index);

alter table public.mock_examination_items enable row level security;
revoke all on public.mock_examination_items from public, anon, authenticated;
grant select on public.mock_examination_items to anon, authenticated;
grant insert, update, delete on public.mock_examination_items to authenticated;

drop policy if exists "Anyone reads mock examination items" on public.mock_examination_items;
create policy "Anyone reads mock examination items"
  on public.mock_examination_items for select
  using (true);

drop policy if exists "Staff manages mock items" on public.mock_examination_items;
create policy "Staff manages mock items"
  on public.mock_examination_items for all to authenticated
  using (public.has_role('super_admin') or public.has_role('curriculum_admin'))
  with check (public.has_role('super_admin') or public.has_role('curriculum_admin'));

-- ============================================================================
-- 4. Table: learner_exam_attempts
-- ============================================================================
create table if not exists public.learner_exam_attempts (
  id uuid primary key default gen_random_uuid(),
  mock_exam_id uuid not null references public.generated_mock_examinations (id) on delete cascade,
  learner_id uuid not null references public.learners (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'in_progress' check (
    status in ('in_progress', 'completed', 'abandoned', 'expired')
  ),
  started_at timestamptz not null default now(),
  duration_minutes integer not null check (duration_minutes > 0),
  expires_at timestamptz not null,
  submitted_at timestamptz,
  total_score numeric default 0.0,
  total_possible_marks numeric not null default 100.0,
  percentage numeric default 0.0,
  predicted_division_or_grade text,
  created_at timestamptz not null default now()
);

create index if not exists learner_exam_attempts_user_learner_idx
  on public.learner_exam_attempts (user_id, learner_id, status);

alter table public.learner_exam_attempts enable row level security;
revoke all on public.learner_exam_attempts from public, anon, authenticated;
grant select, insert, update on public.learner_exam_attempts to authenticated;

drop policy if exists "Learners and parents read own exam attempts" on public.learner_exam_attempts;
create policy "Learners and parents read own exam attempts"
  on public.learner_exam_attempts for select to authenticated
  using (
    user_id = auth.uid()
    or public.has_role('super_admin')
    or public.has_role('curriculum_admin')
  );

drop policy if exists "Learners create own exam attempts" on public.learner_exam_attempts;
create policy "Learners create own exam attempts"
  on public.learner_exam_attempts for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "Learners update own in_progress exam attempts" on public.learner_exam_attempts;
create policy "Learners update own in_progress exam attempts"
  on public.learner_exam_attempts for update to authenticated
  using (
    user_id = auth.uid()
    or public.has_role('super_admin')
  )
  with check (
    user_id = auth.uid()
    or public.has_role('super_admin')
  );

-- ============================================================================
-- 5. Table: learner_exam_responses
-- ============================================================================
create table if not exists public.learner_exam_responses (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.learner_exam_attempts (id) on delete cascade,
  question_id uuid not null references public.exam_extracted_questions (id) on delete cascade,
  learner_answer text,
  is_flagged boolean not null default false,
  marks_awarded numeric,
  feedback text,
  answered_at timestamptz not null default now(),
  constraint uq_attempt_question unique (attempt_id, question_id)
);

create index if not exists learner_exam_responses_lookup_idx
  on public.learner_exam_responses (attempt_id, question_id);

alter table public.learner_exam_responses enable row level security;
revoke all on public.learner_exam_responses from public, anon, authenticated;
grant select, insert, update on public.learner_exam_responses to authenticated;

drop policy if exists "Learners manage own exam responses" on public.learner_exam_responses;
create policy "Learners manage own exam responses"
  on public.learner_exam_responses for all to authenticated
  using (
    exists (
      select 1 from public.learner_exam_attempts lea
      where lea.id = learner_exam_responses.attempt_id
        and (lea.user_id = auth.uid() or public.has_role('super_admin'))
    )
  )
  with check (
    exists (
      select 1 from public.learner_exam_attempts lea
      where lea.id = learner_exam_responses.attempt_id
        and (lea.user_id = auth.uid() or public.has_role('super_admin'))
    )
  );

-- ============================================================================
-- 6. RPC: generate_automated_mock_exam
-- ============================================================================
create or replace function public.generate_automated_mock_exam(
  p_blueprint_id uuid,
  p_title text,
  p_academic_year integer default 2026
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_blueprint record;
  v_mock_id uuid;
  v_section jsonb;
  v_sec_code text;
  v_sec_req_count integer;
  v_sec_marks numeric;
  v_q record;
  v_order integer;
  v_items_added integer := 0;
begin
  if not (
    public.has_role('super_admin')
    or exists (
      select 1 from public.user_roles
      where user_id = auth.uid()
        and role in ('curriculum_admin', 'content_admin')
    )
  ) then
    raise exception 'Permission denied: Staff authorization required to generate mock exams';
  end if;

  select * into v_blueprint
  from public.examination_blueprints
  where id = p_blueprint_id;

  if not found then
    raise exception 'Blueprint not found';
  end if;

  insert into public.generated_mock_examinations (
    blueprint_id,
    title,
    academic_year,
    total_marks,
    duration_minutes,
    curated_by,
    status
  ) values (
    p_blueprint_id,
    p_title,
    coalesce(p_academic_year, 2026),
    v_blueprint.total_marks,
    v_blueprint.duration_minutes,
    auth.uid(),
    'published'
  )
  returning id into v_mock_id;

  -- Iterate through sections defined in blueprint
  for v_section in select * from jsonb_array_elements(v_blueprint.structure_config)
  loop
    v_sec_code := v_section->>'code';
    v_sec_req_count := coalesce((v_section->>'question_count')::integer, 5);
    v_order := 1;

    for v_q in (
      select q.*
      from public.exam_extracted_questions q
      where q.verification_status = 'approved'
        and (v_blueprint.subject_id is null or q.subject_id = v_blueprint.subject_id)
        and (q.section_code = v_sec_code or v_blueprint.structure_config->0->>'code' is not null)
      order by random()
      limit v_sec_req_count
    )
    loop
      insert into public.mock_examination_items (
        mock_exam_id,
        question_id,
        section_code,
        order_index,
        marks
      ) values (
        v_mock_id,
        v_q.id,
        v_sec_code,
        v_order,
        v_q.marks
      );

      v_order := v_order + 1;
      v_items_added := v_items_added + 1;
    end loop;
  end loop;

  return jsonb_build_object(
    'mock_exam_id', v_mock_id,
    'title', p_title,
    'total_marks', v_blueprint.total_marks,
    'duration_minutes', v_blueprint.duration_minutes,
    'items_count', v_items_added
  );
end;
$$;

grant execute on function public.generate_automated_mock_exam(uuid, text, integer) to authenticated;

-- ============================================================================
-- 7. RPC: start_learner_exam_attempt (Anti-Cheating Stripped Payload)
-- ============================================================================
create or replace function public.start_learner_exam_attempt(
  p_mock_exam_id uuid,
  p_learner_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid;
  v_mock record;
  v_attempt_id uuid;
  v_expires_at timestamptz;
  v_questions jsonb;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required to start examination attempt';
  end if;

  -- Verify learner belongs to authenticated parent/user
  if not (
    exists (
      select 1 from public.parent_learners pl
      where pl.learner_id = p_learner_id
        and pl.parent_user_id = v_uid
        and pl.relationship_status = 'active'
    )
    or exists (
      select 1 from public.learners l
      where l.id = p_learner_id and l.created_by_parent_user_id = v_uid
    )
    or public.has_role('super_admin')
  ) then
    raise exception 'Permission denied: Invalid learner profile';
  end if;

  select * into v_mock
  from public.generated_mock_examinations
  where id = p_mock_exam_id and status = 'published';

  if not found then
    raise exception 'Mock examination not found or inactive';
  end if;

  v_expires_at := now() + (v_mock.duration_minutes || ' minutes')::interval;

  insert into public.learner_exam_attempts (
    mock_exam_id,
    learner_id,
    user_id,
    status,
    started_at,
    duration_minutes,
    expires_at,
    total_possible_marks
  ) values (
    p_mock_exam_id,
    p_learner_id,
    v_uid,
    'in_progress',
    now(),
    v_mock.duration_minutes,
    v_expires_at,
    v_mock.total_marks
  )
  returning id into v_attempt_id;

  -- Build questions list, STRIPPING correct_answer and rubric_guide for integrity
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'item_id', mi.id,
        'question_id', q.id,
        'section_code', mi.section_code,
        'order_index', mi.order_index,
        'marks', mi.marks,
        'question_number', q.question_number,
        'sub_part', q.sub_part,
        'question_text', q.question_text,
        'diagram_url', q.diagram_url,
        'question_type', q.question_type,
        'options', (
          -- Strip is_correct flag from options during active attempt
          select jsonb_agg(
            jsonb_build_object(
              'key', opt->>'key',
              'text', opt->>'text'
            )
          )
          from jsonb_array_elements(q.options) opt
        ),
        'topic_id', q.topic_id,
        'bloom_level', q.bloom_level,
        'difficulty', q.difficulty
      ) order by mi.section_code, mi.order_index
    ),
    '[]'::jsonb
  ) into v_questions
  from public.mock_examination_items mi
  join public.exam_extracted_questions q on q.id = mi.question_id
  where mi.mock_exam_id = p_mock_exam_id;

  return jsonb_build_object(
    'attempt_id', v_attempt_id,
    'mock_exam_id', p_mock_exam_id,
    'title', v_mock.title,
    'duration_minutes', v_mock.duration_minutes,
    'started_at', now(),
    'expires_at', v_expires_at,
    'total_possible_marks', v_mock.total_marks,
    'questions', v_questions
  );
end;
$$;

grant execute on function public.start_learner_exam_attempt(uuid, uuid) to authenticated;

-- ============================================================================
-- 8. RPC: record_exam_response
-- ============================================================================
create or replace function public.record_exam_response(
  p_attempt_id uuid,
  p_question_id uuid,
  p_answer text default null,
  p_is_flagged boolean default false
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid;
  v_attempt record;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  select * into v_attempt
  from public.learner_exam_attempts
  where id = p_attempt_id;

  if not found then
    raise exception 'Examination attempt not found';
  end if;

  if v_attempt.user_id <> v_uid and not public.has_role('super_admin') then
    raise exception 'Access denied to this examination attempt';
  end if;

  if v_attempt.status <> 'in_progress' then
    raise exception 'Cannot record response: Attempt status is %', v_attempt.status;
  end if;

  -- Strict server-side time verification (+2 min grace period for network latency)
  if now() > (v_attempt.expires_at + interval '2 minutes') then
    update public.learner_exam_attempts
    set status = 'expired'
    where id = p_attempt_id;
    raise exception 'Examination time has expired';
  end if;

  insert into public.learner_exam_responses (
    attempt_id,
    question_id,
    learner_answer,
    is_flagged,
    answered_at
  ) values (
    p_attempt_id,
    p_question_id,
    p_answer,
    p_is_flagged,
    now()
  )
  on conflict (attempt_id, question_id)
  do update set
    learner_answer = excluded.learner_answer,
    is_flagged = excluded.is_flagged,
    answered_at = excluded.answered_at;

  return jsonb_build_object(
    'attempt_id', p_attempt_id,
    'question_id', p_question_id,
    'saved_at', now(),
    'is_flagged', p_is_flagged
  );
end;
$$;

grant execute on function public.record_exam_response(uuid, uuid, text, boolean) to authenticated;

-- ============================================================================
-- 9. RPC: get_learner_exam_attempt (Resume / State Sync)
-- ============================================================================
create or replace function public.get_learner_exam_attempt(p_attempt_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid;
  v_attempt record;
  v_mock record;
  v_questions jsonb;
  v_responses jsonb;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  select * into v_attempt
  from public.learner_exam_attempts
  where id = p_attempt_id;

  if not found then
    raise exception 'Attempt not found';
  end if;

  if v_attempt.user_id <> v_uid and not public.has_role('super_admin') then
    raise exception 'Permission denied';
  end if;

  select * into v_mock
  from public.generated_mock_examinations
  where id = v_attempt.mock_exam_id;

  -- Active responses
  select coalesce(
    jsonb_object_agg(
      r.question_id::text,
      jsonb_build_object(
        'learner_answer', r.learner_answer,
        'is_flagged', r.is_flagged,
        'answered_at', r.answered_at
      )
    ),
    '{}'::jsonb
  ) into v_responses
  from public.learner_exam_responses r
  where r.attempt_id = p_attempt_id;

  -- Questions (stripped of answers if in_progress)
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'item_id', mi.id,
        'question_id', q.id,
        'section_code', mi.section_code,
        'order_index', mi.order_index,
        'marks', mi.marks,
        'question_number', q.question_number,
        'sub_part', q.sub_part,
        'question_text', q.question_text,
        'diagram_url', q.diagram_url,
        'question_type', q.question_type,
        'options', (
          select jsonb_agg(
            jsonb_build_object(
              'key', opt->>'key',
              'text', opt->>'text'
            )
          )
          from jsonb_array_elements(q.options) opt
        ),
        'topic_id', q.topic_id,
        'bloom_level', q.bloom_level,
        'difficulty', q.difficulty
      ) order by mi.section_code, mi.order_index
    ),
    '[]'::jsonb
  ) into v_questions
  from public.mock_examination_items mi
  join public.exam_extracted_questions q on q.id = mi.question_id
  where mi.mock_exam_id = v_attempt.mock_exam_id;

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'mock_exam_id', v_attempt.mock_exam_id,
    'title', v_mock.title,
    'status', v_attempt.status,
    'started_at', v_attempt.started_at,
    'duration_minutes', v_attempt.duration_minutes,
    'expires_at', v_attempt.expires_at,
    'seconds_remaining', greatest(0, floor(extract(epoch from (v_attempt.expires_at - now())))::integer),
    'total_possible_marks', v_attempt.total_possible_marks,
    'questions', v_questions,
    'responses', v_responses
  );
end;
$$;

grant execute on function public.get_learner_exam_attempt(uuid) to authenticated;

-- ============================================================================
-- 10. Seed Official Blueprints & Pilot Generated Mock Exam
-- ============================================================================
insert into public.examination_blueprints (
  id,
  national_examination_id,
  subject_id,
  title,
  total_marks,
  duration_minutes,
  structure_config,
  is_active
) values (
  'b1000000-0000-0000-0000-000000000001',
  'TZ-CSEE',
  '30000000-0000-0000-0000-000000000102', -- Basic Mathematics
  'NECTA CSEE Basic Mathematics Standard Blueprint',
  100.0,
  180,
  '[
    {"code": "A", "name": "Section A", "question_count": 10, "marks_per_question": 6, "total_marks": 60},
    {"code": "B", "name": "Section B", "question_count": 4, "marks_per_question": 10, "total_marks": 40}
  ]'::jsonb,
  true
),
(
  'b1000000-0000-0000-0000-000000000002',
  'KE-KCSE',
  '30000000-0000-0000-0000-000000000103', -- Science/Chemistry
  'KNEC KCSE Chemistry Paper 1 Blueprint',
  80.0,
  120,
  '[
    {"code": "A", "name": "Theory Questions", "question_count": 28, "total_marks": 80}
  ]'::jsonb,
  true
)
on conflict (id) do nothing;

-- Seed Published Mock Examination
insert into public.generated_mock_examinations (
  id,
  blueprint_id,
  title,
  academic_year,
  total_marks,
  duration_minutes,
  status
) values (
  '60000000-0000-0000-0000-000000000001',
  'b1000000-0000-0000-0000-000000000001',
  'NECTA CSEE National Simulation Mock 2026 — Basic Mathematics',
  2026,
  100.0,
  180,
  'published'
)
on conflict (id) do nothing;

-- Populate mock examination items from approved seed questions
insert into public.mock_examination_items (
  id,
  mock_exam_id,
  question_id,
  section_code,
  order_index,
  marks
) values (
  '70000000-0000-0000-0000-000000000001',
  '60000000-0000-0000-0000-000000000001',
  '50000000-0000-0000-0000-000000000001', -- Section A Q1
  'A',
  1,
  6.0
),
(
  '70000000-0000-0000-0000-000000000002',
  '60000000-0000-0000-0000-000000000001',
  '50000000-0000-0000-0000-000000000002', -- Section A Q2
  'A',
  2,
  6.0
),
(
  '70000000-0000-0000-0000-000000000003',
  '60000000-0000-0000-0000-000000000001',
  '50000000-0000-0000-0000-000000000003', -- Section B Q11
  'B',
  1,
  10.0
)
on conflict (id) do nothing;

commit;
