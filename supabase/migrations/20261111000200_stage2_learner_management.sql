begin;

create table public.education_systems (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries (country_code)
    on delete restrict,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  code text not null check (char_length(btrim(code)) between 1 and 40),
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint education_systems_country_code_unique unique (country_code, code),
  constraint education_systems_id_country_unique unique (id, country_code)
);

create table public.curricula (
  id uuid primary key default gen_random_uuid(),
  country_code text not null,
  education_system_id uuid not null,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  code text not null check (char_length(btrim(code)) between 1 and 40),
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint curricula_system_country_fk
    foreign key (education_system_id, country_code)
    references public.education_systems (id, country_code) on delete restrict,
  constraint curricula_system_code_unique
    unique (education_system_id, code),
  constraint curricula_id_scope_unique
    unique (id, country_code, education_system_id),
  constraint curricula_id_system_unique
    unique (id, education_system_id)
);

create table public.education_levels (
  id uuid primary key default gen_random_uuid(),
  curriculum_id uuid not null references public.curricula (id)
    on delete restrict,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  code text not null check (char_length(btrim(code)) between 1 and 40),
  sequence integer not null check (sequence > 0),
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint education_levels_curriculum_code_unique
    unique (curriculum_id, code),
  constraint education_levels_curriculum_sequence_unique
    unique (curriculum_id, sequence),
  constraint education_levels_scope_unique unique (id, curriculum_id)
);

create table public.education_grades (
  id uuid primary key default gen_random_uuid(),
  education_level_id uuid not null,
  curriculum_id uuid not null,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  code text not null check (char_length(btrim(code)) between 1 and 40),
  sequence integer not null check (sequence > 0),
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint education_grades_level_curriculum_fk
    foreign key (education_level_id, curriculum_id)
    references public.education_levels (id, curriculum_id) on delete restrict,
  constraint education_grades_level_code_unique
    unique (education_level_id, code),
  constraint education_grades_level_sequence_unique
    unique (education_level_id, sequence),
  constraint education_grades_scope_unique
    unique (id, education_level_id, curriculum_id),
  constraint education_grades_id_curriculum_unique
    unique (id, curriculum_id)
);

create table public.schools (
  id uuid primary key default gen_random_uuid(),
  country_code text not null,
  education_system_id uuid not null,
  name text not null check (char_length(btrim(name)) between 1 and 200),
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint schools_system_country_fk
    foreign key (education_system_id, country_code)
    references public.education_systems (id, country_code) on delete restrict,
  constraint schools_id_scope_unique unique (id, country_code, education_system_id)
);

create index curricula_country_system_idx
  on public.curricula (country_code, education_system_id);
create index education_levels_curriculum_sequence_idx
  on public.education_levels (curriculum_id, sequence);
create index education_grades_level_sequence_idx
  on public.education_grades (education_level_id, sequence);
create index schools_country_system_name_idx
  on public.schools (country_code, education_system_id, name);

create table public.learners (
  id uuid primary key default gen_random_uuid(),
  first_name text not null
    check (char_length(btrim(first_name)) between 1 and 80),
  middle_name text
    check (middle_name is null or char_length(btrim(middle_name)) <= 80),
  last_name text not null
    check (char_length(btrim(last_name)) between 1 and 80),
  date_of_birth date not null check (date_of_birth <= current_date),
  gender text check (
    gender is null or gender in ('female', 'male', 'other', 'prefer_not_to_say')
  ),
  country_code text not null,
  education_system_id uuid not null,
  curriculum_id uuid not null,
  education_level_id uuid not null,
  grade_id uuid not null,
  school_id uuid,
  status text not null default 'active'
    check (status in ('active', 'inactive', 'deletion_requested')),
  created_by_parent_user_id uuid not null
    references public.parent_accounts (user_id) on delete restrict,
  registration_request_id uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint learners_system_country_fk
    foreign key (education_system_id, country_code)
    references public.education_systems (id, country_code) on delete restrict,
  constraint learners_curriculum_scope_fk
    foreign key (curriculum_id, country_code, education_system_id)
    references public.curricula (id, country_code, education_system_id)
    on delete restrict,
  constraint learners_level_curriculum_fk
    foreign key (education_level_id, curriculum_id)
    references public.education_levels (id, curriculum_id) on delete restrict,
  constraint learners_grade_scope_fk
    foreign key (grade_id, education_level_id, curriculum_id)
    references public.education_grades (id, education_level_id, curriculum_id)
    on delete restrict,
  constraint learners_school_scope_fk
    foreign key (school_id, country_code, education_system_id)
    references public.schools (id, country_code, education_system_id)
    on delete restrict,
  constraint learners_parent_request_unique
    unique (created_by_parent_user_id, registration_request_id)
);

create table public.parent_learners (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references public.learners (id) on delete restrict,
  parent_user_id uuid not null references public.parent_accounts (user_id)
    on delete cascade,
  relationship_role text not null
    check (relationship_role in ('parent', 'guardian')),
  relationship_status text not null default 'active'
    check (relationship_status in ('pending', 'active', 'revoked')),
  created_by_parent_user_id uuid not null
    references public.parent_accounts (user_id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint parent_learners_unique unique (learner_id, parent_user_id)
);

create index learners_country_status_idx
  on public.learners (country_code, status);
create index learners_creator_created_idx
  on public.learners (created_by_parent_user_id, created_at desc);
create index learners_grade_idx on public.learners (grade_id);
create index parent_learners_parent_status_idx
  on public.parent_learners (parent_user_id, relationship_status);
create index parent_learners_learner_status_idx
  on public.parent_learners (learner_id, relationship_status);

create table public.learner_status_history (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references public.learners (id) on delete restrict,
  status text not null
    check (status in ('active', 'inactive', 'deletion_requested')),
  actor_parent_user_id uuid references public.parent_accounts (user_id)
    on delete set null,
  reason text check (reason is null or char_length(reason) <= 500),
  created_at timestamptz not null default now()
);

create table public.learner_change_history (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references public.learners (id) on delete restrict,
  actor_parent_user_id uuid references public.parent_accounts (user_id)
    on delete set null,
  changed_fields jsonb not null check (jsonb_typeof(changed_fields) = 'object'),
  created_at timestamptz not null default now()
);

create index learner_status_history_learner_created_idx
  on public.learner_status_history (learner_id, created_at desc);
create index learner_change_history_learner_created_idx
  on public.learner_change_history (learner_id, created_at desc);

create table public.academic_calendars (
  id uuid primary key default gen_random_uuid(),
  country_code text not null,
  education_system_id uuid not null,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  starts_on date not null,
  ends_on date not null,
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint academic_calendars_dates_check check (ends_on >= starts_on),
  constraint academic_calendars_system_country_fk
    foreign key (education_system_id, country_code)
    references public.education_systems (id, country_code) on delete restrict,
  constraint academic_calendars_id_scope_unique
    unique (id, country_code, education_system_id)
);

create table public.promotion_policies (
  id uuid primary key default gen_random_uuid(),
  country_code text not null,
  education_system_id uuid not null,
  promotion_month integer not null check (promotion_month between 1 and 12),
  promotion_day integer not null check (promotion_day between 1 and 31),
  enabled boolean not null default false,
  approved_by uuid references auth.users (id) on delete set null,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint promotion_policies_approval_check
    check (not enabled or (approved_by is not null and approved_at is not null)),
  constraint promotion_policies_system_country_fk
    foreign key (education_system_id, country_code)
    references public.education_systems (id, country_code) on delete restrict,
  constraint promotion_policies_system_unique unique (education_system_id)
);

create table public.grade_progressions (
  id uuid primary key default gen_random_uuid(),
  education_system_id uuid not null,
  curriculum_id uuid not null,
  from_grade_id uuid not null,
  to_grade_id uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint grade_progressions_curriculum_fk
    foreign key (curriculum_id, education_system_id)
    references public.curricula (id, education_system_id) on delete restrict,
  constraint grade_progressions_from_grade_fk
    foreign key (from_grade_id, curriculum_id)
    references public.education_grades (id, curriculum_id) on delete restrict,
  constraint grade_progressions_to_grade_fk
    foreign key (to_grade_id, curriculum_id)
    references public.education_grades (id, curriculum_id) on delete restrict,
  constraint grade_progressions_unique
    unique (education_system_id, curriculum_id, from_grade_id, to_grade_id),
  constraint grade_progressions_not_self_check
    check (from_grade_id <> to_grade_id)
);

create table public.learner_promotions (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references public.learners (id) on delete restrict,
  from_country_code text not null,
  from_education_system_id uuid not null,
  from_curriculum_id uuid not null,
  from_education_level_id uuid not null,
  from_grade_id uuid not null,
  to_country_code text not null,
  to_education_system_id uuid not null,
  to_curriculum_id uuid not null,
  to_education_level_id uuid not null,
  to_grade_id uuid not null,
  promotion_type text not null
    check (promotion_type in ('promoted', 'repeated', 'system_changed')),
  academic_calendar_id uuid,
  effective_on date not null,
  actor_parent_user_id uuid references public.parent_accounts (user_id)
    on delete set null,
  note text check (note is null or char_length(note) <= 500),
  created_at timestamptz not null default now(),
  constraint learner_promotions_from_grade_fk
    foreign key (from_grade_id, from_education_level_id, from_curriculum_id)
    references public.education_grades (id, education_level_id, curriculum_id)
    on delete restrict,
  constraint learner_promotions_to_grade_fk
    foreign key (to_grade_id, to_education_level_id, to_curriculum_id)
    references public.education_grades (id, education_level_id, curriculum_id)
    on delete restrict,
  constraint learner_promotions_calendar_fk
    foreign key (academic_calendar_id, to_country_code, to_education_system_id)
    references public.academic_calendars (id, country_code, education_system_id)
    on delete restrict,
  constraint learner_promotions_from_system_country_fk
    foreign key (from_education_system_id, from_country_code)
    references public.education_systems (id, country_code) on delete restrict,
  constraint learner_promotions_to_system_country_fk
    foreign key (to_education_system_id, to_country_code)
    references public.education_systems (id, country_code) on delete restrict,
  constraint learner_promotions_from_curriculum_system_fk
    foreign key (from_curriculum_id, from_education_system_id)
    references public.curricula (id, education_system_id) on delete restrict,
  constraint learner_promotions_to_curriculum_system_fk
    foreign key (to_curriculum_id, to_education_system_id)
    references public.curricula (id, education_system_id) on delete restrict
);

create index academic_calendars_scope_dates_idx
  on public.academic_calendars (country_code, education_system_id, starts_on);
create index grade_progressions_from_grade_idx
  on public.grade_progressions (education_system_id, curriculum_id, from_grade_id);
create index learner_promotions_learner_created_idx
  on public.learner_promotions (learner_id, created_at desc);

create trigger education_systems_set_updated_at
  before update on public.education_systems
  for each row execute function public.set_updated_at();
create trigger curricula_set_updated_at
  before update on public.curricula
  for each row execute function public.set_updated_at();
create trigger education_levels_set_updated_at
  before update on public.education_levels
  for each row execute function public.set_updated_at();
create trigger education_grades_set_updated_at
  before update on public.education_grades
  for each row execute function public.set_updated_at();
create trigger schools_set_updated_at
  before update on public.schools
  for each row execute function public.set_updated_at();
create trigger learners_set_updated_at
  before update on public.learners
  for each row execute function public.set_updated_at();
create trigger parent_learners_set_updated_at
  before update on public.parent_learners
  for each row execute function public.set_updated_at();
create trigger academic_calendars_set_updated_at
  before update on public.academic_calendars
  for each row execute function public.set_updated_at();
create trigger promotion_policies_set_updated_at
  before update on public.promotion_policies
  for each row execute function public.set_updated_at();

create function public.set_promotion_policy_approval()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.enabled and auth.uid() is not null then
    new.approved_by := auth.uid();
    new.approved_at := now();
  end if;
  return new;
end;
$$;

create trigger promotion_policies_set_approval
  before insert or update on public.promotion_policies
  for each row execute function public.set_promotion_policy_approval();
create trigger grade_progressions_set_updated_at
  before update on public.grade_progressions
  for each row execute function public.set_updated_at();

alter table public.education_systems enable row level security;
alter table public.curricula enable row level security;
alter table public.education_levels enable row level security;
alter table public.education_grades enable row level security;
alter table public.schools enable row level security;
alter table public.learners enable row level security;
alter table public.parent_learners enable row level security;
alter table public.learner_status_history enable row level security;
alter table public.learner_change_history enable row level security;
alter table public.academic_calendars enable row level security;
alter table public.promotion_policies enable row level security;
alter table public.grade_progressions enable row level security;
alter table public.learner_promotions enable row level security;

revoke all on public.education_systems, public.curricula,
  public.education_levels, public.education_grades, public.schools,
  public.learners, public.parent_learners, public.learner_status_history,
  public.learner_change_history, public.academic_calendars,
  public.promotion_policies, public.grade_progressions,
  public.learner_promotions from public, anon, authenticated;

grant select on public.education_systems, public.curricula,
  public.education_levels, public.education_grades, public.schools,
  public.academic_calendars, public.grade_progressions to authenticated;
grant select on public.promotion_policies to authenticated;
grant select on public.learners, public.parent_learners,
  public.learner_status_history, public.learner_change_history,
  public.learner_promotions to authenticated;
grant insert, update, delete on public.education_systems, public.curricula,
  public.education_levels, public.education_grades, public.schools,
  public.academic_calendars, public.promotion_policies,
  public.grade_progressions to authenticated;

create policy "Authenticated users can read enabled education systems"
  on public.education_systems for select to authenticated
  using (is_enabled and exists (
    select 1 from public.countries country
    where country.country_code = education_systems.country_code
      and country.is_enabled
  ) or exists (
    select 1 from public.learners learner
    join public.parent_learners relationship
      on relationship.learner_id = learner.id
    where learner.education_system_id = education_systems.id
      and relationship.parent_user_id = (select auth.uid())
      and relationship.relationship_status = 'active'
  ));
create policy "Authenticated users can read enabled curricula"
  on public.curricula for select to authenticated
  using (is_enabled and exists (
    select 1 from public.education_systems system
    join public.countries country using (country_code)
    where system.id = curricula.education_system_id
      and system.is_enabled and country.is_enabled
  ) or exists (
    select 1 from public.learners learner
    join public.parent_learners relationship
      on relationship.learner_id = learner.id
    where learner.curriculum_id = curricula.id
      and relationship.parent_user_id = (select auth.uid())
      and relationship.relationship_status = 'active'
  ));
create policy "Authenticated users can read enabled education levels"
  on public.education_levels for select to authenticated
  using (is_enabled and exists (
    select 1 from public.curricula curriculum
    where curriculum.id = education_levels.curriculum_id
      and curriculum.is_enabled
  ) or exists (
    select 1 from public.learners learner
    join public.parent_learners relationship
      on relationship.learner_id = learner.id
    where learner.education_level_id = education_levels.id
      and relationship.parent_user_id = (select auth.uid())
      and relationship.relationship_status = 'active'
  ));
create policy "Authenticated users can read enabled education grades"
  on public.education_grades for select to authenticated
  using (is_enabled and exists (
    select 1 from public.education_levels level
    join public.curricula curriculum on curriculum.id = level.curriculum_id
    where level.id = education_grades.education_level_id
      and level.is_enabled and curriculum.is_enabled
  ) or exists (
    select 1 from public.learners learner
    join public.parent_learners relationship
      on relationship.learner_id = learner.id
    where learner.grade_id = education_grades.id
      and relationship.parent_user_id = (select auth.uid())
      and relationship.relationship_status = 'active'
  ));
create policy "Authenticated users can read enabled schools"
  on public.schools for select to authenticated
  using (is_enabled and exists (
    select 1 from public.education_systems system
    join public.countries country using (country_code)
    where system.id = schools.education_system_id
      and system.is_enabled and country.is_enabled
  ) or exists (
    select 1 from public.learners learner
    join public.parent_learners relationship
      on relationship.learner_id = learner.id
    where learner.school_id = schools.id
      and relationship.parent_user_id = (select auth.uid())
      and relationship.relationship_status = 'active'
  ));
create policy "Authenticated users can read enabled academic calendars"
  on public.academic_calendars for select to authenticated
  using (is_enabled);
create policy "Authenticated users can read grade progressions"
  on public.grade_progressions for select to authenticated
  using (exists (
    select 1 from public.education_systems system
    where system.id = grade_progressions.education_system_id
      and system.is_enabled
  ));

create function public.can_admin_education_country(p_country_code text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.has_role('super_admin')
    or public.has_role('country_admin', p_country_code);
$$;

revoke all on function public.can_admin_education_country(text)
  from public, anon;
grant execute on function public.can_admin_education_country(text)
  to authenticated;

create policy "Authorized administrators manage education systems"
  on public.education_systems for all to authenticated
  using (public.can_admin_education_country(country_code))
  with check (public.can_admin_education_country(country_code));
create policy "Authorized administrators manage curricula"
  on public.curricula for all to authenticated
  using (public.can_admin_education_country(country_code))
  with check (public.can_admin_education_country(country_code));
create policy "Authorized administrators manage education levels"
  on public.education_levels for all to authenticated
  using (exists (
    select 1 from public.curricula curriculum
    where curriculum.id = education_levels.curriculum_id
      and public.can_admin_education_country(curriculum.country_code)
  ))
  with check (exists (
    select 1 from public.curricula curriculum
    where curriculum.id = education_levels.curriculum_id
      and public.can_admin_education_country(curriculum.country_code)
  ));
create policy "Authorized administrators manage education grades"
  on public.education_grades for all to authenticated
  using (exists (
    select 1
    from public.education_levels level
    join public.curricula curriculum on curriculum.id = level.curriculum_id
    where level.id = education_grades.education_level_id
      and public.can_admin_education_country(curriculum.country_code)
  ))
  with check (exists (
    select 1
    from public.education_levels level
    join public.curricula curriculum on curriculum.id = level.curriculum_id
    where level.id = education_grades.education_level_id
      and public.can_admin_education_country(curriculum.country_code)
  ));
create policy "Authorized administrators manage schools"
  on public.schools for all to authenticated
  using (public.can_admin_education_country(country_code))
  with check (public.can_admin_education_country(country_code));
create policy "Authorized administrators manage academic calendars"
  on public.academic_calendars for all to authenticated
  using (public.can_admin_education_country(country_code))
  with check (public.can_admin_education_country(country_code));
create policy "Authorized administrators manage promotion policies"
  on public.promotion_policies for all to authenticated
  using (public.can_admin_education_country(country_code))
  with check (public.can_admin_education_country(country_code));
create policy "Authorized administrators manage grade progressions"
  on public.grade_progressions for all to authenticated
  using (exists (
    select 1 from public.education_systems system
    where system.id = grade_progressions.education_system_id
      and public.can_admin_education_country(system.country_code)
  ))
  with check (exists (
    select 1 from public.education_systems system
    where system.id = grade_progressions.education_system_id
      and public.can_admin_education_country(system.country_code)
  ));

create function public.is_authorized_learner_parent(p_learner_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.parent_learners relationship
    join public.parent_accounts account
      on account.user_id = relationship.parent_user_id
    join public.account_status account_state
      on account_state.user_id = relationship.parent_user_id
    join public.user_roles role_assignment
      on role_assignment.user_id = relationship.parent_user_id
    where relationship.learner_id = p_learner_id
      and relationship.parent_user_id = (select auth.uid())
      and relationship.relationship_status = 'active'
      and account_state.status = 'active'
      and role_assignment.role = 'parent'
  );
$$;

revoke all on function public.is_authorized_learner_parent(uuid)
  from public, anon;
grant execute on function public.is_authorized_learner_parent(uuid)
  to authenticated;

create policy "Parents can read their authorized learners"
  on public.learners for select to authenticated
  using ((select public.is_authorized_learner_parent(id)));
create policy "Parents can read their own learner relationships"
  on public.parent_learners for select to authenticated
  using (
    parent_user_id = (select auth.uid())
    or created_by_parent_user_id = (select auth.uid())
  );
create policy "Parents can read authorized learner status history"
  on public.learner_status_history for select to authenticated
  using ((select public.is_authorized_learner_parent(learner_id)));
create policy "Parents can read authorized learner change history"
  on public.learner_change_history for select to authenticated
  using ((select public.is_authorized_learner_parent(learner_id)));
create policy "Parents can read authorized learner promotion history"
  on public.learner_promotions for select to authenticated
  using ((select public.is_authorized_learner_parent(learner_id)));

create function public.audit_learner_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  changed jsonb := '{}'::jsonb;
begin
  if tg_op = 'INSERT' then
    changed := jsonb_build_object('created', true);
  else
    if new.first_name is distinct from old.first_name then
      changed := changed || jsonb_build_object(
        'first_name', jsonb_build_object('from', old.first_name, 'to', new.first_name));
    end if;
    if new.middle_name is distinct from old.middle_name then
      changed := changed || jsonb_build_object(
        'middle_name', jsonb_build_object('from', old.middle_name, 'to', new.middle_name));
    end if;
    if new.last_name is distinct from old.last_name then
      changed := changed || jsonb_build_object(
        'last_name', jsonb_build_object('from', old.last_name, 'to', new.last_name));
    end if;
    if new.date_of_birth is distinct from old.date_of_birth then
      changed := changed || jsonb_build_object(
        'date_of_birth', jsonb_build_object('from', old.date_of_birth, 'to', new.date_of_birth));
    end if;
    if new.gender is distinct from old.gender then
      changed := changed || jsonb_build_object(
        'gender', jsonb_build_object('from', old.gender, 'to', new.gender));
    end if;
    if new.country_code is distinct from old.country_code
       or new.education_system_id is distinct from old.education_system_id
       or new.curriculum_id is distinct from old.curriculum_id
       or new.education_level_id is distinct from old.education_level_id
       or new.grade_id is distinct from old.grade_id
       or new.school_id is distinct from old.school_id then
      changed := changed || jsonb_build_object(
        'education', jsonb_build_object(
          'from', jsonb_build_object(
            'country_code', old.country_code,
            'education_system_id', old.education_system_id,
            'curriculum_id', old.curriculum_id,
            'education_level_id', old.education_level_id,
            'grade_id', old.grade_id,
            'school_id', old.school_id),
          'to', jsonb_build_object(
            'country_code', new.country_code,
            'education_system_id', new.education_system_id,
            'curriculum_id', new.curriculum_id,
            'education_level_id', new.education_level_id,
            'grade_id', new.grade_id,
            'school_id', new.school_id)));
    end if;
  end if;

  insert into public.learner_change_history (
    learner_id, actor_parent_user_id, changed_fields
  )
  values (new.id, auth.uid(), changed);
  return new;
end;
$$;

revoke all on function public.audit_learner_change()
  from public, anon, authenticated;
create trigger learners_audit_change
  after insert or update on public.learners
  for each row execute function public.audit_learner_change();

create function public.audit_learner_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  status_reason text;
begin
  if tg_op = 'INSERT' or new.status is distinct from old.status then
    status_reason := case new.status
      when 'inactive' then 'Deactivated by parent'
      when 'deletion_requested' then 'Deletion requested by parent'
      else null
    end;
    insert into public.learner_status_history (
      learner_id, status, actor_parent_user_id, reason
    )
    values (new.id, new.status, auth.uid(), status_reason);
  end if;
  return new;
end;
$$;

revoke all on function public.audit_learner_status()
  from public, anon, authenticated;
create trigger learners_audit_status
  after insert or update of status on public.learners
  for each row execute function public.audit_learner_status();

create function public.validate_learner_education(
  p_country_code text,
  p_education_system_id uuid,
  p_curriculum_id uuid,
  p_education_level_id uuid,
  p_grade_id uuid,
  p_school_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.countries country
    join public.education_systems system
      on system.country_code = country.country_code
    join public.curricula curriculum
      on curriculum.country_code = country.country_code
      and curriculum.education_system_id = system.id
    join public.education_levels level
      on level.curriculum_id = curriculum.id
    join public.education_grades grade
      on grade.education_level_id = level.id
      and grade.curriculum_id = curriculum.id
    where country.country_code = upper(btrim(p_country_code))
      and country.is_enabled
      and system.id = p_education_system_id and system.is_enabled
      and curriculum.id = p_curriculum_id and curriculum.is_enabled
      and level.id = p_education_level_id and level.is_enabled
      and grade.id = p_grade_id and grade.is_enabled
  ) then
    raise exception 'The selected education configuration is invalid'
      using errcode = '22023';
  end if;

  if p_school_id is not null and not exists (
    select 1 from public.schools school
    where school.id = p_school_id
      and school.country_code = upper(btrim(p_country_code))
      and school.education_system_id = p_education_system_id
      and school.is_enabled
  ) then
    raise exception 'The selected school does not match the education system'
      using errcode = '22023';
  end if;
end;
$$;

revoke all on function public.validate_learner_education(
  text, uuid, uuid, uuid, uuid, uuid
) from public, anon, authenticated;

create function public.create_learner(
  p_registration_request_id uuid,
  p_first_name text,
  p_middle_name text,
  p_last_name text,
  p_date_of_birth date,
  p_gender text,
  p_country_code text,
  p_education_system_id uuid,
  p_curriculum_id uuid,
  p_education_level_id uuid,
  p_grade_id uuid,
  p_school_id uuid default null
)
returns public.learners
language plpgsql
security definer
set search_path = ''
as $$
declare
  requesting_parent uuid := auth.uid();
  learner_record public.learners;
begin
  if requesting_parent is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.parent_accounts account
    join public.account_status account_state on account_state.user_id = account.user_id
    join public.user_roles role_assignment on role_assignment.user_id = account.user_id
    where account.user_id = requesting_parent
      and account_state.status = 'active'
      and role_assignment.role = 'parent'
  ) then
    raise exception 'An active parent account is required' using errcode = '42501';
  end if;
  if p_registration_request_id is null then
    raise exception 'A registration request identifier is required'
      using errcode = '22023';
  end if;
  if p_date_of_birth is null or p_date_of_birth > current_date then
    raise exception 'A valid date of birth is required' using errcode = '22023';
  end if;
  if p_gender is not null and p_gender not in (
    'female', 'male', 'other', 'prefer_not_to_say'
  ) then
    raise exception 'The selected gender value is invalid'
      using errcode = '22023';
  end if;

  perform public.validate_learner_education(
    p_country_code, p_education_system_id, p_curriculum_id,
    p_education_level_id, p_grade_id, p_school_id
  );

  insert into public.learners (
    first_name, middle_name, last_name, date_of_birth, gender,
    country_code, education_system_id, curriculum_id,
    education_level_id, grade_id, school_id,
    created_by_parent_user_id, registration_request_id
  )
  values (
    btrim(p_first_name), nullif(btrim(coalesce(p_middle_name, '')), ''),
    btrim(p_last_name), p_date_of_birth, p_gender,
    upper(btrim(p_country_code)), p_education_system_id, p_curriculum_id,
    p_education_level_id, p_grade_id, p_school_id,
    requesting_parent, p_registration_request_id
  )
  on conflict (created_by_parent_user_id, registration_request_id) do nothing
  returning * into learner_record;

  if not found then
    select * into learner_record
    from public.learners learner
    where learner.created_by_parent_user_id = requesting_parent
      and learner.registration_request_id = p_registration_request_id;
    if not found then
      raise exception 'The learner registration could not be completed'
        using errcode = '55000';
    end if;
    return learner_record;
  end if;

  insert into public.parent_learners (
    learner_id, parent_user_id, relationship_role,
    relationship_status, created_by_parent_user_id
  )
  values (
    learner_record.id, requesting_parent, 'parent', 'active', requesting_parent
  );
  return learner_record;
end;
$$;

revoke all on function public.create_learner(
  uuid, text, text, text, date, text, text, uuid, uuid, uuid, uuid, uuid
) from public, anon;
grant execute on function public.create_learner(
  uuid, text, text, text, date, text, text, uuid, uuid, uuid, uuid, uuid
) to authenticated;

create function public.update_learner(
  p_learner_id uuid,
  p_first_name text,
  p_middle_name text,
  p_last_name text,
  p_date_of_birth date,
  p_gender text,
  p_country_code text,
  p_education_system_id uuid,
  p_curriculum_id uuid,
  p_education_level_id uuid,
  p_grade_id uuid,
  p_school_id uuid default null
)
returns public.learners
language plpgsql
security definer
set search_path = ''
as $$
declare
  learner_record public.learners;
begin
  if auth.uid() is null
     or not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'You are not authorized to manage this learner'
      using errcode = '42501';
  end if;
  if p_date_of_birth is null or p_date_of_birth > current_date then
    raise exception 'A valid date of birth is required' using errcode = '22023';
  end if;
  if p_gender is not null and p_gender not in (
    'female', 'male', 'other', 'prefer_not_to_say'
  ) then
    raise exception 'The selected gender value is invalid'
      using errcode = '22023';
  end if;
  perform public.validate_learner_education(
    p_country_code, p_education_system_id, p_curriculum_id,
    p_education_level_id, p_grade_id, p_school_id
  );

  update public.learners
  set first_name = btrim(p_first_name),
      middle_name = nullif(btrim(coalesce(p_middle_name, '')), ''),
      last_name = btrim(p_last_name),
      date_of_birth = p_date_of_birth,
      gender = p_gender,
      country_code = upper(btrim(p_country_code)),
      education_system_id = p_education_system_id,
      curriculum_id = p_curriculum_id,
      education_level_id = p_education_level_id,
      grade_id = p_grade_id,
      school_id = p_school_id
  where id = p_learner_id and status = 'active'
  returning * into learner_record;

  if not found then
    raise exception 'The learner is not active'
      using errcode = '55000';
  end if;
  return learner_record;
end;
$$;

revoke all on function public.update_learner(
  uuid, text, text, text, date, text, text, uuid, uuid, uuid, uuid, uuid
) from public, anon;
grant execute on function public.update_learner(
  uuid, text, text, text, date, text, text, uuid, uuid, uuid, uuid, uuid
) to authenticated;

create function public.deactivate_learner(p_learner_id uuid)
returns public.learners
language plpgsql
security definer
set search_path = ''
as $$
declare
  learner_record public.learners;
begin
  if auth.uid() is null
     or not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'You are not authorized to manage this learner'
      using errcode = '42501';
  end if;
  update public.learners
  set status = 'inactive'
  where id = p_learner_id and status = 'active'
  returning * into learner_record;
  if not found then
    raise exception 'The learner is not active'
      using errcode = '55000';
  end if;
  return learner_record;
end;
$$;

revoke all on function public.deactivate_learner(uuid) from public, anon;
grant execute on function public.deactivate_learner(uuid) to authenticated;

create function public.request_learner_deletion(p_learner_id uuid)
returns public.learners
language plpgsql
security definer
set search_path = ''
as $$
declare
  learner_record public.learners;
begin
  if auth.uid() is null
     or not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'You are not authorized to manage this learner'
      using errcode = '42501';
  end if;
  update public.learners
  set status = 'deletion_requested'
  where id = p_learner_id and status = 'active'
  returning * into learner_record;
  if not found then
    raise exception 'The learner is not active'
      using errcode = '55000';
  end if;
  return learner_record;
end;
$$;

revoke all on function public.request_learner_deletion(uuid)
  from public, anon;
grant execute on function public.request_learner_deletion(uuid)
  to authenticated;

create function public.record_learner_promotion(
  p_learner_id uuid,
  p_to_country_code text,
  p_to_education_system_id uuid,
  p_to_curriculum_id uuid,
  p_to_education_level_id uuid,
  p_to_grade_id uuid,
  p_to_school_id uuid,
  p_promotion_type text,
  p_effective_on date,
  p_academic_calendar_id uuid default null,
  p_note text default null
)
returns public.learner_promotions
language plpgsql
security definer
set search_path = ''
as $$
declare
  learner_record public.learners;
  promotion_record public.learner_promotions;
begin
  if auth.uid() is null
     or not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'You are not authorized to manage this learner'
      using errcode = '42501';
  end if;
  if p_promotion_type not in ('promoted', 'repeated', 'system_changed') then
    raise exception 'The promotion type is invalid' using errcode = '22023';
  end if;
  if p_effective_on is null or p_effective_on > current_date then
    raise exception 'The effective date must not be in the future'
      using errcode = '22023';
  end if;
  if char_length(coalesce(p_note, '')) > 500 then
    raise exception 'The promotion note is too long' using errcode = '22023';
  end if;

  select * into learner_record
  from public.learners learner
  where learner.id = p_learner_id and learner.status = 'active'
  for update;
  if not found then
    raise exception 'The learner is not active' using errcode = '55000';
  end if;

  perform public.validate_learner_education(
    p_to_country_code, p_to_education_system_id, p_to_curriculum_id,
    p_to_education_level_id, p_to_grade_id, p_to_school_id
  );

  if p_promotion_type = 'promoted' and not exists (
    select 1 from public.grade_progressions progression
    where progression.education_system_id = learner_record.education_system_id
      and progression.curriculum_id = learner_record.curriculum_id
      and progression.from_grade_id = learner_record.grade_id
      and progression.to_grade_id = p_to_grade_id
      and learner_record.country_code = upper(btrim(p_to_country_code))
      and p_to_education_system_id = learner_record.education_system_id
      and p_to_curriculum_id = learner_record.curriculum_id
  ) then
    raise exception 'The selected grade is not a configured progression'
      using errcode = '22023';
  end if;
  if p_promotion_type = 'repeated'
     and (p_to_grade_id <> learner_record.grade_id
       or p_to_education_system_id <> learner_record.education_system_id
       or p_to_curriculum_id <> learner_record.curriculum_id) then
    raise exception 'A repeated grade must match the current grade'
      using errcode = '22023';
  end if;
  if p_promotion_type = 'system_changed'
     and p_to_education_system_id = learner_record.education_system_id then
    raise exception 'A system change must use a different education system'
      using errcode = '22023';
  end if;

  if p_academic_calendar_id is not null and not exists (
    select 1 from public.academic_calendars calendar
    where calendar.id = p_academic_calendar_id
      and calendar.country_code = upper(btrim(p_to_country_code))
      and calendar.education_system_id = p_to_education_system_id
      and calendar.is_enabled
      and p_effective_on between calendar.starts_on and calendar.ends_on
  ) then
    raise exception 'The selected academic calendar is invalid'
      using errcode = '22023';
  end if;

  update public.learners
  set country_code = upper(btrim(p_to_country_code)),
      education_system_id = p_to_education_system_id,
      curriculum_id = p_to_curriculum_id,
      education_level_id = p_to_education_level_id,
      grade_id = p_to_grade_id,
      school_id = p_to_school_id
  where id = p_learner_id;

  insert into public.learner_promotions (
    learner_id,
    from_country_code, from_education_system_id, from_curriculum_id,
    from_education_level_id, from_grade_id,
    to_country_code, to_education_system_id, to_curriculum_id,
    to_education_level_id, to_grade_id,
    promotion_type, academic_calendar_id, effective_on,
    actor_parent_user_id, note
  )
  values (
    learner_record.id,
    learner_record.country_code, learner_record.education_system_id,
    learner_record.curriculum_id, learner_record.education_level_id,
    learner_record.grade_id,
    upper(btrim(p_to_country_code)), p_to_education_system_id,
    p_to_curriculum_id, p_to_education_level_id, p_to_grade_id,
    p_promotion_type, p_academic_calendar_id, p_effective_on,
    auth.uid(), nullif(btrim(coalesce(p_note, '')), '')
  )
  returning * into promotion_record;
  return promotion_record;
end;
$$;

revoke all on function public.record_learner_promotion(
  uuid, text, uuid, uuid, uuid, uuid, uuid, text, date, uuid, text
) from public, anon;
grant execute on function public.record_learner_promotion(
  uuid, text, uuid, uuid, uuid, uuid, uuid, text, date, uuid, text
) to authenticated;

create function public.invite_learner_guardian(
  p_learner_id uuid,
  p_guardian_user_id uuid
)
returns public.parent_learners
language plpgsql
security definer
set search_path = ''
as $$
declare
  relationship public.parent_learners;
begin
  if auth.uid() is null
     or not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'You are not authorized to manage this learner'
      using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.learners learner
    where learner.id = p_learner_id and learner.status = 'active'
  ) then
    raise exception 'The learner is not active'
      using errcode = '55000';
  end if;
  if p_guardian_user_id is null or p_guardian_user_id = auth.uid()
     or not exists (
       select 1 from public.parent_accounts account
       join public.account_status account_state
         on account_state.user_id = account.user_id
       join public.user_roles role_assignment
         on role_assignment.user_id = account.user_id
       where account.user_id = p_guardian_user_id
         and account_state.status = 'active'
         and role_assignment.role = 'parent'
     ) then
    raise exception 'An active parent account is required for the guardian'
      using errcode = '22023';
  end if;

  insert into public.parent_learners (
    learner_id, parent_user_id, relationship_role,
    relationship_status, created_by_parent_user_id
  )
  values (p_learner_id, p_guardian_user_id, 'guardian', 'pending', auth.uid())
  on conflict (learner_id, parent_user_id) do update
    set relationship_status = 'pending',
        created_by_parent_user_id = excluded.created_by_parent_user_id
    where public.parent_learners.relationship_status = 'revoked'
  returning * into relationship;
  if not found then
    raise exception 'A relationship already exists for this parent'
      using errcode = '23505';
  end if;
  return relationship;
end;
$$;

revoke all on function public.invite_learner_guardian(uuid, uuid)
  from public, anon;
grant execute on function public.invite_learner_guardian(uuid, uuid)
  to authenticated;

create function public.accept_learner_guardian_invitation(
  p_relationship_id uuid
)
returns public.parent_learners
language plpgsql
security definer
set search_path = ''
as $$
declare
  relationship public.parent_learners;
begin
  if auth.uid() is null or not exists (
    select 1 from public.parent_accounts account
    join public.account_status account_state
      on account_state.user_id = account.user_id
    join public.user_roles role_assignment
      on role_assignment.user_id = account.user_id
    where account.user_id = auth.uid()
      and account_state.status = 'active'
      and role_assignment.role = 'parent'
  ) then
    raise exception 'An active parent account is required'
      using errcode = '42501';
  end if;

  update public.parent_learners
  set relationship_status = 'active'
  where id = p_relationship_id
    and parent_user_id = auth.uid()
    and relationship_role = 'guardian'
    and relationship_status = 'pending'
  returning * into relationship;
  if not found then
    raise exception 'The guardian invitation is unavailable'
      using errcode = '42501';
  end if;
  return relationship;
end;
$$;

revoke all on function public.accept_learner_guardian_invitation(uuid)
  from public, anon;
grant execute on function public.accept_learner_guardian_invitation(uuid)
  to authenticated;

create function public.revoke_learner_guardian(
  p_learner_id uuid,
  p_guardian_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or not exists (
    select 1 from public.parent_learners relationship
    where relationship.learner_id = p_learner_id
      and relationship.parent_user_id = p_guardian_user_id
      and relationship.relationship_role = 'guardian'
      and relationship.relationship_status <> 'revoked'
      and (relationship.parent_user_id = auth.uid()
        or relationship.created_by_parent_user_id = auth.uid())
  ) then
    raise exception 'You are not authorized to revoke this guardian'
      using errcode = '42501';
  end if;
  update public.parent_learners
  set relationship_status = 'revoked'
  where learner_id = p_learner_id
    and parent_user_id = p_guardian_user_id
    and relationship_role = 'guardian'
    and relationship_status <> 'revoked';
end;
$$;

revoke all on function public.revoke_learner_guardian(uuid, uuid)
  from public, anon;
grant execute on function public.revoke_learner_guardian(uuid, uuid)
  to authenticated;

insert into public.education_systems (
  id, country_code, name, code
)
values (
  '20000000-0000-0000-0000-000000000001',
  'TZ',
  'Tanzania national education system',
  'TZ_NATIONAL'
);

insert into public.curricula (
  id, country_code, education_system_id, name, code
)
values (
  '20000000-0000-0000-0000-000000000002',
  'TZ',
  '20000000-0000-0000-0000-000000000001',
  'Tanzania Institute of Education',
  'TIE'
);

insert into public.education_levels (
  id, curriculum_id, name, code, sequence
)
values
  ('20000000-0000-0000-0000-000000000010',
   '20000000-0000-0000-0000-000000000002',
   'Primary education', 'PRIMARY', 1),
  ('20000000-0000-0000-0000-000000000011',
   '20000000-0000-0000-0000-000000000002',
   'Ordinary-level secondary education', 'SECONDARY_ORDINARY', 2),
  ('20000000-0000-0000-0000-000000000012',
   '20000000-0000-0000-0000-000000000002',
   'Advanced-level secondary education', 'SECONDARY_ADVANCED', 3);

insert into public.education_grades (
  education_level_id, curriculum_id, name, code, sequence
)
select
  '20000000-0000-0000-0000-000000000010',
  '20000000-0000-0000-0000-000000000002',
  'Standard ' || grade_number,
  'STANDARD_' || grade_number,
  grade_number
from generate_series(1, 7) as grade_number;

insert into public.education_grades (
  education_level_id, curriculum_id, name, code, sequence
)
select
  case when form_number <= 4
    then '20000000-0000-0000-0000-000000000011'::uuid
    else '20000000-0000-0000-0000-000000000012'::uuid
  end,
  '20000000-0000-0000-0000-000000000002',
  'Form ' || form_number,
  'FORM_' || form_number,
  case when form_number <= 4 then form_number else form_number - 4 end
from generate_series(1, 6) as form_number;

insert into public.grade_progressions (
  education_system_id, curriculum_id, from_grade_id, to_grade_id
)
select
  '20000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000002',
  previous_grade.id,
  next_grade.id
from public.education_grades previous_grade
join public.education_grades next_grade
  on next_grade.education_level_id = previous_grade.education_level_id
  and next_grade.sequence = previous_grade.sequence + 1
where previous_grade.curriculum_id =
  '20000000-0000-0000-0000-000000000002';

commit;
