create table public.countries (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  product_name text not null,
  currency_code text not null,
  timezone text not null,
  default_language_code text not null,
  supported_language_codes text[] not null default '{}',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.curricula (
  id uuid primary key default gen_random_uuid(),
  country_id uuid not null references public.countries(id),
  code text not null,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (country_id, code)
);

create table public.education_systems (
  id uuid primary key default gen_random_uuid(),
  curriculum_id uuid not null references public.curricula(id),
  code text not null,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (curriculum_id, code)
);

create table public.education_levels (
  id uuid primary key default gen_random_uuid(),
  education_system_id uuid not null references public.education_systems(id),
  code text not null,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (education_system_id, code)
);

create table public.grades (
  id uuid primary key default gen_random_uuid(),
  education_level_id uuid not null references public.education_levels(id),
  code text not null,
  name text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (education_level_id, code)
);

create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  curriculum_id uuid not null references public.curricula(id),
  code text not null,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (curriculum_id, code)
);

create table public.languages (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.curriculum_terms (
  id uuid primary key default gen_random_uuid(),
  curriculum_id uuid not null references public.curricula(id),
  term_key text not null,
  language_code text not null references public.languages(code),
  label text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (curriculum_id, term_key, language_code)
);

alter table public.countries enable row level security;
alter table public.curricula enable row level security;
alter table public.education_systems enable row level security;
alter table public.education_levels enable row level security;
alter table public.grades enable row level security;
alter table public.subjects enable row level security;
alter table public.languages enable row level security;
alter table public.curriculum_terms enable row level security;

create policy "Active countries are readable"
  on public.countries for select
  using (is_active);

create policy "Active curricula are readable"
  on public.curricula for select
  using (
    is_active and exists (
      select 1 from public.countries
      where countries.id = curricula.country_id and countries.is_active
    )
  );

create policy "Active education systems are readable"
  on public.education_systems for select
  using (
    is_active and exists (
      select 1 from public.curricula
      where curricula.id = education_systems.curriculum_id and curricula.is_active
    )
  );

create policy "Active education levels are readable"
  on public.education_levels for select
  using (
    is_active and exists (
      select 1 from public.education_systems
      where education_systems.id = education_levels.education_system_id and education_systems.is_active
    )
  );

create policy "Active grades are readable"
  on public.grades for select
  using (
    is_active and exists (
      select 1 from public.education_levels
      where education_levels.id = grades.education_level_id and education_levels.is_active
    )
  );

create policy "Active subjects are readable"
  on public.subjects for select
  using (
    is_active and exists (
      select 1 from public.curricula
      where curricula.id = subjects.curriculum_id and curricula.is_active
    )
  );

create policy "Active languages are readable"
  on public.languages for select
  using (is_active);

create policy "Curriculum terms are readable"
  on public.curriculum_terms for select
  using (
    exists (
      select 1 from public.curricula
      where curricula.id = curriculum_terms.curriculum_id and curricula.is_active
    ) and exists (
      select 1 from public.languages
      where languages.code = curriculum_terms.language_code and languages.is_active
    )
  );

insert into public.languages (code, name)
values ('en', 'English'), ('sw', 'Kiswahili')
on conflict (code) do nothing;

insert into public.countries (code, product_name, currency_code, timezone, default_language_code, supported_language_codes)
values
  ('TZ', 'LearnTZ', 'TZS', 'Africa/Dar_es_Salaam', 'sw', array['en', 'sw']),
  ('KE', 'LearnKE', 'KES', 'Africa/Nairobi', 'en', array['en', 'sw']),
  ('UG', 'LearnUG', 'UGX', 'Africa/Kampala', 'en', array['en', 'sw']),
  ('RW', 'LearnRW', 'RWF', 'Africa/Kigali', 'en', array['en']),
  ('BI', 'LearnBI', 'BIF', 'Africa/Bujumbura', 'fr', array['en', 'fr']),
  ('SS', 'LearnSS', 'SSP', 'Africa/Juba', 'en', array['en'])
on conflict (code) do nothing;

insert into public.curricula (country_id, code, name)
select id, 'TIE', 'Tanzania Institute of Education' from public.countries where code = 'TZ'
on conflict (country_id, code) do nothing;
insert into public.curricula (country_id, code, name)
select id, 'CBC', 'Competency Based Curriculum' from public.countries where code = 'KE'
on conflict (country_id, code) do nothing;
insert into public.curricula (country_id, code, name)
select id, 'UNEB', 'Uganda national curriculum' from public.countries where code = 'UG'
on conflict (country_id, code) do nothing;
insert into public.curricula (country_id, code, name)
select id, 'NATIONAL', 'National curriculum' from public.countries where code in ('RW', 'BI', 'SS')
on conflict (country_id, code) do nothing;

insert into public.education_systems (curriculum_id, code, name)
select curricula.id, 'PRIMARY', 'Primary' from public.curricula
on conflict (curriculum_id, code) do nothing;
insert into public.education_systems (curriculum_id, code, name)
select curricula.id, 'SECONDARY', 'Secondary' from public.curricula where curricula.code = 'TIE'
on conflict (curriculum_id, code) do nothing;

insert into public.languages (code, name)
values ('fr', 'French')
on conflict (code) do nothing;

insert into public.education_levels (education_system_id, code, name)
select education_systems.id, 'PRIMARY', 'Primary school'
from public.education_systems
join public.curricula on curricula.id = education_systems.curriculum_id
where curricula.code in ('TIE', 'CBC', 'UNEB', 'NATIONAL')
  and education_systems.code = 'PRIMARY'
on conflict (education_system_id, code) do nothing;

insert into public.grades (education_level_id, code, name, sort_order)
select education_levels.id, grade.code, grade.name, grade.sort_order
from public.education_levels
join public.education_systems on education_systems.id = education_levels.education_system_id
join public.curricula on curricula.id = education_systems.curriculum_id
cross join (values
  ('STD_1', 'Standard 1', 1),
  ('STD_2', 'Standard 2', 2),
  ('STD_3', 'Standard 3', 3),
  ('STD_4', 'Standard 4', 4),
  ('STD_5', 'Standard 5', 5),
  ('STD_6', 'Standard 6', 6),
  ('STD_7', 'Standard 7', 7)
) as grade(code, name, sort_order)
where curricula.code = 'TIE' and education_levels.code = 'PRIMARY'
on conflict (education_level_id, code) do nothing;

insert into public.subjects (curriculum_id, code, name)
select id, 'MATHEMATICS', 'Mathematics' from public.curricula where code in ('TIE', 'CBC', 'UNEB')
on conflict (curriculum_id, code) do nothing;
insert into public.subjects (curriculum_id, code, name)
select id, 'ENGLISH', 'English' from public.curricula where code in ('TIE', 'CBC', 'UNEB')
on conflict (curriculum_id, code) do nothing;
