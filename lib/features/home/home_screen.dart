import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = appLocalizationsOf(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LearnTZ'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.translate), tooltip: 'Change language'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(strings.welcome, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(strings.tagline, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 28),
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.explore, size: 42, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 18),
                  Expanded(child: Text('Your learning journey starts here.', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: scheme.onPrimaryContainer))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Built for every learner', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const _FeatureTile(icon: Icons.menu_book_outlined, title: 'Learn', subtitle: 'Structured lessons for every stage.'),
          const _FeatureTile(icon: Icons.edit_note, title: 'Practice', subtitle: 'Build confidence through practice.'),
          const _FeatureTile(icon: Icons.insights_outlined, title: 'Progress', subtitle: 'A foundation for meaningful progress tracking.'),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), contentPadding: EdgeInsets.zero);
  }
}

AppLocalizations appLocalizationsOf(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations)!;
