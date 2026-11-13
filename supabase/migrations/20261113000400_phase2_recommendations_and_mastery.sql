-- LearnTZ Phase 2 Migration: Recommendations Engine and Mastery Tracking
-- Sub-Stage 3 (Stages 2.5 & 2.6 / TASK-206 & TASK-207)

begin;

-- ============================================================================
-- 1. Create table public.learner_recommendations
-- ============================================================================

grant insert, update on public.learner_topic_mastery to authenticated;

create policy "Parents manage own learner topic mastery"
  on public.learner_topic_mastery for all to authenticated
  using (
    public.is_authorized_learner_parent(learner_topic_mastery.learner_id)
    or public.has_role('super_admin')
  )
  with check (
    public.is_authorized_learner_parent(learner_topic_mastery.learner_id)
    or public.has_role('super_admin')
  );

create table if not exists public.learner_recommendations (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references public.learners (id) on delete cascade,
  subject_id uuid not null references public.subjects (id) on delete cascade,
  topic_id uuid references public.topics (id) on delete set null,
  lesson_id uuid references public.lessons (id) on delete set null,
  recommendation_type text not null check (
    recommendation_type in ('remedial', 'advanced', 'spaced_repetition')
  ),
  title text not null check (char_length(btrim(title)) between 1 and 200),
  reason text not null check (char_length(btrim(reason)) between 1 and 1000),
  priority integer not null default 1 check (priority between 1 and 5),
  is_dismissed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (learner_id, topic_id, recommendation_type)
);

create index if not exists learner_recommendations_lookup_idx
  on public.learner_recommendations (learner_id, is_dismissed, priority, created_at desc);

create trigger learner_recommendations_set_updated_at
  before update on public.learner_recommendations
  for each row execute function public.set_updated_at();

alter table public.learner_recommendations enable row level security;
revoke all on public.learner_recommendations from public, anon, authenticated;
grant select, update on public.learner_recommendations to authenticated;

create policy "Parents read own learner recommendations"
  on public.learner_recommendations for select to authenticated
  using (
    public.is_authorized_learner_parent(learner_recommendations.learner_id)
    or public.has_role('super_admin')
  );

create policy "Parents update own learner recommendations"
  on public.learner_recommendations for update to authenticated
  using (
    public.is_authorized_learner_parent(learner_recommendations.learner_id)
    or public.has_role('super_admin')
  )
  with check (
    public.is_authorized_learner_parent(learner_recommendations.learner_id)
    or public.has_role('super_admin')
  );

-- ============================================================================
-- 2. Recommendation Engine RPCs
-- ============================================================================

-- A) Engine generator: Evaluates topic mastery and populates recommendations
create or replace function public.generate_learner_recommendations(
  p_learner_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rec record;
  v_next_topic record;
  v_lesson record;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Authorized parent access is required for this learner' using errcode = '42501';
  end if;

  -- 1. Remedial: topics with accuracy < 60% or in_progress status with attempts
  for v_rec in
    select m.topic_id, t.subject_id, t.title as topic_title, s.name as subject_name
    from public.learner_topic_mastery m
    join public.topics t on t.id = m.topic_id
    join public.subjects s on s.id = t.subject_id
    where m.learner_id = p_learner_id
      and (m.accuracy_rate < 60.0 or m.mastery_status = 'in_progress')
      and m.quizzes_attempted > 0
  loop
    if not exists (
      select 1 from public.learner_recommendations
      where learner_id = p_learner_id
        and topic_id = v_rec.topic_id
        and recommendation_type = 'remedial'
    ) then
      select id into v_lesson
      from public.lessons
      where topic_id = v_rec.topic_id
        and is_published
      order by display_order
      limit 1;

      insert into public.learner_recommendations (
        learner_id, subject_id, topic_id, lesson_id, recommendation_type,
        title, reason, priority
      )
      values (
        p_learner_id,
        v_rec.subject_id,
        v_rec.topic_id,
        v_lesson.id,
        'remedial',
        'Zoezi la Uimarishaji: ' || v_rec.topic_title,
        'Kiwango cha usahihi katika mada ya "' || v_rec.topic_title || '" kiko chini ya 60%. Fanya marudio na zoezi la uimarishaji kuongeza umahiri.',
        1
      )
      on conflict (learner_id, topic_id, recommendation_type) do nothing;
    end if;
  end loop;

  -- 2. Advanced: mastered topics (>=85%) -> recommend next topic in subject
  for v_rec in
    select m.topic_id, t.subject_id, t.display_order, t.title as topic_title, s.name as subject_name
    from public.learner_topic_mastery m
    join public.topics t on t.id = m.topic_id
    join public.subjects s on s.id = t.subject_id
    where m.learner_id = p_learner_id
      and m.mastery_status = 'mastered'
  loop
    select id, title into v_next_topic
    from public.topics
    where subject_id = v_rec.subject_id
      and display_order > v_rec.display_order
      and is_published
    order by display_order
    limit 1;

    if found and not exists (
      select 1 from public.learner_recommendations
      where learner_id = p_learner_id
        and topic_id = v_next_topic.id
        and recommendation_type = 'advanced'
    ) then
      select id into v_lesson
      from public.lessons
      where topic_id = v_next_topic.id
        and is_published
      order by display_order
      limit 1;

      insert into public.learner_recommendations (
        learner_id, subject_id, topic_id, lesson_id, recommendation_type,
        title, reason, priority
      )
      values (
        p_learner_id,
        v_rec.subject_id,
        v_next_topic.id,
        v_lesson.id,
        'advanced',
        'Mada Inayofuata: ' || v_next_topic.title,
        'Umefaulu mada ya "' || v_rec.topic_title || '" kwa umahiri mkubwa (85%+)! Endelea na mada mpya ili kukuza maarifa zaidi.',
        2
      )
      on conflict (learner_id, topic_id, recommendation_type) do nothing;
    end if;
  end loop;

  -- 3. Spaced Repetition: practiced > 14 days ago
  for v_rec in
    select m.topic_id, t.subject_id, t.title as topic_title, s.name as subject_name
    from public.learner_topic_mastery m
    join public.topics t on t.id = m.topic_id
    join public.subjects s on s.id = t.subject_id
    where m.learner_id = p_learner_id
      and m.last_practiced_at < now() - interval '14 days'
  loop
    if not exists (
      select 1 from public.learner_recommendations
      where learner_id = p_learner_id
        and topic_id = v_rec.topic_id
        and recommendation_type = 'spaced_repetition'
    ) then
      select id into v_lesson
      from public.lessons
      where topic_id = v_rec.topic_id
        and is_published
      order by display_order
      limit 1;

      insert into public.learner_recommendations (
        learner_id, subject_id, topic_id, lesson_id, recommendation_type,
        title, reason, priority
      )
      values (
        p_learner_id,
        v_rec.subject_id,
        v_rec.topic_id,
        v_lesson.id,
        'spaced_repetition',
        'Marudio ya Mara kwa Mara: ' || v_rec.topic_title,
        'Imepita zaidi ya wiki 2 tangu usome mada hii. Fanya marudio mafupi kudumisha kumbukumbu ya somo.',
        3
      )
      on conflict (learner_id, topic_id, recommendation_type) do nothing;
    end if;
  end loop;
end;
$$;

revoke all on function public.generate_learner_recommendations(uuid) from public, anon;
grant execute on function public.generate_learner_recommendations(uuid) to authenticated;

-- B) Fetch active recommendations for a learner
create or replace function public.get_learner_recommendations(
  p_learner_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Authorized parent access is required for this learner' using errcode = '42501';
  end if;

  -- Trigger generation pass
  perform public.generate_learner_recommendations(p_learner_id);

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', r.id,
        'subject_id', r.subject_id,
        'subject_name', s.name,
        'topic_id', r.topic_id,
        'topic_title', t.title,
        'lesson_id', r.lesson_id,
        'lesson_title', l.title,
        'recommendation_type', r.recommendation_type,
        'title', r.title,
        'reason', r.reason,
        'priority', r.priority,
        'created_at', r.created_at
      ) order by r.priority asc, r.created_at desc
    ),
    '[]'::jsonb
  ) into v_result
  from public.learner_recommendations r
  join public.subjects s on s.id = r.subject_id
  left join public.topics t on t.id = r.topic_id
  left join public.lessons l on l.id = r.lesson_id
  where r.learner_id = p_learner_id
    and not r.is_dismissed;

  return v_result;
end;
$$;

revoke all on function public.get_learner_recommendations(uuid) from public, anon;
grant execute on function public.get_learner_recommendations(uuid) to authenticated;

-- C) Dismiss a recommendation
create or replace function public.dismiss_learner_recommendation(
  p_learner_id uuid,
  p_recommendation_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Authorized parent access is required for this learner' using errcode = '42501';
  end if;

  update public.learner_recommendations
  set is_dismissed = true,
      updated_at = now()
  where id = p_recommendation_id
    and learner_id = p_learner_id;

  return found;
end;
$$;

revoke all on function public.dismiss_learner_recommendation(uuid, uuid) from public, anon;
grant execute on function public.dismiss_learner_recommendation(uuid, uuid) to authenticated;

-- ============================================================================
-- 3. Mastery Tracking & Reporting Engine RPC
-- ============================================================================

create or replace function public.get_learner_mastery_report(
  p_learner_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_learner public.learners;
  v_total_topics integer := 0;
  v_mastered integer := 0;
  v_proficient integer := 0;
  v_in_progress integer := 0;
  v_not_started integer := 0;
  v_overall_accuracy numeric(5, 2) := 0.00;
  v_streak integer := 0;
  v_readiness integer := 0;
  v_subjects_breakdown jsonb := '[]'::jsonb;
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

  if not found then
    raise exception 'Learner not found' using errcode = '22023';
  end if;

  -- 1. Count total published topics in learner's curriculum and grade
  select count(t.id)::integer into v_total_topics
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.country_code = v_learner.country_code
    and s.curriculum_id = v_learner.curriculum_id
    and (s.grade_id is null or s.grade_id = v_learner.grade_id)
    and t.is_published
    and s.is_published;

  -- 2. Count topic mastery tiers
  select
    coalesce(count(*) filter (where m.mastery_status = 'mastered'), 0)::integer,
    coalesce(count(*) filter (where m.mastery_status = 'proficient'), 0)::integer,
    coalesce(count(*) filter (where m.mastery_status = 'in_progress'), 0)::integer,
    coalesce(round(avg(m.accuracy_rate), 2), 0.00)
  into v_mastered, v_proficient, v_in_progress, v_overall_accuracy
  from public.learner_topic_mastery m
  join public.topics t on t.id = m.topic_id
  join public.subjects s on s.id = t.subject_id
  where m.learner_id = p_learner_id
    and s.country_code = v_learner.country_code
    and s.curriculum_id = v_learner.curriculum_id;

  v_not_started := greatest(0, v_total_topics - (v_mastered + v_proficient + v_in_progress));

  -- 3. Calculate streak days from activity
  with daily_activity as (
    select distinct date_trunc('day', created_at at time zone 'UTC')::date as act_date
    from public.learner_assessment_attempts
    where learner_id = p_learner_id
    union
    select distinct date_trunc('day', last_accessed_at at time zone 'UTC')::date as act_date
    from public.learner_progress
    where learner_id = p_learner_id
  ),
  consecutive as (
    select
      act_date,
      act_date - (dense_rank() over (order by act_date desc))::integer as grp
    from daily_activity
    where act_date <= (now() at time zone 'UTC')::date
  )
  select coalesce(count(*), 0)::integer into v_streak
  from consecutive
  where grp = (
    select grp from consecutive
    where act_date >= (now() at time zone 'UTC')::date - 1
    order by act_date desc limit 1
  );

  -- 4. Examination Readiness Index (0 - 100%)
  if v_total_topics > 0 then
    v_readiness := least(100, greatest(0,
      round(((v_mastered * 1.0) + (v_proficient * 0.7) + (v_in_progress * 0.3)) / v_total_topics * 100.0)::integer
    ));
  else
    v_readiness := 0;
  end if;

  -- 5. Subject-level breakdown
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'subject_id', subj.id,
        'subject_name', subj.name,
        'subject_code', subj.code,
        'total_topics', subj.total_topics,
        'mastered_topics', coalesce(m_agg.mastered, 0),
        'proficient_topics', coalesce(m_agg.proficient, 0),
        'in_progress_topics', coalesce(m_agg.in_progress, 0),
        'not_started_topics', greatest(0, subj.total_topics - coalesce(m_agg.attempted, 0)),
        'average_accuracy', coalesce(m_agg.avg_accuracy, 0.00),
        'mastery_percent', case
          when subj.total_topics > 0 then
            round((coalesce(m_agg.mastered, 0)::numeric / subj.total_topics) * 100)::integer
          else 0
        end
      ) order by subj.display_order
    ),
    '[]'::jsonb
  ) into v_subjects_breakdown
  from (
    select
      s.id,
      s.name,
      s.code,
      s.display_order,
      count(t.id)::integer as total_topics
    from public.subjects s
    join public.topics t on t.subject_id = s.id and t.is_published
    where s.country_code = v_learner.country_code
      and s.curriculum_id = v_learner.curriculum_id
      and (s.grade_id is null or s.grade_id = v_learner.grade_id)
      and s.is_published
    group by s.id, s.name, s.code, s.display_order
  ) subj
  left join (
    select
      t.subject_id,
      count(*) filter (where m.mastery_status = 'mastered')::integer as mastered,
      count(*) filter (where m.mastery_status = 'proficient')::integer as proficient,
      count(*) filter (where m.mastery_status = 'in_progress')::integer as in_progress,
      count(*)::integer as attempted,
      round(avg(m.accuracy_rate), 2) as avg_accuracy
    from public.learner_topic_mastery m
    join public.topics t on t.id = m.topic_id
    where m.learner_id = p_learner_id
    group by t.subject_id
  ) m_agg on m_agg.subject_id = subj.id;

  return jsonb_build_object(
    'learner_id', p_learner_id,
    'total_topics', v_total_topics,
    'mastered_topics', v_mastered,
    'proficient_topics', v_proficient,
    'in_progress_topics', v_in_progress,
    'not_started_topics', v_not_started,
    'overall_accuracy_rate', v_overall_accuracy,
    'streak_days', v_streak,
    'readiness_index', v_readiness,
    'subjects_breakdown', v_subjects_breakdown
  );
end;
$$;

revoke all on function public.get_learner_mastery_report(uuid) from public, anon;
grant execute on function public.get_learner_mastery_report(uuid) to authenticated;

commit;
