-- ============================================================================
-- Migration: 20261113000100_phase1_academic_calendar_and_terms.sql
-- Description: Academic terms table, 2026 school calendar seeds for TZ, KE, UG,
--              and active calendar/term resolution RPCs with Row-Level Security.
-- ============================================================================

-- 1. Create academic_terms table
create table if not exists public.academic_terms (
  id uuid primary key default gen_random_uuid(),
  academic_calendar_id uuid not null,
  country_code text not null,
  education_system_id uuid not null,
  term_number integer not null check (term_number between 1 and 4),
  name text not null check (char_length(btrim(name)) between 1 and 120),
  starts_on date not null,
  ends_on date not null,
  is_break boolean not null default false,
  is_current boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint academic_terms_dates_check check (ends_on >= starts_on),
  constraint academic_terms_calendar_fk
    foreign key (academic_calendar_id, country_code, education_system_id)
    references public.academic_calendars (id, country_code, education_system_id)
    on delete cascade,
  constraint academic_terms_unique_term
    unique (academic_calendar_id, term_number)
);

create index if not exists academic_terms_calendar_idx
  on public.academic_terms (academic_calendar_id, term_number);

create index if not exists academic_terms_country_system_idx
  on public.academic_terms (country_code, education_system_id);

-- 2. Trigger for updated_at
drop trigger if exists set_academic_terms_updated_at on public.academic_terms;
create trigger set_academic_terms_updated_at
  before update on public.academic_terms
  for each row execute function public.set_updated_at();

-- 3. Row Level Security
alter table public.academic_terms enable row level security;

drop policy if exists "Public and authenticated can read enabled academic terms" on public.academic_terms;
create policy "Public and authenticated can read enabled academic terms"
  on public.academic_terms for select
  using (exists (
    select 1 from public.academic_calendars cal
    where cal.id = academic_terms.academic_calendar_id
      and cal.is_enabled
  ));

drop policy if exists "Authorized administrators manage academic terms" on public.academic_terms;
create policy "Authorized administrators manage academic terms"
  on public.academic_terms for all to authenticated
  using (public.can_admin_education_country(country_code))
  with check (public.can_admin_education_country(country_code));

-- 4. RPCs: get_active_academic_calendar & list_academic_terms
create or replace function public.get_active_academic_calendar(
  p_country_code text,
  p_education_system_id uuid,
  p_reference_date date default current_date
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_country text := upper(btrim(coalesce(p_country_code, '')));
  v_calendar record;
  v_terms jsonb;
begin
  select id, country_code, education_system_id, name, starts_on, ends_on, is_enabled
  into v_calendar
  from public.academic_calendars
  where country_code = v_country
    and education_system_id = p_education_system_id
    and is_enabled
    and p_reference_date between starts_on and ends_on
  order by starts_on desc
  limit 1;

  if v_calendar.id is null then
    -- fallback to latest enabled calendar for the system
    select id, country_code, education_system_id, name, starts_on, ends_on, is_enabled
    into v_calendar
    from public.academic_calendars
    where country_code = v_country
      and education_system_id = p_education_system_id
      and is_enabled
    order by starts_on desc
    limit 1;
  end if;

  if v_calendar.id is null then
    return null;
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', t.id,
        'term_number', t.term_number,
        'name', t.name,
        'starts_on', t.starts_on,
        'ends_on', t.ends_on,
        'is_break', t.is_break,
        'is_current', (p_reference_date between t.starts_on and t.ends_on)
      ) order by t.term_number
    ),
    '[]'::jsonb
  )
  into v_terms
  from public.academic_terms t
  where t.academic_calendar_id = v_calendar.id;

  return jsonb_build_object(
    'id', v_calendar.id,
    'country_code', v_calendar.country_code,
    'education_system_id', v_calendar.education_system_id,
    'name', v_calendar.name,
    'starts_on', v_calendar.starts_on,
    'ends_on', v_calendar.ends_on,
    'is_enabled', v_calendar.is_enabled,
    'terms', v_terms
  );
end;
$$;

create or replace function public.list_academic_terms(
  p_academic_calendar_id uuid
)
returns table (
  id uuid,
  academic_calendar_id uuid,
  country_code text,
  education_system_id uuid,
  term_number integer,
  name text,
  starts_on date,
  ends_on date,
  is_break boolean,
  is_current boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    t.id,
    t.academic_calendar_id,
    t.country_code,
    t.education_system_id,
    t.term_number,
    t.name,
    t.starts_on,
    t.ends_on,
    t.is_break,
    (current_date between t.starts_on and t.ends_on) as is_current
  from public.academic_terms t
  join public.academic_calendars cal on cal.id = t.academic_calendar_id
  where t.academic_calendar_id = p_academic_calendar_id
    and cal.is_enabled
  order by t.term_number;
$$;

grant execute on function public.get_active_academic_calendar(text, uuid, date) to anon, authenticated;
grant execute on function public.list_academic_terms(uuid) to anon, authenticated;

-- 5. Seed 2026 Academic Calendars and Terms
-- ----------------------------------------------------------------------------
-- A. TANZANIA (TZ) - TIE National Education System (2 Terms)
-- ----------------------------------------------------------------------------
insert into public.academic_calendars (
  id, country_code, education_system_id, name, starts_on, ends_on, is_enabled
)
values (
  '20000000-0000-0000-0000-000000000101',
  'TZ',
  '20000000-0000-0000-0000-000000000001',
  'Mwaka wa Masomo 2026',
  '2026-01-05',
  '2026-12-04',
  true
)
on conflict (id) do update set
  name = excluded.name,
  starts_on = excluded.starts_on,
  ends_on = excluded.ends_on,
  is_enabled = excluded.is_enabled;

insert into public.academic_terms (
  id, academic_calendar_id, country_code, education_system_id, term_number, name, starts_on, ends_on, is_break, is_current
)
values
(
  '20000000-0000-0000-0000-000000000111',
  '20000000-0000-0000-0000-000000000101',
  'TZ',
  '20000000-0000-0000-0000-000000000001',
  1,
  'Muhula wa Kwanza (Term 1)',
  '2026-01-05',
  '2026-06-19',
  false,
  false
),
(
  '20000000-0000-0000-0000-000000000112',
  '20000000-0000-0000-0000-000000000101',
  'TZ',
  '20000000-0000-0000-0000-000000000001',
  2,
  'Muhula wa Pili (Term 2)',
  '2026-07-06',
  '2026-12-04',
  false,
  false
)
on conflict (academic_calendar_id, term_number) do update set
  name = excluded.name,
  starts_on = excluded.starts_on,
  ends_on = excluded.ends_on,
  is_break = excluded.is_break;

-- ----------------------------------------------------------------------------
-- B. KENYA (KE) - KICD CBC Education System (3 Terms)
-- ----------------------------------------------------------------------------
insert into public.academic_calendars (
  id, country_code, education_system_id, name, starts_on, ends_on, is_enabled
)
values (
  '20000000-0000-0000-0000-000000000121',
  'KE',
  '20000000-0000-0000-0000-000000000021',
  'Academic Year 2026 (CBC)',
  '2026-01-05',
  '2026-11-06',
  true
)
on conflict (id) do update set
  name = excluded.name,
  starts_on = excluded.starts_on,
  ends_on = excluded.ends_on,
  is_enabled = excluded.is_enabled;

insert into public.academic_terms (
  id, academic_calendar_id, country_code, education_system_id, term_number, name, starts_on, ends_on, is_break, is_current
)
values
(
  '20000000-0000-0000-0000-000000000131',
  '20000000-0000-0000-0000-000000000121',
  'KE',
  '20000000-0000-0000-0000-000000000021',
  1,
  'Term 1',
  '2026-01-05',
  '2026-04-03',
  false,
  false
),
(
  '20000000-0000-0000-0000-000000000132',
  '20000000-0000-0000-0000-000000000121',
  'KE',
  '20000000-0000-0000-0000-000000000021',
  2,
  'Term 2',
  '2026-05-04',
  '2026-08-07',
  false,
  false
),
(
  '20000000-0000-0000-0000-000000000133',
  '20000000-0000-0000-0000-000000000121',
  'KE',
  '20000000-0000-0000-0000-000000000021',
  3,
  'Term 3',
  '2026-08-31',
  '2026-11-06',
  false,
  false
)
on conflict (academic_calendar_id, term_number) do update set
  name = excluded.name,
  starts_on = excluded.starts_on,
  ends_on = excluded.ends_on,
  is_break = excluded.is_break;

-- ----------------------------------------------------------------------------
-- C. UGANDA (UG) - NCDC Education System (3 Terms)
-- ----------------------------------------------------------------------------
insert into public.academic_calendars (
  id, country_code, education_system_id, name, starts_on, ends_on, is_enabled
)
values (
  '20000000-0000-0000-0000-000000000151',
  'UG',
  '20000000-0000-0000-0000-000000000051',
  'Academic Year 2026',
  '2026-02-02',
  '2026-12-04',
  true
)
on conflict (id) do update set
  name = excluded.name,
  starts_on = excluded.starts_on,
  ends_on = excluded.ends_on,
  is_enabled = excluded.is_enabled;

insert into public.academic_terms (
  id, academic_calendar_id, country_code, education_system_id, term_number, name, starts_on, ends_on, is_break, is_current
)
values
(
  '20000000-0000-0000-0000-000000000161',
  '20000000-0000-0000-0000-000000000151',
  'UG',
  '20000000-0000-0000-0000-000000000051',
  1,
  'Term 1',
  '2026-02-02',
  '2026-05-01',
  false,
  false
),
(
  '20000000-0000-0000-0000-000000000162',
  '20000000-0000-0000-0000-000000000151',
  'UG',
  '20000000-0000-0000-0000-000000000051',
  2,
  'Term 2',
  '2026-05-25',
  '2026-08-21',
  false,
  false
),
(
  '20000000-0000-0000-0000-000000000163',
  '20000000-0000-0000-0000-000000000151',
  'UG',
  '20000000-0000-0000-0000-000000000051',
  3,
  'Term 3',
  '2026-09-14',
  '2026-12-04',
  false,
  false
)
on conflict (academic_calendar_id, term_number) do update set
  name = excluded.name,
  starts_on = excluded.starts_on,
  ends_on = excluded.ends_on,
  is_break = excluded.is_break;
