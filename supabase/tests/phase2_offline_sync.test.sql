begin;
select plan(11);

-- 1. Schema structure checks
select has_table('public', 'learner_sync_events', 'learner_sync_events table exists');
select has_column('public', 'learner_sync_events', 'client_event_id', 'has client_event_id column');
select has_column('public', 'learner_sync_events', 'event_type', 'has event_type column');

-- 2. Test setup: Auth users
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'e1000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'parent_sync@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Sync Parent","country_code":"TZ"}', now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'e1000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'stranger_sync@learntz.test', '',
    now(), '{"provider":"email","providers":["email"]}',
    '{"full_name":"Stranger Sync","country_code":"TZ"}', now(), now()
  )
on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'e1000000-0000-0000-0000-000000000001', true);

-- Create learner
select set_config(
  'test.learner_id',
  (public.create_learner(
    '60000000-0000-0000-0000-000000000003',
    'Fatuma',
    null,
    'Sync',
    '2016-08-14',
    null,
    'TZ',
    '20000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000010',
    (select id from public.education_grades where code = 'STANDARD_1'),
    null
  )).id::text,
  true
);

-- Stranger cannot sync or download offline pack
select set_config('request.jwt.claim.sub', 'e1000000-0000-0000-0000-000000000002', true);

select throws_ok(
  format('select public.sync_learner_offline_activity(%L::uuid, %L::jsonb)',
    current_setting('test.learner_id'), '[]'::text),
  '42501',
  'Authorized parent access is required for this learner',
  'Stranger cannot sync learner offline activity'
);

select throws_ok(
  format('select public.get_subject_offline_pack(%L::uuid, %L::uuid)',
    current_setting('test.learner_id'), '30000000-0000-0000-0000-000000000101'),
  '42501',
  'Authorized parent access is required for this learner',
  'Stranger cannot download subject offline pack'
);

-- Switch back to authorized parent
select set_config('request.jwt.claim.sub', 'e1000000-0000-0000-0000-000000000001', true);

-- Test 6: Sync offline reading progress (75%)
select is(
  (public.sync_learner_offline_activity(
    current_setting('test.learner_id')::uuid,
    jsonb_build_array(
      jsonb_build_object(
        'client_event_id', 'a0000000-0000-0000-0000-000000000001'::uuid,
        'event_type', 'reading_progress',
        'payload', jsonb_build_object(
          'lesson_id', '30000000-0000-0000-0000-000000000301'::uuid,
          'reading_progress_percent', 75
        ),
        'client_recorded_at', now()
      )
    )
  ) ->> 'events_processed')::integer,
  1,
  'First sync event processed successfully'
);

-- Test 7: Verify progress was recorded in learner_progress
select is(
  (select reading_progress_percent
   from public.learner_progress
   where learner_id = current_setting('test.learner_id')::uuid
     and lesson_id = '30000000-0000-0000-0000-000000000301'),
  75,
  'Learner progress reading_progress_percent set to 75%'
);

-- Test 8: Re-sending same event is recognized as duplicate (idempotent)
select is(
  (public.sync_learner_offline_activity(
    current_setting('test.learner_id')::uuid,
    jsonb_build_array(
      jsonb_build_object(
        'client_event_id', 'a0000000-0000-0000-0000-000000000001'::uuid,
        'event_type', 'reading_progress',
        'payload', jsonb_build_object(
          'lesson_id', '30000000-0000-0000-0000-000000000301'::uuid,
          'reading_progress_percent', 75
        ),
        'client_recorded_at', now()
      )
    )
  ) ->> 'events_duplicate')::integer,
  1,
  'Re-sent event identified as duplicate'
);

-- Test 9: Conflict resolution: sending lower progress (40%) does NOT decrease recorded 75%
select public.sync_learner_offline_activity(
  current_setting('test.learner_id')::uuid,
  jsonb_build_array(
    jsonb_build_object(
      'client_event_id', 'a0000000-0000-0000-0000-000000000002'::uuid,
      'event_type', 'reading_progress',
      'payload', jsonb_build_object(
        'lesson_id', '30000000-0000-0000-0000-000000000301'::uuid,
        'reading_progress_percent', 40
      ),
      'client_recorded_at', now()
    )
  )
);

select is(
  (select reading_progress_percent
   from public.learner_progress
   where learner_id = current_setting('test.learner_id')::uuid
     and lesson_id = '30000000-0000-0000-0000-000000000301'),
  75,
  'Conflict resolution keeps higher progress percent (75% retained over 40%)'
);

-- Test 11: Sync lesson_completed event completes the lesson
select public.sync_learner_offline_activity(
  current_setting('test.learner_id')::uuid,
  jsonb_build_array(
    jsonb_build_object(
      'client_event_id', 'a0000000-0000-0000-0000-000000000003'::uuid,
      'event_type', 'lesson_completed',
      'payload', jsonb_build_object(
        'lesson_id', '30000000-0000-0000-0000-000000000301'::uuid
      ),
      'client_recorded_at', now()
    )
  )
);

select is(
  (select status
   from public.learner_progress
   where learner_id = current_setting('test.learner_id')::uuid
     and lesson_id = '30000000-0000-0000-0000-000000000301'),
  'completed',
  'Status transitioned to completed'
);

-- Test 12: Offline pack download returns topics and flashcard decks
select is(
  (select (public.get_subject_offline_pack(
    current_setting('test.learner_id')::uuid,
    '30000000-0000-0000-0000-000000000101'::uuid
  ) ->> 'subject_name')),
  'Kiswahili',
  'Offline pack downloaded for Kiswahili subject'
);

select * from finish();
rollback;
