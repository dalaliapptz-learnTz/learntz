import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('sw')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get welcome => locale.languageCode == 'sw' ? 'Karibu LearnTZ' : 'Welcome to LearnTZ';
  String get tagline => locale.languageCode == 'sw' ? 'Jifunze popote, wakati wowote.' : 'Learn Anywhere, Anytime.';
  String get home => locale.languageCode == 'sw' ? 'Mwanzo' : 'Home';
  String get learn => locale.languageCode == 'sw' ? 'Jifunze' : 'Learn';
  String get progress => locale.languageCode == 'sw' ? 'Maendeleo' : 'Progress';
  String get signIn => locale.languageCode == 'sw' ? 'Ingia' : 'Sign in';
  String get comingSoon => locale.languageCode == 'sw' ? 'Inakuja hivi karibuni' : 'Coming soon';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
