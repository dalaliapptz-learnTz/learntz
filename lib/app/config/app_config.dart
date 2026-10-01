import '../../core/config/platform_configuration.dart';

class AppConfig {
  const AppConfig({
    required this.productName,
    required this.countryCode,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      productName: String.fromEnvironment('PRODUCT_NAME', defaultValue: 'LearnTZ'),
      countryCode: String.fromEnvironment('COUNTRY_CODE', defaultValue: 'TZ'),
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  }

  final String productName;
  final String countryCode;
  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get hasSupabaseConfiguration =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  String get tagline => 'Learn Anywhere, Anytime.';

  CountryConfiguration get countryConfiguration => PlatformCatalog.country(countryCode);
}
