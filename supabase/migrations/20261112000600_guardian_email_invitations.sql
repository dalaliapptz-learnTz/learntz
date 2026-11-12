begin;

-- Helper to safely retrieve the authenticated user's normalized email
create or replace function public.current_user_email()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select lower(email)
  from auth.users
  where id = (select auth.uid());
$$;

revoke all on function public.current_user_email() from public, anon;
grant execute on function public.current_user_email() to authenticated;

-- Table for email-based guardian invitations
create table public.guardian_invitations (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references public.learners (id) on delete cascade,
  inviter_user_id uuid not null references public.profiles (id) on delete cascade,
  invitee_email text not null
    check (char_length(btrim(invitee_email)) between 3 and 255),
  status text not null default 'pending' check (status in (
    'pending', 'accepted', 'declined', 'revoked', 'expired'
  )),
  expires_at timestamptz not null default (now() + interval '7 days'),
  responded_at timestamptz,
  responded_by_user_id uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index guardian_invitations_pending_unique_idx
  on public.guardian_invitations (learner_id, lower(invitee_email))
  where status = 'pending';

create index guardian_invitations_invitee_email_idx
  on public.guardian_invitations (lower(invitee_email), status);

create index guardian_invitations_learner_idx
  on public.guardian_invitations (learner_id, status);

create trigger guardian_invitations_set_updated_at
  before update on public.guardian_invitations
  for each row execute function public.set_updated_at();

alter table public.guardian_invitations enable row level security;

revoke all on public.guardian_invitations from public, anon, authenticated;
grant select on public.guardian_invitations to authenticated;

create policy "Authorized learner parents can read guardian invitations"
  on public.guardian_invitations for select to authenticated
  using ((select public.is_authorized_learner_parent(learner_id)));

create policy "Invitees can read their own pending guardian invitations"
  on public.guardian_invitations for select to authenticated
  using (
    lower(invitee_email) = (select public.current_user_email())
    and status = 'pending'
    and expires_at > now()
  );

-- Invite a guardian by email without leaking whether the account exists
create or replace function public.invite_learner_guardian_by_email(
  p_learner_id uuid,
  p_invitee_email text
)
returns public.guardian_invitations
language plpgsql
security definer
set search_path = ''
as $$
declare
  acting_user uuid := auth.uid();
  caller_email text := public.current_user_email();
  normalized_email text := lower(btrim(coalesce(p_invitee_email, '')));
  invitation_record public.guardian_invitations;
begin
  if acting_user is null or not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'You are not authorized to manage this learner'
      using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.learners learner
    where learner.id = p_learner_id and learner.status = 'active'
  ) then
    raise exception 'The learner is not active'
      using errcode = '55000';
  end if;

  if normalized_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
     or char_length(normalized_email) > 255 then
    raise exception 'A valid email address is required'
      using errcode = '22023';
  end if;

  if caller_email is not null and normalized_email = caller_email then
    raise exception 'You cannot invite your own email address'
      using errcode = '22023';
  end if;

  -- Upsert pending invitation (refresh expiration if already pending)
  insert into public.guardian_invitations (
    learner_id, inviter_user_id, invitee_email, status, expires_at
  )
  values (
    p_learner_id, acting_user, normalized_email, 'pending', now() + interval '7 days'
  )
  on conflict (learner_id, lower(invitee_email)) where status = 'pending'
  do update set
    expires_at = now() + interval '7 days',
    inviter_user_id = acting_user,
    updated_at = now()
  returning * into invitation_record;

  perform public.write_audit_log(
    acting_user,
    null,
    'guardian.email_invited',
    jsonb_build_object(
      'learner_id', p_learner_id,
      'invitation_id', invitation_record.id
    )
  );

  return invitation_record;
end;
$$;

-- List incoming pending invitations for the authenticated parent with safe display metadata
create or replace function public.list_incoming_guardian_invitations()
returns table (
  id uuid,
  learner_id uuid,
  learner_name text,
  inviter_name text,
  invitee_email text,
  expires_at timestamptz,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_email text := public.current_user_email();
begin
  if auth.uid() is null or caller_email is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  return query
  select
    inv.id,
    inv.learner_id,
    concat_ws(' ', l.first_name, l.middle_name, l.last_name) as learner_name,
    p.full_name as inviter_name,
    inv.invitee_email,
    inv.expires_at,
    inv.created_at
  from public.guardian_invitations inv
  join public.learners l on l.id = inv.learner_id
  join public.profiles p on p.id = inv.inviter_user_id
  where lower(inv.invitee_email) = caller_email
    and inv.status = 'pending'
    and inv.expires_at > now()
    and l.status = 'active'
  order by inv.created_at desc;
end;
$$;

-- Respond to a pending guardian invitation (accept or decline)
create or replace function public.respond_guardian_invitation(
  p_invitation_id uuid,
  p_accept boolean
)
returns public.guardian_invitations
language plpgsql
security definer
set search_path = ''
as $$
declare
  acting_user uuid := auth.uid();
  caller_email text := public.current_user_email();
  invitation_record public.guardian_invitations;
begin
  if acting_user is null or caller_email is null or not exists (
    select 1 from public.parent_accounts account
    join public.account_status account_state
      on account_state.user_id = account.user_id
    join public.user_roles role_assignment
      on role_assignment.user_id = account.user_id
    where account.user_id = acting_user
      and account_state.status = 'active'
      and role_assignment.role = 'parent'
  ) then
    raise exception 'An active parent account is required'
      using errcode = '42501';
  end if;

  select * into invitation_record
  from public.guardian_invitations
  where id = p_invitation_id
    and lower(invitee_email) = caller_email
    and status = 'pending'
  for update;

  if not found then
    raise exception 'The guardian invitation is unavailable'
      using errcode = '42501';
  end if;

  if invitation_record.expires_at <= now() then
    update public.guardian_invitations
    set status = 'expired', updated_at = now()
    where id = invitation_record.id;
    raise exception 'The guardian invitation has expired'
      using errcode = '22023';
  end if;

  if p_accept then
    insert into public.parent_learners (
      learner_id, parent_user_id, relationship_role,
      relationship_status, created_by_parent_user_id
    )
    values (
      invitation_record.learner_id,
      acting_user,
      'guardian',
      'active',
      invitation_record.inviter_user_id
    )
    on conflict (learner_id, parent_user_id) do update
      set relationship_status = 'active',
          updated_at = now();

    update public.guardian_invitations
    set status = 'accepted',
        responded_at = now(),
        responded_by_user_id = acting_user,
        updated_at = now()
    where id = invitation_record.id
    returning * into invitation_record;

    perform public.write_audit_log(
      acting_user,
      invitation_record.inviter_user_id,
      'guardian.invitation_accepted',
      jsonb_build_object(
        'learner_id', invitation_record.learner_id,
        'invitation_id', invitation_record.id
      )
    );
  else
    update public.guardian_invitations
    set status = 'declined',
        responded_at = now(),
        responded_by_user_id = acting_user,
        updated_at = now()
    where id = invitation_record.id
    returning * into invitation_record;

    perform public.write_audit_log(
      acting_user,
      invitation_record.inviter_user_id,
      'guardian.invitation_declined',
      jsonb_build_object(
        'learner_id', invitation_record.learner_id,
        'invitation_id', invitation_record.id
      )
    );
  end if;

  return invitation_record;
end;
$$;

-- Revoke a pending guardian invitation by an authorized parent
create or replace function public.revoke_guardian_invitation(
  p_invitation_id uuid
)
returns public.guardian_invitations
language plpgsql
security definer
set search_path = ''
as $$
declare
  acting_user uuid := auth.uid();
  invitation_record public.guardian_invitations;
begin
  select * into invitation_record
  from public.guardian_invitations
  where id = p_invitation_id
    and status = 'pending'
  for update;

  if not found or not public.is_authorized_learner_parent(invitation_record.learner_id) then
    raise exception 'You are not authorized to revoke this invitation'
      using errcode = '42501';
  end if;

  update public.guardian_invitations
  set status = 'revoked',
      updated_at = now()
  where id = invitation_record.id
  returning * into invitation_record;

  perform public.write_audit_log(
    acting_user,
    null,
    'guardian.invitation_revoked',
    jsonb_build_object(
      'learner_id', invitation_record.learner_id,
      'invitation_id', invitation_record.id
    )
  );

  return invitation_record;
end;
$$;

revoke all on function public.invite_learner_guardian_by_email(uuid, text) from public, anon;
revoke all on function public.list_incoming_guardian_invitations() from public, anon;
revoke all on function public.respond_guardian_invitation(uuid, boolean) from public, anon;
revoke all on function public.revoke_guardian_invitation(uuid) from public, anon;

grant execute on function public.invite_learner_guardian_by_email(uuid, text) to authenticated;
grant execute on function public.list_incoming_guardian_invitations() to authenticated;
grant execute on function public.respond_guardian_invitation(uuid, boolean) to authenticated;
grant execute on function public.revoke_guardian_invitation(uuid) to authenticated;

commit;
