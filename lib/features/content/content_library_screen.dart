import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/config/app_config.dart';
import '../auth/models/account_models.dart';
import '../auth/state/auth_controller.dart';
import '../progress/state/progress_controller.dart';
import '../progress/models/learning_progress.dart';
import 'data/content_repository.dart';
import 'models/content_models.dart';

class ContentLibraryScreen extends ConsumerWidget {
  const ContentLibraryScreen({super.key, this.learnerId});

  final String? learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final repository = ref.watch(contentRepositoryProvider);
    final progress = ref.watch(progressControllerProvider);
    if (learnerId != null && !progress.isLoaded(learnerId!)) {
      progress.load(learnerId!);
    }
    final learner = learnerId == null ? null : _findLearner(ref.watch(authControllerProvider).learners, learnerId!);
    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: FutureBuilder<List<LearningResource>>(
        future: repository.getResources(countryCode: config.countryCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Learning content is temporarily unavailable.'));
          }
          final resources = snapshot.data ?? const <LearningResource>[];
          if (resources.isEmpty) {
            return const Center(child: Text('No learning content is available yet.'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(learner == null ? 'Explore lessons' : '${learner.fullName}\'s learning', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Content for ${config.countryConfiguration.productName}', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              ...resources.map((resource) => _ResourceCard(resource: resource, learnerId: learnerId, progress: progress)),
            ],
          );
        },
      ),
    );
  }
}

LearnerProfile? _findLearner(List<LearnerProfile> learners, String learnerId) {
  for (final learner in learners) {
    if (learner.id == learnerId) return learner;
  }
  return null;
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource, required this.learnerId, required this.progress});

  final LearningResource resource;
  final String? learnerId;
  final ProgressController progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book_outlined),
                const SizedBox(width: 12),
                Expanded(child: Text(resource.subjectName, style: Theme.of(context).textTheme.labelLarge)),
                Chip(label: Text(_sourceLabel(resource.source))),
              ],
            ),
            const SizedBox(height: 12),
            Text(resource.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(resource.description),
            const SizedBox(height: 16),
            ...resource.lessons.map(
              (lesson) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.play_circle_outline),
                title: Text(lesson.title),
                subtitle: Text('${lesson.durationMinutes} min · ${lesson.summary}'),
                trailing: _LessonStatus(progress: progress.forLesson(learnerId ?? '', lesson.id)),
                onTap: () => context.go('/learn/lesson/${lesson.id}${learnerId == null ? '' : '?learnerId=${Uri.encodeComponent(learnerId!)}'}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sourceLabel(ContentSource source) {
    switch (source) {
      case ContentSource.officialLicensed:
        return 'Licensed';
      case ContentSource.learnOriginal:
        return 'Learn original';
      case ContentSource.teacherCreated:
        return 'Teacher';
      case ContentSource.thirdPartyLicensed:
        return 'Third-party';
      case ContentSource.supplementary:
        return 'Supplementary';
    }
  }
}

class _LessonStatus extends StatelessWidget {
  const _LessonStatus({required this.progress});

  final LearningProgress? progress;

  @override
  Widget build(BuildContext context) {
    if (progress == null) return const Icon(Icons.chevron_right);
    if (progress!.isComplete) return Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary);
    return SizedBox(width: 42, child: Text('${progress!.completionPercent}%', textAlign: TextAlign.end));
  }
}
