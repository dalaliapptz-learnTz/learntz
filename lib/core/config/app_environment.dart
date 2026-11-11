enum AppEnvironmentName { development, staging, production }

class AppEnvironment {
  const AppEnvironment._({
    required this.name,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.authRedirectUrl,
  });

  factory AppEnvironment.fromCompileTime() {
    const rawName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabasePublishableKey = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    );
    const authRedirectUrl = String.fromEnvironment(
      'SUPABASE_AUTH_REDIRECT_URL',
    );

    return AppEnvironment.fromValues(
      environment: rawName,
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: supabasePublishableKey,
      authRedirectUrl: authRedirectUrl,
    );
  }

  factory AppEnvironment.fromValues({
    required String environment,
    String? supabaseUrl,
    String? supabasePublishableKey,
    String? authRedirectUrl,
  }) {
    final name = switch (environment) {
      'development' => AppEnvironmentName.development,
      'staging' => AppEnvironmentName.staging,
      'production' => AppEnvironmentName.production,
      _ => throw FormatException('Unsupported APP_ENV value: $environment'),
    };
    final normalizedUrl = supabaseUrl?.trim();
    final normalizedKey = supabasePublishableKey?.trim();
    final hasUrl = normalizedUrl?.isNotEmpty ?? false;
    final hasKey = normalizedKey?.isNotEmpty ?? false;

    if (hasUrl != hasKey) {
      throw const FormatException(
        'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be configured together.',
      );
    }

    if (hasUrl) {
      final uri = Uri.tryParse(normalizedUrl!);
      final isLocalDevelopmentEndpoint =
          uri != null &&
          name == AppEnvironmentName.development &&
          uri.scheme == 'http' &&
          const [
            'localhost',
            '127.0.0.1',
            '::1',
            '10.0.2.2',
          ].contains(uri.host);
      if (uri == null ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          (uri.scheme != 'https' && !isLocalDevelopmentEndpoint)) {
        throw const FormatException('SUPABASE_URL is not a valid endpoint.');
      }
    }

    final normalizedRedirectUrl = authRedirectUrl?.trim();
    if (normalizedRedirectUrl != null && normalizedRedirectUrl.isNotEmpty) {
      final redirectUri = Uri.tryParse(normalizedRedirectUrl);
      if (redirectUri == null ||
          redirectUri.scheme.isEmpty ||
          redirectUri.host.isEmpty ||
          redirectUri.userInfo.isNotEmpty ||
          !const ['https', 'http', 'learntz'].contains(redirectUri.scheme) ||
          (redirectUri.scheme == 'http' &&
              (name != AppEnvironmentName.development ||
                  !const [
                    'localhost',
                    '127.0.0.1',
                    '::1',
                  ].contains(redirectUri.host)))) {
        throw const FormatException(
          'SUPABASE_AUTH_REDIRECT_URL is not a valid callback URL.',
        );
      }
    }

    return AppEnvironment._(
      name: name,
      supabaseUrl: hasUrl ? normalizedUrl : null,
      supabasePublishableKey: hasKey ? normalizedKey : null,
      authRedirectUrl: normalizedRedirectUrl?.isNotEmpty == true
          ? normalizedRedirectUrl
          : null,
    );
  }

  final AppEnvironmentName name;
  final String? supabaseUrl;
  final String? supabasePublishableKey;
  final String? authRedirectUrl;

  bool get hasSupabaseConfiguration =>
      supabaseUrl != null && supabasePublishableKey != null;
}
