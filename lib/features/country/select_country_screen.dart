import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/country_configuration.dart';
import '../../core/config/country_providers.dart';
import '../../core/state/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_card.dart';

class SelectCountryScreen extends ConsumerWidget {
  const SelectCountryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCountry = ref.watch(selectedCountryProvider);
    final countries = ref.watch(countriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.countryTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.countryDescription(selectedCountry.productName),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          countries.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => AppCard(
              child: Column(
                children: [
                  Text(
                    error is CountriesBackendNotConfiguredException
                        ? l10n.countriesNotConfigured(selectedCountry.productName)
                        : error is PostgrestException
                        ? l10n.requestFailed
                        : l10n.requestFailed,
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(countriesProvider),
                    child: Text(l10n.tryAgainAction),
                  ),
                ],
              ),
            ),
            data: (items) => _CountryList(
              countries: items,
              selectedCountry: selectedCountry,
              onSelected: ref
                  .read(selectedCountryProvider.notifier)
                  .selectCountry,
              l10n: l10n,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryList extends StatelessWidget {
  const _CountryList({
    required this.countries,
    required this.selectedCountry,
    required this.onSelected,
    required this.l10n,
  });

  final List<CountryConfiguration> countries;
  final CountryConfiguration selectedCountry;
  final ValueChanged<CountryConfiguration> onSelected;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final country in countries) ...[
          AppCard(
            onTap: () => onSelected(country),
            padding: const EdgeInsets.all(20),
            child: Semantics(
              button: true,
              selected: selectedCountry.countryCode == country.countryCode,
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: Color(country.accentBrandColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          country.displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(country.productName),
                      ],
                    ),
                  ),
                  if (selectedCountry.countryCode == country.countryCode)
                    Icon(
                      Icons.check_circle,
                      color: Color(country.accentBrandColor),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (countries.isEmpty) AppCard(child: Text(l10n.noCountriesAvailable)),
        if (countries.isNotEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.countryConfigurationTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _CountryDetail(
                  label: l10n.productLabel,
                  value: selectedCountry.productName,
                ),
                _CountryDetail(
                  label: l10n.currencyLabel,
                  value: selectedCountry.currencyCode,
                ),
                _CountryDetail(
                  label: l10n.educationSystemLabel,
                  value: selectedCountry.educationSystem.isEmpty
                      ? l10n.curriculumNotConfigured
                      : selectedCountry.educationSystem,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CountryDetail extends StatelessWidget {
  const _CountryDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 480;
    final labelText = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
    final valueText = Text(value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelText, const SizedBox(height: 4), valueText],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 150, child: labelText),
                Expanded(child: valueText),
              ],
            ),
    );
  }
}
