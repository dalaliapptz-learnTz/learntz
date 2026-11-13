import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/tokens/design_tokens.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/auth_screens.dart';
import '../learners/learner_providers.dart';
import 'learning_models.dart';
import 'learning_providers.dart';

class MasteryProgressBar extends StatelessWidget {
  const MasteryProgressBar({required this.summary, super.key});

  final LearnerLearningSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ratio = (summary.masteryPercent.clamp(0, 100)) / 100.0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.learningMasteryTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${summary.masteryPercent}%',
                key: const ValueKey('mastery-percent-label'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            key: const ValueKey('mastery-progress-indicator'),
            value: ratio,
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.learningMasteryStats(
              summary.completedLessons,
              summary.totalLessons,
              summary.averageQuizScorePercent,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class LearningHubScreen extends ConsumerWidget {
  const LearningHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeLearner = ref.watch(activeLearnerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.learningHubTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.learningHubSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.revisionCentre),
                        icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                        label: Text(l10n.revisionCentreTitle),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.socialProfile),
                        icon: const Icon(Icons.badge_outlined, size: 18),
                        label: const Text('Academic Profile'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.communityFeed),
                        icon: const Icon(Icons.forum_outlined, size: 18),
                        label: const Text('Community Feed'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.communities),
                        icon: const Icon(Icons.groups_outlined, size: 18),
                        label: const Text('Communities Hub'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.challenges),
                        icon: const Icon(Icons.emoji_events_outlined, size: 18),
                        label: const Text('Academic Arena'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.notifications),
                        icon: const Icon(Icons.notifications_outlined, size: 18),
                        label: const Text('Notifications'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.resourceLibrary),
                        icon: const Icon(Icons.menu_book_outlined, size: 18),
                        label: Text(l10n.resourceLibraryTitle),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.curriculumExplorer),
                        icon: const Icon(Icons.explore_outlined, size: 18),
                        label: Text(l10n.curriculumExplorerAction),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.parentDashboard),
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: Text(l10n.parentDashboardTitle),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (activeLearner == null)
                _SelectLearnerPrompt()
              else ...[
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.school_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeLearner.fullName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${activeLearner.countryCode} • ${activeLearner.status}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.read(activeLearnerProvider.notifier).clear(),
                        child: Text(l10n.switchLearnerAction),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _OfflineSyncStatusBar(learnerId: activeLearner.id),
                _LearnerDailyTargetAndResumeSection(learnerId: activeLearner.id),
                const SizedBox(height: 16),
                _LearnerRecommendationsSection(learnerId: activeLearner.id),
                _LearnerMasteryOverviewSection(learnerId: activeLearner.id),
                const SizedBox(height: 16),
                ref
                    .watch(activeLearnerLearningCatalogProvider)
                    .when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => AuthInlineMessage(
                        message: l10n.requestFailed,
                        isError: true,
                      ),
                      data: (bundle) {
                        if (bundle == null) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MasteryProgressBar(summary: bundle.summary),
                            if (!bundle.summary.hasActiveSubscription) ...[
                              const SizedBox(height: 12),
                              AppCard(
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_open_outlined),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(l10n.learningPreviewBanner),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          context.go(AppRoutes.subscriptions),
                                      child: Text(l10n.viewSubscriptionsAction),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            if (bundle.subjects.isEmpty)
                              AppCard(child: Text(l10n.noSubjectsPublished))
                            else
                              for (final subject in bundle.subjects) ...[
                                _SubjectSectionCard(
                                  subject: subject,
                                  topics:
                                      bundle.topicsBySubject[subject.id] ??
                                      const [],
                                  lessonsByTopic: bundle.lessonsByTopic,
                                  progressByLesson: bundle.progressByLesson,
                                ),
                                const SizedBox(height: 16),
                              ],
                          ],
                        );
                      },
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectLearnerPrompt extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final learnersAsync = ref.watch(parentLearnersProvider);
    return learnersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          AuthInlineMessage(message: l10n.requestFailed, isError: true),
      data: (learners) {
        if (learners.isEmpty) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.noLearnersTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(l10n.noLearnersDescription),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.addLearner),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(l10n.addLearnerAction),
                ),
              ],
            ),
          );
        }
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectActiveLearnerTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final learner in learners)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(learner.fullName),
                  subtitle: Text(learner.countryCode),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => ref
                      .read(activeLearnerProvider.notifier)
                      .select(learner.id),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SubjectSectionCard extends StatelessWidget {
  const _SubjectSectionCard({
    required this.subject,
    required this.topics,
    required this.lessonsByTopic,
    required this.progressByLesson,
  });

  final LearningSubject subject;
  final List<LearningTopic> topics;
  final Map<String, List<LearningLesson>> lessonsByTopic;
  final Map<String, LearnerProgressRecord> progressByLesson;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subject.name, style: Theme.of(context).textTheme.titleLarge),
          if (subject.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subject.description),
          ],
          const SizedBox(height: 12),
          for (final topic in topics) ...[
            Text(
              topic.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            for (final lesson
                in lessonsByTopic[topic.id] ?? const <LearningLesson>[])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  (progressByLesson[lesson.id]?.isCompleted ?? false)
                      ? Icons.check_circle
                      : Icons.menu_book_outlined,
                ),
                title: Text(lesson.title),
                subtitle: Text(
                  '${lesson.estimatedMinutes} min • '
                  '${progressByLesson[lesson.id]?.status ?? "not_started"}'
                  '${progressByLesson[lesson.id]?.bestQuizScorePercent != null ? " • ${l10n.bestScoreLabel(progressByLesson[lesson.id]!.bestQuizScorePercent!)}" : ""}',
                ),
                trailing: lesson.isFreePreview
                    ? Chip(label: Text(l10n.freePreviewLabel))
                    : const Icon(Icons.arrow_forward),
                onTap: () => context.go(AppRoutes.lessonReader(lesson.id)),
              ),
          ],
        ],
      ),
    );
  }
}

class LessonReaderScreen extends ConsumerStatefulWidget {
  const LessonReaderScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  ConsumerState<LessonReaderScreen> createState() => _LessonReaderScreenState();
}

class _LessonReaderScreenState extends ConsumerState<LessonReaderScreen> {
  double _readingProgress = 25;
  bool _isSaving = false;
  String? _statusMessage;

  Future<void> _saveProgress({required bool complete}) async {
    final learner = ref.read(activeLearnerProvider);
    final repo = ref.read(learningRepositoryProvider);
    if (learner == null || repo == null) return;
    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });
    try {
      final updated = await repo.upsertLessonProgress(
        learnerId: learner.id,
        lessonId: widget.lessonId,
        readingProgressPercent: complete ? 100 : _readingProgress.round(),
        markCompleted: complete,
      );
      ref.invalidate(activeLearnerLearningCatalogProvider);
      if (mounted) {
        setState(() {
          _readingProgress = updated.readingProgressPercent.toDouble();
          _statusMessage = complete
              ? AppLocalizations.of(context)!.lessonCompletedMessage
              : AppLocalizations.of(context)!.lessonProgressSavedMessage(
                  updated.readingProgressPercent,
                );
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = error.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeLearner = ref.watch(activeLearnerProvider);
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));

    if (activeLearner == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.selectActiveLearnerTitle),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(AppRoutes.learn),
                child: Text(l10n.learningHubTitle),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: lessonAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                AuthInlineMessage(message: l10n.requestFailed, isError: true),
            data: (lesson) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.learn),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.learningHubTitle),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${activeLearner.fullName} • ${lesson.estimatedMinutes} min',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  if (lesson.summary != null &&
                      lesson.summary!.isNotEmpty) ...[
                    AppCard(
                      child: Text(
                        lesson.summary!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _InteractiveLessonBlocksView(
                    blocks: lesson.effectiveContentBlocks,
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.readingProgressLabel(_readingProgress.round()),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Slider(
                          value: _readingProgress,
                          min: 0,
                          max: 100,
                          divisions: 4,
                          label: '${_readingProgress.round()}%',
                          onChanged: _isSaving
                              ? null
                              : (val) => setState(() => _readingProgress = val),
                        ),
                        if (_statusMessage != null) ...[
                          AuthInlineMessage(
                            message: _statusMessage!,
                            isError: false,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _saveProgress(complete: false),
                              child: Text(l10n.saveProgressAction),
                            ),
                            FilledButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _saveProgress(complete: true),
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(l10n.markLessonCompletedAction),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () => context.go(
                                AppRoutes.lessonQuiz(widget.lessonId),
                              ),
                              icon: const Icon(Icons.quiz_outlined),
                              label: Text(l10n.takePracticeQuizAction),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class PracticeQuizScreen extends ConsumerStatefulWidget {
  const PracticeQuizScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  ConsumerState<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends ConsumerState<PracticeQuizScreen> {
  final Map<String, int> _selectedOptions = {};
  QuizSubmissionResult? _submissionResult;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Modern multi-type assessment state
  final Map<String, dynamic> _assessmentAnswers = {};
  AssessmentSubmissionResult? _assessmentResult;

  Future<void> _submitQuiz(PracticeQuiz quiz) async {
    final learner = ref.read(activeLearnerProvider);
    final repo = ref.read(learningRepositoryProvider);
    if (learner == null || repo == null) return;
    if (quiz.questions.any((q) => !_selectedOptions.containsKey(q.id))) {
      setState(
        () => _errorMessage =
            AppLocalizations.of(context)!.answerAllQuestionsError,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final indices = [
        for (final q in quiz.questions) _selectedOptions[q.id]!,
      ];
      final result = await repo.submitQuizAttempt(
        learnerId: learner.id,
        quizId: quiz.id,
        selectedIndices: indices,
      );
      ref.invalidate(activeLearnerLearningCatalogProvider);
      if (mounted) {
        setState(() => _submissionResult = result);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitAssessment({
    required String topicId,
    required List<QuestionBankItem> questions,
  }) async {
    final learner = ref.read(activeLearnerProvider);
    final repo = ref.read(learningRepositoryProvider);
    if (learner == null || repo == null) return;

    if (questions.any((q) => !_assessmentAnswers.containsKey(q.id))) {
      setState(
        () => _errorMessage =
            AppLocalizations.of(context)!.answerAllQuestionsError,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final payload = [
        for (final q in questions)
          {
            'question_id': q.id,
            'answer': _assessmentAnswers[q.id],
          },
      ];
      final result = await repo.submitAssessmentAttempt(
        learnerId: learner.id,
        topicId: topicId,
        answers: payload,
      );
      ref.invalidate(activeLearnerLearningCatalogProvider);
      if (mounted) {
        setState(() => _assessmentResult = result);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeLearner = ref.watch(activeLearnerProvider);
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));
    final quizAsync = ref.watch(lessonQuizProvider(widget.lessonId));

    if (activeLearner == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: FilledButton(
            onPressed: () => context.go(AppRoutes.learn),
            child: Text(l10n.learningHubTitle),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: lessonAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                AuthInlineMessage(message: l10n.requestFailed, isError: true),
            data: (lesson) {
              final topicQuestionsAsync =
                  ref.watch(topicAssessmentQuestionsProvider(lesson.topicId));

              return topicQuestionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _buildLegacyQuizView(context, quizAsync, l10n),
                data: (topicQuestions) {
                  if (topicQuestions.isNotEmpty) {
                    return _buildModernAssessmentView(
                      context,
                      lesson,
                      topicQuestions,
                      l10n,
                    );
                  }
                  return _buildLegacyQuizView(context, quizAsync, l10n);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModernAssessmentView(
    BuildContext context,
    LearningLesson lesson,
    List<QuestionBankItem> questions,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.go(AppRoutes.lessonReader(widget.lessonId)),
          icon: const Icon(Icons.arrow_back),
          label: Text(l10n.backToLessonAction),
        ),
        const SizedBox(height: 8),
        Text(
          lesson.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        if (_assessmentResult != null) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _assessmentResult!.passed
                            ? l10n.assessmentPassedTitle(
                                _assessmentResult!.scorePercent,
                              )
                            : l10n.assessmentTryAgainTitle(
                                _assessmentResult!.scorePercent,
                              ),
                        key: const ValueKey('quiz-result-heading'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _buildMasteryPill(context, _assessmentResult!.masteryStatus, l10n),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.assessmentScoreSummary(
                    _assessmentResult!.correctCount,
                    _assessmentResult!.totalQuestions,
                    _masteryLabel(_assessmentResult!.masteryStatus, l10n),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.learn),
                  child: Text(l10n.backToLearningHubAction),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_errorMessage != null) ...[
          AuthInlineMessage(message: _errorMessage!, isError: true),
          const SizedBox(height: 12),
        ],
        for (final (qIndex, q) in questions.indexed) ...[
          _buildQuestionBankCard(context, qIndex, q, l10n),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          key: const ValueKey('submit-quiz-button'),
          onPressed: _isSubmitting
              ? null
              : () => _submitAssessment(
                    topicId: lesson.topicId,
                    questions: questions,
                  ),
          icon: const Icon(Icons.send_outlined),
          label: Text(l10n.submitQuizAction),
        ),
      ],
    );
  }

  Widget _buildMasteryPill(
    BuildContext context,
    String status,
    AppLocalizations l10n,
  ) {
    Color bg;
    Color fg;
    IconData icon;
    if (status == 'mastered') {
      bg = LearnTzColors.accent100;
      fg = LearnTzColors.accent900;
      icon = Icons.stars;
    } else if (status == 'proficient') {
      bg = LearnTzColors.successBg;
      fg = LearnTzColors.successText;
      icon = Icons.verified;
    } else {
      bg = LearnTzColors.infoBg;
      fg = LearnTzColors.infoText;
      icon = Icons.timelapse;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Text(
            _masteryLabel(status, l10n),
            style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _masteryLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'mastered':
        return l10n.masteryStatusMastered;
      case 'proficient':
        return l10n.masteryStatusProficient;
      default:
        return l10n.masteryStatusInProgress;
    }
  }

  Widget _buildQuestionBankCard(
    BuildContext context,
    int qIndex,
    QuestionBankItem q,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final graded = _assessmentResult?.results
        .where((r) => r.questionId == q.id)
        .firstOrNull;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(
                label: Text(
                  _questionTypeLabel(q.questionType, l10n),
                  style: const TextStyle(fontSize: 11),
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Text(
                q.difficultyLevel.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (graded != null)
                Icon(
                  graded.isCorrect ? Icons.check_circle : Icons.cancel,
                  color: graded.isCorrect ? Colors.green : Colors.red,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${qIndex + 1}. ${q.questionText}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildQuestionInput(context, q, l10n),
          if (graded != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: graded.isCorrect
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!graded.isCorrect) ...[
                    Text(
                      l10n.correctAnswerLabel(graded.correctAnswer.toString()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (graded.explanation.isNotEmpty)
                    Text(
                      '${l10n.explanationLabel}: ${graded.explanation}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionInput(
    BuildContext context,
    QuestionBankItem q,
    AppLocalizations l10n,
  ) {
    switch (q.questionType) {
      case 'true_false':
        final current = _assessmentAnswers[q.id] as bool?;
        return Row(
          children: [
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: current == true
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
              ),
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() => _assessmentAnswers[q.id] = true),
              child: Text(l10n.trueOption),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: current == false
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
              ),
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() => _assessmentAnswers[q.id] = false),
              child: Text(l10n.falseOption),
            ),
          ],
        );

      case 'fill_in_the_blank':
        return TextFormField(
          initialValue: _assessmentAnswers[q.id]?.toString(),
          decoration: InputDecoration(
            hintText: l10n.fillBlankHint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          enabled: !_isSubmitting,
          onChanged: (val) => _assessmentAnswers[q.id] = val.trim(),
        );

      case 'short_answer':
        return TextFormField(
          initialValue: _assessmentAnswers[q.id]?.toString(),
          decoration: InputDecoration(
            hintText: l10n.shortAnswerHint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 2,
          enabled: !_isSubmitting,
          onChanged: (val) => _assessmentAnswers[q.id] = val.trim(),
        );

      case 'matching':
        final currentMap =
            (_assessmentAnswers[q.id] as Map<String, dynamic>?) ?? {};
        return Column(
          children: [
            for (final p in q.matchingPremises) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        p.text,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.arrow_forward, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('matching-${q.id}-${p.id}'),
                        initialValue: currentMap[p.id]?.toString(),
                        hint: Text(
                          l10n.matchingSelectPlaceholder,
                          style: const TextStyle(fontSize: 12),
                        ),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        items: [
                          for (final r in q.matchingResponses)
                            DropdownMenuItem<String>(
                              value: r.id,
                              child: Text(r.text),
                            ),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    final updated = Map<String, dynamic>.from(
                                      currentMap,
                                    );
                                    updated[p.id] = val;
                                    _assessmentAnswers[q.id] = updated;
                                  });
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

      case 'multiple_choice':
      default:
        final options = q.options ?? const [];
        return RadioGroup<int>(
          groupValue: _assessmentAnswers[q.id] as int?,
          onChanged: _isSubmitting
              ? (_) {}
              : (val) {
                  if (val != null) {
                    setState(() => _assessmentAnswers[q.id] = val);
                  }
                },
          child: Column(
            children: [
              for (final (optIndex, option) in options.indexed)
                RadioListTile<int>(
                  value: optIndex,
                  title: Text(option),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        );
    }
  }

  String _questionTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'multiple_choice':
        return l10n.questionTypeMultipleChoice;
      case 'true_false':
        return l10n.questionTypeTrueFalse;
      case 'fill_in_the_blank':
        return l10n.questionTypeFillBlank;
      case 'matching':
        return l10n.questionTypeMatching;
      case 'short_answer':
        return l10n.questionTypeShortAnswer;
      default:
        return type;
    }
  }

  Widget _buildLegacyQuizView(
    BuildContext context,
    AsyncValue<PracticeQuiz?> quizAsync,
    AppLocalizations l10n,
  ) {
    return quizAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          AuthInlineMessage(message: l10n.requestFailed, isError: true),
      data: (quiz) {
        if (quiz == null) {
          return AppCard(child: Text(l10n.noQuizForLesson));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () =>
                  context.go(AppRoutes.lessonReader(widget.lessonId)),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.backToLessonAction),
            ),
            const SizedBox(height: 8),
            Text(
              quiz.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            if (_submissionResult != null) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _submissionResult!.passed
                          ? l10n.quizPassedTitle(
                              _submissionResult!.scorePercent,
                            )
                          : l10n.quizTryAgainTitle(
                              _submissionResult!.scorePercent,
                            ),
                      key: const ValueKey('quiz-result-heading'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.quizScoreSummary(
                        _submissionResult!.correctCount,
                        _submissionResult!.totalQuestions,
                        _submissionResult!.bestQuizScorePercent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.learn),
                      child: Text(l10n.backToLearningHubAction),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_errorMessage != null) ...[
              AuthInlineMessage(message: _errorMessage!, isError: true),
              const SizedBox(height: 12),
            ],
            for (final (qIndex, q) in quiz.questions.indexed) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${qIndex + 1}. ${q.prompt}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<int>(
                      groupValue: _selectedOptions[q.id],
                      onChanged: _isSubmitting
                          ? (_) {}
                          : (val) {
                              if (val != null) {
                                setState(() => _selectedOptions[q.id] = val);
                              }
                            },
                      child: Column(
                        children: [
                          for (final (optIndex, option) in q.options.indexed)
                            RadioListTile<int>(
                              value: optIndex,
                              title: Text(option),
                              contentPadding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ),
                    if (_submissionResult != null &&
                        qIndex < _submissionResult!.results.length &&
                        _submissionResult!
                            .results[qIndex]
                            .explanation
                            .isNotEmpty)
                      Text(
                        _submissionResult!.results[qIndex].explanation,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              key: const ValueKey('submit-quiz-button'),
              onPressed: _isSubmitting ? null : () => _submitQuiz(quiz),
              icon: const Icon(Icons.send_outlined),
              label: Text(l10n.submitQuizAction),
            ),
          ],
        );
      },
    );
  }
}

class _InteractiveLessonBlocksView extends StatelessWidget {
  const _InteractiveLessonBlocksView({required this.blocks});

  final List<LessonContentBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks) ...[
          _buildBlock(context, block),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildBlock(BuildContext context, LessonContentBlock block) {
    switch (block.type) {
      case 'callout':
        return _CalloutBlockWidget(block: block);
      case 'definition':
        return _DefinitionBlockWidget(block: block);
      case 'example':
        return _ExampleBlockWidget(block: block);
      case 'diagram':
        return _DiagramBlockWidget(block: block);
      case 'checkpoint':
        return _InlineCheckpointWidget(block: block);
      case 'markdown':
      default:
        final paragraphs = (block.body ?? '')
            .split('\n\n')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final p in paragraphs) ...[
                Text(
                  p
                      .replaceAll('# ', '')
                      .replaceAll('## ', '')
                      .replaceAll('### ', ''),
                  style: p.startsWith('#')
                      ? Theme.of(context).textTheme.titleLarge
                      : Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
    }
  }
}

class _CalloutBlockWidget extends StatelessWidget {
  const _CalloutBlockWidget({required this.block});

  final LessonContentBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWarning = block.style == 'warning';
    final isTip = block.style == 'tip';

    final Color accentColor = isWarning
        ? Colors.amber.shade700
        : isTip
            ? Colors.green.shade700
            : theme.colorScheme.primary;

    final IconData iconData = isWarning
        ? Icons.warning_amber_rounded
        : isTip
            ? Icons.lightbulb_outline
            : Icons.info_outline;

    return AppCard(
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accentColor, width: 4)),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    block.title ??
                        (isTip ? 'Tip' : isWarning ? 'Warning' : 'Note'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (block.content != null && block.content!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                block.content!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DefinitionBlockWidget extends StatelessWidget {
  const _DefinitionBlockWidget({required this.block});

  final LessonContentBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(
                avatar: const Icon(Icons.bookmark_outline, size: 16),
                label: Text(l10n.definitionLabel),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              if (block.pronunciation != null) ...[
                const SizedBox(width: 8),
                Text(
                  block.pronunciation!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            block.term ?? '',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            block.definition ?? '',
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
          if (block.example != null && block.example!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${l10n.exampleLabel}: ${block.example!}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExampleBlockWidget extends StatelessWidget {
  const _ExampleBlockWidget({required this.block});

  final LessonContentBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                block.title ?? l10n.exampleLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (block.problem != null) ...[
            const SizedBox(height: 8),
            Text(block.problem!, style: theme.textTheme.bodyLarge),
          ],
          if (block.steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final (index, step) in block.steps.indexed) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(step, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ],
          ],
          if (block.takeaway != null && block.takeaway!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.takeawayLabel}: ${block.takeaway!}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiagramBlockWidget extends StatelessWidget {
  const _DiagramBlockWidget({required this.block});

  final LessonContentBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                  if (block.altText != null) ...[
                    const SizedBox(height: 8),
                    Text(block.altText!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
          if (block.caption != null) ...[
            const SizedBox(height: 8),
            Text(
              block.caption!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineCheckpointWidget extends StatefulWidget {
  const _InlineCheckpointWidget({required this.block});

  final LessonContentBlock block;

  @override
  State<_InlineCheckpointWidget> createState() =>
      _InlineCheckpointWidgetState();
}

class _InlineCheckpointWidgetState extends State<_InlineCheckpointWidget> {
  int? _selectedIndex;
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isCorrect = _selectedIndex == widget.block.correctIndex;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.quiz_outlined,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.checkpointTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (widget.block.question != null) ...[
            const SizedBox(height: 8),
            Text(widget.block.question!, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: 12),
          RadioGroup<int>(
            groupValue: _selectedIndex,
            onChanged: _checked
                ? (_) {}
                : (val) {
                    if (val != null) {
                      setState(() => _selectedIndex = val);
                    }
                  },
            child: Column(
              children: [
                for (final (idx, opt) in widget.block.options.indexed)
                  RadioListTile<int>(
                    value: idx,
                    title: Text(opt),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (!_checked)
            FilledButton.tonal(
              onPressed: _selectedIndex != null
                  ? () => setState(() => _checked = true)
                  : null,
              child: Text(l10n.checkAnswerAction),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrect
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel_outlined,
                        color: isCorrect ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCorrect
                            ? l10n.checkpointCorrect
                            : l10n.checkpointIncorrect,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (widget.block.explanation != null &&
                      widget.block.explanation!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.block.explanation!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LearnerDailyTargetAndResumeSection extends ConsumerWidget {
  const _LearnerDailyTargetAndResumeSection({required this.learnerId});

  final String learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dashboardAsync = ref.watch(learnerDashboardDataProvider(learnerId));

    return dashboardAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.bolt, color: Colors.amber),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.dailyGoalTitle}: ${data.todayCompletedLessons}/${data.dailyTargetLessons} ${l10n.lessonsCompletedLabel}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          data.activeTermName != null
                              ? '${l10n.activeTermLabel}: ${data.activeTermName}'
                              : '${data.dailyTargetMinutes} ${l10n.targetMinutesLabel}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    avatar: const Icon(
                      Icons.local_fire_department,
                      size: 18,
                      color: Colors.deepOrange,
                    ),
                    label: Text('${data.streakDays} ${l10n.streakDaysSuffix}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (data.resumeLesson != null) ...[
              AppCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      size: 36,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.resumeLearningTitle,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '${data.resumeLesson!.subjectName}: ${data.resumeLesson!.lessonTitle}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: (data.resumeLesson!.readingProgressPercent
                                    .clamp(0, 100)) /
                                100.0,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => context.go(
                        AppRoutes.lessonReader(data.resumeLesson!.lessonId),
                      ),
                      child: Text(l10n.continueAction),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _OfflineSyncStatusBar extends ConsumerWidget {
  const _OfflineSyncStatusBar({required this.learnerId});

  final String learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final syncState = ref.watch(offlineSyncNotifierProvider);
    final hasPending = syncState.pendingCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: hasPending
            ? Colors.amber.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasPending
              ? Colors.amber.withValues(alpha: 0.4)
              : Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPending ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
            size: 20,
            color: hasPending ? Colors.amber.shade800 : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasPending
                  ? l10n.syncStatusPending(syncState.pendingCount)
                  : l10n.syncStatusSynced,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: hasPending ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ),
          if (hasPending)
            FilledButton.tonal(
              onPressed: syncState.isSyncing
                  ? null
                  : () async {
                      final result = await ref
                          .read(offlineSyncNotifierProvider.notifier)
                          .flushQueue(learnerId);
                      if (context.mounted && result != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.syncSuccessMessage)),
                        );
                      }
                    },
              child: syncState.isSyncing
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.syncingAction),
                      ],
                    )
                  : Text(l10n.syncNowAction),
            ),
        ],
      ),
    );
  }
}

class _LearnerRecommendationsSection extends ConsumerWidget {
  const _LearnerRecommendationsSection({required this.learnerId});

  final String learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recsAsync = ref.watch(learnerRecommendationsProvider(learnerId));

    return recsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (recommendations) {
        if (recommendations.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.recommendationsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.recommendationsSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final rec in recommendations) ...[
              _RecommendationCard(
                recommendation: rec,
                learnerId: learnerId,
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _RecommendationCard extends ConsumerStatefulWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.learnerId,
  });

  final LearnerRecommendation recommendation;
  final String learnerId;

  @override
  ConsumerState<_RecommendationCard> createState() =>
      _RecommendationCardState();
}

class _RecommendationCardState extends ConsumerState<_RecommendationCard> {
  bool _isDismissing = false;

  Future<void> _dismiss() async {
    final repo = ref.read(learningRepositoryProvider);
    if (repo == null) return;
    setState(() => _isDismissing = true);
    try {
      await repo.dismissLearnerRecommendation(
        learnerId: widget.learnerId,
        recommendationId: widget.recommendation.id,
      );
      ref.invalidate(learnerRecommendationsProvider(widget.learnerId));
    } catch (_) {
      if (mounted) setState(() => _isDismissing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final rec = widget.recommendation;

    Color badgeBg;
    Color badgeFg;
    String badgeText;
    IconData badgeIcon;

    if (rec.recommendationType == 'remedial') {
      badgeBg = Colors.orange.shade100;
      badgeFg = Colors.orange.shade900;
      badgeText = l10n.remedialPill;
      badgeIcon = Icons.fitness_center;
    } else if (rec.recommendationType == 'advanced') {
      badgeBg = Colors.purple.shade100;
      badgeFg = Colors.purple.shade900;
      badgeText = l10n.advancedPill;
      badgeIcon = Icons.trending_up;
    } else {
      badgeBg = Colors.blue.shade100;
      badgeFg = Colors.blue.shade900;
      badgeText = l10n.spacedRepetitionPill;
      badgeIcon = Icons.update;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeFg),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeFg,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rec.subjectName,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: l10n.dismissRecommendationAction,
                onPressed: _isDismissing ? null : _dismiss,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(rec.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(rec.reason, style: theme.textTheme.bodyMedium),
          if (rec.lessonId != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () =>
                  context.go(AppRoutes.lessonReader(rec.lessonId!)),
              icon: const Icon(Icons.play_arrow_outlined, size: 18),
              label: Text(l10n.startRecommendedLessonAction),
            ),
          ],
        ],
      ),
    );
  }
}

class _LearnerMasteryOverviewSection extends ConsumerWidget {
  const _LearnerMasteryOverviewSection({required this.learnerId});

  final String learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reportAsync = ref.watch(learnerMasteryReportProvider(learnerId));

    return reportAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (report) {
        if (report.totalTopics == 0) return const SizedBox.shrink();

        final theme = Theme.of(context);
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights_outlined,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.masteryReportTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.speed, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${report.readinessIndex}% ${l10n.readinessIndexLabel}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildMasteryTierStat(
                    context,
                    count: report.masteredTopics,
                    label: l10n.topicsMasteredLabel,
                    color: Colors.amber.shade700,
                  ),
                  _buildMasteryTierStat(
                    context,
                    count: report.proficientTopics,
                    label: l10n.topicsProficientLabel,
                    color: Colors.green.shade700,
                  ),
                  _buildMasteryTierStat(
                    context,
                    count: report.inProgressTopics,
                    label: l10n.topicsInProgressLabel,
                    color: Colors.blue.shade700,
                  ),
                  _buildMasteryTierStat(
                    context,
                    count: report.notStartedTopics,
                    label: l10n.topicsNotStartedLabel,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
              if (report.overallAccuracyRate > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${l10n.overallAccuracyLabel}: ',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${report.overallAccuracyRate}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMasteryTierStat(
    BuildContext context, {
    required int count,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
