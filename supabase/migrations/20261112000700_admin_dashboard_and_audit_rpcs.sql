begin;

-- Return the authenticated user's administrative and staff capabilities
create or replace function public.get_admin_capabilities()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  acting_user uuid := auth.uid();
  roles_json jsonb;
  is_super boolean := false;
  is_country boolean := false;
  is_support boolean := false;
  is_curriculum boolean := false;
  can_access boolean := false;
begin
  if acting_user is null then
    return jsonb_build_object(
      'can_access_admin', false,
      'is_super_admin', false,
      'is_country_admin', false,
      'is_support_admin', false,
      'is_curriculum_staff', false,
      'roles', '[]'::jsonb
    );
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object('role', r.role, 'country_code', r.country_code)
    ),
    '[]'::jsonb
  )
  into roles_json
  from public.user_roles r
  where r.user_id = acting_user
    and r.role not in ('parent', 'learner');

  select
    exists(select 1 from public.user_roles r where r.user_id = acting_user and r.role = 'super_admin'),
    exists(select 1 from public.user_roles r where r.user_id = acting_user and r.role = 'country_admin'),
    exists(select 1 from public.user_roles r where r.user_id = acting_user and r.role = 'support_admin'),
    exists(
      select 1 from public.user_roles r
      where r.user_id = acting_user
        and r.role in ('curriculum_editor', 'curriculum_reviewer', 'curriculum_approver', 'curriculum_admin')
    )
  into is_super, is_country, is_support, is_curriculum;

  can_access := is_super or is_country or is_support or is_curriculum
    or exists(
      select 1 from public.user_roles r
      where r.user_id = acting_user
        and r.role in ('content_admin', 'finance_admin')
    );

  return jsonb_build_object(
    'can_access_admin', can_access,
    'is_super_admin', is_super,
    'is_country_admin', is_country,
    'is_support_admin', is_support,
    'is_curriculum_staff', is_curriculum or is_super or is_country,
    'roles', roles_json
  );
end;
$$;

-- Return operational metrics for the admin dashboard
create or replace function public.get_admin_dashboard_stats()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  acting_user uuid := auth.uid();
  is_global boolean := false;
  allowed_countries text[];
  countries_count integer := 0;
  parents_count integer := 0;
  learners_count integer := 0;
  account_requests_count integer := 0;
  imports_count integer := 0;
begin
  if acting_user is null or not exists (
    select 1 from public.user_roles r
    where r.user_id = acting_user and r.role not in ('parent', 'learner')
  ) then
    raise exception 'Administrative authorization is required' using errcode = '42501';
  end if;

  is_global := public.has_role('super_admin')
    or exists (
      select 1 from public.user_roles r
      where r.user_id = acting_user
        and r.role in ('support_admin', 'finance_admin', 'content_admin')
        and r.country_code is null
    );

  if not is_global then
    select array_agg(distinct r.country_code)
    into allowed_countries
    from public.user_roles r
    where r.user_id = acting_user and r.country_code is not null;
  end if;

  select count(*) into countries_count
  from public.countries c
  where c.is_enabled
    and (is_global or c.country_code = any(coalesce(allowed_countries, '{}'::text[])));

  select count(*) into parents_count
  from public.parent_accounts p
  where is_global or p.country_code = any(coalesce(allowed_countries, '{}'::text[]));

  select count(*) into learners_count
  from public.learners l
  where l.status = 'active'
    and (is_global or l.country_code = any(coalesce(allowed_countries, '{}'::text[])));

  if public.has_role('super_admin') or public.has_role('support_admin') or public.has_role('country_admin') then
    select count(*) into account_requests_count
    from public.account_status s
    join public.parent_accounts p on p.user_id = s.user_id
    where s.status in ('deactivation_requested', 'deletion_requested')
      and (is_global or p.country_code = any(coalesce(allowed_countries, '{}'::text[])));
  end if;

  select count(*) into imports_count
  from public.curriculum_import_jobs j
  join public.curricula cur on cur.id = j.curriculum_id
  where j.status in ('queued', 'processing', 'in_review')
    and (is_global or cur.country_code = any(coalesce(allowed_countries, '{}'::text[])));

  return jsonb_build_object(
    'enabled_countries', countries_count,
    'parent_accounts', parents_count,
    'active_learners', learners_count,
    'pending_account_requests', account_requests_count,
    'pending_curriculum_imports', imports_count
  );
end;
$$;

-- List pending deactivation/deletion account requests for support or super admins
create or replace function public.list_admin_account_requests()
returns table (
  user_id uuid,
  full_name text,
  country_code text,
  status text,
  request_reason text,
  requested_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or (
    not public.has_role('super_admin')
    and not public.has_role('support_admin')
  ) then
    raise exception 'Support or super administrator authorization is required'
      using errcode = '42501';
  end if;

  return query
  select
    s.user_id,
    p.full_name,
    pa.country_code,
    s.status,
    s.request_reason,
    s.requested_at
  from public.account_status s
  join public.profiles p on p.id = s.user_id
  join public.parent_accounts pa on pa.user_id = s.user_id
  where s.status in ('deactivation_requested', 'deletion_requested')
  order by s.requested_at asc nulls last;
end;
$$;

-- Resolve a pending account status request
create or replace function public.resolve_admin_account_request(
  p_user_id uuid,
  p_new_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or (
    not public.has_role('super_admin')
    and not public.has_role('support_admin')
  ) then
    raise exception 'Support or super administrator authorization is required'
      using errcode = '42501';
  end if;

  if p_new_status not in ('active', 'deactivated', 'deleted') then
    raise exception 'Invalid target account status: %', p_new_status
      using errcode = '22023';
  end if;

  update public.account_status
  set status = p_new_status,
      updated_at = now()
  where user_id = p_user_id
    and status in ('deactivation_requested', 'deletion_requested');

  if not found then
    raise exception 'No pending account request found for user %', p_user_id
      using errcode = '22023';
  end if;

  perform public.write_audit_log(
    auth.uid(),
    p_user_id,
    'account_status.resolved',
    jsonb_build_object('new_status', p_new_status)
  );
end;
$$;

-- List recent audit logs for security and support review
create or replace function public.list_admin_audit_logs(
  p_limit integer default 50,
  p_offset integer default 0,
  p_action_filter text default null
)
returns table (
  id uuid,
  actor_user_id uuid,
  target_user_id uuid,
  action text,
  metadata jsonb,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  safe_limit integer := least(greatest(coalesce(p_limit, 50), 1), 200);
  safe_offset integer := greatest(coalesce(p_offset, 0), 0);
begin
  if auth.uid() is null or (
    not public.has_role('super_admin')
    and not public.has_role('support_admin')
  ) then
    raise exception 'Support or super administrator authorization is required'
      using errcode = '42501';
  end if;

  return query
  select
    a.id,
    a.actor_user_id,
    a.target_user_id,
    a.action,
    a.metadata,
    a.created_at
  from public.audit_logs a
  where p_action_filter is null or a.action ilike ('%' || p_action_filter || '%')
  order by a.created_at desc
  limit safe_limit
  offset safe_offset;
end;
$$;

revoke all on function public.get_admin_capabilities() from public, anon;
revoke all on function public.get_admin_dashboard_stats() from public, anon;
revoke all on function public.list_admin_account_requests() from public, anon;
revoke all on function public.resolve_admin_account_request(uuid, text) from public, anon;
revoke all on function public.list_admin_audit_logs(integer, integer, text) from public, anon;

grant execute on function public.get_admin_capabilities() to authenticated;
grant execute on function public.get_admin_dashboard_stats() to authenticated;
grant execute on function public.list_admin_account_requests() to authenticated;
grant execute on function public.resolve_admin_account_request(uuid, text) to authenticated;
grant execute on function public.list_admin_audit_logs(integer, integer, text) to authenticated;

commit;
