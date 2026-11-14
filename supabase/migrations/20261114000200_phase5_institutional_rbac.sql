-- LearnTZ Enterprise SaaS: Phase 5 Sub-Stage 2
-- Institutional Role-Based Access Control, Staff Directory & Invitation Engine
-- Target Jurisdictions: Tanzania, Kenya, Uganda

begin;

-- 1. Custom Enum Types
do $$
begin
  if not exists (select 1 from pg_type where typname = 'institutional_role') then
    create type public.institutional_role as enum (
      'institutional_admin',
      'education_officer',
      'school_principal',
      'head_of_department',
      'teacher',
      'curriculum_analyst',
      'researcher',
      'partner_auditor'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'membership_status') then
    create type public.membership_status as enum (
      'invited',
      'active',
      'suspended',
      'archived'
    );
  end if;
end $$;

-- 2. Organization Memberships Table
create table if not exists public.organization_memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role public.institutional_role not null,
  job_title text check (job_title is null or char_length(btrim(job_title)) <= 120),
  department text check (department is null or char_length(btrim(department)) <= 120),
  permissions text[] not null default '{}',
  status public.membership_status not null default 'active',
  invited_by_user_id uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_organization_user_membership unique (organization_id, user_id)
);

create index if not exists idx_org_memberships_user
  on public.organization_memberships (user_id, status);

create index if not exists idx_org_memberships_org_role
  on public.organization_memberships (organization_id, role, status);

-- 3. Organization Staff Invitations Table
create table if not exists public.organization_invitations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  email text not null check (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  role public.institutional_role not null,
  job_title text,
  department text,
  token text not null unique default encode(gen_random_bytes(32), 'hex'),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined', 'expired', 'revoked')),
  invited_by_user_id uuid not null references auth.users (id) on delete cascade,
  expires_at timestamptz not null default (now() + interval '14 days'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_org_invitations_email_status
  on public.organization_invitations (lower(email), status);

-- 4. Helper Security Functions
create or replace function public.get_user_organization_ids(p_user_id uuid)
returns setof uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select organization_id from public.organization_memberships
  where user_id = p_user_id and status = 'active';
$$;

create or replace function public.has_institutional_permission(
  p_org_id uuid,
  p_permission text
)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    return false;
  end if;

  -- Platform super admins have universal institutional permission
  if public.has_role('super_admin') then
    return true;
  end if;

  -- Institutional admin role has all permissions implicitly
  if exists (
    select 1 from public.organization_memberships
    where organization_id = p_org_id
      and user_id = v_user_id
      and role = 'institutional_admin'
      and status = 'active'
  ) then
    return true;
  end if;

  -- Check explicit permission in text array
  return exists (
    select 1 from public.organization_memberships
    where organization_id = p_org_id
      and user_id = v_user_id
      and status = 'active'
      and p_permission = any(permissions)
  );
end;
$$;

create or replace function public.has_institutional_role(
  p_org_id uuid,
  p_roles public.institutional_role[]
)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    return false;
  end if;

  if public.has_role('super_admin') then
    return true;
  end if;

  return exists (
    select 1 from public.organization_memberships
    where organization_id = p_org_id
      and user_id = v_user_id
      and role = any(p_roles)
      and status = 'active'
  );
end;
$$;

-- 5. Row-Level Security
alter table public.organization_memberships enable row level security;
alter table public.organization_invitations enable row level security;

-- Memberships RLS
create policy "Users can view members of their organizations"
  on public.organization_memberships
  for select
  to authenticated
  using (
    public.has_role('super_admin')
    or user_id = auth.uid()
    or organization_id in (select public.get_user_organization_ids(auth.uid()))
  );

create policy "Admins can manage memberships"
  on public.organization_memberships
  for all
  to authenticated
  using (
    public.has_role('super_admin')
    or public.has_institutional_permission(organization_id, 'manage_members')
  )
  with check (
    public.has_role('super_admin')
    or public.has_institutional_permission(organization_id, 'manage_members')
  );

-- Invitations RLS
create policy "Staff can view invitations for their organization"
  on public.organization_invitations
  for select
  to authenticated
  using (
    public.has_role('super_admin')
    or lower(email) = public.current_user_email()
    or public.has_institutional_permission(organization_id, 'manage_members')
  );

-- 6. Security-Definer RPCs

-- 6.1 Invite Staff Member
create or replace function public.invite_organization_member(
  p_org_id uuid,
  p_email text,
  p_role public.institutional_role,
  p_job_title text default null,
  p_department text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_invitation_id uuid;
  v_clean_email text := lower(btrim(p_email));
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if not (
    public.has_role('super_admin')
    or public.has_institutional_permission(p_org_id, 'manage_members')
  ) then
    raise exception 'Permission denied: cannot manage members in this organization'
      using errcode = '42501';
  end if;

  -- Check if already an active member
  if exists (
    select 1 from public.organization_memberships m
    join auth.users u on m.user_id = u.id
    where m.organization_id = p_org_id
      and lower(u.email) = v_clean_email
      and m.status = 'active'
  ) then
    raise exception 'User with email % is already an active member of this organization', v_clean_email
      using errcode = '23505';
  end if;

  -- Invalidate any existing pending invitation for this email in this org
  update public.organization_invitations
  set status = 'revoked', updated_at = now()
  where organization_id = p_org_id
    and lower(email) = v_clean_email
    and status = 'pending';

  insert into public.organization_invitations (
    organization_id,
    email,
    role,
    job_title,
    department,
    invited_by_user_id
  ) values (
    p_org_id,
    v_clean_email,
    p_role,
    p_job_title,
    p_department,
    v_user_id
  ) returning id into v_invitation_id;

  return v_invitation_id;
end;
$$;

-- 6.2 Respond to Organization Invitation
create or replace function public.respond_organization_invitation(
  p_invitation_id uuid,
  p_accept boolean
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_user_email text;
  v_invitation record;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select lower(email) into v_user_email from auth.users where id = v_user_id;

  select * into v_invitation
  from public.organization_invitations
  where id = p_invitation_id
    and status = 'pending';

  if v_invitation is null then
    raise exception 'Invitation not found or no longer pending' using errcode = '22023';
  end if;

  if now() > v_invitation.expires_at then
    update public.organization_invitations
    set status = 'expired', updated_at = now()
    where id = p_invitation_id;
    raise exception 'Invitation has expired' using errcode = '22023';
  end if;

  if lower(v_invitation.email) <> v_user_email then
    raise exception 'Invitation email % does not match authenticated user email %',
      v_invitation.email, v_user_email
      using errcode = '42501';
  end if;

  if p_accept then
    -- Insert or reactivate membership
    insert into public.organization_memberships (
      organization_id,
      user_id,
      role,
      job_title,
      department,
      status,
      invited_by_user_id
    ) values (
      v_invitation.organization_id,
      v_user_id,
      v_invitation.role,
      v_invitation.job_title,
      v_invitation.department,
      'active',
      v_invitation.invited_by_user_id
    )
    on conflict (organization_id, user_id) do update
      set role = excluded.role,
          job_title = excluded.job_title,
          department = excluded.department,
          status = 'active',
          updated_at = now();

    update public.organization_invitations
    set status = 'accepted', updated_at = now()
    where id = p_invitation_id;

    return true;
  else
    update public.organization_invitations
    set status = 'declined', updated_at = now()
    where id = p_invitation_id;

    return false;
  end if;
end;
$$;

-- 6.3 List Organization Members
create or replace function public.list_organization_members(p_org_id uuid)
returns table (
  membership_id uuid,
  user_id uuid,
  full_name text,
  email text,
  role public.institutional_role,
  job_title text,
  department text,
  status public.membership_status,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    m.id as membership_id,
    m.user_id,
    coalesce(p.full_name, u.raw_user_meta_data->>'full_name', 'Staff Member') as full_name,
    u.email,
    m.role,
    m.job_title,
    m.department,
    m.status,
    m.created_at
  from public.organization_memberships m
  join auth.users u on m.user_id = u.id
  left join public.profiles p on m.user_id = p.id
  where m.organization_id = p_org_id
  order by m.role asc, m.created_at asc;
$$;

-- 6.4 Get User's Institutional Workspaces
create or replace function public.get_user_institutional_workspaces()
returns table (
  organization_id uuid,
  name text,
  slug text,
  type public.organization_type,
  country_code text,
  brand_color text,
  logo_url text,
  role public.institutional_role,
  job_title text,
  department text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    o.id as organization_id,
    o.name,
    o.slug,
    o.type,
    o.country_code,
    o.brand_color,
    o.logo_url,
    m.role,
    m.job_title,
    m.department
  from public.organization_memberships m
  join public.organizations o on m.organization_id = o.id
  where m.user_id = auth.uid()
    and m.status = 'active'
    and o.status = 'active'
  order by o.name asc;
$$;

-- 6.5 Update Member Role
create or replace function public.update_organization_member_role(
  p_membership_id uuid,
  p_new_role public.institutional_role,
  p_job_title text default null
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org_id uuid;
begin
  select organization_id into v_org_id
  from public.organization_memberships
  where id = p_membership_id;

  if v_org_id is null then
    raise exception 'Membership record % not found', p_membership_id using errcode = '22023';
  end if;

  if not (
    public.has_role('super_admin')
    or public.has_institutional_permission(v_org_id, 'manage_members')
  ) then
    raise exception 'Permission denied: cannot manage member roles in this organization'
      using errcode = '42501';
  end if;

  update public.organization_memberships
  set role = p_new_role,
      job_title = coalesce(p_job_title, job_title),
      updated_at = now()
  where id = p_membership_id;

  return true;
end;
$$;

-- 6.6 Remove Member
create or replace function public.remove_organization_member(p_membership_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org_id uuid;
begin
  select organization_id into v_org_id
  from public.organization_memberships
  where id = p_membership_id;

  if v_org_id is null then
    raise exception 'Membership record % not found', p_membership_id using errcode = '22023';
  end if;

  if not (
    public.has_role('super_admin')
    or public.has_institutional_permission(v_org_id, 'manage_members')
  ) then
    raise exception 'Permission denied: cannot remove members in this organization'
      using errcode = '42501';
  end if;

  update public.organization_memberships
  set status = 'archived',
      updated_at = now()
  where id = p_membership_id;

  return true;
end;
$$;

commit;
