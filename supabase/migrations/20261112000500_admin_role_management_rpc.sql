begin;

-- Function: assign_user_role
-- Allows super_admin or service_role to grant a role to a user with validation and audit logging
create or replace function public.assign_user_role(
  p_user_id uuid,
  p_role text,
  p_country_code text default null
)
returns public.user_roles
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_profile public.profiles;
  assignment_record public.user_roles;
  normalized_country text := nullif(upper(btrim(coalesce(p_country_code, ''))), '');
begin
  -- 1. Authorization: service_role or active super_admin
  if auth.role() is distinct from 'service_role' and not public.has_role('super_admin') then
    raise exception 'Super administrator authorization is required' using errcode = '42501';
  end if;

  -- 2. Validate target user exists
  select * into target_profile
  from public.profiles
  where id = p_user_id;
  if not found then
    raise exception 'Target user profile % was not found', p_user_id using errcode = '22023';
  end if;

  -- 3. Validate role name
  if p_role not in (
    'super_admin', 'country_admin', 'content_admin',
    'finance_admin', 'support_admin', 'parent', 'learner',
    'curriculum_editor', 'curriculum_reviewer',
    'curriculum_approver', 'curriculum_admin'
  ) then
    raise exception 'Invalid role: %', p_role using errcode = '22023';
  end if;

  -- 4. Validate country scoping constraint
  if p_role in ('country_admin', 'curriculum_editor', 'curriculum_reviewer', 'curriculum_approver', 'curriculum_admin') then
    if normalized_country is null then
      raise exception 'A country code is required for country-scoped role %', p_role using errcode = '22023';
    end if;
    if not exists (
      select 1 from public.countries
      where country_code = normalized_country and is_enabled
    ) then
      raise exception 'Country code % is not a valid enabled country', normalized_country using errcode = '22023';
    end if;
  else
    if normalized_country is not null and p_role in ('super_admin', 'parent', 'learner') then
      raise exception 'Country code must be null for role %', p_role using errcode = '22023';
    end if;
  end if;

  -- 5. Upsert role assignment
  insert into public.user_roles (user_id, role, country_code)
  values (p_user_id, p_role, normalized_country)
  on conflict (user_id, role, coalesce(country_code, ''))
  do update set updated_at = now()
  returning * into assignment_record;

  return assignment_record;
end;
$$;

-- Function: revoke_user_role
-- Allows super_admin or service_role to revoke a role from a user with safety checks
create or replace function public.revoke_user_role(
  p_user_id uuid,
  p_role text,
  p_country_code text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_country text := nullif(upper(btrim(coalesce(p_country_code, ''))), '');
  deleted_count integer := 0;
begin
  -- 1. Authorization: service_role or active super_admin
  if auth.role() is distinct from 'service_role' and not public.has_role('super_admin') then
    raise exception 'Super administrator authorization is required' using errcode = '42501';
  end if;

  -- 2. Safety check: do not revoke the last remaining super_admin
  if p_role = 'super_admin' then
    if (
      select count(*)
      from public.user_roles
      where role = 'super_admin' and user_id <> p_user_id
    ) < 1 then
      raise exception 'Cannot revoke the last super administrator' using errcode = '55000';
    end if;
  end if;

  -- 3. Delete assignment
  delete from public.user_roles
  where user_id = p_user_id
    and role = p_role
    and (country_code is not distinct from normalized_country);

  get diagnostics deleted_count = row_count;
  return deleted_count > 0;
end;
$$;

-- Permissions
revoke all on function public.assign_user_role(uuid, text, text) from public, anon;
revoke all on function public.revoke_user_role(uuid, text, text) from public, anon;

grant execute on function public.assign_user_role(uuid, text, text) to authenticated, service_role;
grant execute on function public.revoke_user_role(uuid, text, text) to authenticated, service_role;

commit;
