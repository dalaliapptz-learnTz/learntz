import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/state/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';

class LearnTzApp extends ConsumerWidget {
  const LearnTzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final country = ref.watch(selectedCountryProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) {
        final l10n = AppLocalizations.of(context)!;
        return l10n.appTitle(country.productName, l10n.tagline);
      },
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(country),
      darkTheme: AppTheme.darkTheme(country),
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(appRouterProvider),
      locale: ref.watch(appLocaleProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
