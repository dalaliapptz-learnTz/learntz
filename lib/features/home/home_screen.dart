import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/components/components.dart';
import '../../core/design_system/tokens/design_tokens.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final productName = ref.watch(selectedCountryProvider).productName;
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: LearnTzSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeTitle(productName),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          LearnTzSpacing.vGapSm,
          Text(
            l10n.homeDescription(productName),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          LearnTzSpacing.vGapLg,
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.explore_outlined, color: colors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeCardTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      LearnTzSpacing.vGapXs,
                      Text(
                        l10n.homeCardDescription,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          LearnTzSpacing.vGapMd,
          AppCard(
            variant: AppCardVariant.interactive,
            onTap: () => context.go(AppRoutes.country),
            child: Row(
              children: [
                Icon(Icons.public, color: colors.secondary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.countryTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Icon(Icons.arrow_forward, color: LearnTzColors.textSecondary),
              ],
            ),
          ),
          LearnTzSpacing.vGapMd,
          AppCard(
            key: const Key('home-cms-card'),
            variant: AppCardVariant.interactive,
            onTap: () => context.push(AppRoutes.contentStudio),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: colors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Content Management Studio',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      LearnTzSpacing.vGapXs,
                      Text(
                        'Interactive Curriculum Authoring, Markdown Studio & Two-Party Review',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: LearnTzColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
