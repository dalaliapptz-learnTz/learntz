-- ============================================================================
-- Test Suite: phase1_academic_calendar.test.sql
-- Description: Tests academic_terms, 2026 calendar seeds, RLS policies, and RPCs.
-- ============================================================================

begin;
select plan(24);

-- 1. Table structure and constraints
select has_table('public', 'academic_terms', 'Table academic_terms should exist');
select col_is_pk('public', 'academic_terms', 'id', 'academic_terms.id should be primary key');
select col_not_null('public', 'academic_terms', 'academic_calendar_id', 'academic_calendar_id cannot be null');
select col_not_null('public', 'academic_terms', 'country_code', 'country_code cannot be null');
select col_not_null('public', 'academic_terms', 'education_system_id', 'education_system_id cannot be null');
select col_not_null('public', 'academic_terms', 'term_number', 'term_number cannot be null');
select col_not_null('public', 'academic_terms', 'starts_on', 'starts_on cannot be null');
select col_not_null('public', 'academic_terms', 'ends_on', 'ends_on cannot be null');

-- 2. Verify 2026 Calendars Seeded
select results_eq(
  $$ select country_code, name, starts_on, ends_on from public.academic_calendars where id = '20000000-0000-0000-0000-000000000101' $$,
  $$ values ('TZ'::text, 'Mwaka wa Masomo 2026'::text, '2026-01-05'::date, '2026-12-04'::date) $$,
  'Tanzania 2026 academic calendar should be seeded correctly'
);

select results_eq(
  $$ select country_code, name, starts_on, ends_on from public.academic_calendars where id = '20000000-0000-0000-0000-000000000121' $$,
  $$ values ('KE'::text, 'Academic Year 2026 (CBC)'::text, '2026-01-05'::date, '2026-11-06'::date) $$,
  'Kenya 2026 academic calendar should be seeded correctly'
);

select results_eq(
  $$ select country_code, name, starts_on, ends_on from public.academic_calendars where id = '20000000-0000-0000-0000-000000000151' $$,
  $$ values ('UG'::text, 'Academic Year 2026'::text, '2026-02-02'::date, '2026-12-04'::date) $$,
  'Uganda 2026 academic calendar should be seeded correctly'
);

-- 3. Verify Term counts per Country
select results_eq(
  $$ select count(*)::int from public.academic_terms where academic_calendar_id = '20000000-0000-0000-0000-000000000101' $$,
  $$ values (2) $$,
  'Tanzania 2026 calendar should have exactly 2 terms'
);

select results_eq(
  $$ select count(*)::int from public.academic_terms where academic_calendar_id = '20000000-0000-0000-0000-000000000121' $$,
  $$ values (3) $$,
  'Kenya 2026 calendar should have exactly 3 terms'
);

select results_eq(
  $$ select count(*)::int from public.academic_terms where academic_calendar_id = '20000000-0000-0000-0000-000000000151' $$,
  $$ values (3) $$,
  'Uganda 2026 calendar should have exactly 3 terms'
);

-- 4. Check term sequence and dates order
select is(
  (select starts_on from public.academic_terms where id = '20000000-0000-0000-0000-000000000111'),
  '2026-01-05'::date,
  'TZ Term 1 should start on 2026-01-05'
);

select is(
  (select starts_on from public.academic_terms where id = '20000000-0000-0000-0000-000000000112'),
  '2026-07-06'::date,
  'TZ Term 2 should start on 2026-07-06'
);

-- 5. RPC function existence
select has_function('public', 'get_active_academic_calendar', ARRAY['text', 'uuid', 'date'], 'get_active_academic_calendar RPC should exist');
select has_function('public', 'list_academic_terms', ARRAY['uuid'], 'list_academic_terms RPC should exist');

-- 6. RPC test: get_active_academic_calendar for Tanzania
select is(
  public.get_active_academic_calendar(
    'TZ',
    '20000000-0000-0000-0000-000000000001'::uuid,
    '2026-03-15'::date
  ) ->> 'name',
  'Mwaka wa Masomo 2026',
  'get_active_academic_calendar returns 2026 calendar for March 2026 date'
);

select is(
  jsonb_array_length(
    public.get_active_academic_calendar(
      'TZ',
      '20000000-0000-0000-0000-000000000001'::uuid,
      '2026-03-15'::date
    ) -> 'terms'
  ),
  2,
  'get_active_academic_calendar returns 2 terms for Tanzania'
);

select is(
  (public.get_active_academic_calendar(
    'TZ',
    '20000000-0000-0000-0000-000000000001'::uuid,
    '2026-03-15'::date
  ) -> 'terms' -> 0 ->> 'is_current')::boolean,
  true,
  'March 15, 2026 should mark Term 1 as current'
);

select is(
  (public.get_active_academic_calendar(
    'TZ',
    '20000000-0000-0000-0000-000000000001'::uuid,
    '2026-08-15'::date
  ) -> 'terms' -> 1 ->> 'is_current')::boolean,
  true,
  'August 15, 2026 should mark Term 2 as current'
);

-- 7. RPC test: list_academic_terms
select results_eq(
  $$ select term_number, name from public.list_academic_terms('20000000-0000-0000-0000-000000000121'::uuid) $$,
  $$ values
     (1, 'Term 1'::text),
     (2, 'Term 2'::text),
     (3, 'Term 3'::text)
  $$,
  'list_academic_terms returns ordered list of terms for Kenya'
);

-- 8. Check date constraint on terms
select throws_ok(
  $$
    insert into public.academic_terms (
      academic_calendar_id, country_code, education_system_id, term_number, name, starts_on, ends_on
    ) values (
      '20000000-0000-0000-0000-000000000101', 'TZ', '20000000-0000-0000-0000-000000000001',
      3, 'Invalid Dates Term', '2026-10-10', '2026-05-01'
    )
  $$,
  '23514',
  NULL,
  'Invalid ends_on < starts_on should throw check constraint violation'
);

select * from finish();
rollback;
