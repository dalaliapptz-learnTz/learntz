import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/state/auth_controller.dart';
import 'content_library_screen.dart';

class LearnerSelectionScreen extends ConsumerWidget {
  const LearnerSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (!auth.isSignedIn) return const ContentLibraryScreen();
    if (auth.learners.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Learn')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school_outlined, size: 56),
                const SizedBox(height: 16),
                Text('Choose a learner first', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Add a pupil profile so progress can be tracked for the right learner.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(onPressed: () => context.go('/parent/pupils/add'), icon: const Icon(Icons.person_add_alt_1), label: const Text('Add a pupil')),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a learner')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Who is learning today?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Progress is saved separately for each pupil.'),
          const SizedBox(height: 24),
          ...auth.learners.map(
            (learner) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(learner.fullName),
                subtitle: Text('${learner.grade} · ${learner.curriculum}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/learn/${learner.id}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
