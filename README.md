# LearnTZ

**Learn Anywhere, Anytime**

LearnTZ is a Flutter learning platform for families, starting in Tanzania and designed for data-driven expansion across African countries. The product supplements official national curricula. Stages 0-2 provide a responsive Android/Web app, English/Kiswahili localization, Supabase Auth parent accounts, and database-enforced learner management and access policies. Stage 3.2 adds a protected TIE primary curriculum source/review workflow, but curriculum text remains blocked until source rights are documented.

Stage 2 provides parent-managed learner profiles and switching, profile editing/deactivation/deletion requests, guardian relationship primitives, education configuration, and manual promotion history. Only Tanzania's TIE education structure is seeded. There is no automatic promotion policy. Lessons, assessments, progress tracking, subscriptions/payments, school management, and teacher accounts remain out of scope. Live authentication and database behavior require a configured Supabase project.

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
- [Stage 2 completion report](STAGE2_COMPLETION.md)
- [TIE source inventory](TIE_SOURCE_INVENTORY.md)
- [Stage 3.2 completion report](STAGE3_2_COMPLETION.md)

## Quality checks

```sh
dart format .
flutter analyze
flutter test
flutter build apk
flutter build web
```

Database policy tests are in `supabase/tests/`; run `supabase db reset`, `supabase migration up`, and `supabase test db` against a clean local Supabase stack.
