-- Phase 3 Sub-Stage 5: Moderation Queue, Child Protection & Social Notifications
-- Migration: 20261113001100_phase3_moderation_and_notifications.sql

-- 1. Social Moderation Reports
create table public.social_moderation_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_learner_id uuid not null references public.learners (id) on delete cascade,
  target_type text not null
    check (target_type in ('post', 'comment', 'channel_message', 'learner_profile')),
  target_id uuid not null,
  reason_category text not null
    check (reason_category in (
      'inappropriate_language',
      'contact_sharing',
      'bullying_harassment',
      'non_educational',
      'misinformation',
      'other'
    )),
  details text check (details is null or char_length(details) <= 500),
  status text not null default 'pending'
    check (status in ('pending', 'under_review', 'resolved_action_taken', 'resolved_dismissed')),
  moderator_user_id uuid references auth.users (id) on delete set null,
  action_taken text
    check (action_taken is null or action_taken in ('hidden', 'deleted', 'warning_issued', 'learner_suspended', 'dismissed')),
  resolution_notes text,
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

create index social_moderation_reports_status_idx
  on public.social_moderation_reports (status, created_at desc);
create index social_moderation_reports_target_idx
  on public.social_moderation_reports (target_type, target_id);

-- 2. Social Notifications
create table public.social_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_learner_id uuid not null references public.learners (id) on delete cascade,
  actor_learner_id uuid references public.learners (id) on delete cascade,
  notification_type text not null
    check (notification_type in (
      'reaction_received',
      'comment_received',
      'mention',
      'challenge_available',
      'badge_awarded',
      'community_announcement',
      'moderation_alert'
    )),
  title text not null check (char_length(btrim(title)) between 2 and 140),
  body text not null check (char_length(btrim(body)) between 2 and 500),
  target_route text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index social_notifications_recipient_idx
  on public.social_notifications (recipient_learner_id, is_read, created_at desc);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.social_moderation_reports enable row level security;
alter table public.social_notifications enable row level security;

-- Reports RLS
create policy "Authorized parents and staff can file reports"
  on public.social_moderation_reports for insert to authenticated
  with check (
    (select public.is_authorized_learner_parent(reporter_learner_id))
    or (select public.has_role('super_admin'))
  );

create policy "Reporters and staff can read reports"
  on public.social_moderation_reports for select to authenticated
  using (
    (select public.is_authorized_learner_parent(reporter_learner_id))
    or (select public.has_role('super_admin'))
    or (select public.has_role('support_admin'))
  );

create policy "Staff can update reports"
  on public.social_moderation_reports for update to authenticated
  using (
    (select public.has_role('super_admin'))
    or (select public.has_role('support_admin'))
  );

-- Notifications RLS
create policy "Learners and parents can read notifications"
  on public.social_notifications for select to authenticated
  using (
    (select public.is_authorized_learner_parent(recipient_learner_id))
    or (select public.has_role('super_admin'))
  );

create policy "Learners and parents can update notifications"
  on public.social_notifications for update to authenticated
  using (
    (select public.is_authorized_learner_parent(recipient_learner_id))
    or (select public.has_role('super_admin'))
  );

-- ============================================================================
-- RPC FUNCTIONS
-- ============================================================================

-- RPC: Report Inappropriate Social Content
create or replace function public.report_social_content(
  p_reporter_learner_id uuid,
  p_target_type text,
  p_target_id uuid,
  p_reason_category text,
  p_details text default null
)
returns public.social_moderation_reports
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_report public.social_moderation_reports%rowtype;
  v_count integer;
begin
  if not (public.is_authorized_learner_parent(p_reporter_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to file report on behalf of learner' using errcode = '42501';
  end if;

  insert into public.social_moderation_reports (
    reporter_learner_id,
    target_type,
    target_id,
    reason_category,
    details
  ) values (
    p_reporter_learner_id,
    p_target_type,
    p_target_id,
    p_reason_category,
    p_details
  ) returning * into v_report;

  -- Auto-flag if multiple reports exist for this target
  select count(*) into v_count
  from public.social_moderation_reports
  where target_type = p_target_type and target_id = p_target_id and status = 'pending';

  if v_count >= 2 then
    if p_target_type = 'post' then
      update public.social_posts set status = 'flagged' where id = p_target_id;
    elsif p_target_type = 'comment' then
      update public.social_post_comments set status = 'flagged' where id = p_target_id;
    elsif p_target_type = 'channel_message' then
      update public.channel_messages set status = 'flagged' where id = p_target_id;
    end if;
  end if;

  return v_report;
end;
$$;

revoke all on function public.report_social_content(uuid, text, uuid, text, text) from public, anon;
grant execute on function public.report_social_content(uuid, text, uuid, text, text) to authenticated;

-- RPC: Get Moderation Queue (Staff & Super Admin)
create or replace function public.get_moderation_queue(
  p_status text default 'pending',
  p_limit integer default 25
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_queue jsonb;
begin
  if not (public.has_role('super_admin') or public.has_role('support_admin')) then
    raise exception 'Unauthorized to access moderation queue' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(q_row), '[]'::jsonb) into v_queue
  from (
    select
      r.id,
      r.reporter_learner_id,
      sp.display_name as reporter_display_name,
      r.target_type,
      r.target_id,
      r.reason_category,
      r.details,
      r.status,
      r.created_at,
      case r.target_type
        when 'post' then (select title || ' - ' || left(content, 80) from public.social_posts where id = r.target_id)
        when 'comment' then (select left(content, 100) from public.social_post_comments where id = r.target_id)
        when 'channel_message' then (select left(content, 100) from public.channel_messages where id = r.target_id)
        when 'learner_profile' then (select display_name from public.learner_social_profiles where learner_id = r.target_id)
        else null
      end as target_preview
    from public.social_moderation_reports r
    join public.learner_social_profiles sp on sp.learner_id = r.reporter_learner_id
    where (p_status is null or r.status = p_status)
    order by r.created_at desc
    limit greatest(1, least(p_limit, 50))
  ) q_row;

  return v_queue;
end;
$$;

revoke all on function public.get_moderation_queue(text, integer) from public, anon;
grant execute on function public.get_moderation_queue(text, integer) to authenticated;

-- RPC: Review Moderation Report (Staff & Super Admin)
create or replace function public.review_moderation_report(
  p_report_id uuid,
  p_action text,
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_report public.social_moderation_reports%rowtype;
begin
  if not (public.has_role('super_admin') or public.has_role('support_admin')) then
    raise exception 'Unauthorized to review moderation reports' using errcode = '42501';
  end if;

  select * into v_report
  from public.social_moderation_reports
  where id = p_report_id;

  if not found then
    raise exception 'Report not found' using errcode = 'P0002';
  end if;

  if p_action not in ('hidden', 'deleted', 'warning_issued', 'learner_suspended', 'dismissed') then
    raise exception 'Invalid moderation action: %', p_action using errcode = '23514';
  end if;

  -- Apply action to target
  if p_action in ('hidden', 'deleted') then
    if v_report.target_type = 'post' then
      update public.social_posts set status = 'hidden' where id = v_report.target_id;
    elsif v_report.target_type = 'comment' then
      update public.social_post_comments set status = 'hidden' where id = v_report.target_id;
    elsif v_report.target_type = 'channel_message' then
      update public.channel_messages set status = 'hidden' where id = v_report.target_id;
    end if;
  end if;

  update public.social_moderation_reports
  set
    status = case when p_action = 'dismissed' then 'resolved_dismissed' else 'resolved_action_taken' end,
    moderator_user_id = auth.uid(),
    action_taken = p_action,
    resolution_notes = p_notes,
    resolved_at = now()
  where id = p_report_id;

  return jsonb_build_object(
    'report_id', p_report_id,
    'action_taken', p_action,
    'status', case when p_action = 'dismissed' then 'resolved_dismissed' else 'resolved_action_taken' end,
    'resolved_at', now()
  );
end;
$$;

revoke all on function public.review_moderation_report(uuid, text, text) from public, anon;
grant execute on function public.review_moderation_report(uuid, text, text) to authenticated;

-- RPC: Get Learner Social Notifications
create or replace function public.get_learner_social_notifications(
  p_learner_id uuid,
  p_unread_only boolean default false,
  p_limit integer default 25
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_notifs jsonb;
begin
  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to view learner notifications' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(n_row), '[]'::jsonb) into v_notifs
  from (
    select
      n.id,
      n.recipient_learner_id,
      n.actor_learner_id,
      sp.display_name as actor_display_name,
      sp.avatar_preset as actor_avatar_preset,
      n.notification_type,
      n.title,
      n.body,
      n.target_route,
      n.is_read,
      n.created_at
    from public.social_notifications n
    left join public.learner_social_profiles sp on sp.learner_id = n.actor_learner_id
    where n.recipient_learner_id = p_learner_id
      and (not p_unread_only or not n.is_read)
    order by n.created_at desc
    limit greatest(1, least(p_limit, 50))
  ) n_row;

  return v_notifs;
end;
$$;

revoke all on function public.get_learner_social_notifications(uuid, boolean, integer) from public, anon;
grant execute on function public.get_learner_social_notifications(uuid, boolean, integer) to authenticated;

-- RPC: Mark Notifications Read
create or replace function public.mark_notifications_read(
  p_learner_id uuid,
  p_notification_ids uuid[] default null
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_updated integer;
begin
  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Unauthorized to update learner notifications' using errcode = '42501';
  end if;

  update public.social_notifications
  set is_read = true
  where recipient_learner_id = p_learner_id
    and (p_notification_ids is null or id = any(p_notification_ids))
    and not is_read;

  get diagnostics v_updated = row_count;
  return v_updated;
end;
$$;

revoke all on function public.mark_notifications_read(uuid, uuid[]) from public, anon;
grant execute on function public.mark_notifications_read(uuid, uuid[]) to authenticated;

-- Automatic notification trigger for reactions & comments
create or replace function public.trg_notify_social_interaction()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_target_learner_id uuid;
  v_actor_display text;
begin
  if TG_TABLE_NAME = 'social_post_reactions' then
    select author_learner_id into v_target_learner_id
    from public.social_posts where id = new.post_id;

    if v_target_learner_id is not null and v_target_learner_id <> new.learner_id then
      select display_name into v_actor_display
      from public.learner_social_profiles where learner_id = new.learner_id;

      insert into public.social_notifications (
        recipient_learner_id,
        actor_learner_id,
        notification_type,
        title,
        body,
        target_route
      ) values (
        v_target_learner_id,
        new.learner_id,
        'reaction_received',
        'Reaction on your post',
        coalesce(v_actor_display, 'A classmate') || ' reacted ' || new.reaction_type || ' to your post.',
        '/social/feed'
      );
    end if;
  elsif TG_TABLE_NAME = 'social_post_comments' then
    select author_learner_id into v_target_learner_id
    from public.social_posts where id = new.post_id;

    if v_target_learner_id is not null and v_target_learner_id <> new.author_learner_id then
      select display_name into v_actor_display
      from public.learner_social_profiles where learner_id = new.author_learner_id;

      insert into public.social_notifications (
        recipient_learner_id,
        actor_learner_id,
        notification_type,
        title,
        body,
        target_route
      ) values (
        v_target_learner_id,
        new.author_learner_id,
        'comment_received',
        'New answer or comment',
        coalesce(v_actor_display, 'A classmate') || ' answered: ' || left(new.content, 60),
        '/social/feed'
      );
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_notify_reaction on public.social_post_reactions;
create trigger trg_notify_reaction
  after insert on public.social_post_reactions
  for each row execute function public.trg_notify_social_interaction();

drop trigger if exists trg_notify_comment on public.social_post_comments;
create trigger trg_notify_comment
  after insert on public.social_post_comments
  for each row execute function public.trg_notify_social_interaction();
