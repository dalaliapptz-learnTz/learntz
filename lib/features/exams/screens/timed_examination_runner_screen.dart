import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../exam_models.dart';
import '../exam_providers.dart';
import '../exam_repository.dart';

class TimedExaminationRunnerScreen extends ConsumerStatefulWidget {
  const TimedExaminationRunnerScreen({
    required this.attemptId,
    super.key,
  });

  final String attemptId;

  @override
  ConsumerState<TimedExaminationRunnerScreen> createState() =>
      _TimedExaminationRunnerScreenState();
}

class _TimedExaminationRunnerScreenState
    extends ConsumerState<TimedExaminationRunnerScreen> {
  Timer? _timer;
  final TextEditingController _structuredAnswerController =
      TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      ref.read(examRunnerProvider.notifier).tick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _structuredAnswerController.dispose();
    super.dispose();
  }

  void _syncCurrentQuestionText(MockRunnerQuestion? q, String? currentAnswer) {
    if (q != null && q.questionType != 'multiple_choice') {
      if (_structuredAnswerController.text != (currentAnswer ?? '')) {
        _structuredAnswerController.text = currentAnswer ?? '';
      }
    }
  }

  String _formatTimer(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00:00';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    return '$hStr:$mStr:$sStr';
  }

  Future<bool> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Examination?'),
        content: const Text(
          'Your answers are automatically saved. However, the countdown timer will continue running in the background until the official end time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay & Continue'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit to Hub'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final attemptAsync = ref.watch(learnerExamAttemptProvider(widget.attemptId));
    final runnerState = ref.watch(examRunnerProvider);
    final repo = ref.watch(examRepositoryProvider);

    return attemptAsync.when(
      loading: () => const Scaffold(
        backgroundColor: LearnTzColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: LearnTzColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: LearnTzColors.error),
              const SizedBox(height: 12),
              Text('Failed to load examination attempt: $err'),
              const SizedBox(height: 16),
              AppButton(
                label: 'Return to Exam Centre',
                onPressed: () => context.go(AppRoutes.examCentre),
              ),
            ],
          ),
        ),
      ),
      data: (attempt) {
        if (attempt == null) {
          return const Scaffold(
            body: Center(child: Text('Exam attempt not found')),
          );
        }

        // Initialize state once when attempt data loads
        if (!_initialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(examRunnerProvider.notifier).initAttempt(attempt);
            final currentQ = attempt.questions.isNotEmpty
                ? attempt.questions.first
                : null;
            if (currentQ != null) {
              final initialAns = attempt.responses[currentQ.questionId]?.learnerAnswer;
              _syncCurrentQuestionText(currentQ, initialAns);
            }
          });
          _initialized = true;
        }

        final currentQuestion = runnerState.currentQuestion;
        final currentAns = currentQuestion != null
            ? runnerState.answers[currentQuestion.questionId]
            : null;
        final isFlagged = currentQuestion != null &&
            runnerState.flaggedQuestionIds.contains(currentQuestion.questionId);

        // Timer badge color
        final timerColor = runnerState.isUrgentTime
            ? LearnTzColors.error
            : runnerState.isCriticalTime
                ? LearnTzColors.warning
                : LearnTzColors.primary;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final shouldPop = await _confirmExit();
            if (shouldPop && context.mounted) {
              context.go(AppRoutes.examCentre);
            }
          },
          child: Scaffold(
            backgroundColor: LearnTzColors.background,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              titleSpacing: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  if (await _confirmExit() && context.mounted) {
                    context.go(AppRoutes.examCentre);
                  }
                },
                tooltip: 'Exit Examination',
              ),
              title: Text(
                attempt.title,
                style: LearnTzTypography.h4.copyWith(
                  fontWeight: FontWeight.w700,
                  color: LearnTzColors.textPrimary,
                ),
              ),
              actions: [
                // Floating Timer Widget in AppBar
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: timerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: timerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, color: timerColor, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimer(runnerState.secondsRemaining),
                        style: LearnTzTypography.caption.copyWith(
                          color: timerColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: runnerState.isExpired
                ? _buildExpiredView(context)
                : currentQuestion == null
                    ? const Center(child: Text('No questions in this examination'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Progress bar
                            _buildProgressBar(runnerState, attempt),

                            const SizedBox(height: 16),

                            // Main Layout: Question Canvas & Side Palette
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth >= 900;
                                if (isWide) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 7,
                                        child: _buildQuestionCanvas(
                                          currentQuestion: currentQuestion,
                                          currentAns: currentAns,
                                          isFlagged: isFlagged,
                                          repo: repo,
                                          runnerState: runnerState,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        flex: 3,
                                        child: _buildQuestionNavigatorPalette(
                                          attempt: attempt,
                                          runnerState: runnerState,
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      _buildQuestionCanvas(
                                        currentQuestion: currentQuestion,
                                        currentAns: currentAns,
                                        isFlagged: isFlagged,
                                        repo: repo,
                                        runnerState: runnerState,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildQuestionNavigatorPalette(
                                        attempt: attempt,
                                        runnerState: runnerState,
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(
      ExamRunnerState runnerState, LearnerExamAttemptData attempt) {
    final answeredCount = runnerState.answers.length;
    final totalCount = attempt.questions.length;
    final fraction = totalCount > 0 ? (answeredCount / totalCount) : 0.0;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: LearnTzColors.neutral200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(LearnTzColors.success),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$answeredCount / $totalCount Answered',
          style: LearnTzTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: LearnTzColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCanvas({
    required MockRunnerQuestion currentQuestion,
    required String? currentAns,
    required bool isFlagged,
    required ExamRepository? repo,
    required ExamRunnerState runnerState,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Identifier & Flags
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppBadge(
                    label: currentQuestion.label,
                    variant: AppBadgeVariant.primary,
                  ),
                  AppBadge(
                    label: '${currentQuestion.marks.toStringAsFixed(0)} Marks',
                    variant: AppBadgeVariant.neutral,
                  ),
                  AppBadge(
                    label: currentQuestion.difficulty.toUpperCase(),
                    variant: AppBadgeVariant.neutral,
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  isFlagged ? Icons.flag : Icons.outlined_flag,
                  color: isFlagged
                      ? LearnTzColors.accent
                      : LearnTzColors.textSecondary,
                ),
                tooltip: isFlagged ? 'Flagged for Review' : 'Flag Question',
                onPressed: () {
                  ref
                      .read(examRunnerProvider.notifier)
                      .toggleFlag(currentQuestion.questionId, repo);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Question Prompt Text
          SelectableText(
            currentQuestion.questionText,
            style: LearnTzTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: LearnTzColors.textPrimary,
              height: 1.5,
            ),
          ),

          // Diagram Image if present
          if (currentQuestion.diagramUrl != null &&
              currentQuestion.diagramUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                currentQuestion.diagramUrl!,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  height: 100,
                  color: LearnTzColors.neutral50,
                  alignment: Alignment.center,
                  child: Text(
                    'Diagram attached to exam paper',
                    style: LearnTzTypography.caption,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Input form based on question type
          if (currentQuestion.questionType == 'multiple_choice' &&
              currentQuestion.options.isNotEmpty) ...[
            ...currentQuestion.options.map((opt) {
              final isSelected = currentAns == opt.key;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    ref.read(examRunnerProvider.notifier).setAnswer(
                          currentQuestion.questionId,
                          opt.key,
                          repo,
                        );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? LearnTzColors.primary.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? LearnTzColors.primary
                            : LearnTzColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? LearnTzColors.primary
                                : LearnTzColors.neutral100,
                          ),
                          child: Text(
                            opt.key,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : LearnTzColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            opt.text,
                            style: LearnTzTypography.bodyRegular.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ] else ...[
            Text(
              'Your Working / Response:',
              style: LearnTzTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: LearnTzColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _structuredAnswerController,
              label: 'Answer',
              hint: 'Write your calculation steps or essay explanation here...',
              maxLines: 5,
              onChanged: (val) {
                ref.read(examRunnerProvider.notifier).setAnswer(
                      currentQuestion.questionId,
                      val,
                      repo,
                    );
              },
            ),
          ],

          const SizedBox(height: 24),

          // Bottom Action Row: Previous, Next, Save indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppButton(
                label: 'Previous',
                icon: Icons.chevron_left,
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.sm,
                onPressed: runnerState.currentQuestionIndex > 0
                    ? () {
                        ref
                            .read(examRunnerProvider.notifier)
                            .previousQuestion();
                        final prevQ = runnerState.attemptData?.questions[
                            runnerState.currentQuestionIndex - 1];
                        if (prevQ != null) {
                          _syncCurrentQuestionText(
                            prevQ,
                            runnerState.answers[prevQ.questionId],
                          );
                        }
                      }
                    : null,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.cloud_done_outlined,
                    color: LearnTzColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Auto-saved',
                    style: LearnTzTypography.caption.copyWith(
                      color: LearnTzColors.success,
                    ),
                  ),
                ],
              ),
              AppButton(
                label: 'Next',
                trailingIcon: Icons.chevron_right,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.sm,
                onPressed: runnerState.attemptData != null &&
                        runnerState.currentQuestionIndex <
                            runnerState.attemptData!.questions.length - 1
                    ? () {
                        ref.read(examRunnerProvider.notifier).nextQuestion();
                        final nextQ = runnerState.attemptData?.questions[
                            runnerState.currentQuestionIndex + 1];
                        if (nextQ != null) {
                          _syncCurrentQuestionText(
                            nextQ,
                            runnerState.answers[nextQ.questionId],
                          );
                        }
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionNavigatorPalette({
    required LearnerExamAttemptData attempt,
    required ExamRunnerState runnerState,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question Navigator',
            style: LearnTzTypography.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Legend
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildLegendItem(LearnTzColors.success, 'Answered'),
              _buildLegendItem(LearnTzColors.accent, 'Flagged'),
              _buildLegendItem(LearnTzColors.primary, 'Current'),
              _buildLegendItem(LearnTzColors.neutral200, 'Unanswered'),
            ],
          ),

          const SizedBox(height: 16),

          // Numbered tiles grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: attempt.questions.length,
            itemBuilder: (context, index) {
              final q = attempt.questions[index];
              final isCurrent = index == runnerState.currentQuestionIndex;
              final isAnswered = runnerState.answers.containsKey(q.questionId) &&
                  runnerState.answers[q.questionId]!.isNotEmpty;
              final isFlagged =
                  runnerState.flaggedQuestionIds.contains(q.questionId);

              Color tileBg = Colors.white;
              Color tileBorder = LearnTzColors.border;
              Color tileText = LearnTzColors.textPrimary;

              if (isCurrent) {
                tileBg = LearnTzColors.primary;
                tileBorder = LearnTzColors.primary;
                tileText = Colors.white;
              } else if (isFlagged) {
                tileBg = LearnTzColors.accent.withValues(alpha: 0.2);
                tileBorder = LearnTzColors.accent;
                tileText = LearnTzColors.accent;
              } else if (isAnswered) {
                tileBg = LearnTzColors.success.withValues(alpha: 0.15);
                tileBorder = LearnTzColors.success;
                tileText = LearnTzColors.success;
              }

              return InkWell(
                onTap: () {
                  ref.read(examRunnerProvider.notifier).selectQuestion(index);
                  _syncCurrentQuestionText(
                    q,
                    runnerState.answers[q.questionId],
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: tileBorder, width: isCurrent ? 2 : 1),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: tileText,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: LearnTzTypography.caption),
      ],
    );
  }

  Widget _buildExpiredView(BuildContext context) {
    return Center(
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.hourglass_empty,
                size: 54,
                color: LearnTzColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Examination Time Concluded',
                style: LearnTzTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All recorded responses have been preserved on the server.\nYou may now proceed to view your results and pedagogical remediation.',
                textAlign: TextAlign.center,
                style: LearnTzTypography.bodyRegular.copyWith(
                  color: LearnTzColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'View Examination Results',
                icon: Icons.analytics_outlined,
                onPressed: () {
                  context.go(AppRoutes.examCentre);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
