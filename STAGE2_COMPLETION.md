# LearnTZ Stage 2 Completion Report

## COMPLETED

- Added parent-managed learner registration, dashboard cards, profile retrieval/editing, deactivation, deletion requests, profile selection, and manual promotion UI.
- Added learner-scoped Riverpod state and protected `go_router` paths under `/account`.
- Added database-side ownership checks, request idempotency, education consistency validation, guardian invitation/acceptance primitives, audit history, and soft status changes.
- Added Tanzania TIE education configuration. Other country rows remain without learner-ready education structures.
- Added English and Kiswahili learner UI copy, Flutter model tests, protected-route coverage, and 35 pgTAP assertions.
- Verified both database migrations and all 58 database tests against a clean local Supabase stack.
- Updated architecture, development, README, and changelog documentation.

## IN PROGRESS

- Guardian invitation creation and acceptance exist as database RPCs. The Flutter app does not yet include account lookup or invite delivery; an approved email/notification channel is needed before that flow can be used by parents.

## BLOCKED

- Guardian invitation delivery/account lookup is not implemented in the Flutter UI.

## DATABASE CHANGES

Added `20261111000200_stage2_learner_management.sql` after the Stage 1 migration. It creates education systems, curricula, levels, grades, optional schools, learners, parent-learner relationships, immutable status/change history, academic calendars, promotion policy, grade progressions, and promotion history.

The Stage 1 migration also grants the anonymous role execution of the safe `has_role` helper used by the enabled-country RLS policy. Its security test now expects both the parent-registration and trusted role-assignment audit events.

Learner writes are limited to authenticated database functions. RLS scopes learner and history reads to active parent/guardian relationships. Education configuration writes require super-administrator or country-administrator authorization. Tanzania is the only learner-ready country; automatic promotion is not configured or running.

## FLUTTER FILES CREATED/MODIFIED

- Added [learner_models.dart](/Users/mac/learntz/lib/features/learners/learner_models.dart), [learner_repository.dart](/Users/mac/learntz/lib/features/learners/learner_repository.dart), [learner_providers.dart](/Users/mac/learntz/lib/features/learners/learner_providers.dart), and [learner_screens.dart](/Users/mac/learntz/lib/features/learners/learner_screens.dart).
- Updated [app_router.dart](/Users/mac/learntz/lib/core/routing/app_router.dart), [account_screens.dart](/Users/mac/learntz/lib/features/account/account_screens.dart), and both localization ARB files.
- Added [learner_models_test.dart](/Users/mac/learntz/test/features/learners/learner_models_test.dart) and protected learner-route coverage in [widget_test.dart](/Users/mac/learntz/test/widget_test.dart).

## SECURITY TEST RESULTS

- Flutter client does not accept or send a parent/owner ID for learner writes; the database derives the parent from `auth.uid()`.
- Learner, guardian, and audit authorization policies/functions and cross-parent pgTAP cases were added.
- A fresh local Supabase stack was started with optional Logflare/vector excluded because Logflare failed health checks (`No Free Plan created yet`).
- `supabase db reset`: passed; recreated the local database and applied both versioned migrations.
- `supabase migration up`: passed; no pending migrations remained after the reset.
- `supabase test db`: passed; both SQL test files passed, **58 tests total** (23 Stage 1, 35 Stage 2).
- No hosted project was linked or modified.
- No service-role key or credential was added to the Flutter client.

## FLUTTER TEST RESULTS

- `flutter analyze`: passed, no issues.
- `flutter test`: passed, 14 tests.

## ANDROID BUILD RESULTS

- `flutter build apk`: passed; release APK compilation completed at `build/app/outputs/flutter-apk/app-release.apk`.

## WEB BUILD RESULTS

- `flutter build web`: passed; output generated in `build/web`.

## REMAINING ISSUES

- Add a secure guardian invitation lookup/delivery flow before exposing guardian invitations in the UI.
- Review country-specific education data with authorized curriculum administrators before enabling additional markets or an automatic promotion policy.

## NEXT REQUIRED ACTION

Before using Stage 2 against a hosted project, deploy the reviewed migrations to that environment and configure verified country education data. Do not enable automatic promotion until a country administrator explicitly configures and approves its policy.
