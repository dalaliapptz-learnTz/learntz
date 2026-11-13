-- LearnTZ Phase 2 Migration: Interactive Lessons and Extended Question Bank
-- Sub-Stage 2 (Stages 2.3 & 2.4 / TASK-204 & TASK-205)

begin;

-- ============================================================================
-- 1. Extend lessons with rich interactive content blocks and summary
-- ============================================================================

alter table public.lessons
  add column if not exists content_blocks jsonb not null default '[]'::jsonb
    check (jsonb_typeof(content_blocks) = 'array'),
  add column if not exists summary text;

-- ============================================================================
-- 2. Question Bank & Extended Question Types
-- ============================================================================

create table if not exists public.question_bank (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries (country_code) on update cascade,
  curriculum_id uuid not null references public.curricula (id) on update cascade,
  subject_id uuid not null references public.subjects (id) on delete cascade,
  topic_id uuid not null references public.topics (id) on delete cascade,
  grade_id uuid references public.education_grades (id) on delete set null,
  lesson_id uuid references public.lessons (id) on delete set null,
  question_type text not null check (
    question_type in ('multiple_choice', 'true_false', 'fill_in_the_blank', 'matching', 'short_answer')
  ),
  difficulty_level text not null default 'medium' check (
    difficulty_level in ('easy', 'medium', 'hard')
  ),
  question_text text not null check (char_length(btrim(question_text)) between 1 and 2000),
  options jsonb,
  correct_answer jsonb not null,
  explanation text,
  cognitive_tier text default 'knowledge' check (
    cognitive_tier in ('knowledge', 'comprehension', 'application', 'analysis')
  ),
  display_order integer not null default 1,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists question_bank_topic_lookup_idx
  on public.question_bank (topic_id, is_published, question_type);

create index if not exists question_bank_lesson_idx
  on public.question_bank (lesson_id, is_published) where lesson_id is not null;

create trigger question_bank_set_updated_at
  before update on public.question_bank
  for each row execute function public.set_updated_at();

alter table public.question_bank enable row level security;
revoke all on public.question_bank from public, anon, authenticated;
grant select on public.question_bank to authenticated;
grant insert, update, delete on public.question_bank to authenticated;

create policy "Content admins manage question bank"
  on public.question_bank for all to authenticated
  using (
    public.has_role('super_admin')
    or public.has_role('content_admin', question_bank.country_code)
    or public.has_role('curriculum_admin', question_bank.country_code)
  )
  with check (
    public.has_role('super_admin')
    or public.has_role('content_admin', question_bank.country_code)
    or public.has_role('curriculum_admin', question_bank.country_code)
  );

-- ============================================================================
-- 3. Topic Mastery & Assessment Attempts
-- ============================================================================

create table if not exists public.learner_topic_mastery (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references public.learners (id) on delete cascade,
  topic_id uuid not null references public.topics (id) on delete cascade,
  mastery_status text not null default 'in_progress' check (
    mastery_status in ('in_progress', 'proficient', 'mastered')
  ),
  accuracy_rate numeric(5, 2) not null default 0.00 check (accuracy_rate between 0.00 and 100.00),
  quizzes_attempted integer not null default 0 check (quizzes_attempted >= 0),
  best_score_percent integer not null default 0 check (best_score_percent between 0 and 100),
  last_practiced_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (learner_id, topic_id)
);

create index if not exists learner_topic_mastery_learner_idx
  on public.learner_topic_mastery (learner_id, mastery_status);

create trigger learner_topic_mastery_set_updated_at
  before update on public.learner_topic_mastery
  for each row execute function public.set_updated_at();

alter table public.learner_topic_mastery enable row level security;
revoke all on public.learner_topic_mastery from public, anon, authenticated;
grant select on public.learner_topic_mastery to authenticated;

create policy "Parents read own learner topic mastery"
  on public.learner_topic_mastery for select to authenticated
  using (
    public.is_authorized_learner_parent(learner_topic_mastery.learner_id)
    or public.has_role('super_admin')
  );

create table if not exists public.learner_assessment_attempts (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references public.learners (id) on delete cascade,
  topic_id uuid references public.topics (id) on delete set null,
  lesson_id uuid references public.lessons (id) on delete set null,
  score_percent integer not null check (score_percent between 0 and 100),
  total_questions integer not null check (total_questions > 0),
  correct_count integer not null check (correct_count >= 0),
  passed boolean not null default false,
  results_detail jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists learner_assessment_attempts_learner_idx
  on public.learner_assessment_attempts (learner_id, topic_id, created_at desc);

alter table public.learner_assessment_attempts enable row level security;
revoke all on public.learner_assessment_attempts from public, anon, authenticated;
grant select on public.learner_assessment_attempts to authenticated;

create policy "Parents read learner assessment attempts"
  on public.learner_assessment_attempts for select to authenticated
  using (
    public.is_authorized_learner_parent(learner_assessment_attempts.learner_id)
    or public.has_role('super_admin')
  );

-- ============================================================================
-- 4. Interactive Learning Engine RPCs
-- ============================================================================

-- A) Secure interactive lesson fetch (includes blocks with markdown fallback)
create or replace function public.get_lesson_interactive_content(
  p_lesson_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lesson record;
  v_blocks jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if not public.can_access_learning_lesson(p_lesson_id) then
    raise exception 'Lesson subscription or preview access is required' using errcode = '42501';
  end if;

  select * into v_lesson
  from public.lessons
  where id = p_lesson_id
    and is_published;

  if not found then
    raise exception 'Lesson not found or not published' using errcode = '22023';
  end if;

  if v_lesson.content_blocks is null or jsonb_array_length(v_lesson.content_blocks) = 0 then
    v_blocks := jsonb_build_array(
      jsonb_build_object(
        'type', 'markdown',
        'body', v_lesson.body_markdown
      )
    );
  else
    v_blocks := v_lesson.content_blocks;
  end if;

  return jsonb_build_object(
    'id', v_lesson.id,
    'topic_id', v_lesson.topic_id,
    'title', v_lesson.title,
    'summary', v_lesson.summary,
    'estimated_minutes', v_lesson.estimated_minutes,
    'is_free_preview', v_lesson.is_free_preview,
    'body_markdown', v_lesson.body_markdown,
    'content_blocks', v_blocks
  );
end;
$$;

revoke all on function public.get_lesson_interactive_content(uuid) from public, anon;
grant execute on function public.get_lesson_interactive_content(uuid) to authenticated;

-- B) Fetch sanitized practice questions for a topic (Answers omitted for security)
create or replace function public.get_topic_assessment_questions(
  p_topic_id uuid,
  p_limit integer default 10
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_questions jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

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
    select *
    from public.question_bank
    where topic_id = p_topic_id
      and is_published
    order by display_order, created_at
    limit least(greatest(1, coalesce(p_limit, 10)), 50)
  ) q;

  return v_questions;
end;
$$;

revoke all on function public.get_topic_assessment_questions(uuid, integer) from public, anon;
grant execute on function public.get_topic_assessment_questions(uuid, integer) to authenticated;

-- C) Server-side auto-grading for all 5 question types
create or replace function public.submit_assessment_attempt(
  p_learner_id uuid,
  p_topic_id uuid,
  p_answers jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_total integer;
  v_correct integer := 0;
  v_score_percent integer;
  v_passed boolean;
  v_results jsonb := '[]'::jsonb;
  v_item jsonb;
  v_q_id uuid;
  v_ans jsonb;
  v_q record;
  v_is_correct boolean;
  v_ans_str text;
  v_expected_str text;
  v_pair record;
  v_match_all boolean;
  v_mastery text;
  v_quizzes_att integer;
  v_new_accuracy numeric(5, 2);
  v_best_score integer;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Authorized parent access is required for this learner' using errcode = '42501';
  end if;

  if p_answers is null or jsonb_typeof(p_answers) <> 'array' or jsonb_array_length(p_answers) = 0 then
    raise exception 'Answers array is required and cannot be empty' using errcode = '22023';
  end if;

  v_total := jsonb_array_length(p_answers);

  for v_item in select * from jsonb_array_elements(p_answers) loop
    v_q_id := (v_item ->> 'question_id')::uuid;
    v_ans := v_item -> 'answer';

    select * into v_q
    from public.question_bank
    where id = v_q_id and is_published;

    if not found then
      raise exception 'Question % not found or not published', v_q_id using errcode = '22023';
    end if;

    v_is_correct := false;

    case v_q.question_type
      when 'multiple_choice' then
        if jsonb_typeof(v_ans) = 'number' and jsonb_typeof(v_q.correct_answer) = 'number' then
          v_is_correct := (v_ans::int = v_q.correct_answer::int);
        else
          v_is_correct := (btrim(v_ans::text, '" ') = btrim(v_q.correct_answer::text, '" '));
        end if;

      when 'true_false' then
        if jsonb_typeof(v_ans) = 'boolean' and jsonb_typeof(v_q.correct_answer) = 'boolean' then
          v_is_correct := (v_ans::boolean = v_q.correct_answer::boolean);
        else
          v_ans_str := lower(btrim(v_ans::text, '" '));
          v_expected_str := lower(btrim(v_q.correct_answer::text, '" '));
          v_is_correct := (
            v_ans_str = v_expected_str or
            (v_ans_str in ('true', 'kweli', 't', 'yes') and v_expected_str in ('true', 'kweli', 't', 'yes')) or
            (v_ans_str in ('false', 'si kweli', 'f', 'no') and v_expected_str in ('false', 'si kweli', 'f', 'no'))
          );
        end if;

      when 'fill_in_the_blank', 'short_answer' then
        v_ans_str := lower(regexp_replace(btrim(v_ans::text, '" '), '\s+', ' ', 'g'));
        if jsonb_typeof(v_q.correct_answer) = 'array' then
          v_is_correct := exists (
            select 1
            from jsonb_array_elements_text(v_q.correct_answer) expected_alt
            where lower(regexp_replace(btrim(expected_alt), '\s+', ' ', 'g')) = v_ans_str
          );
        else
          v_expected_str := lower(regexp_replace(btrim(v_q.correct_answer::text, '" '), '\s+', ' ', 'g'));
          v_is_correct := (v_ans_str = v_expected_str);
        end if;

      when 'matching' then
        if jsonb_typeof(v_ans) = 'object' and jsonb_typeof(v_q.correct_answer) = 'object' then
          v_match_all := true;
          for v_pair in select key, value from jsonb_each_text(v_q.correct_answer) loop
            if (v_ans ->> v_pair.key) is distinct from v_pair.value then
              v_match_all := false;
            end if;
          end loop;
          v_is_correct := v_match_all;
        else
          v_is_correct := false;
        end if;

      else
        v_is_correct := false;
    end case;

    if v_is_correct then
      v_correct := v_correct + 1;
    end if;

    v_results := v_results || jsonb_build_object(
      'question_id', v_q.id,
      'question_type', v_q.question_type,
      'is_correct', v_is_correct,
      'user_answer', v_ans,
      'correct_answer', v_q.correct_answer,
      'explanation', coalesce(v_q.explanation, '')
    );
  end loop;

  v_score_percent := round((v_correct::numeric * 100.0) / v_total)::integer;
  v_passed := v_score_percent >= 70;

  -- 1. Insert assessment attempt record
  insert into public.learner_assessment_attempts (
    learner_id, topic_id, score_percent, total_questions, correct_count, passed, results_detail
  ) values (
    p_learner_id, p_topic_id, v_score_percent, v_total, v_correct, v_passed, v_results
  );

  -- 2. Upsert learner_topic_mastery
  insert into public.learner_topic_mastery (
    learner_id, topic_id, mastery_status, accuracy_rate, quizzes_attempted, best_score_percent, last_practiced_at
  ) values (
    p_learner_id,
    p_topic_id,
    case
      when v_score_percent >= 60 then 'proficient'
      else 'in_progress'
    end,
    v_score_percent::numeric(5, 2),
    1,
    v_score_percent,
    now()
  )
  on conflict (learner_id, topic_id) do update
  set quizzes_attempted = public.learner_topic_mastery.quizzes_attempted + 1,
      accuracy_rate = round(
        ((public.learner_topic_mastery.accuracy_rate * public.learner_topic_mastery.quizzes_attempted) + v_score_percent) /
        (public.learner_topic_mastery.quizzes_attempted + 1),
        2
      ),
      best_score_percent = greatest(public.learner_topic_mastery.best_score_percent, v_score_percent),
      mastery_status = case
        when greatest(public.learner_topic_mastery.best_score_percent, v_score_percent) >= 85
             and (public.learner_topic_mastery.quizzes_attempted + 1) >= 2 then 'mastered'
        when greatest(public.learner_topic_mastery.best_score_percent, v_score_percent) >= 60 then 'proficient'
        else 'in_progress'
      end,
      last_practiced_at = now(),
      updated_at = now()
  returning mastery_status into v_mastery;

  return jsonb_build_object(
    'score_percent', v_score_percent,
    'passed', v_passed,
    'total_questions', v_total,
    'correct_count', v_correct,
    'mastery_status', v_mastery,
    'results', v_results
  );
end;
$$;

revoke all on function public.submit_assessment_attempt(uuid, uuid, jsonb) from public, anon;
grant execute on function public.submit_assessment_attempt(uuid, uuid, jsonb) to authenticated;

-- ============================================================================
-- 5. Seed rich interactive lesson content and question bank
-- ============================================================================

-- A) Seed rich interactive blocks for lesson 'Sauti za Irabu na Silabi Sahili'
update public.lessons
set summary = 'Jifunze irabu tano za Kiswahili (a, e, i, o, u) na jinsi ya kuunda silabi sahili kwa kuunganisha konsonanti na irabu.',
    content_blocks = '[
      {
        "type": "markdown",
        "body": "## Utangulizi wa Irabu\n\nKatika lugha ya Kiswahili, **irabu** ni sauti za msingi zinazotamkwa bila kizuizi cha hewa kinywani.\nKuna irabu tano kuu ambazo ni msingi wa maneno yote ya Kiswahili: **a, e, i, o, u**."
      },
      {
        "type": "callout",
        "style": "tip",
        "title": "Kumbuka Muhimu",
        "content": "Kila neno la Kiswahili lazima liwe na irabu! Hakuna neno la Kiswahili linaloweza kutamkwa bila irabu."
      },
      {
        "type": "definition",
        "term": "Silabi Sahili",
        "pronunciation": "/si.la.bi/",
        "definition": "Kipashio cha kifonolojia kinachoundwa kwa kuunganisha konsonanti moja na irabu moja (kwa mfano: ba, me, ki, lo, tu).",
        "example": "Konsonanti m + Irabu a = ma"
      },
      {
        "type": "example",
        "title": "Mfano wa Kuunda Silabi",
        "problem": "Unganisha herufi zifuatazo kuunda silabi: b + a, k + i, t + o.",
        "steps": [
          "Hatua 1: Tamka sauti ya konsonanti /b/ kisha ongeza sauti ya irabu /a/ -> unapata silabi \"ba\".",
          "Hatua 2: Tamka sauti ya /k/ kisha ongeza /i/ -> unapata \"ki\".",
          "Hatua 3: Tamka sauti ya /t/ kisha ongeza /o/ -> unapata \"to\"."
        ],
        "takeaway": "Kuunganisha silabi huunda maneno: ba + ta = bata; ki + ti = kiti."
      },
      {
        "type": "checkpoint",
        "question": "Ni irabu gani ikiongezwa kwenye konsonanti \"k\" inaunda silabi \"ku\"?",
        "options": ["a", "u", "o", "i"],
        "correct_index": 1,
        "explanation": "Herufi \"u\" ikiongezwa kwenye \"k\" inaunda silabi \"ku\" (k + u = ku)."
      }
    ]'::jsonb
where id = '30000000-0000-0000-0000-000000000301';

-- B) Seed rich interactive blocks for lesson 'Matendo ya Namba Katika Maisha ya Kila Siku'
update public.lessons
set summary = 'Kujifunza kujumlisha na kutoa namba katika maisha ya kila siku sokoni na nyumbani.',
    content_blocks = '[
      {
        "type": "markdown",
        "body": "## Hesabu za Kujumlisha na Kutoa\n\nKatika maisha ya kila siku, tunatumia namba kuhesabu vitu kama matunda, kalamu, fedha na muda."
      },
      {
        "type": "definition",
        "term": "Kujumlisha (+)",
        "definition": "Kuweka makundi mawili au zaidi ya vitu pamoja ili kupata idadi ya jumla kuu.",
        "example": "Machungwa 5 ukiongeza machungwa 3 = machungwa 8."
      },
      {
        "type": "example",
        "title": "Mfano wa Kununua Matunda Sokoni",
        "problem": "Amani alinunua maembe 12. Alipofika nyumbani, mdogo wake alikula maembe 4. Je, Amani alibakiwa na maembe mangapi?",
        "steps": [
          "Hesabu idadi ya awali ya maembe: 12",
          "Tambua tendo linalohitajika: Alikula 4 ina maana ya KUTOA (-)",
          "Kokotoa: 12 - 4 = 8"
        ],
        "takeaway": "Amani amebakiwa na maembe 8."
      },
      {
        "type": "callout",
        "style": "note",
        "title": "Kipimo cha Hisabati",
        "content": "Kumbuka kuthibitisha jibu lako kwa kurudia: 8 + 4 = 12."
      },
      {
        "type": "checkpoint",
        "question": "15 jumlisha 7 ni sawa na ngapi?",
        "options": ["20", "21", "22", "23"],
        "correct_index": 2,
        "explanation": "15 + 7 = 22."
      }
    ]'::jsonb
where id = '30000000-0000-0000-0000-000000000302';

-- C) Seed Question Bank questions covering all 5 question types for Topic 1: Kiswahili (30000000-0000-0000-0000-000000000201)
insert into public.question_bank (
  id, country_code, curriculum_id, subject_id, topic_id, grade_id, lesson_id,
  question_type, difficulty_level, question_text, options, correct_answer, explanation, cognitive_tier, display_order
) values
  -- 1. Multiple Choice
  (
    '40000000-0000-0000-0000-000000000101',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000101',
    '30000000-0000-0000-0000-000000000201',
    (select id from public.education_grades where code = 'STANDARD_1' limit 1),
    '30000000-0000-0000-0000-000000000301',
    'multiple_choice',
    'easy',
    'Kati ya herufi zifuatazo, ni ipi SI irabu ya Kiswahili?',
    '["a", "b", "e", "o"]'::jsonb,
    '1'::jsonb,
    '"b" ni konsonanti, si irabu. Irabu za Kiswahili ni a, e, i, o, u.',
    'knowledge',
    1
  ),
  -- 2. True / False
  (
    '40000000-0000-0000-0000-000000000102',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000101',
    '30000000-0000-0000-0000-000000000201',
    (select id from public.education_grades where code = 'STANDARD_1' limit 1),
    '30000000-0000-0000-0000-000000000301',
    'true_false',
    'easy',
    'Katika lugha ya Kiswahili, kuna irabu tano za msingi ambazo ni a, e, i, o, u.',
    '["Kweli", "Si Kweli"]'::jsonb,
    'true'::jsonb,
    'Ni kweli kabisa, irabu za Kiswahili ni tano: a, e, i, o, na u.',
    'knowledge',
    2
  ),
  -- 3. Fill in the Blank
  (
    '40000000-0000-0000-0000-000000000103',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000101',
    '30000000-0000-0000-0000-000000000201',
    (select id from public.education_grades where code = 'STANDARD_1' limit 1),
    '30000000-0000-0000-0000-000000000301',
    'fill_in_the_blank',
    'medium',
    'Silabi inayotokana na kuunganisha konsonanti "b" na irabu "a" inaitwa ___.',
    null,
    '["ba"]'::jsonb,
    'b + a huunda silabi "ba".',
    'comprehension',
    3
  ),
  -- 4. Matching
  (
    '40000000-0000-0000-0000-000000000104',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000101',
    '30000000-0000-0000-0000-000000000201',
    (select id from public.education_grades where code = 'STANDARD_1' limit 1),
    '30000000-0000-0000-0000-000000000301',
    'matching',
    'medium',
    'Oanisha konsonanti na neno sahihi linaloanza nayo:',
    '{
      "premises": [
        {"id": "p1", "text": "m"},
        {"id": "p2", "text": "b"},
        {"id": "p3", "text": "k"}
      ],
      "responses": [
        {"id": "r1", "text": "mama"},
        {"id": "r2", "text": "baba"},
        {"id": "r3", "text": "kiti"}
      ]
    }'::jsonb,
    '{"p1": "r1", "p2": "r2", "p3": "r3"}'::jsonb,
    'm huanza mama, b huanza baba, na k huanza kiti.',
    'application',
    4
  ),
  -- 5. Short Answer
  (
    '40000000-0000-0000-0000-000000000105',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000101',
    '30000000-0000-0000-0000-000000000201',
    (select id from public.education_grades where code = 'STANDARD_1' limit 1),
    '30000000-0000-0000-0000-000000000301',
    'short_answer',
    'easy',
    'Taja jina la mzazi wa kike katika lugha ya Kiswahili:',
    null,
    '["mama"]'::jsonb,
    'Mzazi wa kike anaitwa "mama".',
    'knowledge',
    5
  );

-- D) Seed Question Bank questions covering all 5 question types for Topic 2: Hisabati (30000000-0000-0000-0000-000000000202)
insert into public.question_bank (
  id, country_code, curriculum_id, subject_id, topic_id, grade_id, lesson_id,
  question_type, difficulty_level, question_text, options, correct_answer, explanation, cognitive_tier, display_order
) values
  -- 1. Multiple Choice
  (
    '40000000-0000-0000-0000-000000000201',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000102',
    '30000000-0000-0000-0000-000000000202',
    (select id from public.education_grades where code = 'STANDARD_1' limit 1),
    '30000000-0000-0000-0000-000000000302',
    'multiple_choice',
    'easy',
    'Juma ana machungwa 15, akala machungwa 4. Je, amebakiwa na machungwa mangapi?',
    '["9", "11", "19", "12"]'::jsonb,
    '1'::jsonb,
    '15 - 4 = 11.',
    'application',
    1
  ),
  -- 2. True / False
  (
    '40000000-0000-0000-0000-000000000202',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000102',
    '30000000-0000-0000-0000-000000000202',
    (select id from public.education_grades where code = 'STANDARD_1' limit 1),
    '30000000-0000-0000-0000-000000000302',
    'true_false',
    'easy',
    'Jumla ya 25 na 15 ni sawa na 40.',
    '["Kweli", "Si Kweli"]'::jsonb,
    'true'::jsonb,
    '25 + 15 = 40, kwa hivyo ni Kweli.',
    'knowledge',
    2
  ),
  -- 3. Fill in the Blank
  (
    '40000000-0000-0000-0000-000000000203',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000102',
    '30000000-0000-0000-0000-000000000202',
    (select id from public.education_grades where code = 'STANDARD_1' limit 1),
    '30000000-0000-0000-0000-000000000302',
    'fill_in_the_blank',
    'medium',
    'Kamilisha mlinganyo: 12 + ___ = 20.',
    null,
    '["8"]'::jsonb,
    '20 - 12 = 8, kwa hivyo namba inayokosekana ni 8.',
    'comprehension',
    3
  ),
  -- 4. Matching
  (
    '40000000-0000-0000-0000-000000000204',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000102',
    '30000000-0000-0000-0000-000000000202',
    (select id from public.education_grades where code = 'STANDARD_1' limit 1),
    '30000000-0000-0000-0000-000000000302',
    'matching',
    'medium',
    'Oanisha matendo ya hisabati na majibu yake:',
    '{
      "premises": [
        {"id": "p1", "text": "10 + 10"},
        {"id": "p2", "text": "50 - 20"},
        {"id": "p3", "text": "4 x 5"}
      ],
      "responses": [
        {"id": "r1", "text": "20"},
        {"id": "r2", "text": "30"},
        {"id": "r3", "text": "20"}
      ]
    }'::jsonb,
    '{"p1": "r1", "p2": "r2", "p3": "r3"}'::jsonb,
    '10 + 10 = 20, 50 - 20 = 30, na 4 x 5 = 20.',
    'application',
    4
  ),
  -- 5. Short Answer
  (
    '40000000-0000-0000-0000-000000000205',
    'TZ',
    '20000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000102',
    '30000000-0000-0000-0000-000000000202',
    (select id from public.education_grades where code = 'STANDARD_1' limit 1),
    '30000000-0000-0000-0000-000000000302',
    'short_answer',
    'easy',
    'Taja jina la tendo la hisabati linalopunguza idadi ya vitu kutoka kwenye jumla kuu:',
    null,
    '["kutoa", "utoaji"]'::jsonb,
    'Tendo la kupunguza idadi huitwa kutoa (utoaji).',
    'knowledge',
    5
  );

commit;
