class CountryConfiguration {
  const CountryConfiguration({
    required this.countryCode,
    required this.displayName,
    required this.productName,
    required this.primaryBrandColor,
    required this.accentBrandColor,
    required this.currencyCode,
    required this.educationSystem,
    required this.supportedLanguageCodes,
    required this.isDefault,
  });

  factory CountryConfiguration.fromJson(Map<String, dynamic> json) {
    return CountryConfiguration(
      countryCode: json['country_code'] as String,
      displayName: json['display_name'] as String,
      productName: json['product_name'] as String,
      primaryBrandColor: (json['primary_brand_color'] as num).toInt(),
      accentBrandColor: (json['accent_brand_color'] as num).toInt(),
      currencyCode: json['currency_code'] as String,
      educationSystem: json['education_system'] as String? ?? '',
      supportedLanguageCodes: (json['supported_language_codes'] as List)
          .cast<String>(),
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  final String countryCode;
  final String displayName;
  final String productName;
  final int primaryBrandColor;
  final int accentBrandColor;
  final String currencyCode;
  final String educationSystem;
  final List<String> supportedLanguageCodes;
  final bool isDefault;
}

const tanzaniaConfiguration = CountryConfiguration(
  countryCode: 'TZ',
  displayName: 'Tanzania',
  productName: 'LearnTZ',
  primaryBrandColor: 0xFF155EEF,
  accentBrandColor: 0xFF168653,
  currencyCode: 'TZS',
  educationSystem: 'Tanzania Institute of Education (TIE)',
  supportedLanguageCodes: ['en', 'sw'],
  isDefault: true,
);
