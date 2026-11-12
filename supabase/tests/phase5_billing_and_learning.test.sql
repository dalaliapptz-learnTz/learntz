begin;

select plan(23);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000501',
    'authenticated', 'authenticated', 'billing-parent-one@example.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Billing Parent One","country_code":"TZ"}', now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000502',
    'authenticated', 'authenticated', 'billing-parent-two@example.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Billing Parent Two","country_code":"TZ"}', now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000503',
    'authenticated', 'authenticated', 'ke-finance-admin@example.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"KE Finance Admin","country_code":"KE"}', now(), now()
  );

insert into public.user_roles (user_id, role, country_code)
values (
  '00000000-0000-0000-0000-000000000503',
  'finance_admin',
  'KE'
);

-- 1. Seeded plans and published content exist
select ok(
  (select count(*) >= 4 from public.subscription_plans where is_active),
  'initial East African subscription plans are seeded'
);
select ok(
  (select count(*) >= 3 from public.subjects where is_published),
  'initial TIE primary subjects are seeded and published'
);

-- 2. Parent One starts checkout and creates learner
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000501', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$
  insert into public.parent_subscriptions (parent_user_id, plan_id, status)
  values (
    '00000000-0000-0000-0000-000000000501',
    (select id from public.subscription_plans where code = 'tz-family-monthly'),
    'active'
  )
  $$,
  null,
  null,
  'parents cannot directly insert an active subscription'
);

select throws_ok(
  $$
  select public.process_mobile_money_webhook(
    'mpesa_tz', 'LTZ-FAKE-REF', 'succeeded', 1500000, 'TZS', '{}'::jsonb
  )
  $$,
  '42501',
  null,
  'authenticated parents cannot invoke webhook settlement RPC'
);

select set_config(
  'learntz.test_checkout',
  (
    select public.start_parent_subscription_checkout(
      (select id from public.subscription_plans where code = 'tz-family-monthly'),
      'mpesa_tz',
      '+255712345678'
    )::text
  ),
  true
);

select is(
  (current_setting('learntz.test_checkout')::jsonb ->> 'status'),
  'pending',
  'checkout creates a pending mobile money payment transaction'
);

select set_config(
  'learntz.test_tx_ref',
  (current_setting('learntz.test_checkout')::jsonb ->> 'reference'),
  true
);

select set_config(
  'learntz.test_learner_id',
  (
    select (public.create_learner(
      '11111111-1111-4111-8111-111111111111'::uuid,
      'Amani',
      null::text,
      'Mushi',
      date '2016-05-01',
      'female',
      'TZ',
      '20000000-0000-0000-0000-000000000001'::uuid,
      '20000000-0000-0000-0000-000000000002'::uuid,
      '20000000-0000-0000-0000-000000000010'::uuid,
      (select id from public.education_grades where curriculum_id = '20000000-0000-0000-0000-000000000002' and code = 'STANDARD_1'),
      null::uuid
    )).id::text
  ),
  true
);

-- Before payment settles: free preview lesson visible, paid lesson hidden
select is(
  (select count(*)::integer from public.lessons where is_published),
  2,
  'unsubscribed parent only reads published free-preview lessons'
);
select is(
  (select count(*)::integer from public.quizzes),
  0,
  'authenticated parents cannot read raw quiz answer keys from quizzes table'
);
select is(
  (select public.get_lesson_practice_quiz(
    current_setting('learntz.test_learner_id')::uuid,
    '30000000-0000-0000-0000-000000000301'
  ) -> 'questions' -> 0 ? 'correct_index'),
  false,
  'get_lesson_practice_quiz strips correct_index from returned questions'
);
select throws_ok(
  $$
  select public.upsert_learner_lesson_progress(
    current_setting('learntz.test_learner_id')::uuid,
    '30000000-0000-0000-0000-000000000303',
    50,
    false
  )
  $$,
  '42501',
  null,
  'unsubscribed parent cannot record progress on paid lesson'
);

-- Free preview quiz submission updates progress & best score
select is(
  (select (public.submit_learner_quiz_attempt(
    current_setting('learntz.test_learner_id')::uuid,
    '30000000-0000-0000-0000-000000000401',
    array[1, 0]
  ) ->> 'score_percent')::integer),
  100,
  'submitting all correct quiz answers computes 100 percent server-side'
);
select is(
  (select (public.get_learner_learning_summary(
    current_setting('learntz.test_learner_id')::uuid
  ) ->> 'completed_lessons')::integer),
  1,
  'passing practice quiz marks lesson completed in learner summary'
);

-- 3. Parent Two cannot see Parent One's subscription, payment transaction, or learner progress
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000502', true);

select is(
  (select count(*)::integer from public.parent_subscriptions),
  0,
  'parent two cannot read parent one subscriptions'
);
select is(
  (select count(*)::integer from public.payment_transactions),
  0,
  'parent two cannot read parent one payment transactions'
);
select is(
  (select count(*)::integer from public.learner_progress),
  0,
  'parent two cannot read parent one learner progress'
);
select throws_ok(
  $$
  select public.submit_learner_quiz_attempt(
    current_setting('learntz.test_learner_id')::uuid,
    '30000000-0000-0000-0000-000000000401',
    array[1, 0]
  )
  $$,
  '42501',
  null,
  'unrelated parent cannot submit quiz attempt for another parent learner'
);

-- 4. KE finance admin cannot read TZ billing records
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000503', true);
select is(
  (select count(*)::integer from public.payment_transactions),
  0,
  'Kenya finance_admin cannot read Tanzania payment transactions'
);

-- 5. Service role settles mobile money webhook & verifies idempotency
reset role;
set local role service_role;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claim.role', 'service_role', true);

select throws_ok(
  $$
  select public.process_mobile_money_webhook(
    'mpesa_tz',
    current_setting('learntz.test_tx_ref'),
    'succeeded',
    100,
    'TZS',
    '{}'::jsonb
  )
  $$,
  '22023',
  null,
  'webhook rejects underpayment amount mismatch'
);

select set_config(
  'learntz.webhook_first',
  (
    select public.process_mobile_money_webhook(
      'mpesa_tz',
      current_setting('learntz.test_tx_ref'),
      'succeeded',
      1500000,
      'TZS',
      '{"TransID":"MPESA12345","ResultCode":0}'::jsonb
    )::text
  ),
  true
);
select is(
  (current_setting('learntz.webhook_first')::jsonb ->> 'subscription_status'),
  'active',
  'valid mobile money webhook activates parent subscription'
);

select set_config(
  'learntz.webhook_dup',
  (
    select public.process_mobile_money_webhook(
      'mpesa_tz',
      current_setting('learntz.test_tx_ref'),
      'succeeded',
      1500000,
      'TZS',
      '{"TransID":"MPESA12345","ResultCode":0}'::jsonb
    )::text
  ),
  true
);
select is(
  (current_setting('learntz.webhook_dup')::jsonb ->> 'idempotent')::boolean,
  true,
  'duplicate webhook delivery is handled idempotently'
);
select is(
  (current_setting('learntz.webhook_dup')::jsonb ->> 'current_period_end'),
  (current_setting('learntz.webhook_first')::jsonb ->> 'current_period_end'),
  'duplicate webhook delivery does not double-extend subscription period'
);

-- 6. Subscribed Parent One now sees paid lesson & owns 1 transaction
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000501', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (select count(*)::integer from public.lessons where is_published),
  3,
  'subscribed parent unlocks full library of published lessons'
);
select is(
  (select count(*)::integer from public.payment_transactions where status = 'succeeded'),
  1,
  'parent one sees their settled mobile money transaction'
);
select is(
  (select (public.upsert_learner_lesson_progress(
    current_setting('learntz.test_learner_id')::uuid,
    '30000000-0000-0000-0000-000000000303',
    100,
    true
  )).status),
  'completed',
  'subscribed parent can complete subscriber-only science lesson'
);

select * from finish();
rollback;
