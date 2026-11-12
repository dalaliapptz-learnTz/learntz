begin;

select plan(32);

-- Provision test parents for Uganda and Kenya
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
    '00000000-0000-0000-0000-000000000601',
    'authenticated',
    'authenticated',
    'uganda-parent@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Uganda Parent","country_code":"UG"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000602',
    'authenticated',
    'authenticated',
    'kenya-parent@example.test',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Kenya Parent","country_code":"KE"}',
    now(),
    now()
  );

-- ============================================================================
-- 1. KENYA (CBC) STRUCTURE TESTS (TASK-601)
-- ============================================================================

-- 1. Kenya education system seeded
select is(
  (select count(*)::integer from public.education_systems where country_code = 'KE' and code = 'KE_CBC' and is_enabled),
  1,
  'Kenya CBC education system is seeded and enabled'
);

-- 2. Kenya curriculum authority seeded
select is(
  (select count(*)::integer from public.curriculum_authorities where country_code = 'KE' and code = 'KICD' and is_enabled),
  1,
  'Kenya KICD authority is seeded and enabled'
);

-- 3. Kenya curriculum seeded
select is(
  (select count(*)::integer from public.curricula where country_code = 'KE' and code = 'CBC' and is_enabled),
  1,
  'Kenya CBC curriculum is seeded and enabled'
);

-- 4. Kenya 4 education levels
select is(
  (select count(*)::integer 
   from public.education_levels l 
   join public.curricula c on c.id = l.curriculum_id 
   where c.country_code = 'KE' and c.code = 'CBC'),
  4,
  'Kenya CBC has 4 education levels (Pre-Primary, Primary, Junior Sec, Senior Sec)'
);

-- 5. Kenya 14 education grades
select is(
  (select count(*)::integer 
   from public.education_grades g 
   join public.curricula c on c.id = g.curriculum_id 
   where c.country_code = 'KE' and c.code = 'CBC'),
  14,
  'Kenya CBC has 14 grades (PP1-2, Grades 1-6, Grades 7-9, Grades 10-12)'
);

-- 6. Kenya grade sequence ordering
select is(
  (select array_agg(g.code order by l.sequence, g.sequence)
   from public.education_grades g
   join public.education_levels l on l.id = g.education_level_id
   join public.curricula c on c.id = g.curriculum_id
   where c.country_code = 'KE' and c.code = 'CBC'),
  array['PP1', 'PP2', 'GRADE_1', 'GRADE_2', 'GRADE_3', 'GRADE_4', 'GRADE_5', 'GRADE_6', 'GRADE_7', 'GRADE_8', 'GRADE_9', 'GRADE_10', 'GRADE_11', 'GRADE_12']::text[],
  'Kenya CBC grades sequence matches official 2-6-3-3 progression'
);

-- 7. Kenya grade progressions count
select is(
  (select count(*)::integer 
   from public.grade_progressions p 
   join public.curricula c on c.id = p.curriculum_id 
   where c.country_code = 'KE' and c.code = 'CBC'),
  13,
  'Kenya CBC has 13 linear grade progressions'
);

-- 8. Kenya cross-level progression: PP2 -> Grade 1
select is(
  (select count(*)::integer 
   from public.grade_progressions p
   join public.education_grades f on f.id = p.from_grade_id
   join public.education_grades t on t.id = p.to_grade_id
   where f.code = 'PP2' and t.code = 'GRADE_1'),
  1,
  'Kenya cross-level progression from PP2 (Pre-Primary) to Grade 1 (Primary) is valid'
);

-- 9. Kenya cross-level progression: Grade 6 -> Grade 7 (Junior Secondary transition)
select is(
  (select count(*)::integer 
   from public.grade_progressions p
   join public.education_grades f on f.id = p.from_grade_id
   join public.education_grades t on t.id = p.to_grade_id
   where f.code = 'GRADE_6' and t.code = 'GRADE_7'),
  1,
  'Kenya cross-level progression from Grade 6 (Primary) to Grade 7 (Junior Secondary) is valid'
);

-- 10. Kenya cross-level progression: Grade 9 -> Grade 10 (Senior Secondary transition)
select is(
  (select count(*)::integer 
   from public.grade_progressions p
   join public.education_grades f on f.id = p.from_grade_id
   join public.education_grades t on t.id = p.to_grade_id
   where f.code = 'GRADE_9' and t.code = 'GRADE_10'),
  1,
  'Kenya cross-level progression from Grade 9 (Junior Secondary) to Grade 10 (Senior Secondary) is valid'
);

-- ============================================================================
-- 2. UGANDA (NCDC) STRUCTURE TESTS (TASK-602)
-- ============================================================================

-- 11. Uganda education system seeded
select is(
  (select count(*)::integer from public.education_systems where country_code = 'UG' and code = 'UG_NATIONAL' and is_enabled),
  1,
  'Uganda National education system is seeded and enabled'
);

-- 12. Uganda curriculum authority seeded
select is(
  (select count(*)::integer from public.curriculum_authorities where country_code = 'UG' and code = 'NCDC' and is_enabled),
  1,
  'Uganda NCDC authority is seeded and enabled'
);

-- 13. Uganda curriculum seeded
select is(
  (select count(*)::integer from public.curricula where country_code = 'UG' and code = 'NCDC_CURRICULUM' and is_enabled),
  1,
  'Uganda National Curriculum is seeded and enabled'
);

-- 14. Uganda 3 education levels
select is(
  (select count(*)::integer 
   from public.education_levels l 
   join public.curricula c on c.id = l.curriculum_id 
   where c.country_code = 'UG' and c.code = 'NCDC_CURRICULUM'),
  3,
  'Uganda NCDC has 3 education levels (Primary, Lower Secondary, Upper Secondary)'
);

-- 15. Uganda 13 education grades
select is(
  (select count(*)::integer 
   from public.education_grades g 
   join public.curricula c on c.id = g.curriculum_id 
   where c.country_code = 'UG' and c.code = 'NCDC_CURRICULUM'),
  13,
  'Uganda NCDC has 13 grades (P1-P7, S1-S4, S5-S6)'
);

-- 16. Uganda grade sequence ordering
select is(
  (select array_agg(g.code order by l.sequence, g.sequence)
   from public.education_grades g
   join public.education_levels l on l.id = g.education_level_id
   join public.curricula c on c.id = g.curriculum_id
   where c.country_code = 'UG' and c.code = 'NCDC_CURRICULUM'),
  array['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6']::text[],
  'Uganda NCDC grades sequence matches official 7-4-2 progression'
);

-- 17. Uganda grade progressions count
select is(
  (select count(*)::integer 
   from public.grade_progressions p 
   join public.curricula c on c.id = p.curriculum_id 
   where c.country_code = 'UG' and c.code = 'NCDC_CURRICULUM'),
  12,
  'Uganda NCDC has 12 linear grade progressions'
);

-- 18. Uganda cross-level progression: P7 -> S1 (PLE transition)
select is(
  (select count(*)::integer 
   from public.grade_progressions p
   join public.education_grades f on f.id = p.from_grade_id
   join public.education_grades t on t.id = p.to_grade_id
   where f.code = 'P7' and t.code = 'S1'),
  1,
  'Uganda cross-level progression from P7 (Primary) to S1 (Lower Secondary) is valid'
);

-- 19. Uganda cross-level progression: S4 -> S5 (UCE to UACE transition)
select is(
  (select count(*)::integer 
   from public.grade_progressions p
   join public.education_grades f on f.id = p.from_grade_id
   join public.education_grades t on t.id = p.to_grade_id
   where f.code = 'S4' and t.code = 'S5'),
  1,
  'Uganda cross-level progression from S4 (Lower Secondary) to S5 (Upper Secondary) is valid'
);

-- ============================================================================
-- 3. UGANDA LEARNER REGISTRATION & PROMOTION TESTS
-- ============================================================================

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000601', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

-- 20. Register Uganda learner in Primary 7 (P7)
select set_config(
  'test.ug_learner_id',
  (public.create_learner(
    '60000000-0000-0000-0000-000000000001',
    'Amina',
    null,
    'Kigozi',
    '2012-05-10',
    'female',
    'UG',
    '20000000-0000-0000-0000-000000000051', -- UG_NATIONAL
    '20000000-0000-0000-0000-000000000053', -- NCDC_CURRICULUM
    '20000000-0000-0000-0000-000000000060', -- PRIMARY level
    '20000000-0000-0000-0000-000000000077', -- P7
    null
  )).id::text,
  true
);

select isnt(
  current_setting('test.ug_learner_id'),
  '',
  'Uganda parent can register a learner in Primary 7'
);

-- 21. Verify learner initial education attributes
select is(
  (select grade_id from public.learners where id = current_setting('test.ug_learner_id')::uuid),
  '20000000-0000-0000-0000-000000000077'::uuid,
  'Learner initial grade is Uganda P7'
);

-- 22. Reject invalid progression: P7 -> S3 (skipping grades S1, S2)
select throws_ok(
  $$select public.record_learner_promotion(
    current_setting('test.ug_learner_id')::uuid,
    'UG',
    '20000000-0000-0000-0000-000000000051',
    '20000000-0000-0000-0000-000000000053',
    '20000000-0000-0000-0000-000000000061', -- LOWER_SECONDARY
    '20000000-0000-0000-0000-00000000007a', -- S3
    null,
    'promoted',
    current_date,
    null,
    'Invalid promotion leap to S3'
  )$$,
  '22023',
  null,
  'Invalid grade leap from P7 directly to S3 is rejected'
);

-- 23. Reject level/grade mismatch (target grade S1 passed with Upper Secondary level id)
select throws_ok(
  $$select public.record_learner_promotion(
    current_setting('test.ug_learner_id')::uuid,
    'UG',
    '20000000-0000-0000-0000-000000000051',
    '20000000-0000-0000-0000-000000000053',
    '20000000-0000-0000-0000-000000000062', -- UPPER_SECONDARY (mismatched)
    '20000000-0000-0000-0000-000000000078', -- S1 (which belongs to Lower Secondary)
    null,
    'promoted',
    current_date,
    null,
    'Mismatched education level'
  )$$,
  '22023',
  null,
  'Education level and grade mismatch during promotion is rejected'
);

-- 24. Valid cross-level promotion: P7 (Primary) -> S1 (Lower Secondary)
select lives_ok(
  $$select public.record_learner_promotion(
    current_setting('test.ug_learner_id')::uuid,
    'UG',
    '20000000-0000-0000-0000-000000000051',
    '20000000-0000-0000-0000-000000000053',
    '20000000-0000-0000-0000-000000000061', -- LOWER_SECONDARY
    '20000000-0000-0000-0000-000000000078', -- S1
    null,
    'promoted',
    current_date,
    null,
    'Promoted to Senior 1 following PLE results'
  )$$,
  'Valid cross-level promotion from Uganda P7 to S1 succeeds'
);

-- 25. Verify learner grade is now S1 and level is LOWER_SECONDARY
select is(
  (select (grade_id = '20000000-0000-0000-0000-000000000078'::uuid and education_level_id = '20000000-0000-0000-0000-000000000061'::uuid)
   from public.learners where id = current_setting('test.ug_learner_id')::uuid),
  true,
  'Learner record is updated to Senior 1 and Lower Secondary level'
);

-- 26. Verify learner promotion history record created
select is(
  (select count(*)::integer 
   from public.learner_promotions 
   where learner_id = current_setting('test.ug_learner_id')::uuid
     and from_grade_id = '20000000-0000-0000-0000-000000000077'::uuid
     and to_grade_id = '20000000-0000-0000-0000-000000000078'::uuid
     and promotion_type = 'promoted'),
  1,
  'Promotion audit record is persisted in learner_promotions'
);

-- ============================================================================
-- 4. KENYA LEARNER REGISTRATION & PROMOTION TESTS
-- ============================================================================

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000602', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

-- 27. Register Kenya learner in Grade 6 (Primary)
select set_config(
  'test.ke_learner_id',
  (public.create_learner(
    '60000000-0000-0000-0000-000000000002',
    'Juma',
    null,
    'Mwangi',
    '2013-08-20',
    'male',
    'KE',
    '20000000-0000-0000-0000-000000000021', -- KE_CBC
    '20000000-0000-0000-0000-000000000023', -- CBC
    '20000000-0000-0000-0000-000000000031', -- PRIMARY level
    '20000000-0000-0000-0000-000000000048', -- GRADE_6
    null
  )).id::text,
  true
);

select isnt(
  current_setting('test.ke_learner_id'),
  '',
  'Kenya parent can register a learner in Grade 6'
);

-- 28. Reject invalid progression: Grade 6 -> Grade 8 (skipping Grade 7)
select throws_ok(
  $$select public.record_learner_promotion(
    current_setting('test.ke_learner_id')::uuid,
    'KE',
    '20000000-0000-0000-0000-000000000021',
    '20000000-0000-0000-0000-000000000023',
    '20000000-0000-0000-0000-000000000032', -- JUNIOR_SECONDARY
    '20000000-0000-0000-0000-00000000004a', -- GRADE_8
    null,
    'promoted',
    current_date,
    null,
    'Invalid grade skip to Grade 8'
  )$$,
  '22023',
  null,
  'Invalid grade leap from Grade 6 to Grade 8 is rejected'
);

-- 29. Valid cross-level progression: Grade 6 (Primary) -> Grade 7 (Junior Secondary)
select lives_ok(
  $$select public.record_learner_promotion(
    current_setting('test.ke_learner_id')::uuid,
    'KE',
    '20000000-0000-0000-0000-000000000021',
    '20000000-0000-0000-0000-000000000023',
    '20000000-0000-0000-0000-000000000032', -- JUNIOR_SECONDARY
    '20000000-0000-0000-0000-000000000049', -- GRADE_7
    null,
    'promoted',
    current_date,
    null,
    'Transitioning to Junior Secondary Grade 7'
  )$$,
  'Valid cross-level promotion from Kenya Grade 6 to Grade 7 succeeds'
);

-- 30. Verify learner grade is now Grade 7 and level is JUNIOR_SECONDARY
select is(
  (select (grade_id = '20000000-0000-0000-0000-000000000049'::uuid and education_level_id = '20000000-0000-0000-0000-000000000032'::uuid)
   from public.learners where id = current_setting('test.ke_learner_id')::uuid),
  true,
  'Learner record is updated to Grade 7 and Junior Secondary level'
);

-- 31. Verify learner promotion history record created
select is(
  (select count(*)::integer 
   from public.learner_promotions 
   where learner_id = current_setting('test.ke_learner_id')::uuid
     and from_grade_id = '20000000-0000-0000-0000-000000000048'::uuid
     and to_grade_id = '20000000-0000-0000-0000-000000000049'::uuid
     and promotion_type = 'promoted'),
  1,
  'Promotion audit record for Kenya learner is persisted'
);

-- 32. Cross-border promotion attempt (Kenya learner promoted with Uganda system) rejected
select throws_ok(
  $$select public.record_learner_promotion(
    current_setting('test.ke_learner_id')::uuid,
    'UG',
    '20000000-0000-0000-0000-000000000051',
    '20000000-0000-0000-0000-000000000053',
    '20000000-0000-0000-0000-000000000061',
    '20000000-0000-0000-0000-000000000078',
    null,
    'promoted',
    current_date,
    null,
    'Invalid cross-country promotion'
  )$$,
  '22023',
  null,
  'Promoting a learner across country boundary without system change is rejected'
);

rollback;
