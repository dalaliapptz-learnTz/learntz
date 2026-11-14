-- pgTAP Test Suite: Phase 5 Sub-Stage 2
-- Institutional Role-Based Access Control, Staff Memberships & Invitation Engine

begin;
select plan(16);

-- 1. Table structure tests
select has_table('public', 'organization_memberships', 'organization_memberships table exists');
select has_table('public', 'organization_invitations', 'organization_invitations table exists');

-- 2. Seed test users for institutional RBAC
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-0000-0000-000000000601',
  'authenticated', 'authenticated',
  'principal@azania.ac.tz', '', now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Principal Azania","country_code":"TZ"}',
  now(), now()
), (
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-0000-0000-000000000602',
  'authenticated', 'authenticated',
  'math-hod@azania.ac.tz', '', now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Head of Math","country_code":"TZ"}',
  now(), now()
), (
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-0000-0000-000000000603',
  'authenticated', 'authenticated',
  'teacher-physics@azania.ac.tz', '', now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Physics Teacher","country_code":"TZ"}',
  now(), now()
);

-- Seed principal membership in Azania Secondary School (a0000000-0000-0000-0000-000000000005)
insert into public.organization_memberships (
  id, organization_id, user_id, role, job_title, department, status, permissions
) values (
  'e0000000-0000-0000-0000-000000000001',
  'a0000000-0000-0000-0000-000000000005',
  '00000000-0000-0000-0000-000000000601',
  'institutional_admin',
  'Head of School',
  'Administration',
  'active',
  array['manage_members', 'manage_curriculum', 'view_analytics']
);

-- 3. Test has_institutional_permission function
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000601', true);

select is(
  public.has_institutional_permission('a0000000-0000-0000-0000-000000000005', 'manage_members'),
  true,
  'Institutional admin has manage_members permission'
);

select is(
  public.has_institutional_role(
    'a0000000-0000-0000-0000-000000000005',
    array['institutional_admin', 'school_principal']::public.institutional_role[]
  ),
  true,
  'has_institutional_role matches institutional_admin'
);

-- 4. Test invite_organization_member RPC
select isnt_empty(
  $$ select public.invite_organization_member(
       'a0000000-0000-0000-0000-000000000005',
       'math-hod@azania.ac.tz',
       'head_of_department',
       'Head of Mathematics Department',
       'Science & Math'
     ) $$,
  'Authorized principal can issue staff invitation'
);

select results_eq(
  $$ select role::text from public.organization_invitations
     where email = 'math-hod@azania.ac.tz' and status = 'pending' $$,
  $$ values ('head_of_department'::text) $$,
  'Invitation is created with pending status and head_of_department role'
);

-- 5. Test unauthorized user cannot invite
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000603', true);

select throws_ok(
  $$ select public.invite_organization_member(
       'a0000000-0000-0000-0000-000000000005',
       'intruder@azania.ac.tz',
       'teacher'
     ) $$,
  '42501',
  'Permission denied: cannot manage members in this organization',
  'Non-member cannot invite staff'
);

-- 6. Test respond_organization_invitation RPC (acceptance)
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000602', true);
select set_config('request.jwt.claim.email', 'math-hod@azania.ac.tz', true);

-- Lookup invitation ID
create temp table _curr_inv as
  select id from public.organization_invitations
  where email = 'math-hod@azania.ac.tz' and status = 'pending' limit 1;

select is(
  (select public.respond_organization_invitation((select id from _curr_inv), true)),
  true,
  'Invited user successfully accepts organization invitation'
);

select results_eq(
  $$ select role::text from public.organization_memberships
     where user_id = '00000000-0000-0000-0000-000000000602' and status = 'active' $$,
  $$ values ('head_of_department'::text) $$,
  'Accepted invitation activates membership with head_of_department role'
);

-- 7. Test get_user_institutional_workspaces RPC
select results_eq(
  $$ select count(*)::integer from public.get_user_institutional_workspaces() $$,
  $$ values (1::integer) $$,
  'User has 1 active institutional workspace (Azania Secondary School)'
);

select results_eq(
  $$ select slug from public.get_user_institutional_workspaces() $$,
  $$ values ('tz-school-azania'::text) $$,
  'Workspace slug matches tz-school-azania'
);

-- 8. Test list_organization_members RPC
select is(
  (select count(*)::integer from public.list_organization_members('a0000000-0000-0000-0000-000000000005')),
  2,
  'list_organization_members returns 2 active staff members'
);

-- 9. Test update_member_role RPC
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000601', true);

create temp table _member_to_update as
  select id from public.organization_memberships
  where user_id = '00000000-0000-0000-0000-000000000602' limit 1;

select is(
  (select public.update_organization_member_role(
     (select id from _member_to_update),
     'school_principal',
     'Vice Principal'
   )),
  true,
  'Admin can promote member role and update title'
);

select results_eq(
  $$ select role::text from public.organization_memberships
     where id = (select id from _member_to_update) $$,
  $$ values ('school_principal'::text) $$,
  'Updated member role is now school_principal'
);

-- 10. Test remove_organization_member RPC
select is(
  (select public.remove_organization_member((select id from _member_to_update))),
  true,
  'Admin can archive member'
);

select results_eq(
  $$ select status::text from public.organization_memberships
     where id = (select id from _member_to_update) $$,
  $$ values ('archived'::text) $$,
  'Removed member status is archived'
);

select * from finish();
rollback;
