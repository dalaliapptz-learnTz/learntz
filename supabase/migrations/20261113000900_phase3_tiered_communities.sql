-- Phase 3 Sub-Stage 3: Hierarchical Communities Hub
-- Migration: 20261113000900_phase3_tiered_communities.sql

-- 1. Tiered Communities Table
create table public.communities (
  id uuid primary key default gen_random_uuid(),
  community_tier text not null
    check (community_tier in ('school', 'class', 'district', 'region', 'national', 'subject')),
  name text not null
    check (char_length(btrim(name)) between 2 and 120),
  description text
    check (description is null or char_length(description) <= 300),
  country_code text not null references public.countries (country_code) on delete restrict,
  school_id uuid references public.schools (id) on delete cascade,
  grade_id uuid references public.education_grades (id) on delete cascade,
  district_name text,
  region_name text,
  subject_id uuid references public.subjects (id) on delete cascade,
  icon_name text not null default 'school',
  members_count integer not null default 0 check (members_count >= 0),
  posts_count integer not null default 0 check (posts_count >= 0),
  is_official boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Unique indexes per tier to avoid duplicates
create unique index communities_national_tier_idx
  on public.communities (country_code)
  where community_tier = 'national';

create unique index communities_school_tier_idx
  on public.communities (school_id)
  where community_tier = 'school';

create unique index communities_class_tier_idx
  on public.communities (school_id, grade_id)
  where community_tier = 'class';

create unique index communities_subject_tier_idx
  on public.communities (country_code, subject_id)
  where community_tier = 'subject';

create index communities_country_tier_idx
  on public.communities (country_code, community_tier);

-- Link social_posts FK to communities
alter table public.social_posts
  drop constraint if exists social_posts_community_fk;
alter table public.social_posts
  add constraint social_posts_community_fk
  foreign key (community_id) references public.communities (id) on delete cascade;

-- 2. Community Memberships
create table public.community_memberships (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities (id) on delete cascade,
  learner_id uuid not null references public.learners (id) on delete cascade,
  role text not null default 'member'
    check (role in ('member', 'prefect', 'moderator', 'teacher_admin')),
  joined_at timestamptz not null default now(),
  constraint community_memberships_unique unique (community_id, learner_id)
);

create index community_memberships_learner_idx
  on public.community_memberships (learner_id);
create index community_memberships_community_idx
  on public.community_memberships (community_id);

-- 3. Community Channels (e.g. #general, #q-and-a, #announcements)
create table public.community_channels (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities (id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 2 and 50),
  channel_type text not null default 'general'
    check (channel_type in ('general', 'q_and_a', 'study_resources', 'announcements')),
  description text check (description is null or char_length(description) <= 250),
  created_at timestamptz not null default now(),
  constraint community_channels_unique_name unique (community_id, name)
);

create index community_channels_community_idx
  on public.community_channels (community_id);

-- 4. Channel Messages
create table public.channel_messages (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references public.community_channels (id) on delete cascade,
  author_learner_id uuid not null references public.learners (id) on delete cascade,
  content text not null check (char_length(btrim(content)) between 1 and 1000),
  status text not null default 'published'
    check (status in ('published', 'flagged', 'hidden')),
  created_at timestamptz not null default now()
);

create index channel_messages_channel_idx
  on public.channel_messages (channel_id, created_at asc);
create index channel_messages_author_idx
  on public.channel_messages (author_learner_id);

-- Apply child safety screening to channel messages
drop trigger if exists trg_screen_channel_message on public.channel_messages;
create trigger trg_screen_channel_message
  before insert or update on public.channel_messages
  for each row execute function public.screen_educational_content();

-- Trigger to increment/decrement community member count
create or replace function public.update_community_member_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if TG_OP = 'INSERT' then
    update public.communities set members_count = members_count + 1 where id = new.community_id;
  elsif TG_OP = 'DELETE' then
    update public.communities set members_count = greatest(0, members_count - 1) where id = old.community_id;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_community_memberships_count on public.community_memberships;
create trigger trg_community_memberships_count
  after insert or delete on public.community_memberships
  for each row execute function public.update_community_member_count();

-- Trigger to auto-provision default channels when a community is created
create or replace function public.provision_community_channels()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.community_channels (community_id, name, channel_type, description)
  values
    (new.id, 'general', 'general', 'General educational discussions and academic collaboration'),
    (new.id, 'q-and-a', 'q_and_a', 'Ask homework and exam revision questions'),
    (new.id, 'announcements', 'announcements', 'Important updates and study tips')
  on conflict do nothing;

  return new;
end;
$$;

drop trigger if exists trg_communities_provision_channels on public.communities;
create trigger trg_communities_provision_channels
  after insert on public.communities
  for each row execute function public.provision_community_channels();

-- Seed Default National Communities
insert into public.communities (community_tier, name, description, country_code, icon_name)
values
  ('national', 'Tanzania National Learning Community', 'Nationwide digital academic community for primary and secondary learners across Tanzania', 'TZ', 'flag'),
  ('national', 'Kenya National Learning Community', 'Nationwide digital academic community for CBC learners across Kenya', 'KE', 'flag'),
  ('national', 'Uganda National Learning Community', 'Nationwide digital academic community for UNEB learners across Uganda', 'UG', 'flag')
on conflict do nothing;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.communities enable row level security;
alter table public.community_memberships enable row level security;
alter table public.community_channels enable row level security;
alter table public.channel_messages enable row level security;

-- Communities RLS
create policy "Authenticated users can read communities"
  on public.communities for select to authenticated using (true);

create policy "Authorized administrators manage communities"
  on public.communities for all to authenticated
  using (
    (select public.has_role('super_admin'))
    or (select public.has_role('country_admin', country_code))
  )
  with check (
    (select public.has_role('super_admin'))
    or (select public.has_role('country_admin', country_code))
  );

-- Memberships RLS
create policy "Authenticated users can read memberships"
  on public.community_memberships for select to authenticated using (true);

create policy "Authorized parents and admins manage memberships"
  on public.community_memberships for all to authenticated
  using (
    (select public.is_authorized_learner_parent(learner_id))
    or (select public.has_role('super_admin'))
  )
  with check (
    (select public.is_authorized_learner_parent(learner_id))
    or (select public.has_role('super_admin'))
  );

-- Channels RLS
create policy "Authenticated users can read channels"
  on public.community_channels for select to authenticated using (true);

-- Messages RLS
create policy "Authenticated users can read messages"
  on public.channel_messages for select to authenticated
  using (status = 'published' or (select public.is_authorized_learner_parent(author_learner_id)) or (select public.has_role('super_admin')));

create policy "Authorized parents and admins can post channel messages"
  on public.channel_messages for insert to authenticated
  with check (
    (select public.is_authorized_learner_parent(author_learner_id))
    or (select public.has_role('super_admin'))
  );

-- ============================================================================
-- RPC FUNCTIONS
-- ============================================================================

-- RPC: Get Learner Communities
create or replace function public.get_learner_communities(p_learner_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_res jsonb;
begin
  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to view learner communities' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(comm_row), '[]'::jsonb) into v_res
  from (
    select
      c.id,
      c.community_tier,
      c.name,
      c.description,
      c.country_code,
      c.school_id,
      c.grade_id,
      c.icon_name,
      c.members_count,
      c.posts_count,
      c.is_official,
      cm.role as learner_role,
      cm.joined_at
    from public.community_memberships cm
    join public.communities c on c.id = cm.community_id
    where cm.learner_id = p_learner_id
    order by
      case c.community_tier
        when 'class' then 1
        when 'school' then 2
        when 'district' then 3
        when 'region' then 4
        when 'subject' then 5
        when 'national' then 6
        else 7
      end,
      c.name asc
  ) comm_row;

  return v_res;
end;
$$;

revoke all on function public.get_learner_communities(uuid) from public, anon;
grant execute on function public.get_learner_communities(uuid) to authenticated;

-- RPC: Auto Enroll Learner into Mandatory / School / National Communities
create or replace function public.auto_enroll_learner_communities(p_learner_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_learner public.learners%rowtype;
  v_nat_comm_id uuid;
  v_school_comm_id uuid;
  v_class_comm_id uuid;
  v_school_name text;
  v_grade_name text;
begin
  select * into v_learner from public.learners where id = p_learner_id;
  if not found then return; end if;

  -- 1. National Community
  select id into v_nat_comm_id
  from public.communities
  where country_code = v_learner.country_code
    and community_tier = 'national'
  limit 1;

  if v_nat_comm_id is not null then
    insert into public.community_memberships (community_id, learner_id, role)
    values (v_nat_comm_id, p_learner_id, 'member')
    on conflict do nothing;
  end if;

  -- 2. School Community (if enrolled in a school)
  if v_learner.school_id is not null then
    select id into v_school_comm_id
    from public.communities
    where school_id = v_learner.school_id
      and community_tier = 'school'
    limit 1;

    if v_school_comm_id is null then
      select name into v_school_name from public.schools where id = v_learner.school_id;
      insert into public.communities (
        community_tier,
        name,
        description,
        country_code,
        school_id,
        icon_name
      ) values (
        'school',
        coalesce(v_school_name, 'School') || ' Community',
        'Official school academic community',
        v_learner.country_code,
        v_learner.school_id,
        'school'
      ) returning id into v_school_comm_id;
    end if;

    insert into public.community_memberships (community_id, learner_id, role)
    values (v_school_comm_id, p_learner_id, 'member')
    on conflict do nothing;

    -- 3. Class Community (school + grade)
    select id into v_class_comm_id
    from public.communities
    where school_id = v_learner.school_id
      and grade_id = v_learner.grade_id
      and community_tier = 'class'
    limit 1;

    if v_class_comm_id is null then
      select name into v_grade_name from public.education_grades where id = v_learner.grade_id;
      insert into public.communities (
        community_tier,
        name,
        description,
        country_code,
        school_id,
        grade_id,
        icon_name
      ) values (
        'class',
        coalesce(v_school_name, 'School') || ' - ' || coalesce(v_grade_name, 'Class'),
        'Official classroom study group',
        v_learner.country_code,
        v_learner.school_id,
        v_learner.grade_id,
        'class'
      ) returning id into v_class_comm_id;
    end if;

    insert into public.community_memberships (community_id, learner_id, role)
    values (v_class_comm_id, p_learner_id, 'member')
    on conflict do nothing;
  end if;
end;
$$;

revoke all on function public.auto_enroll_learner_communities(uuid) from public, anon;
grant execute on function public.auto_enroll_learner_communities(uuid) to authenticated;

-- Hook auto enrollment trigger on learners table
create or replace function public.trg_learners_auto_enroll_communities()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.auto_enroll_learner_communities(new.id);
  return new;
end;
$$;

drop trigger if exists trg_learners_communities_enrollment on public.learners;
create trigger trg_learners_communities_enrollment
  after insert on public.learners
  for each row execute function public.trg_learners_auto_enroll_communities();

-- Backfill existing learners
do $$
declare
  r record;
begin
  for r in select id from public.learners loop
    perform public.auto_enroll_learner_communities(r.id);
  end loop;
end;
$$;

-- RPC: Get Discoverable Communities (e.g. Subject communities, Regional communities)
create or replace function public.get_discoverable_communities(
  p_learner_id uuid,
  p_tier text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_country text;
  v_res jsonb;
begin
  select country_code into v_country from public.learners where id = p_learner_id;
  if not found then return '[]'::jsonb; end if;

  select coalesce(jsonb_agg(comm_row), '[]'::jsonb) into v_res
  from (
    select
      c.id,
      c.community_tier,
      c.name,
      c.description,
      c.country_code,
      c.members_count,
      c.posts_count,
      c.icon_name,
      exists (
        select 1 from public.community_memberships cm
        where cm.community_id = c.id and cm.learner_id = p_learner_id
      ) as is_member
    from public.communities c
    where c.country_code = v_country
      and (p_tier is null or c.community_tier = p_tier)
    order by c.members_count desc, c.name asc
    limit 50
  ) comm_row;

  return v_res;
end;
$$;

revoke all on function public.get_discoverable_communities(uuid, text) from public, anon;
grant execute on function public.get_discoverable_communities(uuid, text) to authenticated;

-- RPC: Join Community
create or replace function public.join_community(
  p_community_id uuid,
  p_learner_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_comm public.communities%rowtype;
  v_learner public.learners%rowtype;
begin
  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to join community for learner' using errcode = '42501';
  end if;

  select * into v_comm from public.communities where id = p_community_id;
  if not found then raise exception 'Community not found' using errcode = 'P0002'; end if;

  select * into v_learner from public.learners where id = p_learner_id;
  if not found then raise exception 'Learner not found' using errcode = 'P0002'; end if;

  -- Verify country isolation
  if v_comm.country_code <> v_learner.country_code then
    raise exception 'Cannot join community from a different country' using errcode = '23514';
  end if;

  insert into public.community_memberships (community_id, learner_id, role)
  values (p_community_id, p_learner_id, 'member')
  on conflict (community_id, learner_id) do nothing;

  return true;
end;
$$;

revoke all on function public.join_community(uuid, uuid) from public, anon;
grant execute on function public.join_community(uuid, uuid) to authenticated;

-- RPC: Leave Community
create or replace function public.leave_community(
  p_community_id uuid,
  p_learner_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_comm public.communities%rowtype;
begin
  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to leave community for learner' using errcode = '42501';
  end if;

  select * into v_comm from public.communities where id = p_community_id;
  if not found then return false; end if;

  -- Mandatory tiers cannot be left (national, school, class)
  if v_comm.community_tier in ('national', 'school', 'class') then
    raise exception 'Mandatory institutional communities cannot be left' using errcode = '23514';
  end if;

  delete from public.community_memberships
  where community_id = p_community_id and learner_id = p_learner_id;

  return true;
end;
$$;

revoke all on function public.leave_community(uuid, uuid) from public, anon;
grant execute on function public.leave_community(uuid, uuid) to authenticated;

-- RPC: Get Community Channels
create or replace function public.get_community_channels(p_community_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_channels jsonb;
begin
  select coalesce(jsonb_agg(ch_row), '[]'::jsonb) into v_channels
  from (
    select
      id,
      community_id,
      name,
      channel_type,
      description,
      created_at
    from public.community_channels
    where community_id = p_community_id
    order by
      case channel_type
        when 'announcements' then 1
        when 'general' then 2
        when 'q_and_a' then 3
        else 4
      end,
      name asc
  ) ch_row;

  return v_channels;
end;
$$;

revoke all on function public.get_community_channels(uuid) from public, anon;
grant execute on function public.get_community_channels(uuid) to authenticated;

-- RPC: Send Channel Message
create or replace function public.send_channel_message(
  p_channel_id uuid,
  p_author_learner_id uuid,
  p_content text
)
returns public.channel_messages
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_msg public.channel_messages%rowtype;
  v_comm_id uuid;
begin
  if not (public.is_authorized_learner_parent(p_author_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to send channel message for learner' using errcode = '42501';
  end if;

  select community_id into v_comm_id
  from public.community_channels
  where id = p_channel_id;

  if not found then
    raise exception 'Channel not found' using errcode = 'P0002';
  end if;

  -- Ensure author is a member of the community
  if not exists (
    select 1 from public.community_memberships
    where community_id = v_comm_id and learner_id = p_author_learner_id
  ) then
    raise exception 'Learner is not a member of this community' using errcode = '42501';
  end if;

  insert into public.channel_messages (
    channel_id,
    author_learner_id,
    content
  ) values (
    p_channel_id,
    p_author_learner_id,
    btrim(p_content)
  ) returning * into v_msg;

  return v_msg;
end;
$$;

revoke all on function public.send_channel_message(uuid, uuid, text) from public, anon;
grant execute on function public.send_channel_message(uuid, uuid, text) to authenticated;

-- RPC: Get Channel Messages
create or replace function public.get_channel_messages(
  p_channel_id uuid,
  p_viewer_learner_id uuid default null,
  p_limit integer default 50
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_msgs jsonb;
begin
  select coalesce(jsonb_agg(msg_row), '[]'::jsonb) into v_msgs
  from (
    select
      m.id,
      m.channel_id,
      m.author_learner_id,
      sp.display_name as author_display_name,
      sp.avatar_preset as author_avatar_preset,
      m.content,
      m.created_at
    from public.channel_messages m
    join public.learner_social_profiles sp on sp.learner_id = m.author_learner_id
    where m.channel_id = p_channel_id
      and m.status = 'published'
      and (
        p_viewer_learner_id is null or not exists (
          select 1 from public.learner_blocks lb
          where (lb.blocker_learner_id = p_viewer_learner_id and lb.blocked_learner_id = m.author_learner_id)
             or (lb.blocker_learner_id = m.author_learner_id and lb.blocked_learner_id = p_viewer_learner_id)
        )
      )
    order by m.created_at asc
    limit greatest(1, least(p_limit, 100))
  ) msg_row;

  return v_msgs;
end;
$$;

revoke all on function public.get_channel_messages(uuid, uuid, integer) from public, anon;
grant execute on function public.get_channel_messages(uuid, uuid, integer) to authenticated;
