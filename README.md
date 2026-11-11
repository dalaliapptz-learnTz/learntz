# LearnTZ

**Learn Anywhere, Anytime**

LearnTZ is a Flutter learning platform for families, starting in Tanzania and designed for data-driven expansion across African countries. The product supplements official national curricula. The Stage 1 foundation includes responsive Android/Web app structure, English/Kiswahili localization, Supabase Auth parent account flows, country configuration, and database-enforced roles and access policies.

Stage 1 does not include learner profiles, curriculum content, lessons, assessments, subscriptions, payments, schools, or teachers. Live authentication and database behavior require a configured Supabase project and have not been verified in this workspace.

## Requirements

- Flutter stable with Dart 3.12 or compatible SDK versions declared in [`pubspec.yaml`](pubspec.yaml)
- Android SDK for Android builds

## Run without Supabase

```sh
flutter pub get
flutter run -d chrome
```

Without backend compile-time values, account and database screens show a clear unconfigured state. English and Kiswahili can be selected from the language menu. For local Supabase setup, database migrations, email callbacks, and security testing, follow [DEVELOPMENT.md](DEVELOPMENT.md) and [ENVIRONMENT.md](ENVIRONMENT.md).

## Project guides

- [Architecture](ARCHITECTURE.md)
- [Development](DEVELOPMENT.md)
- [Environment configuration](ENVIRONMENT.md)
- [Changelog](CHANGELOG.md)

## Quality checks

```sh
dart format .
flutter analyze
flutter test
flutter build apk
flutter build web
```

Database policy tests are in `supabase/tests/stage1_security.test.sql`; run them with `supabase test db` against the local Supabase stack.
