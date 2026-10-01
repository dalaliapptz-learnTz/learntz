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

Learner and parent records are currently held behind repository/controller interfaces. Durable database schema, RLS policies, curriculum configuration, and profile synchronization are reserved for later stages.
