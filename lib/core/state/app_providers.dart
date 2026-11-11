import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_environment.dart';
import '../config/country_configuration.dart';

final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => AppEnvironment.fromCompileTime(),
);

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  return environment.hasSupabaseConfiguration ? Supabase.instance.client : null;
});

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(
  AppLocaleNotifier.new,
);

class AppLocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('en');

  void setLocale(Locale locale) {
    if (const ['en', 'sw'].contains(locale.languageCode)) {
      state = locale;
    }
  }
}

final selectedCountryProvider =
    NotifierProvider<SelectedCountryNotifier, CountryConfiguration>(
      SelectedCountryNotifier.new,
    );

class SelectedCountryNotifier extends Notifier<CountryConfiguration> {
  @override
  CountryConfiguration build() => tanzaniaConfiguration;

  void selectCountry(CountryConfiguration country) {
    state = country;
  }
}
