create table public.countries (
  country_code text primary key
    check (country_code ~ '^[A-Z]{2}$'),
  display_name text not null unique
    check (char_length(btrim(display_name)) between 1 and 80),
  product_name text not null unique
    check (char_length(btrim(product_name)) between 1 and 40),
  currency_code text not null
    check (currency_code ~ '^[A-Z]{3}$'),
  education_system text,
  primary_brand_color bigint not null
    check (primary_brand_color between 0 and 4294967295),
  accent_brand_color bigint not null
    check (accent_brand_color between 0 and 4294967295),
  supported_language_codes text[] not null
    check (cardinality(supported_language_codes) > 0),
  is_enabled boolean not null default true,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index countries_one_default_idx
  on public.countries (is_default) where is_default;

insert into public.countries (
  country_code, display_name, product_name, currency_code,
  education_system, primary_brand_color, accent_brand_color,
  supported_language_codes, is_enabled, is_default
)
values
  ('TZ', 'Tanzania', 'LearnTZ', 'TZS',
   'Tanzania Institute of Education (TIE)', 4279590639, 4280666259,
   array['en', 'sw'], true, true),
  ('KE', 'Kenya', 'LearnKE', 'KES',
   null, 4279590639, 4280666259, array['en', 'sw'], true, false),
  ('UG', 'Uganda', 'LearnUG', 'UGX',
   null, 4279590639, 4280666259, array['en', 'sw'], true, false),
  ('RW', 'Rwanda', 'LearnRW', 'RWF',
   null, 4279590639, 4280666259, array['en', 'sw'], true, false),
  ('BI', 'Burundi', 'LearnBI', 'BIF',
   null, 4279590639, 4280666259, array['en', 'sw'], true, false),
  ('SS', 'South Sudan', 'LearnSS', 'SSP',
   null, 4279590639, 4280666259, array['en', 'sw'], true, false);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null
    check (char_length(btrim(full_name)) between 1 and 120),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.parent_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles (id) on delete cascade,
  country_code text not null references public.countries (country_code),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in (
    'super_admin', 'country_admin', 'content_admin',
    'finance_admin', 'support_admin', 'parent', 'learner'
  )),
  country_code text references public.countries (country_code),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_roles_country_scope_check check (
    (role = 'country_admin' and country_code is not null)
    or (role <> 'country_admin')
  ),
  constraint user_roles_end_user_scope_check check (
    role not in ('parent', 'learner') or country_code is null
  )
);

create unique index user_roles_assignment_unique_idx
  on public.user_roles (user_id, role, coalesce(country_code, ''));
create index user_roles_country_role_idx
  on public.user_roles (country_code, role);

create table public.account_status (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles (id) on delete cascade,
  status text not null check (status in (
    'active', 'deactivation_requested', 'deletion_requested',
    'deactivated', 'deleted'
  )),
  request_reason text
    check (request_reason is null or char_length(request_reason) <= 500),
  requested_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index account_status_status_updated_idx
  on public.account_status (status, updated_at);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references auth.users (id) on delete set null,
  target_user_id uuid references auth.users (id) on delete set null,
  action text not null check (char_length(btrim(action)) between 1 and 100),
  details jsonb not null default '{}'::jsonb
    check (jsonb_typeof(details) = 'object'),
  created_at timestamptz not null default now()
);

create index audit_logs_target_created_idx
  on public.audit_logs (target_user_id, created_at desc);
create index audit_logs_actor_created_idx
  on public.audit_logs (actor_user_id, created_at desc);

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger countries_set_updated_at
  before update on public.countries
  for each row execute function public.set_updated_at();
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger parent_accounts_set_updated_at
  before update on public.parent_accounts
  for each row execute function public.set_updated_at();
create trigger user_roles_set_updated_at
  before update on public.user_roles
  for each row execute function public.set_updated_at();
create trigger account_status_set_updated_at
  before update on public.account_status
  for each row execute function public.set_updated_at();

create function public.has_role(p_role text, p_country_code text default null)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_roles as role_assignment
    where role_assignment.user_id = (select auth.uid())
      and role_assignment.role = p_role
      and (
        role_assignment.country_code is null
        or role_assignment.country_code = p_country_code
      )
  );
$$;

create function public.has_country_access(p_country_code text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.has_role('super_admin')
    or public.has_role('country_admin', p_country_code)
    or public.has_role('content_admin', p_country_code)
    or public.has_role('finance_admin', p_country_code)
    or public.has_role('support_admin', p_country_code);
$$;

revoke all on function public.has_role(text, text) from public, anon;
revoke all on function public.has_country_access(text) from public, anon;
grant execute on function public.has_role(text, text) to authenticated;
grant execute on function public.has_country_access(text) to authenticated;

alter table public.countries enable row level security;
alter table public.profiles enable row level security;
alter table public.parent_accounts enable row level security;
alter table public.user_roles enable row level security;
alter table public.account_status enable row level security;
alter table public.audit_logs enable row level security;

revoke all on public.countries from public, anon, authenticated;
grant select on public.countries to anon, authenticated;
grant update (
  display_name, product_name, currency_code, education_system,
  primary_brand_color, accent_brand_color, supported_language_codes,
  is_enabled, is_default
) on public.countries to authenticated;

create policy "Anyone can read enabled countries"
  on public.countries
  for select
  to anon, authenticated
  using (
    is_enabled
    or public.has_role('super_admin')
    or public.has_role('country_admin', country_code)
  );

create policy "Authorized administrators can update country configuration"
  on public.countries
  for update
  to authenticated
  using (
    public.has_role('super_admin')
    or public.has_role('country_admin', country_code)
  )
  with check (
    public.has_role('super_admin')
    or public.has_role('country_admin', country_code)
  );

revoke all on public.profiles from public, anon, authenticated;
grant select on public.profiles to authenticated;
grant update (full_name) on public.profiles to authenticated;

create policy "Users can read their own profile"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = id);
create policy "Users can update their own profile"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

revoke all on public.parent_accounts from public, anon, authenticated;
grant select on public.parent_accounts to authenticated;

create policy "Parents can read their own account"
  on public.parent_accounts for select to authenticated
  using ((select auth.uid()) = user_id);

revoke all on public.user_roles from public, anon, authenticated;
grant select on public.user_roles to authenticated;

create policy "Users and authorized administrators can read roles"
  on public.user_roles for select to authenticated
  using (
    (select auth.uid()) = user_id
    or public.has_role('super_admin')
    or public.has_role('country_admin', country_code)
  );

revoke all on public.account_status from public, anon, authenticated;
grant select on public.account_status to authenticated;

create policy "Users and authorized support roles can read account status"
  on public.account_status for select to authenticated
  using (
    (select auth.uid()) = user_id
    or public.has_role('super_admin')
    or public.has_role('support_admin')
    or exists (
      select 1 from public.parent_accounts as parent_account
      where parent_account.user_id = account_status.user_id
        and (
          public.has_role('country_admin', parent_account.country_code)
          or public.has_role('support_admin', parent_account.country_code)
        )
    )
  );

revoke all on public.audit_logs from public, anon, authenticated;
grant select on public.audit_logs to authenticated;

create policy "Users can read their own audit events"
  on public.audit_logs for select to authenticated
  using (
    (select auth.uid()) = target_user_id
    or public.has_role('super_admin')
    or public.has_role('support_admin')
    or exists (
      select 1 from public.parent_accounts as parent_account
      where parent_account.user_id = audit_logs.target_user_id
        and public.has_role('country_admin', parent_account.country_code)
    )
  );

create function public.write_audit_log(
  p_actor_user_id uuid,
  p_target_user_id uuid,
  p_action text,
  p_details jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.audit_logs (
    actor_user_id, target_user_id, action, details
  )
  values (
    p_actor_user_id, p_target_user_id, p_action,
    coalesce(p_details, '{}'::jsonb)
  );
$$;

revoke all on function public.write_audit_log(uuid, uuid, text, jsonb)
  from public, anon, authenticated;

create function public.audit_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.full_name is distinct from old.full_name then
    perform public.write_audit_log(
      auth.uid(), new.id, 'profile.updated', '{"field":"full_name"}'::jsonb
    );
  end if;
  return new;
end;
$$;

revoke all on function public.audit_profile_update()
  from public, anon, authenticated;
create trigger profiles_audit_update
  after update on public.profiles
  for each row execute function public.audit_profile_update();

create function public.audit_role_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_id uuid;
  role_name text;
  country text;
  audit_action text;
begin
  if tg_op = 'DELETE' then
    target_id := old.user_id;
    role_name := old.role;
    country := old.country_code;
    audit_action := 'role.removed';
  else
    target_id := new.user_id;
    role_name := new.role;
    country := new.country_code;
    audit_action := case when tg_op = 'INSERT' then 'role.granted' else 'role.updated' end;
  end if;

  perform public.write_audit_log(
    auth.uid(),
    target_id,
    audit_action,
    jsonb_build_object('role', role_name, 'country_code', country)
  );
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function public.audit_role_change()
  from public, anon, authenticated;
create trigger user_roles_audit_change
  after insert or update or delete on public.user_roles
  for each row execute function public.audit_role_change();

create function public.audit_account_status_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status is distinct from old.status then
    perform public.write_audit_log(
      auth.uid(),
      new.user_id,
      'account_status.' || new.status,
      jsonb_build_object('status', new.status)
    );
  end if;
  return new;
end;
$$;

revoke all on function public.audit_account_status_change()
  from public, anon, authenticated;
create trigger account_status_audit_change
  after update on public.account_status
  for each row execute function public.audit_account_status_change();

create function public.create_parent_account_for_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  profile_name text;
  selected_country text;
begin
  profile_name := btrim(coalesce(new.raw_user_meta_data ->> 'full_name', ''));
  if char_length(profile_name) not between 1 and 120 then
    raise exception 'A valid parent full name is required'
      using errcode = '22023';
  end if;

  selected_country := upper(btrim(coalesce(
    new.raw_user_meta_data ->> 'country_code',
    (select country_code from public.countries where is_default and is_enabled)
  )));
  if not exists (
    select 1 from public.countries
    where country_code = selected_country and is_enabled
  ) then
    raise exception 'A supported country is required'
      using errcode = '22023';
  end if;

  insert into public.profiles (id, full_name)
  values (new.id, profile_name);

  insert into public.parent_accounts (user_id, country_code)
  values (new.id, selected_country);

  insert into public.account_status (user_id, status)
  values (new.id, 'active');

  -- The role is assigned from trusted database code; client metadata is ignored.
  insert into public.user_roles (user_id, role)
  values (new.id, 'parent');

  perform public.write_audit_log(
    new.id, new.id, 'parent.registered',
    jsonb_build_object('country_code', selected_country)
  );
  return new;
end;
$$;

revoke all on function public.create_parent_account_for_auth_user()
  from public, anon, authenticated;
create trigger on_auth_user_created_parent_account
  after insert on auth.users
  for each row execute function public.create_parent_account_for_auth_user();

create function public.request_account_status(
  p_status text,
  p_reason text default null
)
returns public.account_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  requesting_user uuid;
  updated_status public.account_status;
  normalized_reason text;
begin
  requesting_user := auth.uid();
  if requesting_user is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  if p_status not in ('deactivation_requested', 'deletion_requested') then
    raise exception 'Unsupported account status request' using errcode = '22023';
  end if;

  normalized_reason := nullif(btrim(coalesce(p_reason, '')), '');
  if char_length(coalesce(normalized_reason, '')) > 500 then
    raise exception 'The request reason is too long' using errcode = '22023';
  end if;

  update public.account_status
  set status = p_status,
      request_reason = normalized_reason,
      requested_at = now()
  where user_id = requesting_user
    and status = 'active'
  returning * into updated_status;

  if not found then
    raise exception 'An account request is already in progress'
      using errcode = '55000';
  end if;

  return updated_status;
end;
$$;

revoke all on function public.request_account_status(text, text)
  from public, anon;
grant execute on function public.request_account_status(text, text)
  to authenticated;
