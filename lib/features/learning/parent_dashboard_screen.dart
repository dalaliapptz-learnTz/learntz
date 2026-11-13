import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/auth_screens.dart';
import '../learners/learner_providers.dart';
import 'learning_models.dart';
import 'learning_providers.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final overviewAsync = ref.watch(parentDashboardOverviewProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.account),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.parentDashboardTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          l10n.parentDashboardSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              overviewAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AuthInlineMessage(
                  message: l10n.requestFailed,
                  isError: true,
                ),
                data: (learners) {
                  if (learners.isEmpty) {
                    return AppCard(
                      child: Column(
                        children: [
                          const Icon(Icons.people_outline, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            l10n.noLearnersRegistered,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: () => context.go(AppRoutes.addLearner),
                            child: Text(l10n.registerChildAction),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final learner in learners) ...[
                        _ParentLearnerCard(learner: learner),
                        const SizedBox(height: 20),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentLearnerCard extends ConsumerWidget {
  const _ParentLearnerCard({required this.learner});

  final ParentLearnerOverview learner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ratio = (learner.masteryPercent.clamp(0, 100)) / 100.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  learner.firstName.isNotEmpty ? learner.firstName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      learner.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${learner.gradeName} • ${learner.systemName} • ${learner.schoolName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Chip(
                avatar: const Icon(Icons.local_fire_department, size: 18, color: Colors.deepOrange),
                label: Text('${learner.streakDays} ${l10n.streakDaysSuffix}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mastery Bar
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.curriculumMasteryLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${learner.masteryPercent}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '${learner.completedLessons} of ${learner.totalLessons} ${l10n.lessonsCompletedLabel} • ${l10n.averageQuizLabel}: ${learner.averageQuizScorePercent}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (learner.lastLessonAccessed != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.lastActiveLessonLabel}: ${learner.lastLessonAccessed!.subjectName} - ${learner.lastLessonAccessed!.lessonTitle} (${learner.lastLessonAccessed!.readingProgressPercent}%)',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Subjects Overview
          if (learner.subjectsOverview.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.subjectPerformanceLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final subj in learner.subjectsOverview)
                  Chip(
                    avatar: Icon(
                      subj.status == 'excelling'
                          ? Icons.trending_up
                          : subj.status == 'needs_practice'
                              ? Icons.priority_high
                              : Icons.check_circle_outline,
                      size: 16,
                      color: subj.status == 'excelling'
                          ? Colors.green
                          : subj.status == 'needs_practice'
                              ? Colors.red
                              : Colors.blue,
                    ),
                    label: Text(
                      '${subj.subjectName}: ${subj.averageQuizScore}% (${subj.completedLessons}/${subj.totalLessons})',
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.learnerProfile(learner.learnerId)),
                child: Text(l10n.learnerProfileTitle),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(activeLearnerProvider.notifier).select(learner.learnerId);
                  if (context.mounted) {
                    context.go(AppRoutes.learn);
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.openLearningHubAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
