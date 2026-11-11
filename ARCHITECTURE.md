# Architecture

## Product boundary

LearnTZ is one multi-country product, not a collection of country-specific apps. The first configured market is Tanzania. Country settings are represented by `CountryConfiguration`; new market data should be added through configuration and, when a backend is established, managed records rather than duplicated screens or applications. LearnTZ is intended to supplement, not replace, official curricula.

Stage 1 adds parent email authentication and account management. Learner profiles and all learning, payment, school, and teacher functionality remain out of scope.

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

Profiles, parent accounts, roles, account status, and audit logs have RLS enabled. Audit records are append-only and use `created_at`; mutable records also track `updated_at`. Account deactivation/deletion endpoints record requests only. A trusted operator must review requests, follow applicable retention/legal requirements, and perform any eventual account suspension or deletion outside the client. No service-role key belongs in a client build.

## Key decisions

- One Flutter target set (`android`, `web`) and one shared codebase for every country.
- Feature-first UI boundaries with small shared core layers; no premature domain/backend scaffolding.
- Flutter ARB localization for English and Kiswahili.
- Compile-time deployment configuration rather than a dotenv runtime dependency.
- No custom font dependency; platform sans-serif fallback keeps the initial app lightweight and supports both scripts.
