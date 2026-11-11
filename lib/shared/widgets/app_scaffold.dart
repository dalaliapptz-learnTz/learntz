import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authEvent = ref.watch(authStateChangesProvider).asData?.value;
    final client = ref.watch(supabaseClientProvider);
    final isSignedIn =
        authEvent?.session != null || client?.auth.currentSession != null;
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final destinations = [
      (AppRoutes.welcome, l10n.navigationWelcome, Icons.waving_hand_outlined),
      (AppRoutes.home, l10n.navigationHome, Icons.home_outlined),
      (AppRoutes.about, l10n.navigationAbout, Icons.info_outline),
      (AppRoutes.country, l10n.navigationCountry, Icons.public),
      (AppRoutes.help, l10n.navigationHelp, Icons.help_outline),
    ];
    final selectedIndex = destinations.indexWhere(
      (destination) => destination.$1 == location,
    );

    return Scaffold(
      appBar: AppBar(
        title: const _BrandMark(),
        actions: [
          if (isWide)
            for (final (index, destination) in destinations.indexed)
              TextButton(
                key: ValueKey('nav-${destination.$1}'),
                onPressed: () => context.go(destination.$1),
                style: TextButton.styleFrom(
                  foregroundColor: index == selectedIndex
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.muted,
                ),
                child: Text(destination.$2),
              ),
          IconButton(
            key: const ValueKey('account-action'),
            tooltip: isSignedIn ? l10n.accountTitle : l10n.signInAction,
            onPressed: () =>
                context.go(isSignedIn ? AppRoutes.account : AppRoutes.signIn),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          _LanguageMenu(
            onSelected: ref.read(appLocaleProvider.notifier).setLocale,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              onDestinationSelected: (index) =>
                  context.go(destinations[index].$1),
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    key: ValueKey('nav-${destination.$1}'),
                    icon: Icon(destination.$3),
                    label: destination.$2,
                  ),
              ],
            ),
    );
  }
}

class _BrandMark extends ConsumerWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productName = ref.watch(selectedCountryProvider).productName;
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: productName,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            productName,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.onSelected});

  final ValueChanged<Locale> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<Locale>(
      tooltip: l10n.language,
      icon: const Icon(Icons.language),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: Locale('en'), child: Text('English')),
        PopupMenuItem(value: Locale('sw'), child: Text('Kiswahili')),
      ],
    );
  }
}
