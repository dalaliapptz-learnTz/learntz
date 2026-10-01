create table public.learning_progress (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  learner_id text not null,
  lesson_id text not null references public.lessons(id) on delete cascade,
  completion_percent integer not null default 0 check (completion_percent between 0 and 100),
  last_block_index integer not null default 0 check (last_block_index >= 0),
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (owner_user_id, learner_id, lesson_id)
);

create index learning_progress_owner_learner_idx
  on public.learning_progress (owner_user_id, learner_id);

alter table public.learning_progress enable row level security;

create policy "Learners progress is readable by its owner"
  on public.learning_progress for select
  using (owner_user_id = auth.uid());

create policy "Learners progress can be created by its owner"
  on public.learning_progress for insert
  with check (owner_user_id = auth.uid());

create policy "Learners progress can be updated by its owner"
  on public.learning_progress for update
  using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());
