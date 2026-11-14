-- LearnTZ Enterprise SaaS: Phase 5 Sub-Stage 1
-- Multi-Tenant Organizations, Hierarchy Closure Table & Registration Engine
-- Target Jurisdictions: Tanzania, Kenya, Uganda

begin;

-- 1. Custom Enum Types
do $$
begin
  if not exists (select 1 from pg_type where typname = 'organization_type') then
    create type public.organization_type as enum (
      'ministry',
      'examination_authority',
      'regional_office',
      'district_office',
      'school_network',
      'school',
      'research_institution',
      'development_partner'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'organization_status') then
    create type public.organization_status as enum (
      'pending_verification',
      'active',
      'suspended',
      'archived'
    );
  end if;
end $$;

-- 2. Organizations Table
create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries (country_code) on delete restrict,
  name text not null check (char_length(btrim(name)) between 2 and 255),
  slug text not null check (char_length(btrim(slug)) between 2 and 120),
  type public.organization_type not null,
  registration_number text,
  parent_organization_id uuid references public.organizations (id) on delete restrict,
  school_id uuid references public.schools (id) on delete set null,
  website_url text,
  contact_email text check (contact_email is null or contact_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  contact_phone text,
  logo_url text,
  brand_color text not null default '#0F4C81',
  status public.organization_status not null default 'pending_verification',
  settings jsonb not null default '{}'::jsonb,
  created_by_user_id uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_organization_slug unique (slug)
);

create index if not exists idx_organizations_country_type
  on public.organizations (country_code, type);

create index if not exists idx_organizations_parent
  on public.organizations (parent_organization_id);

create index if not exists idx_organizations_status
  on public.organizations (status);

-- Add optional foreign key back from schools to organizations
alter table public.schools
  add column if not exists organization_id uuid references public.organizations (id) on delete set null;

-- 3. Closure Table for Hierarchical Queries
create table if not exists public.organization_hierarchies (
  ancestor_id uuid not null references public.organizations (id) on delete cascade,
  descendant_id uuid not null references public.organizations (id) on delete cascade,
  depth integer not null check (depth >= 0),
  created_at timestamptz not null default now(),
  primary key (ancestor_id, descendant_id)
);

create index if not exists idx_org_hierarchies_descendant
  on public.organization_hierarchies (descendant_id, depth);

-- 4. Trigger to Maintain Hierarchy Closure Table
create or replace function public.maintain_organization_hierarchy()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if TG_OP = 'INSERT' then
    -- Self-referencing link (depth 0)
    insert into public.organization_hierarchies (ancestor_id, descendant_id, depth)
    values (NEW.id, NEW.id, 0);

    -- If parent exists, copy all parent's ancestors with depth + 1
    if NEW.parent_organization_id is not null then
      insert into public.organization_hierarchies (ancestor_id, descendant_id, depth)
      select h.ancestor_id, NEW.id, h.depth + 1
      from public.organization_hierarchies h
      where h.descendant_id = NEW.parent_organization_id;
    end if;

    return NEW;
  elsif TG_OP = 'UPDATE' then
    if OLD.parent_organization_id is distinct from NEW.parent_organization_id then
      -- Prevent circular loop
      if NEW.parent_organization_id is not null and exists (
        select 1 from public.organization_hierarchies
        where ancestor_id = NEW.id and descendant_id = NEW.parent_organization_id
      ) then
        raise exception 'Circular hierarchy detected: cannot set parent to a descendant'
          using errcode = '22023';
      end if;

      -- Remove obsolete paths from ancestors to this subtree
      delete from public.organization_hierarchies
      where descendant_id in (
        select descendant_id from public.organization_hierarchies where ancestor_id = NEW.id
      )
      and ancestor_id in (
        select ancestor_id from public.organization_hierarchies
        where descendant_id = OLD.id and ancestor_id <> OLD.id
      );

      -- If new parent is set, attach entire subtree under new parent's ancestors
      if NEW.parent_organization_id is not null then
        insert into public.organization_hierarchies (ancestor_id, descendant_id, depth)
        select supertree.ancestor_id, subtree.descendant_id, supertree.depth + subtree.depth + 1
        from public.organization_hierarchies supertree
        cross join public.organization_hierarchies subtree
        where supertree.descendant_id = NEW.parent_organization_id
          and subtree.ancestor_id = NEW.id;
      end if;
    end if;

    NEW.updated_at := now();
    return NEW;
  end if;

  return null;
end;
$$;

drop trigger if exists trg_maintain_organization_hierarchy on public.organizations;
create trigger trg_maintain_organization_hierarchy
  after insert or update on public.organizations
  for each row
  execute function public.maintain_organization_hierarchy();

-- 5. Row-Level Security
alter table public.organizations enable row level security;
alter table public.organization_hierarchies enable row level security;

-- Read policies
create policy "Anyone can view active organizations"
  on public.organizations
  for select
  to authenticated, anon
  using (
    status = 'active'
    or public.has_role('super_admin')
    or public.has_role('country_admin', country_code)
    or created_by_user_id = auth.uid()
  );

create policy "Anyone can view organization hierarchies"
  on public.organization_hierarchies
  for select
  to authenticated, anon
  using (true);

-- Insert policy
create policy "Authenticated users can create organizations"
  on public.organizations
  for insert
  to authenticated
  with check (
    auth.uid() is not null
  );

-- Update policy
create policy "Super admins and creators can update organizations"
  on public.organizations
  for update
  to authenticated
  using (
    public.has_role('super_admin')
    or public.has_role('country_admin', country_code)
    or created_by_user_id = auth.uid()
  )
  with check (
    public.has_role('super_admin')
    or public.has_role('country_admin', country_code)
    or created_by_user_id = auth.uid()
  );

-- 6. Security-Definer RPCs

-- 6.1 Register Enterprise Organization
create or replace function public.register_enterprise_organization(
  p_country_code text,
  p_name text,
  p_slug text,
  p_type public.organization_type,
  p_registration_number text default null,
  p_parent_organization_id uuid default null,
  p_website_url text default null,
  p_contact_email text default null,
  p_contact_phone text default null,
  p_brand_color text default '#0F4C81',
  p_settings jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org_id uuid;
  v_initial_status public.organization_status;
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if not exists (select 1 from public.countries where country_code = p_country_code) then
    raise exception 'Country code % is invalid', p_country_code using errcode = '22023';
  end if;

  if exists (select 1 from public.organizations where slug = p_slug) then
    raise exception 'Organization slug % already exists', p_slug using errcode = '23505';
  end if;

  if p_parent_organization_id is not null and not exists (
    select 1 from public.organizations where id = p_parent_organization_id
  ) then
    raise exception 'Parent organization % does not exist', p_parent_organization_id using errcode = '22023';
  end if;

  -- Super admins & country admins get immediate active status; others are pending verification
  if public.has_role('super_admin') or public.has_role('country_admin', p_country_code) then
    v_initial_status := 'active';
  else
    v_initial_status := 'pending_verification';
  end if;

  insert into public.organizations (
    country_code,
    name,
    slug,
    type,
    registration_number,
    parent_organization_id,
    website_url,
    contact_email,
    contact_phone,
    brand_color,
    status,
    settings,
    created_by_user_id
  ) values (
    p_country_code,
    btrim(p_name),
    lower(btrim(p_slug)),
    p_type,
    p_registration_number,
    p_parent_organization_id,
    p_website_url,
    p_contact_email,
    p_contact_phone,
    coalesce(p_brand_color, '#0F4C81'),
    v_initial_status,
    coalesce(p_settings, '{}'::jsonb),
    v_user_id
  ) returning id into v_org_id;

  return v_org_id;
end;
$$;

-- 6.2 Get Organization Details
create or replace function public.get_organization_details(p_org_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_result jsonb;
begin
  select jsonb_build_object(
    'id', o.id,
    'country_code', o.country_code,
    'name', o.name,
    'slug', o.slug,
    'type', o.type,
    'registration_number', o.registration_number,
    'parent_organization_id', o.parent_organization_id,
    'parent_name', p.name,
    'parent_slug', p.slug,
    'website_url', o.website_url,
    'contact_email', o.contact_email,
    'contact_phone', o.contact_phone,
    'logo_url', o.logo_url,
    'brand_color', o.brand_color,
    'status', o.status,
    'settings', o.settings,
    'created_at', o.created_at,
    'direct_children_count', (
      select count(*) from public.organizations child
      where child.parent_organization_id = o.id
    ),
    'total_descendants_count', (
      select count(*) from public.organization_hierarchies h
      where h.ancestor_id = o.id and h.depth > 0
    )
  ) into v_result
  from public.organizations o
  left join public.organizations p on o.parent_organization_id = p.id
  where o.id = p_org_id;

  return v_result;
end;
$$;

-- 6.3 List Subordinate Organizations (Hierarchical Subtree)
create or replace function public.list_subordinate_organizations(
  p_org_id uuid,
  p_type public.organization_type default null
)
returns table (
  id uuid,
  name text,
  slug text,
  type public.organization_type,
  depth integer,
  parent_id uuid,
  status public.organization_status
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    o.id,
    o.name,
    o.slug,
    o.type,
    h.depth,
    o.parent_organization_id as parent_id,
    o.status
  from public.organization_hierarchies h
  join public.organizations o on h.descendant_id = o.id
  where h.ancestor_id = p_org_id
    and (p_type is null or o.type = p_type)
  order by h.depth asc, o.name asc;
$$;

-- 6.4 List Organizations with Filtering
create or replace function public.list_organizations(
  p_country_code text default null,
  p_type public.organization_type default null,
  p_search text default null,
  p_status public.organization_status default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  id uuid,
  country_code text,
  name text,
  slug text,
  type public.organization_type,
  parent_name text,
  status public.organization_status,
  brand_color text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    o.id,
    o.country_code,
    o.name,
    o.slug,
    o.type,
    p.name as parent_name,
    o.status,
    o.brand_color,
    o.created_at
  from public.organizations o
  left join public.organizations p on o.parent_organization_id = p.id
  where (p_country_code is null or o.country_code = p_country_code)
    and (p_type is null or o.type = p_type)
    and (p_status is null or o.status = p_status)
    and (
      p_search is null
      or o.name ilike '%' || p_search || '%'
      or o.slug ilike '%' || p_search || '%'
    )
  order by o.created_at desc
  limit p_limit offset p_offset;
$$;

-- 7. Seed Initial Core Organizations
-- Tanzania
insert into public.organizations (
  id, country_code, name, slug, type, registration_number, brand_color, status
) values (
  'a0000000-0000-0000-0000-000000000001',
  'TZ',
  'Ministry of Education, Science and Technology (MoEST)',
  'tz-moest',
  'ministry',
  'TZ-GOV-MOEST',
  '#0F4C81',
  'active'
), (
  'a0000000-0000-0000-0000-000000000002',
  'TZ',
  'National Examinations Council of Tanzania (NECTA)',
  'tz-necta',
  'examination_authority',
  'TZ-GOV-NECTA',
  '#15803D',
  'active'
) on conflict (slug) do nothing;

-- Regional & District Hierarchy under MoEST
insert into public.organizations (
  id, country_code, name, slug, type, parent_organization_id, brand_color, status
) values (
  'a0000000-0000-0000-0000-000000000003',
  'TZ',
  'Dar es Salaam Regional Education Office',
  'tz-reo-dar',
  'regional_office',
  'a0000000-0000-0000-0000-000000000001',
  '#0F4C81',
  'active'
), (
  'a0000000-0000-0000-0000-000000000004',
  'TZ',
  'Ilala District Education Office',
  'tz-deo-ilala',
  'district_office',
  'a0000000-0000-0000-0000-000000000003',
  '#0F4C81',
  'active'
), (
  'a0000000-0000-0000-0000-000000000005',
  'TZ',
  'Azania Secondary School',
  'tz-school-azania',
  'school',
  'a0000000-0000-0000-0000-000000000004',
  '#0F4C81',
  'active'
) on conflict (slug) do nothing;

-- Kenya
insert into public.organizations (
  id, country_code, name, slug, type, registration_number, brand_color, status
) values (
  'b0000000-0000-0000-0000-000000000001',
  'KE',
  'Ministry of Education Kenya',
  'ke-moe',
  'ministry',
  'KE-GOV-MOE',
  '#991B1B',
  'active'
), (
  'b0000000-0000-0000-0000-000000000002',
  'KE',
  'Kenya National Examinations Council (KNEC)',
  'ke-knec',
  'examination_authority',
  'KE-GOV-KNEC',
  '#15803D',
  'active'
) on conflict (slug) do nothing;

-- Uganda
insert into public.organizations (
  id, country_code, name, slug, type, registration_number, brand_color, status
) values (
  'c0000000-0000-0000-0000-000000000001',
  'UG',
  'Ministry of Education and Sports (MoES)',
  'ug-moes',
  'ministry',
  'UG-GOV-MOES',
  '#D97706',
  'active'
), (
  'c0000000-0000-0000-0000-000000000002',
  'UG',
  'Uganda National Examinations Board (UNEB)',
  'ug-uneb',
  'examination_authority',
  'UG-GOV-UNEB',
  '#15803D',
  'active'
) on conflict (slug) do nothing;

-- Development Partner & Research
insert into public.organizations (
  id, country_code, name, slug, type, registration_number, brand_color, status
) values (
  'd0000000-0000-0000-0000-000000000001',
  'TZ',
  'UNICEF East Africa Education Initiative',
  'unicef-east-africa',
  'development_partner',
  'UN-DEV-UNICEF-EA',
  '#0284C7',
  'active'
), (
  'd0000000-0000-0000-0000-000000000002',
  'TZ',
  'East African Institute of Educational Research',
  'ea-ier-research',
  'research_institution',
  'NGO-EA-IER-2026',
  '#475569',
  'active'
) on conflict (slug) do nothing;

commit;
