import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../learners/learner_providers.dart';
import 'learning_providers.dart';

class RevisionCentreScreen extends ConsumerWidget {
  const RevisionCentreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeLearner = ref.watch(activeLearnerProvider);

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
                    onPressed: () => context.go(AppRoutes.learn),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.revisionCentreTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          l10n.revisionCentreSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.resourceLibrary),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: Text(l10n.resourceLibraryTitle),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (activeLearner == null)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        l10n.noLearnersDescription,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                )
              else ...[
                _RevisionOverviewHeader(learnerId: activeLearner.id),
                const SizedBox(height: 24),
                _WeakTopicDrillsSection(learnerId: activeLearner.id),
                const SizedBox(height: 24),
                _FlashcardDecksSection(learnerId: activeLearner.id),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RevisionOverviewHeader extends ConsumerWidget {
  const _RevisionOverviewHeader({required this.learnerId});

  final String learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final overviewAsync = ref.watch(learnerRevisionOverviewProvider(learnerId));

    return overviewAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${l10n.requestFailed}: $e'),
        ),
      ),
      data: (overview) {
        final colorScheme = Theme.of(context).colorScheme;
        return AppCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: overview.readinessIndex / 100.0,
                            strokeWidth: 8,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            color: overview.readinessIndex >= 70
                                ? Colors.green
                                : (overview.readinessIndex >= 40
                                    ? Colors.orange
                                    : Colors.red),
                          ),
                        ),
                        Text(
                          '${overview.readinessIndex}%',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.examReadinessScore,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            overview.readinessIndex >= 75
                                ? l10n.examReadinessHigh
                                : (overview.readinessIndex >= 50
                                    ? l10n.examReadinessModerate
                                    : l10n.examReadinessNeedsWork),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MetricPill(
                      label: l10n.masteredTopicsCount,
                      value: '${overview.masteredTopicsCount}',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _MetricPill(
                      label: l10n.proficientTopicsCount,
                      value: '${overview.proficientTopicsCount}',
                      icon: Icons.trending_up_outlined,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _MetricPill(
                      label: l10n.flashcardsAvailable,
                      value: '${overview.flashcardDecksCount}',
                      icon: Icons.style_outlined,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 12),
                    _MetricPill(
                      label: l10n.resourcesAvailable,
                      value: '${overview.learningResourcesCount}',
                      icon: Icons.folder_open_outlined,
                      color: Colors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeakTopicDrillsSection extends ConsumerWidget {
  const _WeakTopicDrillsSection({required this.learnerId});

  final String learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final overviewAsync = ref.watch(learnerRevisionOverviewProvider(learnerId));

    return overviewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (context, error) => const SizedBox.shrink(),
      data: (overview) {
        final weakTopics = overview.weakTopics;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.weakAreaDrillsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (weakTopics.isNotEmpty)
                  FilledButton.tonalIcon(
                    onPressed: () {
                      final firstTopic = weakTopics.first;
                      context.go(
                        AppRoutes.lessonQuiz(firstTopic.topicId),
                      );
                    },
                    icon: const Icon(Icons.bolt, size: 18),
                    label: Text(l10n.startWeakAreaDrill),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (weakTopics.isEmpty)
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration_outlined, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.noWeakAreasFound,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: weakTopics.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final topic = weakTopics[index];
                  final accuracy = topic.accuracyRate;
                  final accuracyColor = accuracy < 50
                      ? Colors.red
                      : (accuracy < 75 ? Colors.orange : Colors.green);

                  return AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accuracyColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${accuracy.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: accuracyColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  topic.topicTitle,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${topic.subjectName} • ${topic.quizzesAttempted} ${l10n.attemptsLabel}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              context.go(
                                AppRoutes.lessonQuiz(topic.topicId),
                              );
                            },
                            child: Text(l10n.drillAction),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _FlashcardDecksSection extends ConsumerWidget {
  const _FlashcardDecksSection({required this.learnerId});

  final String learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final decksAsync = ref.watch(
      flashcardDecksProvider((learnerId: learnerId, subjectId: null)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.flashcardsSectionTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        decksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('${l10n.requestFailed}: $e'),
          data: (decks) {
            if (decks.isEmpty) {
              return AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noFlashcardDecksAvailable),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    mainAxisExtent: 150,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: decks.length,
                  itemBuilder: (context, index) {
                    final deck = decks[index];
                    return AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    deck.subjectName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${deck.estimatedMinutes} ${l10n.minutesShort}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              deck.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              deck.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${deck.cardCount} ${l10n.cardsLabel}',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    context.go(
                                      AppRoutes.flashcardStudy(deck.id),
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow, size: 16),
                                  label: Text(l10n.studyFlashcardsAction),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
