# Development

## Local setup

1. Install a stable Flutter SDK and the Android SDK if building Android.
2. From the project root, run `flutter pub get`.
3. Run `flutter run -d chrome` for the Web app, or `flutter run` with an Android device/emulator selected.
4. Choose English or Kiswahili using the language control in the app bar.

No Supabase project is required for UI-only development. Without backend compile-time values, the application starts without initializing Supabase and account operations remain unavailable.

## Local Supabase backend

1. Install the Supabase CLI and Docker using their official installation instructions.
2. Start the configured local stack: `supabase start`.
3. Apply the version-controlled migrations with `supabase migration up`.
4. Read the local project URL and publishable key from `supabase status`.
5. Add those values and a callback URL to the Flutter run command as described in [ENVIRONMENT.md](ENVIRONMENT.md).
6. Configure Supabase Auth email confirmation and password recovery templates to return to the configured callback URL. The callback must also be in the Supabase Auth redirect allowlist.
7. Test policies and trigger behavior with `supabase test db`.

The local Supabase Auth configuration enables email confirmation and a 10-character minimum. Hosted projects must be configured equivalently. Set production/staging redirect allowlists narrowly, use HTTPS for Web callbacks, configure Supabase Auth rate limits and CAPTCHA/abuse controls appropriate to the deployment, and verify SMTP delivery before enabling registrations. Auth provider defaults are not a substitute for deployment-specific rate-limit and email-delivery verification.

## Code and localization

- Keep country-specific UI data in configuration, not country-specific branches or duplicated apps.
- Keep Supabase access in repositories and test authorization at the database layer.
- Add user-visible copy to both `lib/l10n/app_en.arb` and `lib/l10n/app_sw.arb`.
- Generate localization output with `flutter pub get` or `flutter gen-l10n`; generated Dart files under `lib/l10n/generated/` are build output.
- Use the shared theme and widgets for new UI, preserve keyboard access and readable contrast, and test narrow and wide layouts.

## Validation

```sh
dart format .
flutter analyze
flutter test
flutter build apk
flutter build web
```

The APK build validates compilation but is not release-signed. Configure a separate Android release signing key through a secure local or CI process before distributing an APK; never commit signing properties or keystores.

## Stage 2 learner management

The Stage 2 migration is `supabase/migrations/20261111000200_stage2_learner_management.sql`; it depends on the Stage 1 parent/authentication migration. It seeds only Tanzania's TIE system, Standard 1-7, and Forms 1-6. Kenya, Uganda, Rwanda, Burundi, and South Sudan remain without education structures until reviewed country configuration is supplied. Optional school selection is available when an authorized administrator has configured school records.

Parent access to learner records is enforced by RLS and database functions, not by hidden UI controls. Learner writes must use the RPCs exposed by `LearnerRepository`; never add direct client table writes or trust a client-supplied parent ID. Registration retries reuse a UUID idempotency key. Guardian invitations use a pending relationship and require acceptance by the invited active parent. The Flutter UI does not provide account lookup or email delivery for guardian invitations; that requires an approved invitation/notification channel.

Grade progression and academic calendar rows are managed by authorized country administrators. No academic calendar or automatic promotion policy is configured by default. Manual promotion is permitted only for configured progressions, grade repeats, or a switch to another configured education system. There is no automatic promotion job in Stage 2.

Stage 2 does not include lessons, exercises, assessments, learning progress, recommendations, subscriptions/payments, school administration, teacher accounts, or CMS functionality.

## Database verification

Run `supabase db reset`, `supabase migration up`, and `supabase test db` against a clean local stack to verify the versioned PostgreSQL migrations and pgTAP tests. The suites are in `supabase/tests/stage1_security.test.sql`, `supabase/tests/stage2_learners_security.test.sql`, `supabase/tests/stage3_curriculum_foundation.test.sql`, and `supabase/tests/stage3_2_curriculum_pilot.test.sql`. A Flutter build or mocked repository test cannot replace database authorization testing.

## Stage 3.1 curriculum foundation

The migration `supabase/migrations/20261111000300_stage3_curriculum_foundation.sql` extends Stage 2's curriculum configuration; it does not duplicate education tables. It links the existing TIE curriculum to its authority, adds curriculum versioning, language and grade mappings, source provenance, country-scoped curriculum roles, lifecycle functions, and review histories.

Only provision curriculum roles through trusted database operations. Never accept role assignments, source verification, approval, or publication decisions from client-supplied identity or role values. Parents can read enabled authority metadata and published curriculum configuration, but not source documents or internal review histories.

## Stage 3.2 TIE primary pilot

The migration `supabase/migrations/20261111000400_stage3_2_curriculum_pilot.sql` adds the draft-only TIE primary pilot and its source/rights review history, checksum-keyed import jobs, extracted-page provenance, normalized items, duplicate fingerprints, and private storage policies. The protected `/admin/curriculum` route provides source verification, usage-rights review, document selection/checksum validation, private upload, item normalization, independent review, and explicit version submission/approval/publication actions. Stage 3.3 moves document extraction out of Flutter and into the self-hosted worker described below.

The TIE official listing and linked PDF are recorded in [TIE_SOURCE_INVENTORY.md](./TIE_SOURCE_INVENTORY.md). The listing does not establish the document edition, effective dates, or rights to reproduce its content. Accordingly, the seeded source remains unverified and `permission_pending`; no source PDF has been uploaded to Supabase, and no TIE text has been extracted or published. Do not change rights to `authorized` or `public_domain`, upload the document, or publish curriculum content until applicable TIE permission/evidence is documented and independently reviewed.

Database RPCs—not Flutter state—enforce source verification, rights review by a different user, editor/reviewer separation, rights checks at registration/storage upload/extraction/publication, item review, and version approval. Source documents are stored only in a private bucket. Ordinary parents cannot read import jobs, extraction pages, draft items, or internal review history. Flutter never uses a Supabase service-role credential. Provision roles through a trusted operator process; the UI is not a role-management tool.

## Stage 3.3 curriculum import engine

Migrations `20261112000100`–`20261112000300` add validated document metadata for PDF, DOCX, XLSX, CSV, and JSON, worker lease/retry fields, page-level extraction revisions and provenance, validation reports, errors, duplicate-match review, and worker-only claim/complete/fail RPCs. The protected Flutter Import Studio queues private uploads, shows page extraction and validation reports, supports page reprocessing, and provides reviewer decisions for duplicate candidates. Source-linked curriculum items remain human-entered and reviewed; extraction does not classify or invent official curriculum content.

The self-hosted worker is in `workers/curriculum_import/`. Build its production image from that directory with `docker build -t learntz-curriculum-import-worker .`; build and run its tests with `docker build -f Dockerfile.test -t learntz-curriculum-import-worker-test .` and `docker run --rm learntz-curriculum-import-worker-test`. Supply `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` only through a trusted runtime secret manager. Keep the worker private and restrict its network access. The service-role key must never be embedded in Flutter or committed.

PDFium extracts selectable PDF text and tables; scanned pages use PDFium rendering and Tesseract OCR (`swa+eng` by default). OCR confidence is a review signal only. DOCX, XLSX, CSV, and JSON are parsed server-side; non-PDF source pagination is logical rather than printed-page pagination. Malware scanning, handwriting OCR, automatic semantic hierarchy reconstruction, general source/version registration UI, and production worker deployment are not implemented. Similarity matches are reviewer suggestions and are never merged automatically.

The TIE source remains `permission_pending`; do not upload, extract, or publish TIE content until the source edition and usage rights are independently verified. All migration and database test commands for this stage must target the local Supabase stack. Do not use `--remote` or apply these migrations to the hosted project without separate approval.

## Stage 3 validation

Stage 3.1 previously passed 96 pgTAP assertions. Stage 3.2 was freshly validated on the unlinked local Supabase stack by resetting the database, applying migrations `20261111000100` through `20261111000400`, confirming `supabase migration up` had no pending migrations, and passing all 143 pgTAP assertions across Stages 1–3.2. These checks do not authorize a hosted deployment. Do not apply the migrations to a hosted project without separate approval and deployment review.

## Account requests and administrator provisioning

The app records deactivation/deletion requests; it does not deactivate users or delete data. Review each request through an authorized operational process. For deletion, verify the requester, assess legal/retention obligations, preserve only records that must be retained, and execute deletion through a trusted server/database process using protected credentials. Never expose a service-role key in the Flutter app. Administrative roles are provisioned only through reviewed privileged database operations; the client cannot grant or edit roles.
