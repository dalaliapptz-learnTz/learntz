-- pgTAP Test Suite: Phase 5 Sub-Stage 1
-- Multi-Tenant Organizations, Hierarchy Closure Table & Registration RPCs

begin;
select plan(18);

-- 1. Table existence
select has_table('public', 'organizations', 'public.organizations table exists');
select has_table('public', 'organization_hierarchies', 'public.organization_hierarchies table exists');

-- 2. Verify seeded core organizations
select cmp_ok(
  (select count(*)::integer from public.organizations where country_code in ('TZ', 'KE', 'UG')),
  '>=',
  11,
  'Seeded at least 11 core organizations across TZ, KE, and UG'
);

-- 3. Verify hierarchy closure table auto-population
-- MoEST (ancestor of Dar REO, Ilala DEO, and Azania Secondary)
select results_eq(
  $$ select depth from public.organization_hierarchies 
     where ancestor_id = 'a0000000-0000-0000-0000-000000000001'
       and descendant_id = 'a0000000-0000-0000-0000-000000000001' $$,
  $$ values (0) $$,
  'Self-reference in closure table has depth 0'
);

select results_eq(
  $$ select depth from public.organization_hierarchies 
     where ancestor_id = 'a0000000-0000-0000-0000-000000000001'
       and descendant_id = 'a0000000-0000-0000-0000-000000000003' $$,
  $$ values (1) $$,
  'MoEST to Dar REO has depth 1'
);

select results_eq(
  $$ select depth from public.organization_hierarchies 
     where ancestor_id = 'a0000000-0000-0000-0000-000000000001'
       and descendant_id = 'a0000000-0000-0000-0000-000000000004' $$,
  $$ values (2) $$,
  'MoEST to Ilala DEO has depth 2'
);

select results_eq(
  $$ select depth from public.organization_hierarchies 
     where ancestor_id = 'a0000000-0000-0000-0000-000000000001'
       and descendant_id = 'a0000000-0000-0000-0000-000000000005' $$,
  $$ values (3) $$,
  'MoEST to Azania Secondary School has depth 3'
);

-- 4. Test get_organization_details RPC
select results_eq(
  $$ select (public.get_organization_details('a0000000-0000-0000-0000-000000000001')->>'slug')::text $$,
  $$ values ('tz-moest'::text) $$,
  'get_organization_details returns correct slug'
);

select results_eq(
  $$ select (public.get_organization_details('a0000000-0000-0000-0000-000000000001')->>'total_descendants_count')::integer $$,
  $$ values (3::integer) $$,
  'MoEST has 3 total descendants (Dar REO, Ilala DEO, Azania)'
);

select results_eq(
  $$ select (public.get_organization_details('a0000000-0000-0000-0000-000000000003')->>'direct_children_count')::integer $$,
  $$ values (1::integer) $$,
  'Dar REO has 1 direct child (Ilala DEO)'
);

-- 5. Test list_subordinate_organizations RPC
select results_eq(
  $$ select count(*)::integer from public.list_subordinate_organizations('a0000000-0000-0000-0000-000000000001') $$,
  $$ values (4::integer) $$,
  'list_subordinate_organizations returns 4 records including self'
);

select results_eq(
  $$ select name from public.list_subordinate_organizations('a0000000-0000-0000-0000-000000000001', 'school') $$,
  $$ values ('Azania Secondary School'::text) $$,
  'list_subordinate_organizations filtered by type school returns Azania'
);

-- 6. Test list_organizations RPC
select results_eq(
  $$ select count(*)::integer from public.list_organizations('TZ', 'ministry') $$,
  $$ values (1::integer) $$,
  'list_organizations filters by country TZ and type ministry'
);

select results_eq(
  $$ select count(*)::integer from public.list_organizations('KE', 'examination_authority') $$,
  $$ values (1::integer) $$,
  'list_organizations filters by country KE and type examination_authority'
);

-- 7. Test register_enterprise_organization RPC with authentication
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-0000-0000-000000000501',
  'authenticated', 'authenticated',
  'org-creator@example.test', '', now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Org Creator","country_code":"TZ"}',
  now(), now()
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000501', true);

select lives_ok(
  $$ select public.register_enterprise_organization(
       'TZ',
       'St. Matthew School Network',
       'st-matthew-network',
       'school_network',
       'SCH-NET-001',
       null,
       'https://stmatthew.ac.tz',
       'admin@stmatthew.ac.tz'
     ) $$,
  'Authenticated user can register a new school network organization'
);

select results_eq(
  $$ select status::text from public.organizations where slug = 'st-matthew-network' $$,
  $$ values ('pending_verification'::text) $$,
  'Standard user registration initializes as pending_verification'
);

-- 8. Test slug uniqueness constraint
select throws_ok(
  $$ select public.register_enterprise_organization(
       'TZ',
       'Duplicate Org',
       'st-matthew-network',
       'school_network'
     ) $$,
  '23505',
  'Organization slug st-matthew-network already exists',
  'Duplicate slug raises unique violation'
);

-- 9. Test circular reference prevention trigger (as superuser / postgres role)
reset role;

select throws_ok(
  $$ update public.organizations
     set parent_organization_id = 'a0000000-0000-0000-0000-000000000005'
     where id = 'a0000000-0000-0000-0000-000000000001' $$,
  '22023',
  'Circular hierarchy detected: cannot set parent to a descendant',
  'Circular parent assignment is strictly prevented by trigger'
);

select * from finish();
rollback;
