import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/state/auth_controller.dart';

class PupilsScreen extends ConsumerWidget {
  const PupilsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learners = ref.watch(authControllerProvider).learners;
    return Scaffold(
      appBar: AppBar(title: const Text('Your pupils')),
      body: learners.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text('No pupils yet', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text('Add a pupil to begin setting up their learning journey.', textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton.icon(onPressed: () => context.go('/parent/pupils/add'), icon: const Icon(Icons.add), label: const Text('Add pupil')),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ...learners.map(
                  (learner) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(learner.fullName),
                      subtitle: Text(learner.grade),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: () => context.go('/parent/pupils/add'), icon: const Icon(Icons.add), label: const Text('Add another pupil')),
              ],
            ),
    );
  }
}
