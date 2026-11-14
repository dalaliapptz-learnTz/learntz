# Environment configuration

The app reads build-time values through Dart compile-time declarations. It does not read `.env` files. Environment-specific values are supplied to each run or build with `--dart-define`.

| Declaration | Allowed values | Default | Purpose |
|---|---|---|---|
| `APP_ENV` | `development`, `staging`, `production` | `development` | Identifies the deployment environment |
| `SUPABASE_URL` | HTTPS URL (development may use HTTP for local endpoints) | unset | Supabase project endpoint |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase client publishable key | unset | Client key used by Supabase |
| `SUPABASE_AUTH_REDIRECT_URL` | HTTPS callback or development deep-link/callback URL | unset | Verification, email-change, and password-recovery callback |

Example without a backend:

```sh
flutter run -d chrome --dart-define=APP_ENV=development
```

Example for a configured development project:

```sh
flutter run -d chrome \
  --dart-define=APP_ENV=development \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-client-publishable-key
```

For Web development, serve Flutter on port 3000 and use this callback:

```sh
flutter run -d web-server --web-port 3000 \
  --dart-define=APP_ENV=development \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-local-publishable-key \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=http://localhost:3000/auth/callback
```

For Android, configure the Supabase redirect allowlist and build with `--dart-define=SUPABASE_AUTH_REDIRECT_URL=learntz://login-callback/`. The Android manifest registers that callback scheme. Use the actual deployed HTTPS callback for hosted Web builds and allow only the exact URLs needed by each environment.

Provide separate project URLs and client keys for development, staging, and production. Staging and production endpoints must use HTTPS. The app rejects unknown environment names, incomplete URL/key pairs, and non-HTTPS staging/production endpoints.

**Dart compile-time values are embedded in client builds and are not a secret store.** A Supabase publishable key is intended for client use only when every exposed table and operation is protected by correct Row Level Security policies. Never pass a service-role key, database password, signing key, or other privileged secret to Flutter, Web, or Android builds. Keep local environment files out of source control; `.gitignore` excludes `.env` files.

No Supabase credentials or hosted project are configured in this repository. Backend initialization and connectivity therefore remain disabled by default. Local migrations and pgTAP tests require Docker and the Supabase CLI. Supabase Auth manages persistent sessions and refresh; verify this with a real local or hosted project before release.

For deployments, configure verified email delivery, email confirmation, secure password change, allowed callback URLs, and Supabase Auth rate limits. The local configuration sets conservative email, sign-in/sign-up, token-verification, and refresh limits; apply appropriate limits independently to each hosted project. Configure CAPTCHA/abuse protection and monitor Auth logs before public registration. Never reduce these controls to make tests pass.

## Production Hosted Supabase Project (LearnTZ)

The repository is linked to the hosted Supabase production project:
- **Project Ref:** `jmllsuohmllklzhmhiva`
- **Project Name:** LearnTZ
- **Region:** `eu-central-1` (AWS Frankfurt)
- **Project URL:** `https://jmllsuohmllklzhmhiva.supabase.co`
- **Publishable Key:** `sb_publishable_bicPB5xPkjcNeKpuG4fVjg_GnpVQtXp`
- **Database Host (Direct):** `db.jmllsuohmllklzhmhiva.supabase.co:5432`
- **Connection URI (Direct):** `postgresql://postgres:[YOUR-PASSWORD]@db.jmllsuohmllklzhmhiva.supabase.co:5432/postgres`
- **Connection URI (Pooler):** `postgresql://postgres.jmllsuohmllklzhmhiva@aws-1-eu-central-1.pooler.supabase.com:5432/postgres`

### Running or Building with Production Configuration

Using `--dart-define-from-file`:
```sh
flutter run -d chrome --dart-define-from-file=config/production.json
flutter build web --release --dart-define-from-file=config/production.json
```

Or using explicit `--dart-define` flags:
```sh
flutter run -d chrome \
  --dart-define=APP_ENV=production \
  --dart-define=SUPABASE_URL=https://jmllsuohmllklzhmhiva.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_bicPB5xPkjcNeKpuG4fVjg_GnpVQtXp \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=https://jmllsuohmllklzhmhiva.supabase.co/auth/v1/callback
```

### Supabase CLI Link Status

The project is linked to the hosted backend via:
```sh
supabase link --project-ref jmllsuohmllklzhmhiva
```

To inspect migrations on the remote database:
```sh
supabase migration list --remote
```

To push pending local migrations to the remote database:
```sh
supabase db push
```
*(Requires your Supabase database password for postgres on `db.jmllsuohmllklzhmhiva.supabase.co`)*

---

## Android release signing

This foundation does not configure release signing and does not reuse the Android debug key for release builds. The APK build is a compilation check, not a distributable release. Configure signing through a protected local or CI mechanism before distribution. Signing properties and keystore files are excluded by `.gitignore`; do not commit them.
