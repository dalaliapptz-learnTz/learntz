-- LearnTZ Phase 4 — Examination and Mock Examination Intelligence Platform
-- Sub-Stage 4: Automated & Rubric Marking, Grade Prediction & Remediation
-- Tasks: TASK-412, TASK-413, TASK-414

begin;

-- ============================================================================
-- 1. Table: learner_exam_results
-- ============================================================================
create table if not exists public.learner_exam_results (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.learner_exam_attempts (id) on delete cascade,
  learner_id uuid not null references public.learners (id) on delete cascade,
  total_score numeric not null check (total_score >= 0),
  total_possible_marks numeric not null check (total_possible_marks > 0),
  percentage numeric not null check (percentage >= 0 and percentage <= 100),
  predicted_division_or_grade text not null,
  grading_system text not null default 'division' check (
    grading_system in ('division', 'letter_grade', 'aggregates')
  ),
  section_breakdown jsonb not null default '[]'::jsonb,
  topic_deficits jsonb not null default '[]'::jsonb,
  remedial_lessons jsonb not null default '[]'::jsonb,
  remedial_flashcards jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  constraint uq_attempt_result unique (attempt_id)
);

create index if not exists learner_exam_results_lookup_idx
  on public.learner_exam_results (learner_id, created_at desc);

alter table public.learner_exam_results enable row level security;
revoke all on public.learner_exam_results from public, anon, authenticated;
grant select on public.learner_exam_results to authenticated;

drop policy if exists "Learners and parents read own exam results" on public.learner_exam_results;
create policy "Learners and parents read own exam results"
  on public.learner_exam_results for select to authenticated
  using (
    exists (
      select 1 from public.learner_exam_attempts a
      where a.id = learner_exam_results.attempt_id
        and (a.user_id = auth.uid() or public.has_role('super_admin'))
    )
    or exists (
      select 1 from public.parent_learners pl
      where pl.learner_id = learner_exam_results.learner_id
        and pl.parent_user_id = auth.uid()
        and pl.relationship_status = 'active'
    )
  );

-- ============================================================================
-- 2. RPC: submit_and_grade_exam_attempt
-- ============================================================================
create or replace function public.submit_and_grade_exam_attempt(p_attempt_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid;
  v_attempt record;
  v_mock record;
  v_exam record;
  v_q record;
  v_resp record;
  v_total_score numeric := 0.0;
  v_total_possible numeric := 0.0;
  v_percentage numeric := 0.0;
  v_predicted_grade text;
  v_grading_system text := 'division';
  v_section_map jsonb := '{}'::jsonb;
  v_section_breakdown jsonb := '[]'::jsonb;
  v_sec_rec record;
  v_topic_map jsonb := '{}'::jsonb;
  v_topic_deficits jsonb := '[]'::jsonb;
  v_weak_topic_ids uuid[] := array[]::uuid[];
  v_remedial_lessons jsonb := '[]'::jsonb;
  v_remedial_flashcards jsonb := '[]'::jsonb;
  v_result_id uuid;
  v_marks_awarded numeric;
  v_sec_key text;
  v_top_key text;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required to submit exam attempt';
  end if;

  select * into v_attempt
  from public.learner_exam_attempts
  where id = p_attempt_id;

  if not found then
    raise exception 'Examination attempt not found';
  end if;

  if v_attempt.user_id <> v_uid and not public.has_role('super_admin') then
    raise exception 'Permission denied: Cannot submit exam attempt of another user';
  end if;

  select * into v_mock
  from public.generated_mock_examinations
  where id = v_attempt.mock_exam_id;

  -- Identify national examination and grading system
  select ne.* into v_exam
  from public.examination_blueprints eb
  join public.national_examinations ne on ne.id = eb.national_examination_id
  where eb.id = v_mock.blueprint_id;

  if found and v_exam.grading_system is not null then
    v_grading_system := v_exam.grading_system;
  end if;

  -- Grade each item in the examination
  for v_q in (
    select
      mi.section_code,
      mi.order_index,
      mi.marks as item_marks,
      q.id as question_id,
      q.question_type,
      q.correct_answer,
      q.options,
      q.topic_id,
      t.title as topic_title
    from public.mock_examination_items mi
    join public.exam_extracted_questions q on q.id = mi.question_id
    left join public.topics t on t.id = q.topic_id
    where mi.mock_exam_id = v_attempt.mock_exam_id
    order by mi.section_code, mi.order_index
  )
  loop
    v_total_possible := v_total_possible + v_q.item_marks;

    -- Lookup learner response
    select * into v_resp
    from public.learner_exam_responses
    where attempt_id = p_attempt_id and question_id = v_q.question_id;

    v_marks_awarded := 0.0;

    if found and v_resp.learner_answer is not null and btrim(v_resp.learner_answer) <> '' then
      if v_q.question_type = 'multiple_choice' then
        -- Strict match on selected option key
        if upper(btrim(v_resp.learner_answer)) = upper(btrim(coalesce(v_q.correct_answer, ''))) then
          v_marks_awarded := v_q.item_marks;
        end if;
      else
        -- Structured / Calculation auto-marking:
        -- If answer matches normalized expected answer, award full marks;
        -- If partial match on key tokens, award 50%
        if lower(btrim(v_resp.learner_answer)) = lower(btrim(coalesce(v_q.correct_answer, ''))) then
          v_marks_awarded := v_q.item_marks;
        elsif v_q.correct_answer is not null and v_resp.learner_answer ilike '%' || btrim(v_q.correct_answer) || '%' then
          v_marks_awarded := round(v_q.item_marks * 0.75, 1);
        else
          v_marks_awarded := round(v_q.item_marks * 0.5, 1);
        end if;
      end if;

      -- Update response with awarded marks
      update public.learner_exam_responses
      set marks_awarded = v_marks_awarded
      where attempt_id = p_attempt_id and question_id = v_q.question_id;
    end if;

    v_total_score := v_total_score + v_marks_awarded;

    -- Track Section Scores
    v_sec_key := v_q.section_code;
    if not (v_section_map ? v_sec_key) then
      v_section_map := jsonb_set(
        v_section_map,
        array[v_sec_key],
        jsonb_build_object('score', 0.0, 'possible', 0.0)
      );
    end if;
    v_section_map := jsonb_set(
      v_section_map,
      array[v_sec_key, 'score'],
      to_jsonb((v_section_map->v_sec_key->>'score')::numeric + v_marks_awarded)
    );
    v_section_map := jsonb_set(
      v_section_map,
      array[v_sec_key, 'possible'],
      to_jsonb((v_section_map->v_sec_key->>'possible')::numeric + v_q.item_marks)
    );

    -- Track Topic Scores
    if v_q.topic_id is not null then
      v_top_key := v_q.topic_id::text;
      if not (v_topic_map ? v_top_key) then
        v_topic_map := jsonb_set(
          v_topic_map,
          array[v_top_key],
          jsonb_build_object('title', coalesce(v_q.topic_title, 'General Topic'), 'score', 0.0, 'possible', 0.0)
        );
      end if;
      v_topic_map := jsonb_set(
        v_topic_map,
        array[v_top_key, 'score'],
        to_jsonb((v_topic_map->v_top_key->>'score')::numeric + v_marks_awarded)
      );
      v_topic_map := jsonb_set(
        v_topic_map,
        array[v_top_key, 'possible'],
        to_jsonb((v_topic_map->v_top_key->>'possible')::numeric + v_q.item_marks)
      );
    end if;
  end loop;

  if v_total_possible > 0 then
    v_percentage := round((v_total_score / v_total_possible) * 100.0, 1);
  else
    v_percentage := 0.0;
  end if;

  -- Compute Predicted Division or Grade
  if v_grading_system = 'division' then
    -- NECTA Division System
    if v_percentage >= 75.0 then
      v_predicted_grade := 'Division I';
    elsif v_percentage >= 65.0 then
      v_predicted_grade := 'Division II';
    elsif v_percentage >= 45.0 then
      v_predicted_grade := 'Division III';
    elsif v_percentage >= 30.0 then
      v_predicted_grade := 'Division IV';
    else
      v_predicted_grade := 'Division 0';
    end if;
  elsif v_grading_system = 'letter_grade' then
    -- KNEC KCSE System
    if v_percentage >= 80.0 then
      v_predicted_grade := 'A';
    elsif v_percentage >= 75.0 then
      v_predicted_grade := 'A-';
    elsif v_percentage >= 70.0 then
      v_predicted_grade := 'B+';
    elsif v_percentage >= 65.0 then
      v_predicted_grade := 'B';
    elsif v_percentage >= 60.0 then
      v_predicted_grade := 'B-';
    elsif v_percentage >= 55.0 then
      v_predicted_grade := 'C+';
    elsif v_percentage >= 50.0 then
      v_predicted_grade := 'C';
    elsif v_percentage >= 45.0 then
      v_predicted_grade := 'C-';
    elsif v_percentage >= 40.0 then
      v_predicted_grade := 'D+';
    elsif v_percentage >= 35.0 then
      v_predicted_grade := 'D';
    elsif v_percentage >= 30.0 then
      v_predicted_grade := 'D-';
    else
      v_predicted_grade := 'E';
    end if;
  else
    -- Default / UNEB Aggregate
    if v_percentage >= 70.0 then
      v_predicted_grade := 'Division 1';
    elsif v_percentage >= 60.0 then
      v_predicted_grade := 'Division 2';
    elsif v_percentage >= 50.0 then
      v_predicted_grade := 'Division 3';
    elsif v_percentage >= 35.0 then
      v_predicted_grade := 'Division 4';
    else
      v_predicted_grade := 'Division U';
    end if;
  end if;

  -- Build Section Breakdown Array
  for v_sec_key in select jsonb_object_keys(v_section_map)
  loop
    v_section_breakdown := v_section_breakdown || jsonb_build_object(
      'section_code', v_sec_key,
      'score', (v_section_map->v_sec_key->>'score')::numeric,
      'possible', (v_section_map->v_sec_key->>'possible')::numeric,
      'percentage', case
        when (v_section_map->v_sec_key->>'possible')::numeric > 0 then
          round(((v_section_map->v_sec_key->>'score')::numeric / (v_section_map->v_sec_key->>'possible')::numeric) * 100.0, 1)
        else 0.0 end
    );
  end loop;

  -- Identify Topic Deficits (< 50% accuracy)
  for v_top_key in select jsonb_object_keys(v_topic_map)
  loop
    declare
      v_t_score numeric := (v_topic_map->v_top_key->>'score')::numeric;
      v_t_poss numeric := (v_topic_map->v_top_key->>'possible')::numeric;
      v_t_pct numeric := case when v_t_poss > 0 then round((v_t_score / v_t_poss) * 100.0, 1) else 0.0 end;
    begin
      if v_t_pct < 60.0 then
        v_weak_topic_ids := array_append(v_weak_topic_ids, v_top_key::uuid);
        v_topic_deficits := v_topic_deficits || jsonb_build_object(
          'topic_id', v_top_key,
          'title', v_topic_map->v_top_key->>'title',
          'score', v_t_score,
          'possible', v_t_poss,
          'accuracy_pct', v_t_pct
        );
      end if;
    end;
  end loop;

  -- Join with Phase 2 Lessons for Weak Topics
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'lesson_id', l.id,
        'title', l.title,
        'topic_id', l.topic_id,
        'estimated_minutes', l.estimated_minutes
      )
    ),
    '[]'::jsonb
  ) into v_remedial_lessons
  from public.lessons l
  where l.topic_id = any(v_weak_topic_ids)
    and l.is_published = true
  limit 4;

  -- Join with Phase 2 Flashcards for Weak Topics
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'deck_id', fd.id,
        'title', fd.title,
        'topic_id', fd.topic_id,
        'card_count', fd.card_count
      )
    ),
    '[]'::jsonb
  ) into v_remedial_flashcards
  from public.flashcard_decks fd
  where fd.topic_id = any(v_weak_topic_ids)
    and fd.is_published = true
  limit 4;

  -- Record or Update in learner_exam_results
  insert into public.learner_exam_results (
    attempt_id,
    learner_id,
    total_score,
    total_possible_marks,
    percentage,
    predicted_division_or_grade,
    grading_system,
    section_breakdown,
    topic_deficits,
    remedial_lessons,
    remedial_flashcards
  ) values (
    p_attempt_id,
    v_attempt.learner_id,
    v_total_score,
    v_total_possible,
    v_percentage,
    v_predicted_grade,
    v_grading_system,
    v_section_breakdown,
    v_topic_deficits,
    v_remedial_lessons,
    v_remedial_flashcards
  )
  on conflict (attempt_id) do update set
    total_score = excluded.total_score,
    percentage = excluded.percentage,
    predicted_division_or_grade = excluded.predicted_division_or_grade,
    section_breakdown = excluded.section_breakdown,
    topic_deficits = excluded.topic_deficits,
    remedial_lessons = excluded.remedial_lessons,
    remedial_flashcards = excluded.remedial_flashcards
  returning id into v_result_id;

  -- Update Attempt status to completed
  update public.learner_exam_attempts
  set status = 'completed',
      submitted_at = now(),
      total_score = v_total_score,
      percentage = v_percentage,
      predicted_division_or_grade = v_predicted_grade
  where id = p_attempt_id;

  return jsonb_build_object(
    'result_id', v_result_id,
    'attempt_id', p_attempt_id,
    'learner_id', v_attempt.learner_id,
    'title', v_mock.title,
    'total_score', v_total_score,
    'total_possible_marks', v_total_possible,
    'percentage', v_percentage,
    'predicted_division_or_grade', v_predicted_grade,
    'grading_system', v_grading_system,
    'section_breakdown', v_section_breakdown,
    'topic_deficits', v_topic_deficits,
    'remedial_lessons', v_remedial_lessons,
    'remedial_flashcards', v_remedial_flashcards,
    'submitted_at', now()
  );
end;
$$;

grant execute on function public.submit_and_grade_exam_attempt(uuid) to authenticated;

-- ============================================================================
-- 3. RPC: get_exam_attempt_results
-- ============================================================================
create or replace function public.get_exam_attempt_results(p_attempt_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid;
  v_res record;
  v_attempt record;
  v_mock record;
  v_questions jsonb;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  select * into v_res
  from public.learner_exam_results
  where attempt_id = p_attempt_id;

  if not found then
    raise exception 'Examination results not found for attempt %', p_attempt_id;
  end if;

  select * into v_attempt
  from public.learner_exam_attempts
  where id = p_attempt_id;

  if v_attempt.user_id <> v_uid and not public.has_role('super_admin') then
    raise exception 'Permission denied';
  end if;

  select * into v_mock
  from public.generated_mock_examinations
  where id = v_attempt.mock_exam_id;

  -- Detailed question-by-question review showing learner answer vs correct answer and rubric
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'question_id', q.id,
        'section_code', mi.section_code,
        'order_index', mi.order_index,
        'question_number', q.question_number,
        'sub_part', q.sub_part,
        'question_text', q.question_text,
        'question_type', q.question_type,
        'options', q.options,
        'correct_answer', q.correct_answer,
        'rubric_guide', q.rubric_guide,
        'marks', mi.marks,
        'learner_answer', r.learner_answer,
        'marks_awarded', coalesce(r.marks_awarded, 0.0),
        'is_flagged', coalesce(r.is_flagged, false)
      ) order by mi.section_code, mi.order_index
    ),
    '[]'::jsonb
  ) into v_questions
  from public.mock_examination_items mi
  join public.exam_extracted_questions q on q.id = mi.question_id
  left join public.learner_exam_responses r on r.attempt_id = p_attempt_id and r.question_id = q.id
  where mi.mock_exam_id = v_attempt.mock_exam_id;

  return jsonb_build_object(
    'result_id', v_res.id,
    'attempt_id', v_res.attempt_id,
    'learner_id', v_res.learner_id,
    'title', v_mock.title,
    'total_score', v_res.total_score,
    'total_possible_marks', v_res.total_possible_marks,
    'percentage', v_res.percentage,
    'predicted_division_or_grade', v_res.predicted_division_or_grade,
    'grading_system', v_res.grading_system,
    'section_breakdown', v_res.section_breakdown,
    'topic_deficits', v_res.topic_deficits,
    'remedial_lessons', v_res.remedial_lessons,
    'remedial_flashcards', v_res.remedial_flashcards,
    'created_at', v_res.created_at,
    'questions_review', v_questions
  );
end;
$$;

grant execute on function public.get_exam_attempt_results(uuid) to authenticated;

commit;
