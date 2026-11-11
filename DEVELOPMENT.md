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

## Scope guard

Stage 1 covers parent authentication and parent account management only. Do not add learner profiles, curriculum content, assessments, subscriptions, payments, schools, or teacher functionality until a later stage is explicitly authorized.

## Account requests and administrator provisioning

The app records deactivation/deletion requests; it does not deactivate users or delete data. Review each request through an authorized operational process. For deletion, verify the requester, assess legal/retention obligations, preserve only records that must be retained, and execute deletion through a trusted server/database process using protected credentials. Never expose a service-role key in the Flutter app. Administrative roles are provisioned only through reviewed privileged database operations; the client cannot grant or edit roles.
