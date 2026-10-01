import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/content_repository.dart';
import 'models/content_models.dart';

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(contentRepositoryProvider);
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
            ],
          );
        },
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
