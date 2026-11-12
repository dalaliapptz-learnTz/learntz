begin;

create table public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries (country_code)
    on delete restrict,
  code text not null check (char_length(btrim(code)) between 1 and 60),
  name text not null check (char_length(btrim(name)) between 1 and 120),
  price_cents bigint not null check (price_cents >= 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  billing_interval text not null
    check (billing_interval in ('monthly', 'quarterly', 'annual')),
  features jsonb not null default '[]'::jsonb
    check (jsonb_typeof(features) = 'array'),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint subscription_plans_country_code_unique unique (country_code, code)
);

create index subscription_plans_country_active_idx
  on public.subscription_plans (country_code, is_active, billing_interval);

create table public.parent_subscriptions (
  id uuid primary key default gen_random_uuid(),
  parent_user_id uuid not null references public.parent_accounts (user_id)
    on delete cascade,
  plan_id uuid not null references public.subscription_plans (id)
    on delete restrict,
  status text not null default 'pending_payment' check (status in (
    'pending_payment', 'active', 'past_due', 'cancelled', 'expired'
  )),
  current_period_start timestamptz,
  current_period_end timestamptz,
  auto_renew boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint parent_subscriptions_id_parent_unique unique (id, parent_user_id),
  constraint parent_subscriptions_period_check check (
    current_period_end is null
    or current_period_start is null
    or current_period_end >= current_period_start
  )
);

create index parent_subscriptions_parent_status_idx
  on public.parent_subscriptions (parent_user_id, status, created_at desc);

create table public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  subscription_id uuid not null,
  parent_user_id uuid not null references public.parent_accounts (user_id)
    on delete restrict,
  provider text not null check (provider in (
    'mpesa_tz', 'mpesa_ke', 'airtel_money', 'tigo_pesa'
  )),
  reference text not null check (char_length(btrim(reference)) between 4 and 120),
  amount bigint not null check (amount > 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  status text not null default 'pending' check (status in (
    'pending', 'succeeded', 'failed', 'refunded'
  )),
  msisdn text check (msisdn is null or char_length(btrim(msisdn)) <= 20),
  raw_response jsonb not null default '{}'::jsonb
    check (jsonb_typeof(raw_response) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint payment_transactions_subscription_parent_fk
    foreign key (subscription_id, parent_user_id)
    references public.parent_subscriptions (id, parent_user_id)
    on delete restrict,
  constraint payment_transactions_reference_unique unique (reference)
);

create index payment_transactions_parent_created_idx
  on public.payment_transactions (parent_user_id, created_at desc);
create index payment_transactions_sub_created_idx
  on public.payment_transactions (subscription_id, created_at desc);

create trigger subscription_plans_set_updated_at
  before update on public.subscription_plans
  for each row execute function public.set_updated_at();
create trigger parent_subscriptions_set_updated_at
  before update on public.parent_subscriptions
  for each row execute function public.set_updated_at();
create trigger payment_transactions_set_updated_at
  before update on public.payment_transactions
  for each row execute function public.set_updated_at();

alter table public.subscription_plans enable row level security;
alter table public.parent_subscriptions enable row level security;
alter table public.payment_transactions enable row level security;

revoke all on public.subscription_plans, public.parent_subscriptions, public.payment_transactions
  from public, anon, authenticated;

grant select on public.subscription_plans to anon, authenticated;
grant insert, update, delete on public.subscription_plans to authenticated;
grant select on public.parent_subscriptions, public.payment_transactions to authenticated;

create policy "Anyone can read active subscription plans"
  on public.subscription_plans for select to anon, authenticated
  using (
    is_active
    or public.has_role('super_admin')
    or public.has_role('finance_admin', country_code)
    or public.has_role('country_admin', country_code)
  );

create policy "Admins manage subscription plans"
  on public.subscription_plans for all to authenticated
  using (
    public.has_role('super_admin')
    or public.has_role('finance_admin', country_code)
    or public.has_role('country_admin', country_code)
  )
  with check (
    public.has_role('super_admin')
    or public.has_role('finance_admin', country_code)
    or public.has_role('country_admin', country_code)
  );

create policy "Parents read own subscriptions and finance admins read country"
  on public.parent_subscriptions for select to authenticated
  using (
    parent_user_id = (select auth.uid())
    or exists (
      select 1
      from public.subscription_plans plan
      where plan.id = parent_subscriptions.plan_id
        and (
          public.has_role('super_admin')
          or public.has_role('finance_admin', plan.country_code)
          or public.has_role('country_admin', plan.country_code)
        )
    )
  );

create policy "Parents read own payment transactions and finance admins read country"
  on public.payment_transactions for select to authenticated
  using (
    exists (
      select 1
      from public.parent_subscriptions sub
      where sub.id = payment_transactions.subscription_id
        and sub.parent_user_id = (select auth.uid())
    )
    or exists (
      select 1
      from public.parent_subscriptions sub
      join public.subscription_plans plan on plan.id = sub.plan_id
      where sub.id = payment_transactions.subscription_id
        and (
          public.has_role('super_admin')
          or public.has_role('finance_admin', plan.country_code)
          or public.has_role('country_admin', plan.country_code)
        )
    )
  );

create or replace function public.has_active_parent_subscription(p_parent_user_id uuid default null)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.parent_subscriptions sub
    where sub.parent_user_id = coalesce(p_parent_user_id, (select auth.uid()))
      and sub.status = 'active'
      and (sub.current_period_end is null or sub.current_period_end > now())
  );
$$;

revoke all on function public.has_active_parent_subscription(uuid) from public, anon;
grant execute on function public.has_active_parent_subscription(uuid) to authenticated, service_role;

create or replace function public.start_parent_subscription_checkout(
  p_plan_id uuid,
  p_provider text,
  p_msisdn text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_plan public.subscription_plans;
  v_sub public.parent_subscriptions;
  v_tx public.payment_transactions;
  v_clean_msisdn text := nullif(btrim(coalesce(p_msisdn, '')), '');
  v_ref text;
begin
  if v_uid is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  if not exists (
    select 1
    from public.parent_accounts pa
    join public.account_status ast on ast.user_id = pa.user_id
    where pa.user_id = v_uid
      and ast.status = 'active'
      and public.has_role('parent')
  ) then
    raise exception 'An active parent account is required' using errcode = '42501';
  end if;

  if p_provider is null or p_provider not in ('mpesa_tz', 'mpesa_ke', 'airtel_money', 'tigo_pesa') then
    raise exception 'Unsupported mobile money provider' using errcode = '22023';
  end if;

  if v_clean_msisdn is not null and v_clean_msisdn !~ '^\+?[0-9]{9,15}$' then
    raise exception 'Mobile phone number must contain 9 to 15 digits' using errcode = '22023';
  end if;

  select * into v_plan
  from public.subscription_plans
  where id = p_plan_id
    and is_active;
  if not found then
    raise exception 'Subscription plan is unavailable' using errcode = '22023';
  end if;

  if v_plan.price_cents <= 0 then
    raise exception 'Selected plan does not require mobile money checkout' using errcode = '22023';
  end if;

  select * into v_sub
  from public.parent_subscriptions
  where parent_user_id = v_uid
    and plan_id = v_plan.id
    and status in ('active', 'pending_payment')
  order by created_at desc
  limit 1
  for update;

  if not found then
    insert into public.parent_subscriptions (
      parent_user_id, plan_id, status, auto_renew
    ) values (
      v_uid, v_plan.id, 'pending_payment', false
    )
    returning * into v_sub;
  end if;

  v_ref := 'LTZ-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 14));

  insert into public.payment_transactions (
    subscription_id, parent_user_id, provider, reference, amount, currency, status, msisdn
  ) values (
    v_sub.id, v_uid, p_provider, v_ref, v_plan.price_cents, v_plan.currency, 'pending', v_clean_msisdn
  )
  returning * into v_tx;

  perform public.write_audit_log(
    v_uid,
    v_uid,
    'billing.checkout_started',
    jsonb_build_object(
      'subscription_id', v_sub.id,
      'transaction_id', v_tx.id,
      'plan_code', v_plan.code,
      'provider', p_provider,
      'reference', v_tx.reference,
      'amount', v_tx.amount,
      'currency', v_tx.currency
    )
  );

  return jsonb_build_object(
    'subscription_id', v_sub.id,
    'transaction_id', v_tx.id,
    'reference', v_tx.reference,
    'provider', v_tx.provider,
    'amount', v_tx.amount,
    'currency', v_tx.currency,
    'status', v_tx.status,
    'subscription_status', v_sub.status,
    'plan_name', v_plan.name,
    'billing_interval', v_plan.billing_interval
  );
end;
$$;

revoke all on function public.start_parent_subscription_checkout(uuid, text, text) from public, anon;
grant execute on function public.start_parent_subscription_checkout(uuid, text, text) to authenticated;

create or replace function public.process_mobile_money_webhook(
  p_provider text,
  p_reference text,
  p_status text,
  p_amount bigint,
  p_currency text,
  p_raw_response jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tx public.payment_transactions;
  v_sub public.parent_subscriptions;
  v_plan public.subscription_plans;
  v_period_interval interval;
  v_base_time timestamptz;
  v_new_end timestamptz;
  v_clean_ref text := btrim(coalesce(p_reference, ''));
  v_clean_currency text := upper(btrim(coalesce(p_currency, '')));
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'Service role authorization is required' using errcode = '42501';
  end if;

  if p_provider is null or p_provider not in ('mpesa_tz', 'mpesa_ke', 'airtel_money', 'tigo_pesa') then
    raise exception 'Unsupported mobile money provider' using errcode = '22023';
  end if;

  if char_length(v_clean_ref) < 4 then
    raise exception 'Valid transaction reference is required' using errcode = '22023';
  end if;

  if p_status is null or p_status not in ('succeeded', 'failed') then
    raise exception 'Webhook status must be succeeded or failed' using errcode = '22023';
  end if;

  if p_amount is null or p_amount <= 0 or v_clean_currency !~ '^[A-Z]{3}$' then
    raise exception 'Valid positive amount and ISO currency code are required' using errcode = '22023';
  end if;

  select * into v_tx
  from public.payment_transactions
  where reference = v_clean_ref
    and provider = p_provider
  for update;

  if not found then
    raise exception 'Payment transaction not found for provider reference' using errcode = '22023';
  end if;

  if v_tx.amount <> p_amount or upper(v_tx.currency) <> v_clean_currency then
    raise exception 'Payment amount or currency mismatch' using errcode = '22023';
  end if;

  select * into v_sub
  from public.parent_subscriptions
  where id = v_tx.subscription_id
  for update;

  if v_tx.status in ('succeeded', 'failed', 'refunded') then
    return jsonb_build_object(
      'ok', true,
      'idempotent', true,
      'transaction_id', v_tx.id,
      'reference', v_tx.reference,
      'transaction_status', v_tx.status,
      'subscription_id', v_sub.id,
      'subscription_status', v_sub.status,
      'current_period_end', v_sub.current_period_end
    );
  end if;

  select * into v_plan
  from public.subscription_plans
  where id = v_sub.plan_id;

  update public.payment_transactions
  set status = p_status,
      raw_response = coalesce(p_raw_response, '{}'::jsonb)
  where id = v_tx.id
  returning * into v_tx;

  if p_status = 'succeeded' then
    v_period_interval := case v_plan.billing_interval
      when 'monthly' then interval '1 month'
      when 'quarterly' then interval '3 months'
      when 'annual' then interval '1 year'
    end;

    if v_sub.status = 'active' and v_sub.current_period_end is not null and v_sub.current_period_end > now() then
      v_base_time := v_sub.current_period_end;
    else
      v_base_time := now();
    end if;
    v_new_end := v_base_time + v_period_interval;

    update public.parent_subscriptions
    set status = 'active',
        current_period_start = coalesce(v_sub.current_period_start, now()),
        current_period_end = v_new_end,
        auto_renew = true
    where id = v_sub.id
    returning * into v_sub;
  else
    if v_sub.status = 'pending_payment' then
      update public.parent_subscriptions
      set status = 'past_due'
      where id = v_sub.id
      returning * into v_sub;
    end if;
  end if;

  perform public.write_audit_log(
    null,
    v_sub.parent_user_id,
    'billing.webhook_processed',
    jsonb_build_object(
      'transaction_id', v_tx.id,
      'subscription_id', v_sub.id,
      'provider', v_tx.provider,
      'reference', v_tx.reference,
      'transaction_status', v_tx.status,
      'subscription_status', v_sub.status
    )
  );

  return jsonb_build_object(
    'ok', true,
    'idempotent', false,
    'transaction_id', v_tx.id,
    'reference', v_tx.reference,
    'transaction_status', v_tx.status,
    'subscription_id', v_sub.id,
    'subscription_status', v_sub.status,
    'current_period_end', v_sub.current_period_end
  );
end;
$$;

revoke all on function public.process_mobile_money_webhook(text, text, text, bigint, text, jsonb)
  from public, anon, authenticated;
grant execute on function public.process_mobile_money_webhook(text, text, text, bigint, text, jsonb)
  to service_role;

create or replace function public.cancel_parent_subscription(p_subscription_id uuid)
returns public.parent_subscriptions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_sub public.parent_subscriptions;
begin
  if v_uid is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  update public.parent_subscriptions
  set auto_renew = false,
      status = 'cancelled'
  where id = p_subscription_id
    and parent_user_id = v_uid
    and status in ('pending_payment', 'active', 'past_due')
  returning * into v_sub;

  if not found then
    raise exception 'Active or pending subscription not found for user' using errcode = '42501';
  end if;

  perform public.write_audit_log(
    v_uid,
    v_uid,
    'billing.subscription_cancelled',
    jsonb_build_object('subscription_id', v_sub.id)
  );

  return v_sub;
end;
$$;

revoke all on function public.cancel_parent_subscription(uuid) from public, anon;
grant execute on function public.cancel_parent_subscription(uuid) to authenticated;

insert into public.subscription_plans (
  country_code, code, name, price_cents, currency, billing_interval, features, is_active
)
values
  (
    'TZ',
    'tz-family-monthly',
    'LearnTZ Family Monthly',
    1500000,
    'TZS',
    'monthly',
    '["All TIE Primary Standard 1-6 lessons", "Interactive practice quizzes", "Learner mastery progress tracking"]'::jsonb,
    true
  ),
  (
    'TZ',
    'tz-family-annual',
    'LearnTZ Family Annual',
    15000000,
    'TZS',
    'annual',
    '["12 months full curriculum access", "Two months savings vs monthly", "Interactive practice quizzes", "Multi-learner family tracking"]'::jsonb,
    true
  ),
  (
    'KE',
    'ke-family-monthly',
    'LearnKE Family Monthly',
    100000,
    'KES',
    'monthly',
    '["Full Kenya curriculum access", "Interactive practice quizzes", "Learner mastery tracking"]'::jsonb,
    true
  ),
  (
    'UG',
    'ug-family-monthly',
    'LearnUG Family Monthly',
    2500000,
    'UGX',
    'monthly',
    '["Full Uganda curriculum access", "Interactive practice quizzes", "Learner mastery tracking"]'::jsonb,
    true
  );

commit;
