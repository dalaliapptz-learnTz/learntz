begin;

select plan(23);

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'parent-one@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Parent One","country_code":"TZ"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'parent-two@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Parent Two","country_code":"KE"}',
    now(),
    now()
  );

insert into public.user_roles (user_id, role, country_code)
values (
  '00000000-0000-0000-0000-000000000002',
  'country_admin',
  'KE'
);

select is(
  (select count(*)::integer from public.countries),
  6,
  'six initial country configurations are seeded'
);
select is(
  (select count(*)::integer from public.profiles),
  2,
  'auth trigger creates one profile per account'
);
select is(
  (select count(*)::integer from public.parent_accounts),
  2,
  'auth trigger creates one parent account per account'
);
select is(
  (select count(*)::integer from public.user_roles where role = 'parent'),
  2,
  'auth trigger grants only the fixed parent role'
);

set local role anon;
select is(
  (select count(*)::integer from public.countries where is_enabled),
  6,
  'anonymous users can read enabled country configuration'
);
reset role;

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000001',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (select count(*)::integer from public.profiles),
  1,
  'parent can read only their own profile'
);
select is(
  (select count(*)::integer from public.parent_accounts),
  1,
  'parent can read only their own parent account'
);
select is(
  (select count(*)::integer from public.user_roles where role = 'parent'),
  1,
  'parent can read their role but not another user roles'
);
select ok(public.has_role('parent'), 'role helper recognizes own parent role');
select ok(
  not public.has_role('country_admin', 'KE'),
  'role helper does not expose another country administrator role'
);
select is(
  (select count(*)::integer from public.audit_logs),
  2,
  'parent can read own registration and trusted role-assignment audit events'
);

select throws_ok(
  $$insert into public.user_roles (user_id, role)
    values ('00000000-0000-0000-0000-000000000001', 'super_admin')$$,
  '42501',
  null,
  'ordinary users cannot assign or promote roles'
);
select throws_ok(
  $$insert into public.audit_logs (target_user_id, action)
    values ('00000000-0000-0000-0000-000000000001', 'forged')$$,
  '42501',
  null,
  'ordinary users cannot write audit records'
);
select throws_ok(
  $$update public.account_status set status = 'deleted'
    where user_id = '00000000-0000-0000-0000-000000000001'$$,
  '42501',
  null,
  'ordinary users cannot directly change account status'
);
select lives_ok(
  $$update public.profiles
    set full_name = 'Unauthorized edit'
    where id = '00000000-0000-0000-0000-000000000002'$$,
  'cross-account profile update is safely filtered by RLS'
);
select is(
  (select count(*)::integer from public.profiles
    where id = '00000000-0000-0000-0000-000000000002'),
  0,
  'cross-account profile remains invisible'
);
select is(
  (public.request_account_status('deletion_requested', 'User request')).status,
  'deletion_requested',
  'account deletion is recorded as a request, not performed immediately'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000002',
  true
);
select is(
  public.has_country_access('KE'),
  true,
  'country administrator has access only to their assigned country'
);
select is(
  public.has_country_access('TZ'),
  false,
  'country administrator cannot access a different country'
);
select lives_ok(
  $$update public.countries set display_name = 'Tanzania Changed'
    where country_code = 'TZ'$$,
  'country administrator cannot update another country'
);
select is(
  (select display_name from public.countries where country_code = 'TZ'),
  'Tanzania',
  'country administrator update is filtered by country scope'
);
select lives_ok(
  $$update public.countries set display_name = 'Kenya Updated'
    where country_code = 'KE'$$,
  'country administrator can update their assigned country'
);
select is(
  (select display_name from public.countries where country_code = 'KE'),
  'Kenya Updated',
  'country-scoped country update was applied'
);

select * from finish();
rollback;
