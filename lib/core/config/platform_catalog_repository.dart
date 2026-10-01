import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/config/app_config.dart';
import 'platform_configuration.dart';

abstract interface class PlatformCatalogRepository {
  Future<List<CountryConfiguration>> getCountries();
}

class LocalPlatformCatalogRepository implements PlatformCatalogRepository {
  const LocalPlatformCatalogRepository();

  @override
  Future<List<CountryConfiguration>> getCountries() async => PlatformCatalog.countries;
}

class SupabasePlatformCatalogRepository implements PlatformCatalogRepository {
  SupabasePlatformCatalogRepository(this.client);

  final SupabaseClient client;

  @override
  Future<List<CountryConfiguration>> getCountries() async {
    final rows = await client.from('countries').select('''
      code,
      product_name,
      default_language_code,
      currency_code,
      timezone,
      curricula(
        code,
        name,
        education_systems(
          code,
          name,
          education_levels(
            code,
            name,
            grades(code, name)
          )
        )
      )
    ''');

    return (rows as List<dynamic>)
        .map((row) => _countryFromRow(row as Map<String, dynamic>))
        .toList();
  }

  CountryConfiguration _countryFromRow(Map<String, dynamic> row) {
    return CountryConfiguration(
      code: row['code'] as String,
      productName: row['product_name'] as String,
      defaultLanguageCode: row['default_language_code'] as String,
      currencyCode: row['currency_code'] as String,
      timezone: row['timezone'] as String,
      curricula: _list(row['curricula']).map(_curriculumFromRow).toList(),
    );
  }

  CurriculumConfiguration _curriculumFromRow(Map<String, dynamic> row) {
    return CurriculumConfiguration(
      code: row['code'] as String,
      name: row['name'] as String,
      educationSystems: _list(row['education_systems']).map(_systemFromRow).toList(),
    );
  }

  EducationSystemConfiguration _systemFromRow(Map<String, dynamic> row) {
    return EducationSystemConfiguration(
      code: row['code'] as String,
      name: row['name'] as String,
      levels: _list(row['education_levels']).map(_levelFromRow).toList(),
    );
  }

  EducationLevelConfiguration _levelFromRow(Map<String, dynamic> row) {
    return EducationLevelConfiguration(
      code: row['code'] as String,
      name: row['name'] as String,
      grades: _list(row['grades'])
          .map((grade) => GradeConfiguration(code: grade['code'] as String, name: grade['name'] as String))
          .toList(),
    );
  }

  List<Map<String, dynamic>> _list(dynamic value) => (value as List<dynamic>? ?? const [])
      .map((item) => item as Map<String, dynamic>)
      .toList();
}

PlatformCatalogRepository createPlatformCatalogRepository(AppConfig config) {
  if (config.hasSupabaseConfiguration) {
    return SupabasePlatformCatalogRepository(Supabase.instance.client);
  }
  return const LocalPlatformCatalogRepository();
}
