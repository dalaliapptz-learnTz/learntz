# Architecture

## Product boundary

LearnTZ is one multi-country product, not a collection of country-specific apps. The first configured market is Tanzania. Country settings are represented by `CountryConfiguration`; new market data should be added through configuration and, when a backend is established, managed records rather than duplicated screens or applications. LearnTZ is intended to supplement, not replace, official curricula.

Stage 1 adds parent email authentication and account management. Stage 2 adds parent-managed learner profiles and education configuration. Stage 3.1 adds governed curriculum authority and version foundations; Stage 3.2 adds a rights-gated Tanzania TIE primary-source import and human-review workflow. TIE content remains blocked until usage rights are documented. Learning delivery and progress, payments, school management, and teacher functionality remain out of scope.

## Application layers

```text
lib/
  app.dart                     MaterialApp, theme, localization
  main.dart                    environment validation and optional backend bootstrap
  core/
    auth/                      Supabase Auth repository and auth state
    config/                    deployment and market configuration
    routing/                   public and protected go_router routes
    state/                     Riverpod providers
    theme/                     colors and component theme
  features/
    account/                   parent profile and account settings
    auth/                      registration, sign-in, and recovery screens
    learners/                  learner models, repository, providers, and screens
    curriculum/                source rights, PDF import, normalization, and review
    welcome/                   welcome route
    home/                      home placeholder
    about/                     product information
    country/                   configured-country selection
    help/                      support placeholder
  l10n/                        English and Kiswahili ARB source
  shared/widgets/              app shell and reusable UI components
supabase/
  migrations/                  versioned PostgreSQL schema, triggers, and RLS
  tests/                       pgTAP authorization and isolation tests
```

Feature screens depend on core configuration, shared widgets, and generated localization—not on backend implementations. Riverpod owns app-wide locale and selected-country state. `go_router` owns URL-addressable navigation and a shared responsive shell.

## Country model

`CountryConfiguration` keeps country code, product name, primary/accent brand colors, currency, education-system label, and supported language codes together. The shared app shell, theme, title, and localized copy read from the selected configuration. The initial data is Tanzania (`TZ`, `LearnTZ`, blue/green palette, `TZS`, Tanzania Institute of Education) and is configuration, not sample learner or curriculum content. Future market data should have validation, lifecycle, and ownership before being sourced from the database.

## Backend boundary

`supabase_flutter` remains optional at startup and initializes only when both the project URL and publishable key are supplied. Without them, the app does not open a backend connection and account screens explain that the backend is unconfigured.

Auth access is behind a repository and Riverpod providers. Supabase Auth owns password hashing and token refresh. A `flutter_secure_storage` adapter backs both persisted session tokens and PKCE verifier storage on Android/Web; browser storage still depends on same-origin security, HTTPS, and XSS protections. The client never stores plaintext credentials. Signup metadata contains only the validated display name and selected country code. A trusted `auth.users` trigger validates that input, creates the profile, parent account, active status, the fixed `parent` role, and a registration audit record. It ignores any client-supplied role.

Countries are seeded configuration records. RLS allows public reads of enabled countries and restricts country updates by database role. User roles cannot be written through the client. Initial administrator provisioning is an authorized database-operator action; no Flutter-supplied role is trusted. `has_role` and `has_country_access` derive permissions from `auth.uid()` and are safe for use in RLS policies.

Profiles, parent accounts, roles, account status, audit logs, and all Stage 2 learner records have RLS enabled. The learner migration adds normalized education systems, curricula, levels, grades, optional school records, learner profiles, guardian relationships, status/change history, academic calendars, promotion policy, grade progression, and promotion history. Composite foreign keys and a trusted database function enforce country/system/curriculum/level/grade/school consistency.

The client has read access to authorized learner and enabled configuration rows. Learner writes go through security-definer database functions that derive the acting parent from `auth.uid()`; caller-supplied ownership is never accepted. Registration accepts a parent-scoped idempotency key. Guardian invitations remain pending until the invited parent accepts. Learner deactivation and deletion requests are soft status changes; trusted operators must review deletion requests and retention obligations. Append-only learner histories record profile changes, status transitions, and manual promotions.

Only authorized super administrators and country administrators can manage education configuration. Tanzania is the only market with an education system configured; only the explicitly seeded TIE structure is available. The other Stage 1 country rows have no education structure, so learners cannot be registered there until that country's official configuration has been reviewed and added. No academic calendar or promotion policy is seeded. Annual promotions stay disabled unless an authorized administrator configures and approves a policy. Manual promotions are checked against configured grade progression.

Stage 3.1 adds curriculum authorities, version records, grade/language mappings, source provenance, and review history. Stage 3.2 adds a draft-only TIE primary pilot, a rights-review history, checksum-keyed import jobs, private source storage, page-level extraction, normalized items, duplicate detection, and separated editor/reviewer/approver actions. The official TIE listing and linked artifact are catalogued in `TIE_SOURCE_INVENTORY.md`; source identity and usage rights are explicitly unverified/pending. No curriculum text has been extracted, stored, normalized, or published. Imports and lifecycle transitions are blocked by database functions until a separate reviewer records both source verification and documented rights. Extraction rechecks rights at execution time; private storage policies also gate upload and replacement. Other countries receive no invented authority or curriculum data. Country-scoped roles are assigned through trusted database operations, not client input. Published versions cannot be edited, and ordinary parents can read only approved items in published versions—not private source documents, extraction pages, or internal review histories.

Flutter's active learner is in-memory state, not an auth session. Selecting a learner reloads it through RLS before making it active; switching, signing out, and deactivation clear that context and learner-specific provider caches. All learner routes remain under the authenticated `/account` route boundary. No service-role key belongs in a client build.

## Key decisions

- One Flutter target set (`android`, `web`) and one shared codebase for every country.
- Feature-first UI boundaries with small shared core layers; no premature domain/backend scaffolding.
- Flutter ARB localization for English and Kiswahili.
- Compile-time deployment configuration rather than a dotenv runtime dependency.
- No custom font dependency; platform sans-serif fallback keeps the initial app lightweight and supports both scripts.
