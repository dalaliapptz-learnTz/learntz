-- ============================================================================
-- Migration: 20261113000200_phase2_dashboards_and_explorer.sql
-- Description: RPCs supporting Phase 2.1 Learner & Parent Dashboards and
--              Phase 2.2 Curriculum Explorer with Row-Level Security.
-- ============================================================================

-- 1. RPC: get_parent_dashboard_overview
create or replace function public.get_parent_dashboard_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_learners_overview jsonb := '[]'::jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'learner_id', l.id,
        'first_name', l.first_name,
        'last_name', l.last_name,
        'full_name', btrim(l.first_name || ' ' || coalesce(l.middle_name || ' ', '') || l.last_name),
        'country_code', l.country_code,
        'status', l.status,
        'grade_name', coalesce(g.name, 'N/A'),
        'level_name', coalesce(lvl.name, 'N/A'),
        'curriculum_name', coalesce(c.name, 'N/A'),
        'system_name', coalesce(s.name, 'N/A'),
        'school_name', coalesce(sch.name, 'Independent Learner'),
        'total_lessons', coalesce(metrics.total_lessons, 0),
        'completed_lessons', coalesce(metrics.completed_lessons, 0),
        'in_progress_lessons', coalesce(metrics.in_progress_lessons, 0),
        'average_quiz_score_percent', coalesce(metrics.avg_quiz_score, 0),
        'mastery_percent', coalesce(metrics.mastery_pct, 0),
        'streak_days', coalesce(metrics.streak_days, 1),
        'last_accessed_at', metrics.last_activity,
        'last_lesson_accessed', metrics.last_lesson,
        'subjects_overview', coalesce(metrics.subjects_arr, '[]'::jsonb)
      ) order by l.created_at
    ),
    '[]'::jsonb
  )
  into v_learners_overview
  from public.learners l
  join public.parent_learners pl on pl.learner_id = l.id and pl.parent_user_id = v_user_id
  left join public.education_grades g on g.id = l.grade_id
  left join public.education_levels lvl on lvl.id = l.education_level_id
  left join public.curricula c on c.id = l.curriculum_id
  left join public.education_systems s on s.id = l.education_system_id
  left join public.schools sch on sch.id = l.school_id
  left join lateral (
    select
      count(distinct les.id)::int as total_lessons,
      count(distinct case when lp.status = 'completed' then les.id end)::int as completed_lessons,
      count(distinct case when lp.status = 'in_progress' then les.id end)::int as in_progress_lessons,
      round(coalesce(avg(lp.best_quiz_score_percent), 0))::int as avg_quiz_score,
      round(
        case when count(distinct les.id) = 0 then 0
        else (count(distinct case when lp.status = 'completed' then les.id end)::numeric / count(distinct les.id)::numeric) * 100
        end
      )::int as mastery_pct,
      max(lp.last_accessed_at) as last_activity,
      -- Approximate active study streak (days with activity within the last week)
      greatest(1, count(distinct date_trunc('day', lp.last_accessed_at)))::int as streak_days,
      (
        select jsonb_build_object(
          'lesson_id', les_sub.id,
          'lesson_title', les_sub.title,
          'subject_name', subj_sub.name,
          'reading_progress_percent', lp_sub.reading_progress_percent,
          'is_completed', (lp_sub.status = 'completed')
        )
        from public.learner_progress lp_sub
        join public.lessons les_sub on les_sub.id = lp_sub.lesson_id
        join public.topics top_sub on top_sub.id = les_sub.topic_id
        join public.subjects subj_sub on subj_sub.id = top_sub.subject_id
        where lp_sub.learner_id = l.id
        order by lp_sub.last_accessed_at desc
        limit 1
      ) as last_lesson,
      (
        select coalesce(
          jsonb_agg(
            jsonb_build_object(
              'subject_id', subj_agg.id,
              'subject_name', subj_agg.name,
              'total_lessons', subj_agg.tot_lessons,
              'completed_lessons', subj_agg.comp_lessons,
              'average_quiz_score', subj_agg.avg_score,
              'status', case
                when subj_agg.avg_score >= 80 then 'excelling'
                when subj_agg.avg_score < 60 and subj_agg.comp_lessons > 0 then 'needs_practice'
                else 'on_track'
              end
            ) order by subj_agg.subj_order
          ),
          '[]'::jsonb
        )
        from (
          select
            sb.id,
            sb.name,
            sb.display_order as subj_order,
            count(distinct ls.id)::int as tot_lessons,
            count(distinct case when prg.status = 'completed' then ls.id end)::int as comp_lessons,
            round(coalesce(avg(prg.best_quiz_score_percent), 0))::int as avg_score
          from public.subjects sb
          join public.topics tp on tp.subject_id = sb.id and tp.is_published
          join public.lessons ls on ls.topic_id = tp.id and ls.is_published
          left join public.learner_progress prg on prg.lesson_id = ls.id and prg.learner_id = l.id
          where sb.is_published
            and sb.curriculum_id = l.curriculum_id
            and sb.education_level_id = l.education_level_id
            and (sb.grade_id is null or sb.grade_id = l.grade_id)
          group by sb.id, sb.name, sb.display_order
        ) subj_agg
      ) as subjects_arr
    from public.subjects sub
    join public.topics top on top.subject_id = sub.id and top.is_published
    join public.lessons les on les.topic_id = top.id and les.is_published
    left join public.learner_progress lp on lp.lesson_id = les.id and lp.learner_id = l.id
    where sub.is_published
      and sub.curriculum_id = l.curriculum_id
      and sub.education_level_id = l.education_level_id
      and (sub.grade_id is null or sub.grade_id = l.grade_id)
  ) metrics on true;

  return v_learners_overview;
end;
$$;

-- 2. RPC: get_learner_dashboard_data
create or replace function public.get_learner_dashboard_data(p_learner_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_learner public.learners;
  v_grade_name text;
  v_system_name text;
  v_curriculum_name text;
  v_school_name text;
  v_summary jsonb;
  v_resume_lesson jsonb;
  v_streak_days integer := 1;
  v_today_completed integer := 0;
  v_term_info jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Authorized parent access is required for this learner' using errcode = '42501';
  end if;

  select * into v_learner
  from public.learners
  where id = p_learner_id;

  select name into v_grade_name from public.education_grades where id = v_learner.grade_id;
  select name into v_system_name from public.education_systems where id = v_learner.education_system_id;
  select name into v_curriculum_name from public.curricula where id = v_learner.curriculum_id;
  select name into v_school_name from public.schools where id = v_learner.school_id;

  -- 1. Summary
  v_summary := public.get_learner_learning_summary(p_learner_id);

  -- 2. Resume Lesson (most recently accessed incomplete or latest accessed)
  select jsonb_build_object(
    'lesson_id', les.id,
    'lesson_title', les.title,
    'subject_name', s.name,
    'topic_title', t.title,
    'reading_progress_percent', lp.reading_progress_percent,
    'is_completed', (lp.status = 'completed'),
    'last_accessed_at', lp.last_accessed_at
  )
  into v_resume_lesson
  from public.learner_progress lp
  join public.lessons les on les.id = lp.lesson_id
  join public.topics t on t.id = les.topic_id
  join public.subjects s on s.id = t.subject_id
  where lp.learner_id = p_learner_id
  order by (lp.status != 'completed') desc, lp.last_accessed_at desc
  limit 1;

  -- 3. Streak and Today's completion
  select
    greatest(1, count(distinct date_trunc('day', last_accessed_at)))::int,
    count(case when completed_at >= current_date then 1 end)::int
  into v_streak_days, v_today_completed
  from public.learner_progress
  where learner_id = p_learner_id;

  -- 4. Active Term Info
  v_term_info := public.get_active_academic_calendar(
    v_learner.country_code,
    v_learner.education_system_id,
    current_date
  );

  return jsonb_build_object(
    'learner_id', v_learner.id,
    'first_name', v_learner.first_name,
    'last_name', v_learner.last_name,
    'full_name', btrim(v_learner.first_name || ' ' || coalesce(v_learner.middle_name || ' ', '') || v_learner.last_name),
    'country_code', v_learner.country_code,
    'status', v_learner.status,
    'grade_name', coalesce(v_grade_name, 'Grade'),
    'system_name', coalesce(v_system_name, 'National System'),
    'curriculum_name', coalesce(v_curriculum_name, 'Curriculum'),
    'school_name', coalesce(v_school_name, 'Independent Learner'),
    'summary', v_summary,
    'resume_lesson', v_resume_lesson,
    'streak_days', coalesce(v_streak_days, 1),
    'daily_target_lessons', 1,
    'today_completed_lessons', coalesce(v_today_completed, 0),
    'daily_target_minutes', 20,
    'academic_calendar', v_term_info
  );
end;
$$;

-- 3. RPC: get_curriculum_explorer_tree
create or replace function public.get_curriculum_explorer_tree(
  p_country_code text,
  p_education_system_id uuid,
  p_education_level_id uuid default null,
  p_grade_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_country text := upper(btrim(coalesce(p_country_code, '')));
  v_result jsonb := '[]'::jsonb;
begin
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'subject_id', s.id,
        'subject_name', s.name,
        'subject_code', s.code,
        'description', s.description,
        'grade_id', s.grade_id,
        'display_order', s.display_order,
        'topics', coalesce(
          (
            select jsonb_agg(
              jsonb_build_object(
                'topic_id', t.id,
                'title', t.title,
                'summary', t.summary,
                'display_order', t.display_order,
                'lessons', coalesce(
                  (
                    select jsonb_agg(
                      jsonb_build_object(
                        'lesson_id', l.id,
                        'title', l.title,
                        'estimated_minutes', l.estimated_minutes,
                        'is_free_preview', l.is_free_preview,
                        'display_order', l.display_order
                      ) order by l.display_order
                    )
                    from public.lessons l
                    where l.topic_id = t.id and l.is_published
                  ),
                  '[]'::jsonb
                )
              ) order by t.display_order
            )
            from public.topics t
            where t.subject_id = s.id and t.is_published
          ),
          '[]'::jsonb
        )
      ) order by s.display_order
    ),
    '[]'::jsonb
  )
  into v_result
  from public.subjects s
  where s.country_code = v_country
    and s.is_published
    and (p_education_level_id is null or s.education_level_id = p_education_level_id)
    and (p_grade_id is null or s.grade_id is null or s.grade_id = p_grade_id);

  return v_result;
end;
$$;

grant execute on function public.get_parent_dashboard_overview() to authenticated;
grant execute on function public.get_learner_dashboard_data(uuid) to authenticated;
grant execute on function public.get_curriculum_explorer_tree(text, uuid, uuid, uuid) to anon, authenticated;
