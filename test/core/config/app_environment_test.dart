import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/core/config/app_environment.dart';

void main() {
  group('AppEnvironment', () {
    test('allows running without a configured backend', () {
      final environment = AppEnvironment.fromValues(environment: 'development');

      expect(environment.name, AppEnvironmentName.development);
      expect(environment.hasSupabaseConfiguration, isFalse);
      expect(environment.supabaseUrl, isNull);
    });

    test('requires the project URL and publishable key together', () {
      expect(
        () => AppEnvironment.fromValues(
          environment: 'development',
          supabaseUrl: 'https://project.supabase.co',
        ),
        throwsFormatException,
      );
    });

    test('rejects insecure non-local endpoints and non-HTTPS production', () {
      expect(
        () => AppEnvironment.fromValues(
          environment: 'development',
          supabaseUrl: 'http://example.com',
          supabasePublishableKey: 'client-key',
        ),
        throwsFormatException,
      );
      expect(
        () => AppEnvironment.fromValues(
          environment: 'production',
          supabaseUrl: 'http://localhost:54321',
          supabasePublishableKey: 'client-key',
        ),
        throwsFormatException,
      );
    });

    test('allows localhost in development and HTTPS in production', () {
      final local = AppEnvironment.fromValues(
        environment: 'development',
        supabaseUrl: 'http://localhost:54321',
        supabasePublishableKey: 'client-key',
      );
      final production = AppEnvironment.fromValues(
        environment: 'production',
        supabaseUrl: 'https://project.supabase.co',
        supabasePublishableKey: 'client-key',
      );

      expect(local.hasSupabaseConfiguration, isTrue);
      expect(production.name, AppEnvironmentName.production);
    });

    test('rejects unsupported environment names', () {
      expect(
        () => AppEnvironment.fromValues(environment: 'preview'),
        throwsFormatException,
      );
    });

    test('validates email redirect URLs', () {
      final appLink = AppEnvironment.fromValues(
        environment: 'production',
        authRedirectUrl: 'learntz://login-callback/',
      );
      final webLink = AppEnvironment.fromValues(
        environment: 'production',
        authRedirectUrl: 'https://learn.example.com/auth/callback',
      );

      expect(appLink.authRedirectUrl, 'learntz://login-callback/');
      expect(
        webLink.authRedirectUrl,
        'https://learn.example.com/auth/callback',
      );
      expect(
        () => AppEnvironment.fromValues(
          environment: 'production',
          authRedirectUrl: 'http://example.com/callback',
        ),
        throwsFormatException,
      );
      expect(
        () => AppEnvironment.fromValues(
          environment: 'production',
          authRedirectUrl: 'https://user:pass@example.com/callback',
        ),
        throwsFormatException,
      );
    });
  });
}
