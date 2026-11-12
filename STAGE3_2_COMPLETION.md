# LearnTZ Stage 3.2 Completion Report

## COMPLETED

- Added the draft-only Tanzania TIE primary-curriculum source and review workflow, with database-enforced identity, usage-rights, review, approval, and publication gates.
- Added private checksum-keyed PDF import, page extraction, normalized item review, duplicate detection, and explicit curriculum version lifecycle operations.
- Added the protected `/admin/curriculum` Flutter workflow, English and Kiswahili copy, route protection, and model/route tests.
- Added pgTAP coverage for rights gates, RLS, import idempotency, extraction, deduplication, separate review and approval, and publication.
- Updated architecture, development, README, and changelog documentation.

## IN PROGRESS

- Curriculum ingestion remains pending the rights evidence described below. The protected review workflow and lifecycle gates are implemented; no source content has been ingested.

## BLOCKED

- TIE curriculum extraction, upload, and publication remain blocked until the source edition and applicable reproduction/usage permission are documented and independently reviewed. No source PDF was uploaded and no TIE curriculum text was extracted or published.

## DATABASE CHANGES

- Added `20261111000400_stage3_2_curriculum_pilot.sql`, extending Stage 3.1 without duplicating Stage 2 education tables. It adds source/rights review history, a draft-only TIE primary pilot, private storage controls, import jobs, extracted pages, normalized items, review history, duplicate detection, and gated lifecycle functions.
- Added `supabase/tests/stage3_2_curriculum_pilot.test.sql` with 47 Stage 3.2 assertions.
- A fresh reset of the unlinked local Supabase stack applied migrations 001–004. `supabase migration up --local` reported no pending migrations; `supabase test db` passed all **143 assertions** across Stages 1–3.2.
- No hosted Supabase project was linked or modified. The Flutter app contains no service-role credential.

## FLUTTER FILES CREATED/MODIFIED

- Added [curriculum_models.dart](/Users/mac/learntz/lib/features/curriculum/curriculum_models.dart), [curriculum_repository.dart](/Users/mac/learntz/lib/features/curriculum/curriculum_repository.dart), [curriculum_providers.dart](/Users/mac/learntz/lib/features/curriculum/curriculum_providers.dart), [curriculum_pdf_extractor.dart](/Users/mac/learntz/lib/features/curriculum/curriculum_pdf_extractor.dart), and [curriculum_screens.dart](/Users/mac/learntz/lib/features/curriculum/curriculum_screens.dart).
- Updated [app_router.dart](/Users/mac/learntz/lib/core/routing/app_router.dart), [account_screens.dart](/Users/mac/learntz/lib/features/account/account_screens.dart), [app_en.arb](/Users/mac/learntz/lib/l10n/app_en.arb), [app_sw.arb](/Users/mac/learntz/lib/l10n/app_sw.arb), [pubspec.yaml](/Users/mac/learntz/pubspec.yaml), and [pubspec.lock](/Users/mac/learntz/pubspec.lock).
- Added [curriculum_models_test.dart](/Users/mac/learntz/test/features/curriculum/curriculum_models_test.dart) and updated [widget_test.dart](/Users/mac/learntz/test/widget_test.dart).

## SECURITY TEST RESULTS

- Source identity and rights status are recorded separately; rights changes and review history are server-side, with reviewer separation.
- Database functions recheck rights at import, upload, extraction, and publication. Storage is private; parent RLS excludes draft jobs, extracted pages, draft items, and internal review history.
- Item review and version approval are separate operations, and a reviewer cannot approve a version they reviewed.
- Local migration reset, `supabase migration up --local`, and `supabase test db` passed; all **143 pgTAP assertions** passed.
- No hosted database changes were made. Do not apply these migrations to a hosted project without separate approval and deployment review.

## FLUTTER TEST RESULTS

- `flutter analyze`: passed with no issues.
- `flutter test`: passed, **16 tests**.

## ANDROID BUILD RESULTS

- `flutter build apk --debug`: passed.

## WEB BUILD RESULTS

- `flutter build web`: passed.
- `flutter run -d chrome --web-port 5173` is active in Chrome and connected to Flutter's debug service. The widget inspector reports the `WelcomeScreen` in the app tree and no Flutter runtime errors.
- Also served the release build temporarily at port 5174 and confirmed the welcome screen rendered in the integrated Chrome browser. The separate integrated-browser preview of the debug session remained blank; the temporary release server was stopped after the smoke check.

## REMAINING ISSUES

- Obtain and independently review documentation establishing the TIE source edition, effective applicability, and permission to reproduce/use the material before any upload, extraction, or publication.
- Provision authorized curriculum roles through a trusted operator process before using the protected administration workflow.

## NEXT REQUIRED ACTION

Document and independently review TIE usage rights and source-version details. Until then, keep the source unverified and rights pending; do not upload, extract, or publish curriculum content. Stage 3.2 does not authorize Stage 3.3 or any hosted deployment.
