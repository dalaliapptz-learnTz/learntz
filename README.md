# LearnTZ

LearnTZ is a Flutter learning platform foundation for Tanzania and future country products, with the tagline **Learn Anywhere, Anytime.**

## Run locally

```sh
flutter pub get
flutter run
```

Supabase Auth is used when `SUPABASE_URL` and `SUPABASE_ANON_KEY` are provided through Dart defines. Without those values, the app runs in local demo mode for development.

```sh
flutter run \
  --dart-define=PRODUCT_NAME=LearnTZ \
  --dart-define=COUNTRY_CODE=TZ \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-publishable-key
```

## Stage 1

Stage 1 includes:

- Parent registration and sign-in boundaries.
- Supabase Auth integration when configured.
- Local demo authentication when Supabase is not configured.
- Parent dashboard.
- Multiple pupil profiles per parent.
- Pupil name and grade/form registration.
- Route guards for parent and authentication routes.

Learner and parent records are currently held behind repository/controller interfaces. Durable learner profile persistence, relationship authorization, and profile synchronization are reserved for later stages.

## Stage 2

Stage 2 adds the configuration-driven country and curriculum foundation:

- LearnTZ, LearnKE, LearnUG, LearnRW, LearnBI, and LearnSS product configurations.
- Country, curriculum, education system, education level, grade/form, subject, and language models.
- Cascading curriculum selection during pupil setup.
- Local catalog fallback and Supabase catalog repository boundaries.
- Supabase migration with normalized catalog tables and read-only RLS policies for active configuration.

Apply the migration through the Supabase CLI or dashboard when a Supabase project is available:

```sh
supabase db push
```

Stage 2 does not implement learning content, assessments, subscriptions, payments, or recommendations.

## Stage 3

Stage 3 adds the educational content foundation:

- Content provenance metadata for licensed, Learn-original, teacher-created, third-party, and supplementary resources.
- Resource, chapter, topic, lesson, and lesson-block models.
- Local content repository with original sample lessons.
- Supabase content repository boundary.
- Browse and read lesson screens.
- Published-content RLS migration.

The included sample content is original Learn content. Official curriculum material is not reproduced without licensing. Exercises and assessments are reserved for Stage 5.

## Stage 4

Stage 4 adds the learner learning experience and progress foundation:

- Learner selection before starting a scoped learning session.
- Learner-specific lesson completion and progress percentages.
- Last-read block tracking for future resume and offline synchronization.
- Parent dashboard links into each learner's learning area.
- Local progress repository and Supabase repository boundary.
- RLS migration scoped to the authenticated owner.

Progress is currently stored in memory in local demo mode. Durable learner ownership and parent-learner relationship authorization will be strengthened with the account data model in a later stage.
