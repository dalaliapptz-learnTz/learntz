import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../progress/state/progress_controller.dart';
import 'data/content_repository.dart';
import 'models/content_models.dart';

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.lessonId, this.learnerId});

  final String lessonId;
  final String? learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(contentRepositoryProvider);
    final progressController = ref.watch(progressControllerProvider);
    if (learnerId != null && !progressController.isLoaded(learnerId!)) {
      progressController.load(learnerId!);
    }
    final progress = learnerId == null ? null : progressController.forLesson(learnerId!, lessonId);
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson')),
      body: FutureBuilder<LearningLesson?>(
        future: repository.getLesson(lessonId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lesson = snapshot.data;
          if (lesson == null) return const Center(child: Text('This lesson is unavailable.'));
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(lesson.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Row(children: [const Icon(Icons.schedule, size: 18), const SizedBox(width: 6), Text('${lesson.durationMinutes} minutes')]),
              const SizedBox(height: 12),
              Text(lesson.summary, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              ...lesson.blocks.asMap().entries.map((entry) => _LessonBlock(index: entry.key + 1, block: entry.value)),
              if (learnerId != null) ...[
                const SizedBox(height: 8),
                _ProgressCard(
                  progressPercent: progress?.completionPercent ?? 0,
                  isComplete: progress?.isComplete ?? false,
                  onComplete: () async {
                    await ref.read(progressControllerProvider.notifier).markCompleted(
                          learnerId: learnerId!,
                          lessonId: lesson.id,
                          blockCount: lesson.blocks.length,
                        );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progressPercent, required this.isComplete, required this.onComplete});

  final int progressPercent;
  final bool isComplete;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isComplete ? 'Lesson complete' : 'Your progress', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progressPercent / 100),
            const SizedBox(height: 8),
            Text('$progressPercent% complete'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isComplete ? null : onComplete,
              icon: const Icon(Icons.check),
              label: Text(isComplete ? 'Completed' : 'Mark lesson complete'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonBlock extends StatelessWidget {
  const _LessonBlock({required this.index, required this.block});

  final int index;
  final LessonBlock block;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: block.type == LessonBlockType.reflection ? scheme.secondaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$index  ${block.heading}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(block.body, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
