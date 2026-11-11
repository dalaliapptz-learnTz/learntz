import 'package:supabase_flutter/supabase_flutter.dart';

import 'country_configuration.dart';

class CountryRepository {
  const CountryRepository(this._client);

  final SupabaseClient _client;

  Future<List<CountryConfiguration>> listEnabled() async {
    final rows = await _client
        .from('countries')
        .select(
          'country_code, display_name, product_name, currency_code, '
          'education_system, primary_brand_color, accent_brand_color, '
          'supported_language_codes, is_default',
        )
        .eq('is_enabled', true)
        .order('is_default', ascending: false)
        .order('display_name');
    return rows
        .map((row) => CountryConfiguration.fromJson(row))
        .toList(growable: false);
  }
}
