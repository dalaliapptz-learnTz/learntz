begin;
select plan(12);

-- Test 1-3: Check Table and Functions
select has_table('public', 'mock_to_real_comparisons', 'Table mock_to_real_comparisons should exist');
select has_function('public', 'compute_mock_to_real_correlation', ARRAY['uuid', 'uuid'], 'compute_mock_to_real_correlation should exist');
select has_function('public', 'get_mock_intelligence_leaderboard', ARRAY['text', 'integer'], 'get_mock_intelligence_leaderboard should exist');
select has_function('public', 'get_historical_topic_frequency', ARRAY['uuid', 'text'], 'get_historical_topic_frequency should exist');

-- Test 5-6: Verify Seeded Comparison Records
select results_eq(
  'select count(*)::integer from public.mock_to_real_comparisons where country_code = ''TZ'' and year = 2024',
  ARRAY[2],
  'Should have 2 calibration comparisons seeded for TZ in 2024'
);

select is(
  (
    select predictive_validity_index from public.mock_to_real_comparisons
    where id = 'c1000000-0000-0000-0000-000000000001'
  ),
  0.87,
  'Mwanza Mock comparison should have 0.87 predictive validity index'
);

-- Test 7-9: get_mock_intelligence_leaderboard
select ok(
  (
    select (public.get_mock_intelligence_leaderboard('TZ', 2024) ? 'rankings')
  ),
  'Leaderboard should return rankings array'
);

select results_eq(
  $$
    select jsonb_array_length((public.get_mock_intelligence_leaderboard('TZ', 2024))->'rankings')
  $$,
  ARRAY[2],
  'Leaderboard should contain 2 ranked mocks for TZ 2024'
);

select is(
  (
    select (public.get_mock_intelligence_leaderboard('TZ', 2024))->'rankings'->0->>'rank'
  ),
  '1',
  'First entry should hold Rank 1'
);

-- Test 10-11: compute_mock_to_real_correlation
select lives_ok(
  $$
    select public.compute_mock_to_real_correlation(
      '40000000-0000-0000-0000-000000000002'::uuid,
      '40000000-0000-0000-0000-000000000001'::uuid
    );
  $$,
  'Should be able to compute correlation between mock paper and real national paper'
);

select ok(
  (
    select (public.compute_mock_to_real_correlation(
      '40000000-0000-0000-0000-000000000002'::uuid,
      '40000000-0000-0000-0000-000000000001'::uuid
    )->>'predictive_validity_index')::numeric > 0
  ),
  'Computed predictive validity index should be positive'
);

-- Test 12: get_historical_topic_frequency
select ok(
  (
    select (public.get_historical_topic_frequency(null, 'TZ') ? 'topic_frequency')
  ),
  'Historical topic frequency should return topic_frequency array'
);

select * from finish();
rollback;
