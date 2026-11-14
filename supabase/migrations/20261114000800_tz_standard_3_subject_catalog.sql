-- LearnTZ: Tanzania Standard III (Grade 3) subject catalogue
-- Metadata-only seed. No TIE syllabus passages, competencies, or lesson text are copied.
-- Source catalogue: TIE, "Muhtasari wa Elimu ya Msingi" (official syllabus listing),
-- https://tie.go.tz/publications/syllabus-for-primary-education
-- Keep unpublished until the current curriculum edition, medium-specific offering,
-- and subject status have been checked by the curriculum reviewer.

begin;

do $$
declare
  v_grade_count integer;
begin
  select count(*) into v_grade_count
  from public.education_grades grade
  join public.education_levels level
    on level.id = grade.education_level_id
   and level.curriculum_id = grade.curriculum_id
  join public.curricula curriculum
    on curriculum.id = grade.curriculum_id
  where curriculum.country_code = 'TZ'
    and curriculum.code = 'TIE'
    and level.code = 'PRIMARY'
    and grade.code = 'STANDARD_3';

  if v_grade_count <> 1 then
    raise exception
      'Expected exactly one Tanzania TIE Standard III grade record; found %',
      v_grade_count;
  end if;
end;
$$;

with grade_scope as (
  select
    curriculum.id as curriculum_id,
    level.id as education_level_id,
    grade.id as grade_id
  from public.curricula curriculum
  join public.education_levels level
    on level.curriculum_id = curriculum.id
  join public.education_grades grade
    on grade.curriculum_id = curriculum.id
   and grade.education_level_id = level.id
  where curriculum.country_code = 'TZ'
    and curriculum.code = 'TIE'
    and level.code = 'PRIMARY'
    and grade.code = 'STANDARD_3'
),
subject_catalog (
  code, name, learning_area, offering, display_order
) as (
  values
    ('tie3-kiswahili', 'Kiswahili', 'Language and Communication', 'Core subject', 1),
    ('tie3-english', 'English', 'Language and Communication', 'Core subject', 2),
    ('tie3-chinese', 'Chinese', 'Language and Communication', 'Optional language; subject to school capacity', 3),
    ('tie3-arabic', 'Arabic', 'Language and Communication', 'Optional language; subject to school capacity', 4),
    ('tie3-french', 'French', 'Language and Communication', 'Optional language; subject to school capacity', 5),
    ('tie3-mathematics', 'Mathematics', 'Mathematics', 'Core subject', 6),
    ('tie3-historia-tanzania-maadili', 'Historia ya Tanzania na Maadili', 'Social Science', 'Core subject', 7),
    ('tie3-geography-environment', 'Geography and Environment', 'Social Science', 'Core subject', 8),
    ('tie3-religious-education', 'Religious Education', 'Social Science', 'Faith-sensitive offering; school provision to be confirmed', 9),
    ('tie3-science', 'Science', 'Science and Technology', 'Core subject', 10),
    ('tie3-arts-sports', 'Arts and Sports', 'Arts and Sports', 'Core subject', 11)
)
insert into public.subjects (
  country_code,
  curriculum_id,
  education_level_id,
  grade_id,
  code,
  name,
  description,
  display_order,
  is_published
)
select
  'TZ',
  scope.curriculum_id,
  scope.education_level_id,
  scope.grade_id,
  catalog.code,
  catalog.name,
  'Learning area: ' || catalog.learning_area || '. Offering: ' || catalog.offering ||
    '. Catalogue metadata only; verify against the approved Standard III syllabus before publication.',
  catalog.display_order,
  false
from grade_scope scope
cross join subject_catalog catalog
where not exists (
  select 1
  from public.subjects existing
  where existing.curriculum_id = scope.curriculum_id
    and existing.education_level_id = scope.education_level_id
    and existing.grade_id = scope.grade_id
    and existing.code = catalog.code
);

comment on table public.subjects is
  'Country-scoped subject catalogue. Grade-specific TIE Standard III entries seeded as unpublished metadata pending curriculum and rights review.';

commit;
