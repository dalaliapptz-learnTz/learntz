-- Phase 3 Sub-Stage 2: Educational Posts, Reactions & Child-Safe Following
-- Migration: 20261113000800_phase3_social_feed_and_interactions.sql

-- 1. Educational Posts
create table public.social_posts (
  id uuid primary key default gen_random_uuid(),
  author_learner_id uuid not null references public.learners (id) on delete cascade,
  community_id uuid, -- Tiered community scope (FK added in phase3_tiered_communities)
  subject_id uuid references public.subjects (id) on delete set null,
  topic_id uuid references public.topics (id) on delete set null,
  post_type text not null
    check (post_type in ('question', 'concept_explanation', 'study_tip', 'revision_notes', 'discovery', 'resource_share')),
  title text not null
    check (char_length(btrim(title)) between 4 and 140),
  content text not null
    check (char_length(btrim(content)) between 10 and 2000),
  tags text[] not null default '{}',
  status text not null default 'published'
    check (status in ('draft', 'published', 'flagged', 'hidden', 'archived')),
  likes_count integer not null default 0 check (likes_count >= 0),
  comments_count integer not null default 0 check (comments_count >= 0),
  bookmarks_count integer not null default 0 check (bookmarks_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index social_posts_author_idx
  on public.social_posts (author_learner_id, created_at desc);
create index social_posts_subject_idx
  on public.social_posts (subject_id, created_at desc);
create index social_posts_type_status_idx
  on public.social_posts (post_type, status, created_at desc);

-- 2. Post Reactions (Predefined educational reactions)
create table public.social_post_reactions (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.social_posts (id) on delete cascade,
  learner_id uuid not null references public.learners (id) on delete cascade,
  reaction_type text not null
    check (reaction_type in ('helpful', 'insightful', 'brilliant', 'curious', 'clap')),
  created_at timestamptz not null default now(),
  constraint social_post_reactions_unique unique (post_id, learner_id, reaction_type)
);

create index social_post_reactions_post_idx
  on public.social_post_reactions (post_id);
create index social_post_reactions_learner_idx
  on public.social_post_reactions (learner_id);

-- 3. Post Comments & Replies
create table public.social_post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.social_posts (id) on delete cascade,
  author_learner_id uuid not null references public.learners (id) on delete cascade,
  parent_comment_id uuid references public.social_post_comments (id) on delete cascade,
  content text not null
    check (char_length(btrim(content)) between 2 and 600),
  status text not null default 'published'
    check (status in ('published', 'flagged', 'hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index social_post_comments_post_idx
  on public.social_post_comments (post_id, created_at asc);
create index social_post_comments_author_idx
  on public.social_post_comments (author_learner_id);
create index social_post_comments_parent_idx
  on public.social_post_comments (parent_comment_id);

-- 4. Saved / Bookmarked Posts
create table public.saved_posts (
  learner_id uuid not null references public.learners (id) on delete cascade,
  post_id uuid not null references public.social_posts (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (learner_id, post_id)
);

create index saved_posts_learner_idx
  on public.saved_posts (learner_id, created_at desc);

-- 5. Child-Safe Following & Followers
create table public.learner_follows (
  follower_learner_id uuid not null references public.learners (id) on delete cascade,
  target_learner_id uuid not null references public.learners (id) on delete cascade,
  status text not null default 'active'
    check (status in ('pending', 'active', 'rejected', 'blocked')),
  created_at timestamptz not null default now(),
  primary key (follower_learner_id, target_learner_id),
  constraint learner_follows_no_self_follow
    check (follower_learner_id <> target_learner_id)
);

create index learner_follows_target_idx
  on public.learner_follows (target_learner_id, status);
create index learner_follows_follower_idx
  on public.learner_follows (follower_learner_id, status);

-- 6. Learner Block List
create table public.learner_blocks (
  blocker_learner_id uuid not null references public.learners (id) on delete cascade,
  blocked_learner_id uuid not null references public.learners (id) on delete cascade,
  reason text check (reason is null or char_length(reason) <= 250),
  created_at timestamptz not null default now(),
  primary key (blocker_learner_id, blocked_learner_id),
  constraint learner_blocks_no_self_block
    check (blocker_learner_id <> blocked_learner_id)
);

-- ============================================================================
-- CHILD SAFETY SCREENING TRIGGER
-- ============================================================================
create or replace function public.screen_educational_content()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_title text;
  v_content text;
begin
  if TG_TABLE_NAME = 'social_posts' then
    v_title := new.title;
    v_content := new.content;
    if v_title ~* '([0-9]{3,}.*[0-9]{4,})' or v_title ~* '@' or v_title ~* 'https?://' then
      raise exception 'Title contains prohibited contact details or external links for child safety'
        using errcode = '23514';
    end if;
  else
    v_content := new.content;
  end if;

  if v_content ~* '([0-9]{3,}.*[0-9]{4,})' or v_content ~* '@' or v_content ~* 'https?://' then
    raise exception 'Content contains prohibited contact details or external links for child safety'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_screen_social_post on public.social_posts;
create trigger trg_screen_social_post
  before insert or update on public.social_posts
  for each row execute function public.screen_educational_content();

drop trigger if exists trg_screen_social_comment on public.social_post_comments;
create trigger trg_screen_social_comment
  before insert or update on public.social_post_comments
  for each row execute function public.screen_educational_content();

-- ============================================================================
-- DENORMALIZED COUNTERS TRIGGERS
-- ============================================================================
create or replace function public.update_social_post_counters()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if TG_TABLE_NAME = 'social_post_reactions' then
    if TG_OP = 'INSERT' then
      update public.social_posts set likes_count = likes_count + 1 where id = new.post_id;
    elsif TG_OP = 'DELETE' then
      update public.social_posts set likes_count = greatest(0, likes_count - 1) where id = old.post_id;
    end if;
  elsif TG_TABLE_NAME = 'social_post_comments' then
    if TG_OP = 'INSERT' then
      update public.social_posts set comments_count = comments_count + 1 where id = new.post_id;
    elsif TG_OP = 'DELETE' then
      update public.social_posts set comments_count = greatest(0, comments_count - 1) where id = old.post_id;
    end if;
  elsif TG_TABLE_NAME = 'saved_posts' then
    if TG_OP = 'INSERT' then
      update public.social_posts set bookmarks_count = bookmarks_count + 1 where id = new.post_id;
    elsif TG_OP = 'DELETE' then
      update public.social_posts set bookmarks_count = greatest(0, bookmarks_count - 1) where id = old.post_id;
    end if;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_social_post_reactions_counter on public.social_post_reactions;
create trigger trg_social_post_reactions_counter
  after insert or delete on public.social_post_reactions
  for each row execute function public.update_social_post_counters();

drop trigger if exists trg_social_post_comments_counter on public.social_post_comments;
create trigger trg_social_post_comments_counter
  after insert or delete on public.social_post_comments
  for each row execute function public.update_social_post_counters();

drop trigger if exists trg_saved_posts_counter on public.saved_posts;
create trigger trg_saved_posts_counter
  after insert or delete on public.saved_posts
  for each row execute function public.update_social_post_counters();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.social_posts enable row level security;
alter table public.social_post_reactions enable row level security;
alter table public.social_post_comments enable row level security;
alter table public.saved_posts enable row level security;
alter table public.learner_follows enable row level security;
alter table public.learner_blocks enable row level security;

create policy "Authenticated users can read published posts"
  on public.social_posts for select to authenticated
  using (status = 'published' or (select public.is_authorized_learner_parent(author_learner_id)) or (select public.has_role('super_admin')));

create policy "Authorized parents and admins can insert posts"
  on public.social_posts for insert to authenticated
  with check ((select public.is_authorized_learner_parent(author_learner_id)) or (select public.has_role('super_admin')));

create policy "Authorized parents and admins can update own posts"
  on public.social_posts for update to authenticated
  using ((select public.is_authorized_learner_parent(author_learner_id)) or (select public.has_role('super_admin')));

create policy "Authorized parents and admins can delete own posts"
  on public.social_posts for delete to authenticated
  using ((select public.is_authorized_learner_parent(author_learner_id)) or (select public.has_role('super_admin')));

-- Reactions RLS
create policy "Authenticated users can read reactions"
  on public.social_post_reactions for select to authenticated using (true);

create policy "Authorized parents and admins can manage reactions"
  on public.social_post_reactions for all to authenticated
  using ((select public.is_authorized_learner_parent(learner_id)) or (select public.has_role('super_admin')))
  with check ((select public.is_authorized_learner_parent(learner_id)) or (select public.has_role('super_admin')));

-- Comments RLS
create policy "Authenticated users can read comments"
  on public.social_post_comments for select to authenticated
  using (status = 'published' or (select public.is_authorized_learner_parent(author_learner_id)) or (select public.has_role('super_admin')));

create policy "Authorized parents and admins can manage comments"
  on public.social_post_comments for all to authenticated
  using ((select public.is_authorized_learner_parent(author_learner_id)) or (select public.has_role('super_admin')))
  with check ((select public.is_authorized_learner_parent(author_learner_id)) or (select public.has_role('super_admin')));

-- Saved Posts RLS
create policy "Authorized parents can manage saved posts"
  on public.saved_posts for all to authenticated
  using ((select public.is_authorized_learner_parent(learner_id)) or (select public.has_role('super_admin')))
  with check ((select public.is_authorized_learner_parent(learner_id)) or (select public.has_role('super_admin')));

-- Follows RLS
create policy "Authorized parents can manage follows"
  on public.learner_follows for all to authenticated
  using (
    (select public.is_authorized_learner_parent(follower_learner_id))
    or (select public.is_authorized_learner_parent(target_learner_id))
    or (select public.has_role('super_admin'))
  )
  with check (
    (select public.is_authorized_learner_parent(follower_learner_id))
    or (select public.has_role('super_admin'))
  );

-- Blocks RLS
create policy "Authorized parents can manage blocks"
  on public.learner_blocks for all to authenticated
  using ((select public.is_authorized_learner_parent(blocker_learner_id)) or (select public.has_role('super_admin')))
  with check ((select public.is_authorized_learner_parent(blocker_learner_id)) or (select public.has_role('super_admin')));

-- ============================================================================
-- RPC FUNCTIONS
-- ============================================================================

-- RPC: Create Social Post
create or replace function public.create_social_post(
  p_author_learner_id uuid,
  p_post_type text,
  p_title text,
  p_content text,
  p_subject_id uuid default null,
  p_topic_id uuid default null,
  p_tags text[] default '{}'
)
returns public.social_posts
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_post public.social_posts%rowtype;
begin
  if not (public.is_authorized_learner_parent(p_author_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to create post for learner'
      using errcode = '42501';
  end if;

  insert into public.social_posts (
    author_learner_id,
    post_type,
    title,
    content,
    subject_id,
    topic_id,
    tags
  ) values (
    p_author_learner_id,
    p_post_type,
    btrim(p_title),
    btrim(p_content),
    p_subject_id,
    p_topic_id,
    coalesce(p_tags, '{}')
  ) returning * into v_post;

  -- Award points to author for contributing knowledge
  update public.learner_social_profiles
  set points = points + 10
  where learner_id = p_author_learner_id;

  return v_post;
end;
$$;

revoke all on function public.create_social_post(uuid, text, text, text, uuid, uuid, text[]) from public, anon;
grant execute on function public.create_social_post(uuid, text, text, text, uuid, uuid, text[]) to authenticated;

-- RPC: Toggle Post Reaction
create or replace function public.toggle_post_reaction(
  p_post_id uuid,
  p_learner_id uuid,
  p_reaction_type text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_exists boolean;
  v_author_learner_id uuid;
begin
  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to react on behalf of learner'
      using errcode = '42501';
  end if;

  select author_learner_id into v_author_learner_id
  from public.social_posts
  where id = p_post_id;

  if not found then
    raise exception 'Post not found: %', p_post_id using errcode = 'P0002';
  end if;

  select exists (
    select 1 from public.social_post_reactions
    where post_id = p_post_id
      and learner_id = p_learner_id
      and reaction_type = p_reaction_type
  ) into v_exists;

  if v_exists then
    delete from public.social_post_reactions
    where post_id = p_post_id
      and learner_id = p_learner_id
      and reaction_type = p_reaction_type;

    return jsonb_build_object('action', 'removed', 'post_id', p_post_id, 'reaction_type', p_reaction_type);
  else
    insert into public.social_post_reactions (post_id, learner_id, reaction_type)
    values (p_post_id, p_learner_id, p_reaction_type);

    -- Award points to post author for receiving reaction
    if v_author_learner_id <> p_learner_id then
      update public.learner_social_profiles
      set points = points + 2
      where learner_id = v_author_learner_id;
    end if;

    return jsonb_build_object('action', 'added', 'post_id', p_post_id, 'reaction_type', p_reaction_type);
  end if;
end;
$$;

revoke all on function public.toggle_post_reaction(uuid, uuid, text) from public, anon;
grant execute on function public.toggle_post_reaction(uuid, uuid, text) to authenticated;

-- RPC: Add Post Comment
create or replace function public.add_post_comment(
  p_post_id uuid,
  p_author_learner_id uuid,
  p_content text,
  p_parent_comment_id uuid default null
)
returns public.social_post_comments
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_comment public.social_post_comments%rowtype;
begin
  if not (public.is_authorized_learner_parent(p_author_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to comment on behalf of learner'
      using errcode = '42501';
  end if;

  if not exists (select 1 from public.social_posts where id = p_post_id and status = 'published') then
    raise exception 'Post does not exist or is not published'
      using errcode = 'P0002';
  end if;

  insert into public.social_post_comments (
    post_id,
    author_learner_id,
    parent_comment_id,
    content
  ) values (
    p_post_id,
    p_author_learner_id,
    p_parent_comment_id,
    btrim(p_content)
  ) returning * into v_comment;

  -- Award points for answering / commenting
  update public.learner_social_profiles
  set points = points + 5
  where learner_id = p_author_learner_id;

  return v_comment;
end;
$$;

revoke all on function public.add_post_comment(uuid, uuid, text, uuid) from public, anon;
grant execute on function public.add_post_comment(uuid, uuid, text, uuid) to authenticated;

-- RPC: Toggle Save / Bookmark Post
create or replace function public.toggle_save_post(
  p_post_id uuid,
  p_learner_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_saved boolean;
begin
  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to save post for learner'
      using errcode = '42501';
  end if;

  select exists (
    select 1 from public.saved_posts
    where post_id = p_post_id and learner_id = p_learner_id
  ) into v_saved;

  if v_saved then
    delete from public.saved_posts
    where post_id = p_post_id and learner_id = p_learner_id;
    return false;
  else
    insert into public.saved_posts (post_id, learner_id)
    values (p_post_id, p_learner_id);
    return true;
  end if;
end;
$$;

revoke all on function public.toggle_save_post(uuid, uuid) from public, anon;
grant execute on function public.toggle_save_post(uuid, uuid) to authenticated;

-- RPC: Toggle Follow Learner
create or replace function public.toggle_follow_learner(
  p_follower_learner_id uuid,
  p_target_learner_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_exists boolean;
  v_target_profile public.learner_social_profiles%rowtype;
begin
  if not (public.is_authorized_learner_parent(p_follower_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to follow on behalf of learner'
      using errcode = '42501';
  end if;

  if p_follower_learner_id = p_target_learner_id then
    raise exception 'Cannot follow self' using errcode = '23514';
  end if;

  select * into v_target_profile
  from public.learner_social_profiles
  where learner_id = p_target_learner_id;

  if not found or not v_target_profile.allow_follower_requests then
    raise exception 'Target learner does not accept follower requests'
      using errcode = '42501';
  end if;

  select exists (
    select 1 from public.learner_follows
    where follower_learner_id = p_follower_learner_id
      and target_learner_id = p_target_learner_id
  ) into v_exists;

  if v_exists then
    delete from public.learner_follows
    where follower_learner_id = p_follower_learner_id
      and target_learner_id = p_target_learner_id;

    return jsonb_build_object('action', 'unfollowed', 'is_following', false);
  else
    insert into public.learner_follows (follower_learner_id, target_learner_id, status)
    values (p_follower_learner_id, p_target_learner_id, 'active');

    return jsonb_build_object('action', 'followed', 'is_following', true);
  end if;
end;
$$;

revoke all on function public.toggle_follow_learner(uuid, uuid) from public, anon;
grant execute on function public.toggle_follow_learner(uuid, uuid) to authenticated;

-- RPC: Block Learner
create or replace function public.block_learner(
  p_blocker_learner_id uuid,
  p_blocked_learner_id uuid,
  p_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not (public.is_authorized_learner_parent(p_blocker_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to block learner'
      using errcode = '42501';
  end if;

  if p_blocker_learner_id = p_blocked_learner_id then
    raise exception 'Cannot block self' using errcode = '23514';
  end if;

  insert into public.learner_blocks (blocker_learner_id, blocked_learner_id, reason)
  values (p_blocker_learner_id, p_blocked_learner_id, p_reason)
  on conflict (blocker_learner_id, blocked_learner_id) do nothing;

  -- Remove mutual follows if any exist
  delete from public.learner_follows
  where (follower_learner_id = p_blocker_learner_id and target_learner_id = p_blocked_learner_id)
     or (follower_learner_id = p_blocked_learner_id and target_learner_id = p_blocker_learner_id);

  return true;
end;
$$;

revoke all on function public.block_learner(uuid, uuid, text) from public, anon;
grant execute on function public.block_learner(uuid, uuid, text) to authenticated;

-- RPC: Get Social Feed
create or replace function public.get_social_feed(
  p_viewer_learner_id uuid,
  p_post_type text default null,
  p_subject_id uuid default null,
  p_limit integer default 20,
  p_offset integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_posts jsonb;
begin
  select coalesce(jsonb_agg(post_row), '[]'::jsonb) into v_posts
  from (
    select
      p.id,
      p.author_learner_id,
      sp.display_name as author_display_name,
      sp.avatar_preset as author_avatar_preset,
      p.post_type,
      p.title,
      p.content,
      p.tags,
      p.likes_count,
      p.comments_count,
      p.bookmarks_count,
      p.created_at,
      p.subject_id,
      s.name as subject_name,
      exists (
        select 1 from public.social_post_reactions spr
        where spr.post_id = p.id and spr.learner_id = p_viewer_learner_id
      ) as viewer_has_reacted,
      exists (
        select 1 from public.saved_posts sp2
        where sp2.post_id = p.id and sp2.learner_id = p_viewer_learner_id
      ) as viewer_has_saved
    from public.social_posts p
    join public.learner_social_profiles sp on sp.learner_id = p.author_learner_id
    left join public.subjects s on s.id = p.subject_id
    where p.status = 'published'
      and (p_post_type is null or p.post_type = p_post_type)
      and (p_subject_id is null or p.subject_id = p_subject_id)
      -- Child protection: exclude posts from blocked learners
      and not exists (
        select 1 from public.learner_blocks lb
        where (lb.blocker_learner_id = p_viewer_learner_id and lb.blocked_learner_id = p.author_learner_id)
           or (lb.blocker_learner_id = p.author_learner_id and lb.blocked_learner_id = p_viewer_learner_id)
      )
    order by p.created_at desc
    limit greatest(1, least(p_limit, 50))
    offset greatest(0, p_offset)
  ) post_row;

  return v_posts;
end;
$$;

revoke all on function public.get_social_feed(uuid, text, uuid, integer, integer) from public, anon;
grant execute on function public.get_social_feed(uuid, text, uuid, integer, integer) to authenticated;

-- RPC: Get Post Comments
create or replace function public.get_post_comments(
  p_post_id uuid,
  p_viewer_learner_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_comments jsonb;
begin
  select coalesce(jsonb_agg(comm_row), '[]'::jsonb) into v_comments
  from (
    select
      c.id,
      c.post_id,
      c.author_learner_id,
      sp.display_name as author_display_name,
      sp.avatar_preset as author_avatar_preset,
      c.parent_comment_id,
      c.content,
      c.created_at
    from public.social_post_comments c
    join public.learner_social_profiles sp on sp.learner_id = c.author_learner_id
    where c.post_id = p_post_id
      and c.status = 'published'
      and (
        p_viewer_learner_id is null or not exists (
          select 1 from public.learner_blocks lb
          where (lb.blocker_learner_id = p_viewer_learner_id and lb.blocked_learner_id = c.author_learner_id)
             or (lb.blocker_learner_id = c.author_learner_id and lb.blocked_learner_id = p_viewer_learner_id)
        )
      )
    order by c.created_at asc
  ) comm_row;

  return v_comments;
end;
$$;

revoke all on function public.get_post_comments(uuid, uuid) from public, anon;
grant execute on function public.get_post_comments(uuid, uuid) to authenticated;
