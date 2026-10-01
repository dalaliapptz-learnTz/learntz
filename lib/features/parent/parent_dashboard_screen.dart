import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/state/auth_controller.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final parent = auth.parent;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/auth');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Hello, ${parent?.fullName ?? 'parent'}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(auth.isDemoMode ? 'Local demo mode' : 'Account connected', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Your pupils'),
              subtitle: Text('${auth.learners.length} learner${auth.learners.length == 1 ? '' : 's'} registered'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/parent/pupils'),
            ),
          ),
          if (auth.learners.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Continue learning', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...auth.learners.map(
              (learner) => Card(
                child: ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: Text(learner.fullName),
                  subtitle: Text(learner.grade),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/learn/${learner.id}'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go('/parent/pupils/add'),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add a pupil'),
          ),
        ],
      ),
    );
  }
}
