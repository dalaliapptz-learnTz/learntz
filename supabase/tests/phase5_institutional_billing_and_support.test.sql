begin;
select plan(11);

-- 1. Check functions exist
select has_function('public', 'get_organization_subscription_status', ARRAY['uuid'], 'get_organization_subscription_status function exists');
select has_function('public', 'list_organization_support_tickets', ARRAY['uuid'], 'list_organization_support_tickets function exists');
select has_function('public', 'create_organization_support_ticket', ARRAY['uuid', 'text', 'text', 'text', 'text'], 'create_organization_support_ticket function exists');

-- 2. Check seeded subscription plans
select results_eq(
  $$ select count(*)::integer from public.organization_subscription_plans where is_active = true $$,
  $$ values (4::integer) $$,
  'Seeded 4 active enterprise institutional subscription tiers'
);

-- Create a test super_admin user
insert into auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  aud,
  role
) values (
  '00000000-0000-0000-0000-000000000901',
  'superadmin_billing_test@learntz.test',
  '',
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"full_name":"Super Admin Billing Tester"}'::jsonb,
  now(),
  now(),
  'authenticated',
  'authenticated'
) on conflict (id) do nothing;

insert into public.user_roles (user_id, role, country_code)
values ('00000000-0000-0000-0000-000000000901', 'super_admin', null)
on conflict do nothing;

-- 3. Test unauthenticated throws 42501
select throws_matching(
  $$ select public.get_organization_subscription_status('a0000000-0000-0000-0000-000000000005') $$,
  'Authentication required',
  'Unauthenticated query to subscription status fails'
);

-- Set authenticated session for super admin
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000901', true);

-- 4. Test Azania Secondary School subscription status
select lives_ok(
  $$ select public.get_organization_subscription_status('a0000000-0000-0000-0000-000000000005') $$,
  'Super admin can query Azania Secondary School subscription status'
);

select results_eq(
  $$ select (public.get_organization_subscription_status('a0000000-0000-0000-0000-000000000005')->>'plan_id')::text $$,
  $$ values ('school_standard'::text) $$,
  'Azania Secondary School has school_standard plan'
);

select results_eq(
  $$ select (public.get_organization_subscription_status('a0000000-0000-0000-0000-000000000005')->>'allocated_student_seats')::integer $$,
  $$ values (1000::integer) $$,
  'Azania Secondary School has 1000 allocated student seats'
);

-- 5. Test create support ticket
select lives_ok(
  $$ select public.create_organization_support_ticket(
    'a0000000-0000-0000-0000-000000000005',
    'Curriculum CSV Bulk Import Sync Issue',
    'Form 4 Physics question bank import stopped at item 85',
    'curriculum_import',
    'urgent'
  ) $$,
  'Super admin can create urgent support ticket'
);

-- 6. Test list support tickets
select results_eq(
  $$ select count(*)::integer from public.organization_support_tickets where organization_id = 'a0000000-0000-0000-0000-000000000005' $$,
  $$ values (1::integer) $$,
  'Support ticket is listed for Azania Secondary School'
);

select results_eq(
  $$ select priority from public.organization_support_tickets where organization_id = 'a0000000-0000-0000-0000-000000000005' limit 1 $$,
  $$ values ('urgent'::text) $$,
  'Ticket priority is urgent'
);

select * from finish();
rollback;
