-- LearnTZ Phase 4 — Examination and Mock Examination Intelligence Platform
-- Sub-Stage 2: Question Extraction, Classification & Approved Exam Bank
-- Tasks: TASK-404, TASK-405, TASK-406, TASK-407

begin;

-- ============================================================================
-- 1. Table: exam_extracted_questions
-- ============================================================================
create table if not exists public.exam_extracted_questions (
  id uuid primary key default gen_random_uuid(),
  paper_id uuid not null references public.examination_papers (id) on delete cascade,
  section_code text not null check (char_length(btrim(section_code)) between 1 and 20),
  question_number integer not null check (question_number between 1 and 200),
  sub_part text, -- e.g. '(a)', '(b)(i)'
  question_text text not null check (char_length(btrim(question_text)) >= 3),
  diagram_url text,
  question_type text not null default 'structured' check (
    question_type in ('multiple_choice', 'structured', 'essay', 'calculation')
  ),
  options jsonb not null default '[]'::jsonb,
  correct_answer text,
  rubric_guide jsonb not null default '[]'::jsonb,
  marks numeric not null check (marks > 0 and marks <= 100),
  subject_id uuid references public.subjects (id) on delete set null,
  topic_id uuid references public.topics (id) on delete set null,
  bloom_level text not null default 'comprehension' check (
    bloom_level in ('knowledge', 'comprehension', 'application', 'analysis', 'synthesis', 'evaluation')
  ),
  difficulty text not null default 'medium' check (
    difficulty in ('easy', 'medium', 'hard')
  ),
  verification_status text not null default 'draft' check (
    verification_status in ('draft', 'verified', 'approved', 'rejected')
  ),
  verified_by uuid references auth.users (id) on delete set null,
  approved_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chk_two_party_governance check (
    verified_by is null or approved_by is null or verified_by <> approved_by
  )
);

create index if not exists exam_extracted_questions_lookup_idx
  on public.exam_extracted_questions (paper_id, section_code, question_number);

create index if not exists exam_extracted_questions_topic_bloom_idx
  on public.exam_extracted_questions (subject_id, topic_id, bloom_level, difficulty, verification_status);

create trigger exam_extracted_questions_set_updated_at
  before update on public.exam_extracted_questions
  for each row execute function public.set_updated_at();

alter table public.exam_extracted_questions enable row level security;
revoke all on public.exam_extracted_questions from public, anon, authenticated;
grant select on public.exam_extracted_questions to anon, authenticated;
grant insert, update, delete on public.exam_extracted_questions to authenticated;

-- Policies: Approved questions readable by authenticated & anon learners
create policy "Anyone reads approved exam questions"
  on public.exam_extracted_questions for select
  using (
    verification_status = 'approved'
    or public.has_role('super_admin')
    or exists (
      select 1 from public.examination_papers ep
      where ep.id = exam_extracted_questions.paper_id
        and public.has_role('curriculum_admin', ep.country_code)
    )
  );

create policy "Staff manages extracted exam questions"
  on public.exam_extracted_questions for all to authenticated
  using (
    public.has_role('super_admin')
    or exists (
      select 1 from public.examination_papers ep
      where ep.id = exam_extracted_questions.paper_id
        and public.has_role('curriculum_admin', ep.country_code)
    )
  )
  with check (
    public.has_role('super_admin')
    or exists (
      select 1 from public.examination_papers ep
      where ep.id = exam_extracted_questions.paper_id
        and public.has_role('curriculum_admin', ep.country_code)
    )
  );

-- ============================================================================
-- 2. Table: exam_question_reviews
-- ============================================================================
create table if not exists public.exam_question_reviews (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.exam_extracted_questions (id) on delete cascade,
  reviewer_id uuid not null references auth.users (id) on delete cascade,
  decision text not null check (
    decision in ('verified', 'approved', 'rejected', 'changes_requested')
  ),
  notes text,
  reviewed_at timestamptz not null default now()
);

create index if not exists exam_question_reviews_idx
  on public.exam_question_reviews (question_id, reviewer_id, decision);

alter table public.exam_question_reviews enable row level security;
revoke all on public.exam_question_reviews from public, anon, authenticated;
grant select, insert on public.exam_question_reviews to authenticated;

create policy "Staff reads question reviews"
  on public.exam_question_reviews for select to authenticated
  using (
    reviewer_id = auth.uid()
    or public.has_role('super_admin')
    or public.has_role('curriculum_admin')
  );

create policy "Staff creates question reviews"
  on public.exam_question_reviews for insert to authenticated
  with check (
    reviewer_id = auth.uid()
    and (
      public.has_role('super_admin')
      or public.has_role('curriculum_admin')
    )
  );

-- ============================================================================
-- 3. RPC: register_extracted_exam_question
-- ============================================================================
create or replace function public.register_extracted_exam_question(
  p_paper_id uuid,
  p_section_code text,
  p_question_number integer,
  p_question_text text,
  p_marks numeric,
  p_sub_part text default null,
  p_diagram_url text default null,
  p_question_type text default 'structured',
  p_options jsonb default '[]'::jsonb,
  p_correct_answer text default null,
  p_rubric_guide jsonb default '[]'::jsonb,
  p_subject_id uuid default null,
  p_topic_id uuid default null,
  p_bloom_level text default 'comprehension',
  p_difficulty text default 'medium'
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_question_id uuid;
  v_result jsonb;
begin
  if not (
    public.has_role('super_admin')
    or exists (
      select 1 from public.user_roles
      where user_id = auth.uid()
        and role in ('curriculum_admin', 'content_admin')
    )
  ) then
    raise exception 'Permission denied: Curriculum staff authorization required';
  end if;

  insert into public.exam_extracted_questions (
    paper_id,
    section_code,
    question_number,
    sub_part,
    question_text,
    diagram_url,
    question_type,
    options,
    correct_answer,
    rubric_guide,
    marks,
    subject_id,
    topic_id,
    bloom_level,
    difficulty,
    verification_status
  ) values (
    p_paper_id,
    p_section_code,
    p_question_number,
    p_sub_part,
    p_question_text,
    p_diagram_url,
    p_question_type,
    p_options,
    p_correct_answer,
    p_rubric_guide,
    p_marks,
    p_subject_id,
    p_topic_id,
    p_bloom_level,
    p_difficulty,
    'draft'
  )
  returning id into v_question_id;

  select jsonb_build_object(
    'id', q.id,
    'paper_id', q.paper_id,
    'section_code', q.section_code,
    'question_number', q.question_number,
    'sub_part', q.sub_part,
    'question_text', q.question_text,
    'marks', q.marks,
    'verification_status', q.verification_status,
    'created_at', q.created_at
  ) into v_result
  from public.exam_extracted_questions q
  where q.id = v_question_id;

  return v_result;
end;
$$;

grant execute on function public.register_extracted_exam_question(
  uuid, text, integer, text, numeric, text, text, text, jsonb, text, jsonb, uuid, uuid, text, text
) to authenticated;

-- ============================================================================
-- 4. RPC: review_exam_question (Enforcing Two-Party Verification)
-- ============================================================================
create or replace function public.review_exam_question(
  p_question_id uuid,
  p_decision text,
  p_notes text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid;
  v_current record;
  v_new_status text;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  if not (
    public.has_role('super_admin')
    or exists (
      select 1 from public.user_roles
      where user_id = auth.uid()
        and role in ('curriculum_admin', 'content_admin')
    )
  ) then
    raise exception 'Curriculum reviewer privileges required';
  end if;

  select * into v_current
  from public.exam_extracted_questions
  where id = p_question_id;

  if not found then
    raise exception 'Exam question not found';
  end if;

  if p_decision = 'verified' then
    v_new_status := 'verified';
    update public.exam_extracted_questions
    set verification_status = v_new_status,
        verified_by = v_uid,
        updated_at = now()
    where id = p_question_id;

  elsif p_decision = 'approved' then
    -- Enforce two-party governance: approver cannot be the same person as the verifier
    if v_current.verified_by is not null and v_current.verified_by = v_uid and not public.has_role('super_admin') then
      raise exception 'Two-party governance violation: Question must be approved by a distinct staff member from the verifier.';
    end if;

    v_new_status := 'approved';
    update public.exam_extracted_questions
    set verification_status = v_new_status,
        approved_by = v_uid,
        updated_at = now()
    where id = p_question_id;

  elsif p_decision in ('rejected', 'changes_requested') then
    v_new_status := 'rejected';
    update public.exam_extracted_questions
    set verification_status = v_new_status,
        updated_at = now()
    where id = p_question_id;
  else
    raise exception 'Invalid review decision: %', p_decision;
  end if;

  -- Record in audit log of reviews
  insert into public.exam_question_reviews (
    question_id,
    reviewer_id,
    decision,
    notes
  ) values (
    p_question_id,
    v_uid,
    p_decision,
    p_notes
  );

  return jsonb_build_object(
    'question_id', p_question_id,
    'verification_status', v_new_status,
    'reviewer_id', v_uid,
    'decision', p_decision,
    'reviewed_at', now()
  );
end;
$$;

grant execute on function public.review_exam_question(uuid, text, text) to authenticated;

-- ============================================================================
-- 5. RPC: get_approved_exam_questions
-- ============================================================================
create or replace function public.get_approved_exam_questions(
  p_paper_id uuid default null,
  p_subject_id uuid default null,
  p_topic_id uuid default null,
  p_bloom_level text default null,
  p_difficulty text default null,
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_questions jsonb;
  v_total_count integer;
begin
  select count(*)
  into v_total_count
  from public.exam_extracted_questions q
  where (p_paper_id is null or q.paper_id = p_paper_id)
    and (p_subject_id is null or q.subject_id = p_subject_id)
    and (p_topic_id is null or q.topic_id = p_topic_id)
    and (p_bloom_level is null or q.bloom_level = p_bloom_level)
    and (p_difficulty is null or q.difficulty = p_difficulty)
    and (
      p_search is null
      or p_search = ''
      or q.question_text ilike '%' || p_search || '%'
    )
    and (
      q.verification_status = 'approved'
      or public.has_role('super_admin')
      or public.has_role('curriculum_admin')
    );

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', q.id,
        'paper_id', q.paper_id,
        'paper_title', ep.paper_title,
        'year', ep.year,
        'tier', ep.tier,
        'authority_id', ep.authority_id,
        'subject_name', ep.subject_name,
        'section_code', q.section_code,
        'question_number', q.question_number,
        'sub_part', q.sub_part,
        'question_text', q.question_text,
        'diagram_url', q.diagram_url,
        'question_type', q.question_type,
        'options', q.options,
        'correct_answer', q.correct_answer,
        'rubric_guide', q.rubric_guide,
        'marks', q.marks,
        'topic_id', q.topic_id,
        'topic_title', t.title,
        'bloom_level', q.bloom_level,
        'difficulty', q.difficulty,
        'verification_status', q.verification_status,
        'created_at', q.created_at
      ) order by q.section_code, q.question_number, q.created_at
    ),
    '[]'::jsonb
  ) into v_questions
  from (
    select q.*
    from public.exam_extracted_questions q
    where (p_paper_id is null or q.paper_id = p_paper_id)
      and (p_subject_id is null or q.subject_id = p_subject_id)
      and (p_topic_id is null or q.topic_id = p_topic_id)
      and (p_bloom_level is null or q.bloom_level = p_bloom_level)
      and (p_difficulty is null or q.difficulty = p_difficulty)
      and (
        p_search is null
        or p_search = ''
        or q.question_text ilike '%' || p_search || '%'
      )
      and (
        q.verification_status = 'approved'
        or public.has_role('super_admin')
        or public.has_role('curriculum_admin')
      )
    order by q.section_code, q.question_number, q.created_at
    limit coalesce(p_limit, 50)
    offset coalesce(p_offset, 0)
  ) q
  left join public.examination_papers ep on ep.id = q.paper_id
  left join public.topics t on t.id = q.topic_id;

  return jsonb_build_object(
    'questions', v_questions,
    'total_count', v_total_count,
    'limit', coalesce(p_limit, 50),
    'offset', coalesce(p_offset, 0)
  );
end;
$$;

grant execute on function public.get_approved_exam_questions(uuid, uuid, uuid, text, text, text, integer, integer) to anon, authenticated;

-- ============================================================================
-- 6. Seed Initial Approved Examination Questions (NECTA CSEE & KNEC KCSE)
-- ============================================================================

insert into public.exam_extracted_questions (
  id, paper_id, section_code, question_number, sub_part, question_text,
  question_type, options, correct_answer, rubric_guide, marks,
  subject_id, topic_id, bloom_level, difficulty, verification_status
) values
  -- Question 1: NECTA Math Section A (Numbers)
  (
    '50000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    'A',
    1,
    '(a)',
    'Evaluate 0.00357 x 0.021 correct to three significant figures.',
    'calculation',
    '[]'::jsonb,
    '0.0000750',
    '[{"step": "Multiply standard values: 3.57 x 10^-3 * 2.1 x 10^-2 = 7.497 x 10^-5", "marks": 2}, {"step": "Round to 3 significant figures: 7.50 x 10^-5 or 0.0000750", "marks": 1}]'::jsonb,
    3.0,
    '30000000-0000-0000-0000-000000000102',
    null,
    'application',
    'medium',
    'approved'
  ),
  -- Question 2: NECTA Math Section A (Sets)
  (
    '50000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000001',
    'A',
    1,
    '(b)',
    'In a class of 35 students, 20 study Physics and 18 study Chemistry. If 5 students study neither, find the number of students who study both subjects using a Venn diagram.',
    'structured',
    '[]'::jsonb,
    '8 students',
    '[{"step": "Set equation: 35 - 5 = 30 students study at least one", "marks": 1}, {"step": "n(P U C) = n(P) + n(C) - n(P n C) => 30 = 20 + 18 - x", "marks": 1}, {"step": "x = 38 - 30 = 8", "marks": 1}]'::jsonb,
    3.0,
    '30000000-0000-0000-0000-000000000102',
    null,
    'application',
    'medium',
    'approved'
  ),
  -- Question 3: NECTA Math Section A (Algebra)
  (
    '50000000-0000-0000-0000-000000000003',
    '40000000-0000-0000-0000-000000000001',
    'A',
    2,
    null,
    'Solve for x in the equation: 3^(2x - 1) = 27^(x - 2).',
    'calculation',
    '[]'::jsonb,
    'x = 5',
    '[{"step": "Express with common base 3: 27 = 3^3", "marks": 2}, {"step": "Equate exponents: 2x - 1 = 3(x - 2)", "marks": 2}, {"step": "Solve: 2x - 1 = 3x - 6 => x = 5", "marks": 2}]'::jsonb,
    6.0,
    '30000000-0000-0000-0000-000000000102',
    null,
    'analysis',
    'hard',
    'approved'
  ),
  -- Question 4: NECTA Math Section B (Trigonometry)
  (
    '50000000-0000-0000-0000-000000000004',
    '40000000-0000-0000-0000-000000000001',
    'B',
    11,
    null,
    'A vertical mast is supported by two cables anchored on opposite sides on level ground. The angles of elevation of the top of the mast from the anchor points are 40 degrees and 55 degrees respectively. If the distance between the two anchor points is 60 metres, calculate the height of the mast correct to two decimal places.',
    'structured',
    '[]'::jsonb,
    '24.58 m',
    '[{"step": "Sketch and identify right triangles: h = x tan(40) and h = (60 - x) tan(55)", "marks": 3}, {"step": "Equate expressions for h to solve for horizontal distance x", "marks": 4}, {"step": "Substitute to obtain h = 24.58 metres", "marks": 3}]'::jsonb,
    10.0,
    '30000000-0000-0000-0000-000000000102',
    null,
    'evaluation',
    'hard',
    'approved'
  ),
  -- Question 5: KNEC KCSE Chemistry MCQ
  (
    '50000000-0000-0000-0000-000000000005',
    '40000000-0000-0000-0000-000000000007',
    'A',
    1,
    null,
    'Which of the following oxides shows amphoteric properties?',
    'multiple_choice',
    '[{"key": "A", "text": "Sodium oxide (Na2O)", "is_correct": false}, {"key": "B", "text": "Aluminium oxide (Al2O3)", "is_correct": true}, {"key": "C", "text": "Sulphur dioxide (SO2)", "is_correct": false}, {"key": "D", "text": "Calcium oxide (CaO)", "is_correct": false}]'::jsonb,
    'B',
    '[{"step": "Recall that Al2O3 and ZnO react with both acids and bases to form salt and water", "marks": 2}]'::jsonb,
    2.0,
    null,
    null,
    'knowledge',
    'easy',
    'approved'
  )
on conflict (id) do update set
  question_text = excluded.question_text,
  correct_answer = excluded.correct_answer,
  rubric_guide = excluded.rubric_guide;

commit;
