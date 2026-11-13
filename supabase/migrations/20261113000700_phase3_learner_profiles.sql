-- Phase 3 Sub-Stage 1: Learner Social Profiles & Child-Safe Academic Identity
-- Migration: 20261113000700_phase3_learner_profiles.sql

create table public.learner_social_profiles (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null unique references public.learners (id) on delete cascade,
  display_name text not null
    check (char_length(btrim(display_name)) between 2 and 50),
  avatar_preset text not null default 'owl_scholar'
    check (avatar_preset in (
      'owl_scholar',
      'lion_reader',
      'cheetah_runner',
      'giraffe_thinker',
      'elephant_math',
      'zebra_writer',
      'falcon_scout',
      'rhino_builder'
    )),
  bio text check (bio is null or char_length(bio) <= 160),
  academic_interests text[] not null default '{}',
  points integer not null default 0 check (points >= 0),
  badges_count integer not null default 0 check (badges_count >= 0),
  profile_visibility text not null default 'school_only'
    check (profile_visibility in ('public', 'school_only', 'private')),
  allow_follower_requests boolean not null default true,
  show_achievements boolean not null default true,
  show_communities boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index learner_social_profiles_learner_idx
  on public.learner_social_profiles (learner_id);
create index learner_social_profiles_visibility_idx
  on public.learner_social_profiles (profile_visibility);
create index learner_social_profiles_points_idx
  on public.learner_social_profiles (points desc);

-- Automatic Provisioning Trigger
create or replace function public.provision_learner_social_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_display text;
begin
  v_display := coalesce(
    nullif(btrim(new.first_name), ''),
    'Learner'
  ) || ' ' || upper(left(coalesce(nullif(btrim(new.last_name), ''), 'L'), 1)) || '.';

  insert into public.learner_social_profiles (
    learner_id,
    display_name,
    avatar_preset
  ) values (
    new.id,
    v_display,
    'owl_scholar'
  ) on conflict (learner_id) do nothing;

  return new;
end;
$$;

drop trigger if exists trg_learners_provision_social_profile on public.learners;
create trigger trg_learners_provision_social_profile
  after insert on public.learners
  for each row execute function public.provision_learner_social_profile();

-- Backfill any existing learners
insert into public.learner_social_profiles (learner_id, display_name, avatar_preset)
select
  id,
  coalesce(nullif(btrim(first_name), ''), 'Learner') || ' ' || upper(left(coalesce(nullif(btrim(last_name), ''), 'L'), 1)) || '.',
  'owl_scholar'
from public.learners
on conflict (learner_id) do nothing;

-- Enable RLS
alter table public.learner_social_profiles enable row level security;

create policy "Learner social profiles read access"
  on public.learner_social_profiles for select to authenticated
  using (
    (select public.is_authorized_learner_parent(learner_id))
    or (select public.has_role('super_admin'))
    or profile_visibility = 'public'
    or (
      profile_visibility = 'school_only'
      and exists (
        select 1
        from public.learners target_l
        join public.learners viewer_l
          on target_l.school_id is not null
         and target_l.school_id = viewer_l.school_id
        where target_l.id = public.learner_social_profiles.learner_id
          and (select public.is_authorized_learner_parent(viewer_l.id))
      )
    )
  );

create policy "Authorized parents and admins can update learner social profiles"
  on public.learner_social_profiles for update to authenticated
  using (
    (select public.is_authorized_learner_parent(learner_id))
    or (select public.has_role('super_admin'))
  )
  with check (
    (select public.is_authorized_learner_parent(learner_id))
    or (select public.has_role('super_admin'))
  );

create policy "Authorized parents and admins can insert learner social profiles"
  on public.learner_social_profiles for insert to authenticated
  with check (
    (select public.is_authorized_learner_parent(learner_id))
    or (select public.has_role('super_admin'))
  );

-- RPC: Get or Create Learner Social Profile
create or replace function public.get_or_create_learner_social_profile(p_learner_id uuid)
returns public.learner_social_profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.learner_social_profiles%rowtype;
  v_learner public.learners%rowtype;
  v_display text;
begin
  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to access learner social profile'
      using errcode = '42501';
  end if;

  select * into v_profile
  from public.learner_social_profiles
  where learner_id = p_learner_id;

  if not found then
    select * into v_learner
    from public.learners
    where id = p_learner_id;

    if not found then
      raise exception 'Learner not found: %', p_learner_id
        using errcode = 'P0002';
    end if;

    v_display := coalesce(
      nullif(btrim(v_learner.first_name), ''),
      'Learner'
    ) || ' ' || upper(left(coalesce(nullif(btrim(v_learner.last_name), ''), 'L'), 1)) || '.';

    insert into public.learner_social_profiles (
      learner_id,
      display_name,
      avatar_preset
    ) values (
      p_learner_id,
      v_display,
      'owl_scholar'
    ) returning * into v_profile;
  end if;

  return v_profile;
end;
$$;

revoke all on function public.get_or_create_learner_social_profile(uuid) from public, anon;
grant execute on function public.get_or_create_learner_social_profile(uuid) to authenticated;

-- RPC: Update Learner Social Profile with Child Protection Checks
create or replace function public.update_learner_social_profile(
  p_learner_id uuid,
  p_display_name text,
  p_avatar_preset text,
  p_bio text default null,
  p_academic_interests text[] default '{}',
  p_profile_visibility text default 'school_only',
  p_allow_follower_requests boolean default true,
  p_show_achievements boolean default true,
  p_show_communities boolean default true
)
returns public.learner_social_profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.learner_social_profiles%rowtype;
  v_clean_name text;
  v_clean_bio text;
begin
  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to update learner social profile'
      using errcode = '42501';
  end if;

  v_clean_name := btrim(coalesce(p_display_name, ''));
  if char_length(v_clean_name) < 2 or char_length(v_clean_name) > 50 then
    raise exception 'Display name must be between 2 and 50 characters'
      using errcode = '23514';
  end if;

  -- Child Safety: Prevent embedding phone numbers or emails in display name
  if v_clean_name ~* '([0-9]{3,}.*[0-9]{4,})' or v_clean_name ~* '@' or v_clean_name ~* 'https?://' then
    raise exception 'Display name contains prohibited contact or link patterns'
      using errcode = '23514';
  end if;

  v_clean_bio := nullif(btrim(coalesce(p_bio, '')), '');
  if v_clean_bio is not null then
    if char_length(v_clean_bio) > 160 then
      raise exception 'Bio cannot exceed 160 characters'
        using errcode = '23514';
    end if;
    -- Child Safety: Prevent embedding phone numbers, emails, or links in bio
    if v_clean_bio ~* '([0-9]{3,}.*[0-9]{4,})' or v_clean_bio ~* '@' or v_clean_bio ~* 'https?://' then
      raise exception 'Bio contains prohibited contact details or external links'
        using errcode = '23514';
    end if;
  end if;

  if p_profile_visibility not in ('public', 'school_only', 'private') then
    raise exception 'Invalid profile visibility value'
      using errcode = '23514';
  end if;

  if p_avatar_preset not in (
    'owl_scholar', 'lion_reader', 'cheetah_runner', 'giraffe_thinker',
    'elephant_math', 'zebra_writer', 'falcon_scout', 'rhino_builder'
  ) then
    raise exception 'Invalid avatar preset: %', p_avatar_preset
      using errcode = '23514';
  end if;

  update public.learner_social_profiles
  set
    display_name = v_clean_name,
    avatar_preset = p_avatar_preset,
    bio = v_clean_bio,
    academic_interests = coalesce(p_academic_interests, '{}'),
    profile_visibility = p_profile_visibility,
    allow_follower_requests = coalesce(p_allow_follower_requests, true),
    show_achievements = coalesce(p_show_achievements, true),
    show_communities = coalesce(p_show_communities, true),
    updated_at = now()
  where learner_id = p_learner_id
  returning * into v_profile;

  if not found then
    raise exception 'Social profile not found for learner: %', p_learner_id
      using errcode = 'P0002';
  end if;

  return v_profile;
end;
$$;

revoke all on function public.update_learner_social_profile(uuid, text, text, text, text[], text, boolean, boolean, boolean) from public, anon;
grant execute on function public.update_learner_social_profile(uuid, text, text, text, text[], text, boolean, boolean, boolean) to authenticated;

-- RPC: Get Safe Public Social Profile (Child-safe academic identity)
create or replace function public.get_public_learner_social_profile(
  p_target_learner_id uuid,
  p_viewer_learner_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.learner_social_profiles%rowtype;
  v_target_learner public.learners%rowtype;
  v_grade_name text;
  v_school_name text;
  v_country_code text;
  v_is_parent_or_admin boolean := false;
  v_is_school_mate boolean := false;
  v_viewer_school_id uuid;
begin
  select * into v_profile
  from public.learner_social_profiles
  where learner_id = p_target_learner_id;

  if not found then
    return null;
  end if;

  select * into v_target_learner
  from public.learners
  where id = p_target_learner_id;

  if not found then
    return null;
  end if;

  v_is_parent_or_admin := public.is_authorized_learner_parent(p_target_learner_id) or public.has_role('super_admin');

  if not v_is_parent_or_admin then
    if v_profile.profile_visibility = 'private' then
      return jsonb_build_object(
        'learner_id', p_target_learner_id,
        'profile_visibility', 'private',
        'is_private', true
      );
    end if;

    if v_profile.profile_visibility = 'school_only' then
      if p_viewer_learner_id is not null then
        select school_id into v_viewer_school_id
        from public.learners
        where id = p_viewer_learner_id;

        if v_viewer_school_id is not null and v_viewer_school_id = v_target_learner.school_id then
          v_is_school_mate := true;
        end if;
      end if;

      if not v_is_school_mate then
        return jsonb_build_object(
          'learner_id', p_target_learner_id,
          'profile_visibility', 'school_only',
          'is_restricted', true
        );
      end if;
    end if;
  end if;

  -- Fetch non-PII academic metadata
  select name into v_grade_name
  from public.education_grades
  where id = v_target_learner.grade_id;

  if v_target_learner.school_id is not null then
    select name into v_school_name
    from public.schools
    where id = v_target_learner.school_id;
  end if;

  v_country_code := v_target_learner.country_code;

  return jsonb_build_object(
    'learner_id', v_profile.learner_id,
    'display_name', v_profile.display_name,
    'avatar_preset', v_profile.avatar_preset,
    'bio', v_profile.bio,
    'academic_interests', v_profile.academic_interests,
    'points', case when v_profile.show_achievements or v_is_parent_or_admin then v_profile.points else 0 end,
    'badges_count', case when v_profile.show_achievements or v_is_parent_or_admin then v_profile.badges_count else 0 end,
    'profile_visibility', v_profile.profile_visibility,
    'allow_follower_requests', v_profile.allow_follower_requests,
    'show_achievements', v_profile.show_achievements,
    'show_communities', v_profile.show_communities,
    'grade_name', v_grade_name,
    'school_name', v_school_name,
    'country_code', v_country_code,
    'created_at', v_profile.created_at
  );
end;
$$;

revoke all on function public.get_public_learner_social_profile(uuid, uuid) from public, anon;
grant execute on function public.get_public_learner_social_profile(uuid, uuid) to authenticated;
