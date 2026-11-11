# Changelog

## Unreleased — Stage 1

- Added parent email registration, sign-in, verification, password recovery/change, and logout through Supabase Auth.
- Added parent profile and account settings screens with email change verification and deactivation/deletion request flows.
- Added country-seeded PostgreSQL migrations, role helpers, RLS policies, audit triggers, and pgTAP security tests.
- Added protected account routes, Android auth deep-link registration, and bilingual authentication/account copy.
- Documented local Supabase setup, callback configuration, security boundaries, and account-request operations.

## 0.1.0 — Stage 0

- Scaffolded one Flutter application for Android and responsive Web.
- Added environment, country-configuration, routing, state, theme, shared-widget, and feature boundaries.
- Added Welcome, Home, About LearnTZ, Select Country, and Help screens.
- Added English and Kiswahili localization with an in-app language selector.
- Added optional Supabase initialization that remains disabled without explicit client configuration.
- Documented architecture, development, environment setup, and project scope.
