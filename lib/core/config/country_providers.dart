import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_providers.dart';
import 'country_configuration.dart';
import 'country_repository.dart';

final countryRepositoryProvider = Provider<CountryRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : CountryRepository(client);
});

final countriesProvider =
    FutureProvider.autoDispose<List<CountryConfiguration>>((ref) async {
      final repository = ref.watch(countryRepositoryProvider);
      if (repository == null) {
        throw const CountriesBackendNotConfiguredException();
      }
      return repository.listEnabled();
    });

class CountriesBackendNotConfiguredException implements Exception {
  const CountriesBackendNotConfiguredException();
}
