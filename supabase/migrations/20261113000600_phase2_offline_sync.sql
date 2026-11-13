-- LearnTZ Phase 2 Migration: Offline Learning and Synchronisation
-- Sub-Stage 5 (Stage 2.8 / TASK-209)

begin;

-- ============================================================================
-- 1. Create table public.learner_sync_events
-- ============================================================================

create table if not exists public.learner_sync_events (
  id uuid primary key default gen_random_uuid(),
  client_event_id uuid not null unique,
  learner_id uuid not null references public.learners (id) on delete cascade,
  event_type text not null check (
    event_type in (
      'reading_progress',
      'lesson_completed',
      'assessment_submission',
      'quiz_submission'
    )
  ),
  payload jsonb not null default '{}'::jsonb,
  client_recorded_at timestamptz not null,
  processed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists learner_sync_events_learner_idx
  on public.learner_sync_events (learner_id, processed_at desc);

alter table public.learner_sync_events enable row level security;
revoke all on public.learner_sync_events from public, anon, authenticated;
grant select, insert on public.learner_sync_events to authenticated;

create policy "Parents read own learner sync events"
  on public.learner_sync_events for select to authenticated
  using (
    public.is_authorized_learner_parent(learner_sync_events.learner_id)
    or public.has_role('super_admin')
  );

create policy "Parents insert own learner sync events"
  on public.learner_sync_events for insert to authenticated
  with check (
    public.is_authorized_learner_parent(learner_sync_events.learner_id)
    or public.has_role('super_admin')
  );

-- ============================================================================
-- 2. Idempotent Offline Sync Batch RPC
-- ============================================================================

create or replace function public.sync_learner_offline_activity(
  p_learner_id uuid,
  p_events jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event record;
  v_processed_count integer := 0;
  v_duplicate_count integer := 0;
  v_client_event_id uuid;
  v_event_type text;
  v_payload jsonb;
  v_recorded_at timestamptz;
  v_lesson_id uuid;
  v_reading_pct integer;
  v_topic_id uuid;
  v_answers jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Authorized parent access is required for this learner' using errcode = '42501';
  end if;

  if p_events is null or jsonb_typeof(p_events) <> 'array' then
    raise exception 'Events payload must be a JSON array' using errcode = '22023';
  end if;

  for v_event in select * from jsonb_to_recordset(p_events) as x(
    client_event_id uuid,
    event_type text,
    payload jsonb,
    client_recorded_at timestamptz
  )
  loop
    v_client_event_id := v_event.client_event_id;
    v_event_type := v_event.event_type;
    v_payload := coalesce(v_event.payload, '{}'::jsonb);
    v_recorded_at := coalesce(v_event.client_recorded_at, now());

    if v_client_event_id is null or v_event_type is null then
      continue;
    end if;

    -- Check for duplicate client event (idempotency)
    if exists (
      select 1 from public.learner_sync_events
      where client_event_id = v_client_event_id
    ) then
      v_duplicate_count := v_duplicate_count + 1;
      continue;
    end if;

    -- Record sync event
    insert into public.learner_sync_events (
      client_event_id, learner_id, event_type, payload, client_recorded_at
    ) values (
      v_client_event_id, p_learner_id, v_event_type, v_payload, v_recorded_at
    );

    -- Apply changes based on event type
    if v_event_type = 'reading_progress' then
      v_lesson_id := (v_payload ->> 'lesson_id')::uuid;
      v_reading_pct := coalesce((v_payload ->> 'reading_progress_percent')::integer, 0);

      if v_lesson_id is not null then
        insert into public.learner_progress (
          learner_id, lesson_id, status, reading_progress_percent, last_accessed_at
        ) values (
          p_learner_id,
          v_lesson_id,
          case when v_reading_pct >= 100 then 'completed' else 'in_progress' end,
          least(100, greatest(0, v_reading_pct)),
          v_recorded_at
        )
        on conflict (learner_id, lesson_id) do update set
          reading_progress_percent = greatest(
            public.learner_progress.reading_progress_percent,
            least(100, greatest(0, v_reading_pct))
          ),
          status = case
            when public.learner_progress.status = 'completed' or v_reading_pct >= 100 then 'completed'
            else 'in_progress'
          end,
          completed_at = case
            when public.learner_progress.completed_at is not null then public.learner_progress.completed_at
            when v_reading_pct >= 100 then v_recorded_at
            else null
          end,
          last_accessed_at = greatest(public.learner_progress.last_accessed_at, v_recorded_at);
      end if;

    elsif v_event_type = 'lesson_completed' then
      v_lesson_id := (v_payload ->> 'lesson_id')::uuid;

      if v_lesson_id is not null then
        insert into public.learner_progress (
          learner_id, lesson_id, status, reading_progress_percent, completed_at, last_accessed_at
        ) values (
          p_learner_id, v_lesson_id, 'completed', 100, v_recorded_at, v_recorded_at
        )
        on conflict (learner_id, lesson_id) do update set
          status = 'completed',
          reading_progress_percent = 100,
          completed_at = coalesce(public.learner_progress.completed_at, v_recorded_at),
          last_accessed_at = greatest(public.learner_progress.last_accessed_at, v_recorded_at);
      end if;

    elsif v_event_type = 'assessment_submission' then
      v_topic_id := (v_payload ->> 'topic_id')::uuid;
      v_answers := v_payload -> 'answers';

      if v_topic_id is not null and v_answers is not null then
        perform public.submit_assessment_attempt(
          p_learner_id,
          v_topic_id,
          v_answers
        );
      end if;
    end if;

    v_processed_count := v_processed_count + 1;
  end loop;

  return jsonb_build_object(
    'learner_id', p_learner_id,
    'events_received', jsonb_array_length(p_events),
    'events_processed', v_processed_count,
    'events_duplicate', v_duplicate_count,
    'synced_at', now()
  );
end;
$$;

revoke all on function public.sync_learner_offline_activity(uuid, jsonb) from public, anon;
grant execute on function public.sync_learner_offline_activity(uuid, jsonb) to authenticated;

-- ============================================================================
-- 3. Offline Pack Download RPC (Subject Lessons, Flashcards & Questions)
-- ============================================================================

create or replace function public.get_subject_offline_pack(
  p_learner_id uuid,
  p_subject_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_subject record;
  v_topics jsonb;
  v_flashcard_decks jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Authorized parent access is required for this learner' using errcode = '42501';
  end if;

  select s.id, s.name, s.code, s.country_code, s.curriculum_id, s.description
  into v_subject
  from public.subjects s
  where s.id = p_subject_id
    and s.is_published;

  if not found then
    raise exception 'Subject not found' using errcode = 'P0002';
  end if;

  -- 1. Topics with nested lessons and sanitized assessment questions
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', t.id,
        'title', t.title,
        'summary', t.summary,
        'display_order', t.display_order,
        'lessons', (
          select coalesce(
            jsonb_agg(
              jsonb_build_object(
                'id', l.id,
                'title', l.title,
                'summary', l.summary,
                'body_markdown', l.body_markdown,
                'content_blocks', l.content_blocks,
                'estimated_minutes', l.estimated_minutes,
                'display_order', l.display_order
              ) order by l.display_order, l.created_at
            ),
            '[]'::jsonb
          )
          from public.lessons l
          where l.topic_id = t.id and l.is_published
        ),
        'questions', (
          select coalesce(
            jsonb_agg(
              jsonb_build_object(
                'id', q.id,
                'question_type', q.question_type,
                'difficulty_level', q.difficulty_level,
                'question_text', q.question_text,
                'options', q.options,
                'cognitive_tier', q.cognitive_tier,
                'display_order', q.display_order
              ) order by q.display_order, q.created_at
            ),
            '[]'::jsonb
          )
          from public.question_bank q
          where q.topic_id = t.id and q.is_published
        )
      ) order by t.display_order, t.created_at
    ),
    '[]'::jsonb
  ) into v_topics
  from public.topics t
  where t.subject_id = p_subject_id and t.is_published;

  -- 2. Flashcard decks with cards
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', fd.id,
        'title', fd.title,
        'description', fd.description,
        'card_count', fd.card_count,
        'estimated_minutes', fd.estimated_minutes,
        'cards', (
          select coalesce(
            jsonb_agg(
              jsonb_build_object(
                'id', fc.id,
                'front_prompt', fc.front_prompt,
                'back_solution', fc.back_solution,
                'hint', fc.hint,
                'explanation', fc.explanation,
                'display_order', fc.display_order
              ) order by fc.display_order, fc.created_at
            ),
            '[]'::jsonb
          )
          from public.flashcards fc
          where fc.deck_id = fd.id
        )
      ) order by fd.created_at
    ),
    '[]'::jsonb
  ) into v_flashcard_decks
  from public.flashcard_decks fd
  where fd.subject_id = p_subject_id and fd.is_published;

  return jsonb_build_object(
    'subject_id', v_subject.id,
    'subject_name', v_subject.name,
    'subject_code', v_subject.code,
    'country_code', v_subject.country_code,
    'curriculum_id', v_subject.curriculum_id,
    'description', v_subject.description,
    'topics', v_topics,
    'flashcard_decks', v_flashcard_decks,
    'packed_at', now()
  );
end;
$$;

revoke all on function public.get_subject_offline_pack(uuid, uuid) from public, anon;
grant execute on function public.get_subject_offline_pack(uuid, uuid) to authenticated;

commit;
