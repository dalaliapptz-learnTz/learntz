# Changelog

## Unreleased — Stage 1

- Added parent email registration, sign-in, verification, password recovery/change, and logout through Supabase Auth.
- Added parent profile and account settings screens with email change verification and deactivation/deletion request flows.
- Added country-seeded PostgreSQL migrations, role helpers, RLS policies, audit triggers, and pgTAP security tests.
- Added protected account routes, Android auth deep-link registration, and bilingual authentication/account copy.
- Documented local Supabase setup, callback configuration, security boundaries, and account-request operations.

## Unreleased — Stage 2

- Added learner, guardian relationship, education configuration, history, and promotion database schema with parent-scoped RLS and authorization RPCs.
- Seeded Tanzania's TIE education structure; left other supported countries and automatic promotion policies unconfigured pending verified data and approval.
- Added responsive parent learner dashboard, registration/edit/profile screens, profile selection, deactivation, deletion requests, and manual promotion history.
- Added English/Kiswahili learner UI, learner model tests, protected route tests, and Stage 2 pgTAP security tests.

## Unreleased — Stage 3.1

- Added curriculum authority linkage, versioning, language/grade mappings, source provenance, review history, lifecycle functions, and country-scoped curriculum roles.
- Linked the existing TIE curriculum to the Tanzania Institute of Education authority without adding unverified curriculum versions or content.
- Added pgTAP coverage for country-scoped access, source verification, lifecycle authorization, parent read-only visibility, and published-version immutability; all 96 database assertions pass locally.

## Unreleased — Stage 3.2

- Added a draft-only TIE primary pilot, source identity and usage-rights review history, private checksum-keyed PDF imports, page extraction, normalized item review, duplicate detection, and explicit version approval/publication gates.
- Added a protected, responsive curriculum administration workflow with source review, PDF selection/extraction, normalization, independent review, and English/Kiswahili strings.
- Kept TIE source identity and reproduction rights unverified/pending; no TIE curriculum text or PDF is imported or published until permission is documented and independently reviewed.
- Fresh local Supabase reset/migration validation passed all 143 pgTAP assertions; Flutter analysis/tests and Android/Web builds are reported in `STAGE3_2_COMPLETION.md`.

## 0.1.0 — Stage 0

- Scaffolded one Flutter application for Android and responsive Web.
- Added environment, country-configuration, routing, state, theme, shared-widget, and feature boundaries.
- Added Welcome, Home, About LearnTZ, Select Country, and Help screens.
- Added English and Kiswahili localization with an in-app language selector.
- Added optional Supabase initialization that remains disabled without explicit client configuration.
- Documented architecture, development, environment setup, and project scope.
