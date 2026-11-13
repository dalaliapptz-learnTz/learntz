-- Phase 3 Sub-Stage 4: Academic Challenges, Competitions & Educational Leaderboards
-- Migration: 20261113001000_phase3_challenges_and_leaderboards.sql

-- 1. Academic Challenges & Competitions
create table public.academic_challenges (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 4 and 140),
  description text not null check (char_length(btrim(description)) between 10 and 1000),
  country_code text not null references public.countries (country_code) on delete restrict,
  education_level_id uuid references public.education_levels (id) on delete set null,
  grade_id uuid references public.education_grades (id) on delete set null,
  subject_id uuid references public.subjects (id) on delete set null,
  challenge_type text not null
    check (challenge_type in ('daily_quiz', 'weekly_olympiad', 'monthly_championship', 'speed_math', 'science_quest')),
  reward_points integer not null default 50 check (reward_points >= 0),
  badge_key text,
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  status text not null default 'active'
    check (status in ('upcoming', 'active', 'completed', 'archived')),
  questions_payload jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index academic_challenges_country_status_idx
  on public.academic_challenges (country_code, status, ends_at desc);

-- 2. Challenge Participants & Results
create table public.challenge_participants (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.academic_challenges (id) on delete cascade,
  learner_id uuid not null references public.learners (id) on delete cascade,
  score integer not null default 0 check (score >= 0),
  time_spent_seconds integer not null default 0 check (time_spent_seconds >= 0),
  status text not null default 'in_progress'
    check (status in ('in_progress', 'completed')),
  completed_at timestamptz,
  answers_payload jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  constraint challenge_participants_unique unique (challenge_id, learner_id)
);

create index challenge_participants_challenge_idx
  on public.challenge_participants (challenge_id, score desc, time_spent_seconds asc);
create index challenge_participants_learner_idx
  on public.challenge_participants (learner_id);

-- 3. Achievement Badges Catalog
create table public.achievement_badges (
  badge_key text primary key,
  name text not null,
  description text not null,
  category text not null
    check (category in ('learning', 'social', 'competition', 'consistency')),
  icon_name text not null default 'military_tech',
  points_required integer not null default 0 check (points_required >= 0),
  created_at timestamptz not null default now()
);

-- Seed pre-approved achievement badges
insert into public.achievement_badges (badge_key, name, description, category, icon_name, points_required)
values
  ('curious_mind', 'Curious Mind', 'Shared first educational question or knowledge post', 'social', 'psychology', 10),
  ('math_champion', 'Math Champion', 'Completed a speed math or Olympiad challenge', 'competition', 'calculate', 50),
  ('study_streak_7', '7-Day Scholar', 'Consistently learned on LearnTZ for 7 active days', 'consistency', 'bolt', 100),
  ('helpful_peer', 'Helpful Peer', 'Provided answers and earned reactions from fellow learners', 'social', 'favorite', 30),
  ('quiz_master', 'Quiz Master', 'Achieved a top score on an academic challenge', 'competition', 'emoji_events', 100),
  ('top_contributor', 'Master Contributor', 'Accumulated over 200 educational learning points', 'learning', 'stars', 200)
on conflict (badge_key) do nothing;

-- 4. Learner Badges Earned
create table public.learner_badges (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references public.learners (id) on delete cascade,
  badge_key text not null references public.achievement_badges (badge_key) on delete cascade,
  awarded_at timestamptz not null default now(),
  constraint learner_badges_unique unique (learner_id, badge_key)
);

create index learner_badges_learner_idx
  on public.learner_badges (learner_id);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.academic_challenges enable row level security;
alter table public.challenge_participants enable row level security;
alter table public.achievement_badges enable row level security;
alter table public.learner_badges enable row level security;

create policy "Authenticated users can read challenges"
  on public.academic_challenges for select to authenticated using (true);

create policy "Authorized administrators manage challenges"
  on public.academic_challenges for all to authenticated
  using (
    (select public.has_role('super_admin'))
    or (select public.has_role('country_admin', country_code))
  )
  with check (
    (select public.has_role('super_admin'))
    or (select public.has_role('country_admin', country_code))
  );

create policy "Authenticated users can read challenge results"
  on public.challenge_participants for select to authenticated using (true);

create policy "Authorized parents and admins can manage challenge attempts"
  on public.challenge_participants for all to authenticated
  using (
    (select public.is_authorized_learner_parent(learner_id))
    or (select public.has_role('super_admin'))
  )
  with check (
    (select public.is_authorized_learner_parent(learner_id))
    or (select public.has_role('super_admin'))
  );

create policy "Authenticated users can read achievement badges"
  on public.achievement_badges for select to authenticated using (true);

create policy "Authenticated users can read learner badges"
  on public.learner_badges for select to authenticated using (true);

-- ============================================================================
-- RPC FUNCTIONS
-- ============================================================================

-- RPC: Get Active Challenges for Learner
create or replace function public.get_active_challenges(p_learner_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_country text;
  v_grade_id uuid;
  v_challenges jsonb;
begin
  select country_code, grade_id into v_country, v_grade_id
  from public.learners
  where id = p_learner_id;

  if not found then return '[]'::jsonb; end if;

  select coalesce(jsonb_agg(ch_row), '[]'::jsonb) into v_challenges
  from (
    select
      ac.id,
      ac.title,
      ac.description,
      ac.challenge_type,
      ac.reward_points,
      ac.badge_key,
      ac.starts_at,
      ac.ends_at,
      ac.status,
      jsonb_array_length(ac.questions_payload) as total_questions,
      s.name as subject_name,
      cp.id as attempt_id,
      cp.status as attempt_status,
      cp.score as learner_score,
      cp.completed_at
    from public.academic_challenges ac
    left join public.subjects s on s.id = ac.subject_id
    left join public.challenge_participants cp
      on cp.challenge_id = ac.id and cp.learner_id = p_learner_id
    where ac.country_code = v_country
      and ac.status in ('active', 'upcoming')
      and (ac.grade_id is null or ac.grade_id = v_grade_id)
      and ac.ends_at > now()
    order by ac.ends_at asc
  ) ch_row;

  return v_challenges;
end;
$$;

revoke all on function public.get_active_challenges(uuid) from public, anon;
grant execute on function public.get_active_challenges(uuid) to authenticated;

-- RPC: Participate in Challenge
create or replace function public.participate_in_challenge(
  p_challenge_id uuid,
  p_learner_id uuid
)
returns public.challenge_participants
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_participant public.challenge_participants%rowtype;
begin
  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to enter challenge for learner' using errcode = '42501';
  end if;

  if not exists (select 1 from public.academic_challenges where id = p_challenge_id and status = 'active' and ends_at > now()) then
    raise exception 'Challenge is not currently active' using errcode = '23514';
  end if;

  insert into public.challenge_participants (
    challenge_id,
    learner_id,
    status
  ) values (
    p_challenge_id,
    p_learner_id,
    'in_progress'
  )
  on conflict (challenge_id, learner_id) do update
    set status = challenge_participants.status
  returning * into v_participant;

  return v_participant;
end;
$$;

revoke all on function public.participate_in_challenge(uuid, uuid) from public, anon;
grant execute on function public.participate_in_challenge(uuid, uuid) to authenticated;

-- RPC: Submit Challenge Attempt
create or replace function public.submit_challenge_attempt(
  p_challenge_id uuid,
  p_learner_id uuid,
  p_score integer,
  p_time_spent_seconds integer,
  p_answers jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_challenge public.academic_challenges%rowtype;
  v_earned_points integer := 0;
  v_awarded_badge text := null;
  v_total_badges integer;
begin
  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to submit challenge for learner' using errcode = '42501';
  end if;

  select * into v_challenge
  from public.academic_challenges
  where id = p_challenge_id;

  if not found then
    raise exception 'Challenge not found' using errcode = 'P0002';
  end if;

  -- Update participation record
  update public.challenge_participants
  set
    score = greatest(score, p_score),
    time_spent_seconds = p_time_spent_seconds,
    status = 'completed',
    completed_at = now(),
    answers_payload = coalesce(p_answers, '[]'::jsonb)
  where challenge_id = p_challenge_id
    and learner_id = p_learner_id;

  if not found then
    insert into public.challenge_participants (
      challenge_id, learner_id, score, time_spent_seconds, status, completed_at, answers_payload
    ) values (
      p_challenge_id, p_learner_id, p_score, p_time_spent_seconds, 'completed', now(), coalesce(p_answers, '[]'::jsonb)
    );
  end if;

  -- Calculate points based on score
  if p_score >= 80 then
    v_earned_points := v_challenge.reward_points;
  elsif p_score >= 50 then
    v_earned_points := (v_challenge.reward_points * 0.5)::integer;
  else
    v_earned_points := 10; -- participation encouragement points
  end if;

  -- Award points to learner social profile
  update public.learner_social_profiles
  set points = points + v_earned_points
  where learner_id = p_learner_id;

  -- Check badge awards
  if v_challenge.badge_key is not null and p_score >= 80 then
    insert into public.learner_badges (learner_id, badge_key)
    values (p_learner_id, v_challenge.badge_key)
    on conflict do nothing;

    if found then
      v_awarded_badge := v_challenge.badge_key;
    end if;
  end if;

  -- Also check math_champion badge if challenge was speed_math
  if v_challenge.challenge_type = 'speed_math' and p_score >= 70 then
    insert into public.learner_badges (learner_id, badge_key)
    values (p_learner_id, 'math_champion')
    on conflict do nothing;
  end if;

  -- Update denormalized badges_count on profile
  select count(*) into v_total_badges
  from public.learner_badges
  where learner_id = p_learner_id;

  update public.learner_social_profiles
  set badges_count = v_total_badges
  where learner_id = p_learner_id;

  return jsonb_build_object(
    'challenge_id', p_challenge_id,
    'learner_id', p_learner_id,
    'score', p_score,
    'earned_points', v_earned_points,
    'awarded_badge', v_awarded_badge,
    'completed_at', now()
  );
end;
$$;

revoke all on function public.submit_challenge_attempt(uuid, uuid, integer, integer, jsonb) from public, anon;
grant execute on function public.submit_challenge_attempt(uuid, uuid, integer, integer, jsonb) to authenticated;

-- RPC: Get Community Leaderboard (Child-safe pseudonymous ranking)
create or replace function public.get_community_leaderboard(
  p_scope text default 'national',
  p_scope_id text default 'TZ',
  p_limit integer default 25
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_leaderboard jsonb;
begin
  select coalesce(jsonb_agg(lb_row), '[]'::jsonb) into v_leaderboard
  from (
    select
      row_number() over (order by sp.points desc, sp.badges_count desc) as rank,
      sp.learner_id,
      sp.display_name,
      sp.avatar_preset,
      case when sp.show_achievements then sp.points else 0 end as points,
      case when sp.show_achievements then sp.badges_count else 0 end as badges_count,
      eg.name as grade_name,
      sch.name as school_name,
      l.country_code
    from public.learner_social_profiles sp
    join public.learners l on l.id = sp.learner_id
    left join public.education_grades eg on eg.id = l.grade_id
    left join public.schools sch on sch.id = l.school_id
    where (
      (p_scope = 'national' and l.country_code = p_scope_id)
      or (p_scope = 'school' and l.school_id = p_scope_id::uuid)
      or (p_scope = 'class' and l.grade_id = p_scope_id::uuid)
      or (p_scope = 'global')
    )
    and sp.profile_visibility <> 'private'
    order by sp.points desc, sp.badges_count desc
    limit greatest(1, least(p_limit, 50))
  ) lb_row;

  return v_leaderboard;
end;
$$;

revoke all on function public.get_community_leaderboard(text, text, integer) from public, anon;
grant execute on function public.get_community_leaderboard(text, text, integer) to authenticated;

-- Seed a sample Speed Math Challenge for Tanzania
insert into public.academic_challenges (
  title,
  description,
  country_code,
  challenge_type,
  reward_points,
  badge_key,
  starts_at,
  ends_at,
  status,
  questions_payload
) values (
  'East African Speed Math Sprint',
  'Answer 5 rapid mental math calculations to test your arithmetic speed and accuracy!',
  'TZ',
  'speed_math',
  50,
  'math_champion',
  now() - interval '1 day',
  now() + interval '30 days',
  'active',
  '[
    {"id": "q1", "prompt": "What is 15 * 8?", "options": ["100", "120", "140", "110"], "correct_index": 1},
    {"id": "q2", "prompt": "What is 144 / 12?", "options": ["10", "11", "12", "14"], "correct_index": 2},
    {"id": "q3", "prompt": "What is 45 + 55?", "options": ["90", "95", "100", "105"], "correct_index": 2},
    {"id": "q4", "prompt": "What is 7 * 9?", "options": ["56", "63", "64", "72"], "correct_index": 1},
    {"id": "q5", "prompt": "What is the square root of 81?", "options": ["7", "8", "9", "10"], "correct_index": 2}
  ]'::jsonb
) on conflict do nothing;
