-- ============================================================================
-- LearnTZ Phase 5: Sub-Stage 5 — Institutional Subscriptions & Enterprise SLA
-- Seat Licensing, Quotas, Multi-Currency Billing & Enterprise Support Desk
-- ============================================================================

-- 1. Table: organization_subscription_plans
create table if not exists public.organization_subscription_plans (
  id text primary key,
  name text not null check (char_length(btrim(name)) between 2 and 100),
  description text,
  tier text not null check (tier in ('pilot', 'standard_school', 'network_enterprise', 'government_sovereign')),
  max_student_seats integer not null check (max_student_seats > 0),
  max_teacher_seats integer not null check (max_teacher_seats > 0),
  storage_quota_gb integer not null default 50 check (storage_quota_gb > 0),
  price_tzs numeric not null default 0 check (price_tzs >= 0),
  price_kes numeric not null default 0 check (price_kes >= 0),
  price_ugx numeric not null default 0 check (price_ugx >= 0),
  price_usd numeric not null default 0 check (price_usd >= 0),
  sla_response_hours integer not null default 24 check (sla_response_hours between 1 and 72),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.organization_subscription_plans enable row level security;
revoke all on public.organization_subscription_plans from public, anon, authenticated;
grant select on public.organization_subscription_plans to anon, authenticated;
grant all on public.organization_subscription_plans to authenticated;

drop policy if exists "Anyone can read active institutional plans" on public.organization_subscription_plans;
create policy "Anyone can read active institutional plans"
  on public.organization_subscription_plans for select
  using (is_active = true or public.has_role('super_admin'));

-- Seed Enterprise Institutional Plans
insert into public.organization_subscription_plans (
  id,
  name,
  description,
  tier,
  max_student_seats,
  max_teacher_seats,
  storage_quota_gb,
  price_tzs,
  price_kes,
  price_ugx,
  price_usd,
  sla_response_hours
) values
  (
    'school_pilot',
    'Institutional Pilot',
    'Complimentary trial for accredited schools and pilot cohorts',
    'pilot',
    250,
    15,
    25,
    0,
    0,
    0,
    0,
    48
  ),
  (
    'school_standard',
    'Standard School License',
    'Complete curriculum, examination bank and LMS for single-campus schools',
    'standard_school',
    1000,
    60,
    100,
    3500000,
    175000,
    5200000,
    1400,
    24
  ),
  (
    'network_enterprise',
    'Multi-Campus Network Enterprise',
    'Cross-campus analytics, teacher talent mobility and centralized licensing',
    'network_enterprise',
    5000,
    300,
    500,
    12000000,
    600000,
    18000000,
    4800,
    4
  ),
  (
    'government_sovereign',
    'Government & Sovereign Apex',
    'Full national sovereignty, ministry analytics and national exam integration',
    'government_sovereign',
    100000,
    5000,
    5000,
    50000000,
    2500000,
    75000000,
    20000,
    1
  )
on conflict (id) do update set
  name = excluded.name,
  description = excluded.description,
  max_student_seats = excluded.max_student_seats,
  max_teacher_seats = excluded.max_teacher_seats,
  price_tzs = excluded.price_tzs,
  price_kes = excluded.price_kes,
  price_ugx = excluded.price_ugx,
  price_usd = excluded.price_usd,
  sla_response_hours = excluded.sla_response_hours;

-- 2. Table: organization_subscriptions
create table if not exists public.organization_subscriptions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  plan_id text not null references public.organization_subscription_plans (id) on delete restrict,
  billing_cycle text not null default 'annual' check (billing_cycle in ('monthly', 'quarterly', 'annual')),
  currency text not null check (currency in ('TZS', 'KES', 'UGX', 'USD')),
  current_price numeric not null check (current_price >= 0),
  allocated_student_seats integer not null check (allocated_student_seats >= 0),
  used_student_seats integer not null default 0 check (used_student_seats >= 0),
  allocated_teacher_seats integer not null check (allocated_teacher_seats >= 0),
  used_teacher_seats integer not null default 0 check (used_teacher_seats >= 0),
  allocated_storage_gb integer not null default 50 check (allocated_storage_gb >= 0),
  used_storage_gb integer not null default 0 check (used_storage_gb >= 0),
  status text not null default 'active' check (status in ('active', 'past_due', 'canceled', 'trialing')),
  period_start timestamptz not null default now(),
  period_end timestamptz not null,
  tax_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists org_subscriptions_org_idx
  on public.organization_subscriptions (organization_id, status);

alter table public.organization_subscriptions enable row level security;
revoke all on public.organization_subscriptions from public, anon, authenticated;
grant select on public.organization_subscriptions to authenticated;
grant insert, update on public.organization_subscriptions to authenticated;

drop policy if exists "Institutional staff can view own organization subscription" on public.organization_subscriptions;
create policy "Institutional staff can view own organization subscription"
  on public.organization_subscriptions for select to authenticated
  using (
    organization_id in (select public.get_user_organization_ids(auth.uid()))
    or public.has_role('super_admin')
  );

drop policy if exists "Super admins manage institutional subscriptions" on public.organization_subscriptions;
create policy "Super admins manage institutional subscriptions"
  on public.organization_subscriptions for all to authenticated
  using (public.has_role('super_admin'))
  with check (public.has_role('super_admin'));

-- Seed active subscription for Azania Secondary School
insert into public.organization_subscriptions (
  id,
  organization_id,
  plan_id,
  billing_cycle,
  currency,
  current_price,
  allocated_student_seats,
  used_student_seats,
  allocated_teacher_seats,
  used_teacher_seats,
  allocated_storage_gb,
  used_storage_gb,
  status,
  period_start,
  period_end,
  tax_id
) values (
  'f0000000-0000-0000-0000-000000000001',
  'a0000000-0000-0000-0000-000000000005',
  'school_standard',
  'annual',
  'TZS',
  3500000,
  1000,
  450,
  60,
  32,
  100,
  18,
  'active',
  now() - interval '3 months',
  now() + interval '9 months',
  'TZ-TIN-987-654-321'
) on conflict (id) do nothing;

-- 3. Table: organization_support_tickets
create table if not exists public.organization_support_tickets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  created_by_user_id uuid not null references auth.users (id) on delete cascade,
  assigned_agent_id uuid references auth.users (id) on delete set null,
  ticket_number text not null unique,
  subject text not null check (char_length(btrim(subject)) between 4 and 250),
  description text not null,
  category text not null check (category in ('billing', 'curriculum_import', 'technical_integration', 'account_access', 'sla_escalation', 'data_export')),
  priority text not null default 'normal' check (priority in ('low', 'normal', 'high', 'urgent')),
  status text not null default 'open' check (status in ('open', 'in_progress', 'waiting_on_client', 'resolved', 'closed')),
  sla_due_at timestamptz not null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists org_support_tickets_org_idx
  on public.organization_support_tickets (organization_id, status, priority);

create index if not exists org_support_tickets_agent_idx
  on public.organization_support_tickets (assigned_agent_id, status);

alter table public.organization_support_tickets enable row level security;
revoke all on public.organization_support_tickets from public, anon, authenticated;
grant select, insert, update on public.organization_support_tickets to authenticated;

drop policy if exists "Organization members can view own tickets" on public.organization_support_tickets;
create policy "Organization members can view own tickets"
  on public.organization_support_tickets for select to authenticated
  using (
    organization_id in (select public.get_user_organization_ids(auth.uid()))
    or public.has_role('super_admin')
  );

drop policy if exists "Organization members can create tickets" on public.organization_support_tickets;
create policy "Organization members can create tickets"
  on public.organization_support_tickets for insert to authenticated
  with check (
    organization_id in (select public.get_user_organization_ids(auth.uid()))
    or public.has_role('super_admin')
  );

drop policy if exists "Staff can update tickets" on public.organization_support_tickets;
create policy "Staff can update tickets"
  on public.organization_support_tickets for update to authenticated
  using (
    organization_id in (select public.get_user_organization_ids(auth.uid()))
    or public.has_role('super_admin')
  );

-- 4. Table: organization_support_ticket_messages
create table if not exists public.organization_support_ticket_messages (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.organization_support_tickets (id) on delete cascade,
  sender_user_id uuid not null references auth.users (id) on delete cascade,
  is_internal boolean not null default false,
  message text not null check (char_length(btrim(message)) >= 1),
  created_at timestamptz not null default now()
);

create index if not exists ticket_messages_ticket_idx
  on public.organization_support_ticket_messages (ticket_id, created_at asc);

alter table public.organization_support_ticket_messages enable row level security;
revoke all on public.organization_support_ticket_messages from public, anon, authenticated;
grant select, insert on public.organization_support_ticket_messages to authenticated;

drop policy if exists "Ticket participants view messages" on public.organization_support_ticket_messages;
create policy "Ticket participants view messages"
  on public.organization_support_ticket_messages for select to authenticated
  using (
    exists (
      select 1 from public.organization_support_tickets t
      where t.id = ticket_id
        and (
          t.organization_id in (select public.get_user_organization_ids(auth.uid()))
          or public.has_role('super_admin')
        )
    )
  );

drop policy if exists "Ticket participants insert messages" on public.organization_support_ticket_messages;
create policy "Ticket participants insert messages"
  on public.organization_support_ticket_messages for insert to authenticated
  with check (
    exists (
      select 1 from public.organization_support_tickets t
      where t.id = ticket_id
        and (
          t.organization_id in (select public.get_user_organization_ids(auth.uid()))
          or public.has_role('super_admin')
        )
    )
  );

-- ============================================================================
-- 5. RPC: get_organization_subscription_status
-- ============================================================================
create or replace function public.get_organization_subscription_status(p_org_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_country text;
  v_sub record;
  v_plan record;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select country_code into v_country
  from public.organizations
  where id = p_org_id;

  if not (
    public.has_role('super_admin')
    or public.has_role('country_admin', v_country)
    or exists (
      select 1 from public.organization_memberships
      where organization_id = p_org_id
        and user_id = v_user_id
        and status = 'active'
    )
  ) then
    raise exception 'Permission denied: cannot view organization subscription'
      using errcode = '42501';
  end if;

  -- Select active subscription
  select * into v_sub
  from public.organization_subscriptions
  where organization_id = p_org_id
  order by created_at desc
  limit 1;

  if v_sub.id is null then
    -- Return default pilot preview
    return jsonb_build_object(
      'has_subscription', false,
      'plan_id', 'school_pilot',
      'plan_name', 'Institutional Pilot',
      'tier', 'pilot',
      'status', 'trialing',
      'allocated_student_seats', 250,
      'used_student_seats', 0,
      'allocated_teacher_seats', 15,
      'used_teacher_seats', 0,
      'allocated_storage_gb', 25,
      'used_storage_gb', 0,
      'period_end', (now() + interval '30 days'),
      'currency', 'TZS',
      'current_price', 0,
      'sla_response_hours', 48
    );
  end if;

  select * into v_plan
  from public.organization_subscription_plans
  where id = v_sub.plan_id;

  v_result := jsonb_build_object(
    'has_subscription', true,
    'subscription_id', v_sub.id,
    'plan_id', v_sub.plan_id,
    'plan_name', coalesce(v_plan.name, 'Enterprise Plan'),
    'tier', coalesce(v_plan.tier, 'standard_school'),
    'status', v_sub.status,
    'billing_cycle', v_sub.billing_cycle,
    'currency', v_sub.currency,
    'current_price', v_sub.current_price,
    'allocated_student_seats', v_sub.allocated_student_seats,
    'used_student_seats', v_sub.used_student_seats,
    'allocated_teacher_seats', v_sub.allocated_teacher_seats,
    'used_teacher_seats', v_sub.used_teacher_seats,
    'allocated_storage_gb', v_sub.allocated_storage_gb,
    'used_storage_gb', v_sub.used_storage_gb,
    'period_start', v_sub.period_start,
    'period_end', v_sub.period_end,
    'tax_id', v_sub.tax_id,
    'sla_response_hours', coalesce(v_plan.sla_response_hours, 24)
  );

  return v_result;
end;
$$;

-- ============================================================================
-- 6. RPC: list_organization_support_tickets
-- ============================================================================
create or replace function public.list_organization_support_tickets(p_org_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_country text;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select country_code into v_country
  from public.organizations
  where id = p_org_id;

  if not (
    public.has_role('super_admin')
    or public.has_role('country_admin', v_country)
    or exists (
      select 1 from public.organization_memberships
      where organization_id = p_org_id
        and user_id = v_user_id
        and status = 'active'
    )
  ) then
    raise exception 'Permission denied: cannot view support tickets'
      using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(t_rec), '[]'::jsonb) into v_result
  from (
    select
      t.id,
      t.ticket_number,
      t.subject,
      t.description,
      t.category,
      t.priority,
      t.status,
      t.sla_due_at,
      t.resolved_at,
      t.created_at,
      (select count(*)::integer from public.organization_support_ticket_messages m where m.ticket_id = t.id) as message_count
    from public.organization_support_tickets t
    where t.organization_id = p_org_id
    order by t.created_at desc
  ) t_rec;

  return v_result;
end;
$$;

-- ============================================================================
-- 7. RPC: create_organization_support_ticket
-- ============================================================================
create or replace function public.create_organization_support_ticket(
  p_org_id uuid,
  p_subject text,
  p_description text,
  p_category text,
  p_priority text default 'normal'
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_country text;
  v_ticket_number text;
  v_sla_hours integer;
  v_sla_due_at timestamptz;
  v_ticket_id uuid;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select country_code into v_country
  from public.organizations
  where id = p_org_id;

  if not (
    public.has_role('super_admin')
    or public.has_role('country_admin', v_country)
    or exists (
      select 1 from public.organization_memberships
      where organization_id = p_org_id
        and user_id = v_user_id
        and status = 'active'
    )
  ) then
    raise exception 'Permission denied: cannot open support ticket'
      using errcode = '42501';
  end if;

  -- Generate unique ticket number
  v_ticket_number := 'TICK-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substring(gen_random_uuid()::text from 1 for 4));

  -- Calculate SLA deadline based on priority
  v_sla_hours := case p_priority
    when 'urgent' then 1
    when 'high' then 4
    when 'normal' then 24
    when 'low' then 48
    else 24
  end;

  v_sla_due_at := now() + (v_sla_hours || ' hours')::interval;

  insert into public.organization_support_tickets (
    organization_id,
    created_by_user_id,
    ticket_number,
    subject,
    description,
    category,
    priority,
    status,
    sla_due_at
  ) values (
    p_org_id,
    v_user_id,
    v_ticket_number,
    btrim(p_subject),
    btrim(p_description),
    p_category,
    p_priority,
    'open',
    v_sla_due_at
  )
  returning id into v_ticket_id;

  -- Add initial message
  insert into public.organization_support_ticket_messages (
    ticket_id,
    sender_user_id,
    is_internal,
    message
  ) values (
    v_ticket_id,
    v_user_id,
    false,
    btrim(p_description)
  );

  v_result := jsonb_build_object(
    'id', v_ticket_id,
    'ticket_number', v_ticket_number,
    'subject', btrim(p_subject),
    'priority', p_priority,
    'status', 'open',
    'sla_due_at', v_sla_due_at,
    'created_at', now()
  );

  return v_result;
end;
$$;
