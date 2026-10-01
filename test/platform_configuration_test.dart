import 'package:flutter_test/flutter_test.dart';

import 'package:learntz/core/config/platform_catalog_repository.dart';
import 'package:learntz/core/config/platform_configuration.dart';

void main() {
  test('catalog contains the configured country products', () {
    final codes = PlatformCatalog.countries.map((country) => country.code).toSet();

    expect(codes, containsAll(<String>['TZ', 'KE', 'UG', 'RW', 'BI', 'SS']));
    expect(PlatformCatalog.country('TZ').curricula.single.code, 'TIE');
    expect(PlatformCatalog.country('KE').curricula.single.code, 'CBC');
  });

  test('local repository exposes the same configuration catalog', () async {
    const repository = LocalPlatformCatalogRepository();
    final countries = await repository.getCountries();

    expect(countries, hasLength(6));
    expect(countries.first.productName, 'LearnTZ');
  });
}
