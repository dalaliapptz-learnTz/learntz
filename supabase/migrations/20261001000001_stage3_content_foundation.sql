create table public.resources (
  id text primary key,
  country_code text not null references public.countries(code),
  curriculum_code text not null,
  grade_code text not null,
  subject_code text not null,
  subject_name text not null,
  language_code text not null references public.languages(code),
  title text not null,
  description text not null,
  source text not null check (source in ('officialLicensed', 'learnOriginal', 'teacherCreated', 'thirdPartyLicensed', 'supplementary')),
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.chapters (
  id text primary key,
  resource_id text not null references public.resources(id) on delete cascade,
  title text not null,
  sort_order integer not null default 0,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.topics (
  id text primary key,
  chapter_id text not null references public.chapters(id) on delete cascade,
  title text not null,
  sort_order integer not null default 0,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.lessons (
  id text primary key,
  topic_id text not null references public.topics(id) on delete cascade,
  title text not null,
  summary text not null,
  duration_minutes integer not null check (duration_minutes > 0),
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.lesson_blocks (
  id text primary key,
  lesson_id text not null references public.lessons(id) on delete cascade,
  type text not null check (type in ('explanation', 'example', 'reflection')),
  heading text not null,
  body text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.resources enable row level security;
alter table public.chapters enable row level security;
alter table public.topics enable row level security;
alter table public.lessons enable row level security;
alter table public.lesson_blocks enable row level security;

create policy "Published resources are readable"
  on public.resources for select
  using (is_published);

create policy "Published chapters are readable"
  on public.chapters for select
  using (
    is_published and exists (
      select 1 from public.resources
      where resources.id = chapters.resource_id and resources.is_published
    )
  );

create policy "Published topics are readable"
  on public.topics for select
  using (
    is_published and exists (
      select 1 from public.chapters
      where chapters.id = topics.chapter_id and chapters.is_published
    )
  );

create policy "Published lessons are readable"
  on public.lessons for select
  using (
    is_published and exists (
      select 1 from public.topics
      where topics.id = lessons.topic_id and topics.is_published
    )
  );

create policy "Published lesson blocks are readable"
  on public.lesson_blocks for select
  using (exists (
    select 1 from public.lessons
    where lessons.id = lesson_blocks.lesson_id and lessons.is_published
  ));

insert into public.resources (
  id, country_code, curriculum_code, grade_code, subject_code, subject_name,
  language_code, title, description, source, is_published
) values
  (
    'tz-mathematics-fractions', 'TZ', 'TIE', 'STD_5', 'MATHEMATICS', 'Mathematics',
    'en', 'Fractions', 'Build a clear understanding of parts, wholes, and equivalent fractions.',
    'learnOriginal', true
  ),
  (
    'tz-study-skills-reading', 'TZ', 'TIE', 'STD_5', 'ENGLISH', 'English',
    'en', 'Reading with purpose', 'Use questions and key words to make sense of a short text.',
    'supplementary', true
  )
on conflict (id) do nothing;

insert into public.chapters (id, resource_id, title, sort_order, is_published)
values
  ('tz-fractions-chapter', 'tz-mathematics-fractions', 'Fractions', 1, true),
  ('tz-reading-chapter', 'tz-study-skills-reading', 'Reading skills', 1, true)
on conflict (id) do nothing;

insert into public.topics (id, chapter_id, title, sort_order, is_published)
values
  ('tz-fractions-topic', 'tz-fractions-chapter', 'Parts and equivalent fractions', 1, true),
  ('tz-reading-topic', 'tz-reading-chapter', 'Key ideas', 1, true)
on conflict (id) do nothing;

insert into public.lessons (id, topic_id, title, summary, duration_minutes, is_published)
values
  ('tz-fractions-parts-wholes', 'tz-fractions-topic', 'Parts and wholes', 'Recognise a fraction as equal parts of one whole.', 8, true),
  ('tz-fractions-equivalent', 'tz-fractions-topic', 'Equivalent fractions', 'See why different fraction names can describe the same amount.', 10, true),
  ('tz-reading-key-ideas', 'tz-reading-topic', 'Finding key ideas', 'Identify the main idea and supporting details in a paragraph.', 7, true)
on conflict (id) do nothing;

insert into public.lesson_blocks (id, lesson_id, type, heading, body, sort_order)
values
  ('tz-fractions-parts-explanation', 'tz-fractions-parts-wholes', 'explanation', 'A fraction describes a part', 'When a whole is split into equal parts, a fraction tells us how many of those parts we have.', 1),
  ('tz-fractions-parts-example', 'tz-fractions-parts-wholes', 'example', 'Example: 3/4', 'Imagine a chapati divided into four equal pieces. If three pieces are on your plate, you have three-fourths, written as 3/4.', 2),
  ('tz-fractions-parts-reflection', 'tz-fractions-parts-wholes', 'reflection', 'Think about it', 'What fraction of a group of five equal objects would represent two objects?', 3),
  ('tz-fractions-equivalent-explanation', 'tz-fractions-equivalent', 'explanation', 'Same amount, different names', 'Equivalent fractions have different numbers but represent the same amount.', 1),
  ('tz-fractions-equivalent-example', 'tz-fractions-equivalent', 'example', 'Example: 1/2 and 2/4', 'If one half is split into two equal pieces, the whole is now divided into four parts and two parts are shaded.', 2),
  ('tz-reading-key-ideas-explanation', 'tz-reading-key-ideas', 'explanation', 'Read for the main idea', 'The main idea is what a paragraph is mostly about. Supporting details give examples, reasons, or facts that help explain it.', 1)
on conflict (id) do nothing;
