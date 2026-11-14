import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../exam_providers.dart';

class ExamResultsAnalyticsScreen extends ConsumerStatefulWidget {
  const ExamResultsAnalyticsScreen({
    required this.attemptId,
    super.key,
  });

  final String attemptId;

  @override
  ConsumerState<ExamResultsAnalyticsScreen> createState() =>
      _ExamResultsAnalyticsScreenState();
}

class _ExamResultsAnalyticsScreenState
    extends ConsumerState<ExamResultsAnalyticsScreen> {
  bool _showItemizedReview = false;

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(examResultsProvider(widget.attemptId));

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: resultsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Center(
          child: AppCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: LearnTzColors.error),
                  const SizedBox(height: 12),
                  Text('Failed to load examination results: $err'),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Back to Exam Centre',
                    onPressed: () => context.go(AppRoutes.examCentre),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (result) {
          if (result == null) {
            return const Center(child: Text('No results found for this attempt'));
          }

          final isHighPass = result.percentage >= 65.0;
          final isCreditPass = result.percentage >= 45.0 && result.percentage < 65.0;
          final gradeColor = isHighPass
              ? LearnTzColors.success
              : isCreditPass
                  ? LearnTzColors.warning
                  : LearnTzColors.error;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.analytics_outlined,
                                color: LearnTzColors.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Examination Intelligence & Performance',
                                  style: LearnTzTypography.h2.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: LearnTzColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.title,
                            style: LearnTzTypography.bodyRegular.copyWith(
                              color: LearnTzColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    AppButton(
                      label: 'Exam Centre',
                      icon: Icons.assignment_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => context.go(AppRoutes.examCentre),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Hero Performance Card
                AppCard(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Circular Gauge or Score Banner
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: gradeColor.withValues(alpha: 0.1),
                                border: Border.all(color: gradeColor, width: 3),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${result.percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: gradeColor,
                                    ),
                                  ),
                                  Text(
                                    'SCORE',
                                    style: LearnTzTypography.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: gradeColor,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PREDICTED OUTCOME',
                                    style: LearnTzTypography.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      color: LearnTzColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    result.predictedDivisionOrGrade,
                                    style: LearnTzTypography.h1.copyWith(
                                      color: gradeColor,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total Marks: ${result.totalScore.toStringAsFixed(1)} / ${result.totalPossibleMarks.toStringAsFixed(0)} • Grading Standard: ${result.gradingSystem.toUpperCase()}',
                                    style: LearnTzTypography.caption.copyWith(
                                      color: LearnTzColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section Breakdown
                if (result.sectionBreakdown.isNotEmpty) ...[
                  Text(
                    'Sectional Mastery Breakdown',
                    style: LearnTzTypography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: result.sectionBreakdown.map((sec) {
                      final secColor = sec.percentage >= 65.0
                          ? LearnTzColors.success
                          : sec.percentage >= 45.0
                              ? LearnTzColors.warning
                              : LearnTzColors.error;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Section ${sec.sectionCode}',
                                      style: LearnTzTypography.h4.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${sec.percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: secColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: sec.percentage / 100.0,
                                    backgroundColor: LearnTzColors.neutral200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        secColor),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${sec.score.toStringAsFixed(1)} / ${sec.possible.toStringAsFixed(0)} Marks',
                                  style: LearnTzTypography.caption.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Topic Deficits Card
                if (result.topicDeficits.isNotEmpty) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: LearnTzColors.warning, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Targeted Topic Deficits Identified (<60% Mastery)',
                              style: LearnTzTypography.h4.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Our diagnostic engine detected learning gaps in the following syllabus topics during this simulation:',
                          style: LearnTzTypography.bodyRegular.copyWith(
                            color: LearnTzColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: result.topicDeficits.map((td) {
                            return Chip(
                              backgroundColor:
                                  LearnTzColors.warning.withValues(alpha: 0.12),
                              side: const BorderSide(
                                  color: LearnTzColors.warning),
                              avatar: const Icon(Icons.flag_outlined,
                                  size: 16, color: LearnTzColors.warning),
                              label: Text(
                                '${td.title} (${td.accuracyPct.toStringAsFixed(0)}%)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Remedial Study Plan with Direct Phase 2 Links
                if (result.remedialLessons.isNotEmpty ||
                    result.remedialFlashcards.isNotEmpty) ...[
                  Text(
                    'Personalised Remedial Study Plan',
                    style: LearnTzTypography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recommended lessons and revision flashcards automatically generated from your performance deficit profile:',
                    style: LearnTzTypography.bodyRegular.copyWith(
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Remedial Lessons
                  if (result.remedialLessons.isNotEmpty) ...[
                    ...result.remedialLessons.map((les) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: LearnTzColors.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.menu_book,
                                  color: LearnTzColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      les.title,
                                      style:
                                          LearnTzTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${les.estimatedMinutes} min interactive lesson',
                                      style: LearnTzTypography.caption,
                                    ),
                                  ],
                                ),
                              ),
                              AppButton(
                                label: 'Study Lesson',
                                icon: Icons.arrow_forward,
                                variant: AppButtonVariant.primary,
                                size: AppButtonSize.sm,
                                onPressed: () {
                                  context.go(AppRoutes.lessonReader(les.lessonId));
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  // Remedial Flashcards
                  if (result.remedialFlashcards.isNotEmpty) ...[
                    ...result.remedialFlashcards.map((deck) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: LearnTzColors.accent
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.style_outlined,
                                  color: LearnTzColors.accent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      deck.title,
                                      style:
                                          LearnTzTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${deck.cardCount} active revision flashcards',
                                      style: LearnTzTypography.caption,
                                    ),
                                  ],
                                ),
                              ),
                              AppButton(
                                label: 'Revise Deck',
                                icon: Icons.style,
                                variant: AppButtonVariant.secondary,
                                size: AppButtonSize.sm,
                                onPressed: () {
                                  context.go(AppRoutes.flashcardStudy(deck.deckId));
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),
                ],

                // Itemized Question Review Toggle Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Detailed Question-by-Question Marking Review',
                        style: LearnTzTypography.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: _showItemizedReview
                          ? 'Hide Detailed Review'
                          : 'Show Detailed Review',
                      icon: _showItemizedReview
                          ? Icons.expand_less
                          : Icons.expand_more,
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.sm,
                      onPressed: () {
                        setState(() {
                          _showItemizedReview = !_showItemizedReview;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Itemized Review Cards List
                if (_showItemizedReview &&
                    result.questionsReview.isNotEmpty) ...[
                  ...result.questionsReview.map((q) {
                    final isCorrect = q.isFullMarks;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    AppBadge(
                                      label: q.label,
                                      variant: AppBadgeVariant.primary,
                                    ),
                                    AppBadge(
                                      label:
                                          '${q.marksAwarded.toStringAsFixed(1)} / ${q.marks.toStringAsFixed(0)} Marks',
                                      variant: isCorrect
                                          ? AppBadgeVariant.success
                                          : q.isZeroMarks
                                              ? AppBadgeVariant.error
                                              : AppBadgeVariant.warning,
                                    ),
                                  ],
                                ),
                                Icon(
                                  isCorrect
                                      ? Icons.check_circle
                                      : q.isZeroMarks
                                          ? Icons.cancel
                                          : Icons.change_circle_outlined,
                                  color: isCorrect
                                      ? LearnTzColors.success
                                      : q.isZeroMarks
                                          ? LearnTzColors.error
                                          : LearnTzColors.warning,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              q.questionText,
                              style: LearnTzTypography.bodyRegular.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: LearnTzColors.neutral50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Answer: ${q.learnerAnswer ?? '(No response submitted)'}',
                                    style: LearnTzTypography.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isCorrect
                                          ? LearnTzColors.success
                                          : LearnTzColors.error,
                                    ),
                                  ),
                                  if (q.correctAnswer != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Official Solution: ${q.correctAnswer}',
                                      style:
                                          LearnTzTypography.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: LearnTzColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
