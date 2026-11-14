import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../exam_models.dart';
import '../exam_providers.dart';

class ExamQuestionBankScreen extends ConsumerStatefulWidget {
  const ExamQuestionBankScreen({super.key});

  @override
  ConsumerState<ExamQuestionBankScreen> createState() =>
      _ExamQuestionBankScreenState();
}

class _ExamQuestionBankScreenState
    extends ConsumerState<ExamQuestionBankScreen> {
  final _searchController = TextEditingController();
  final Set<String> _revealedAnswers = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleShowAnswer(String questionId) {
    setState(() {
      if (_revealedAnswers.contains(questionId)) {
        _revealedAnswers.remove(questionId);
      } else {
        _revealedAnswers.add(questionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(approvedExamQuestionsProvider);
    final filter = ref.watch(questionBankFilterProvider);

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_stories,
                            color: LearnTzColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'National Exam Question Bank',
                              style: LearnTzTypography.h2.copyWith(
                                color: LearnTzColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Curated, vetted examination questions categorized by Bloom\'s Taxonomy, curriculum topics, and difficulty.',
                        style: LearnTzTypography.bodyRegular.copyWith(
                          color: LearnTzColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      label: 'Exam Centre',
                      icon: Icons.assignment_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => context.go(AppRoutes.examCentre),
                    ),
                    AppButton(
                      label: 'Review Cockpit',
                      icon: Icons.verified_user_outlined,
                      variant: AppButtonVariant.primary,
                      onPressed: () =>
                          context.go(AppRoutes.examQuestionReview),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Search and Filters Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _searchController,
                          label: 'Search Questions',
                          hint: 'Search by keyword, formula, or concept...',
                          prefixIcon: Icons.search,
                          onChanged: (val) {
                            ref
                                .read(questionBankFilterProvider.notifier)
                                .setSearch(val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bloom Taxonomy Filter Chips
                  Text(
                    'Bloom\'s Taxonomy Level:',
                    style: LearnTzTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBloomFilterChip(null, 'All Levels', filter.bloomLevel),
                      _buildBloomFilterChip(
                          'knowledge', 'Knowledge (Recall)', filter.bloomLevel),
                      _buildBloomFilterChip('comprehension',
                          'Comprehension (Understand)', filter.bloomLevel),
                      _buildBloomFilterChip('application',
                          'Application (Calculate)', filter.bloomLevel),
                      _buildBloomFilterChip(
                          'analysis', 'Analysis (Inspect)', filter.bloomLevel),
                      _buildBloomFilterChip(
                          'synthesis', 'Synthesis (Formulate)', filter.bloomLevel),
                      _buildBloomFilterChip(
                          'evaluation', 'Evaluation (Judge)', filter.bloomLevel),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Difficulty Filter Chips
                  Text(
                    'Difficulty Level:',
                    style: LearnTzTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDifficultyFilterChip(
                          null, 'All Difficulties', filter.difficulty),
                      _buildDifficultyFilterChip(
                          'easy', '🟢 Easy', filter.difficulty),
                      _buildDifficultyFilterChip(
                          'medium', '🟡 Medium', filter.difficulty),
                      _buildDifficultyFilterChip(
                          'hard', '🔴 Hard', filter.difficulty),
                      if (filter.bloomLevel != null ||
                          filter.difficulty != null ||
                          filter.searchQuery.isNotEmpty)
                        ActionChip(
                          avatar: const Icon(Icons.clear, size: 16),
                          label: const Text('Reset Filters'),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(questionBankFilterProvider.notifier)
                                .reset();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Questions List
            questionsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: LearnTzColors.error,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load question bank: $err',
                          style: LearnTzTypography.bodyRegular,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (questions) {
                if (questions.isEmpty) {
                  return AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.menu_book,
                              size: 48,
                              color: LearnTzColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No questions found matching your filter criteria.',
                              style: LearnTzTypography.h3,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try adjusting Bloom taxonomy, difficulty levels, or search term.',
                              style: LearnTzTypography.bodyRegular.copyWith(
                                color: LearnTzColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: questions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    return _buildQuestionCard(q);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloomFilterChip(
      String? value, String label, String? currentVal) {
    final isSelected = currentVal == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref
            .read(questionBankFilterProvider.notifier)
            .setBloomLevel(isSelected ? null : value);
      },
      selectedColor: LearnTzColors.primary.withValues(alpha: 0.15),
      checkmarkColor: LearnTzColors.primary,
    );
  }

  Widget _buildDifficultyFilterChip(
      String? value, String label, String? currentVal) {
    final isSelected = currentVal == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref
            .read(questionBankFilterProvider.notifier)
            .setDifficulty(isSelected ? null : value);
      },
      selectedColor: LearnTzColors.accent.withValues(alpha: 0.15),
      checkmarkColor: LearnTzColors.accent,
    );
  }

  Widget _buildQuestionCard(ExamExtractedQuestion q) {
    final isAnswerRevealed = _revealedAnswers.contains(q.id);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Section, Q#, Bloom Level, Difficulty, Marks
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppBadge(
                      label: q.fullIdentifier,
                      variant: AppBadgeVariant.primary,
                    ),
                    if (q.tier != null)
                      AppBadge(
                        label: q.tier!.toUpperCase(),
                        variant: AppBadgeVariant.neutral,
                      ),
                    AppBadge(
                      label: q.bloomLevel.toUpperCase(),
                      variant: _bloomVariant(q.bloomLevel),
                    ),
                    AppBadge(
                      label: q.difficulty.toUpperCase(),
                      variant: _difficultyVariant(q.difficulty),
                    ),
                    if (q.topicTitle != null)
                      AppBadge(
                        label: q.topicTitle!,
                        variant: AppBadgeVariant.info,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: LearnTzColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: LearnTzColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '${q.marks.toStringAsFixed(0)} Marks',
                  style: LearnTzTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: LearnTzColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Paper context subtitle
          if (q.paperTitle != null || q.subjectName != null)
            Text(
              '${q.subjectName ?? ''} • ${q.paperTitle ?? ''} (${q.year ?? ''})',
              style: LearnTzTypography.caption.copyWith(
                color: LearnTzColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),

          const SizedBox(height: 12),

          // Question Prompt Text
          SelectableText(
            q.questionText,
            style: LearnTzTypography.bodyRegular.copyWith(
              color: LearnTzColors.textPrimary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Diagram Image if present
          if (q.diagramUrl != null && q.diagramUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                q.diagramUrl!,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  height: 120,
                  color: LearnTzColors.neutral50,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image,
                          color: LearnTzColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Diagram attachment available in paper PDF',
                        style: LearnTzTypography.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Multiple choice options if present
          if (q.questionType == 'multiple_choice' &&
              q.options.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LearnTzColors.neutral50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LearnTzColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Options:',
                    style: LearnTzTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...q.options.map((opt) {
                    final isCorrect =
                        isAnswerRevealed && (opt.isCorrect || opt.key == q.correctAnswer);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? LearnTzColors.success.withValues(alpha: 0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCorrect
                              ? LearnTzColors.success
                              : LearnTzColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCorrect
                                  ? LearnTzColors.success
                                  : LearnTzColors.neutral100,
                            ),
                            child: Text(
                              opt.key,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCorrect
                                    ? Colors.white
                                    : LearnTzColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              opt.text,
                              style: LearnTzTypography.bodyRegular,
                            ),
                          ),
                          if (isCorrect)
                            const Icon(
                              Icons.check_circle,
                              color: LearnTzColors.success,
                              size: 18,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // Rubric Guide if answer revealed
          if (isAnswerRevealed) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LearnTzColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: LearnTzColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.fact_check_outlined,
                        color: LearnTzColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Marking Scheme & Rubric Guide',
                        style: LearnTzTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: LearnTzColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (q.correctAnswer != null && q.correctAnswer!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Correct Answer: ${q.correctAnswer}',
                      style: LearnTzTypography.bodyRegular.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (q.rubricGuide.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...q.rubricGuide.map((step) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Step ${step.step} (${step.marksAwarded.toStringAsFixed(1)}m): ',
                                style: LearnTzTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  step.description,
                                  style: LearnTzTypography.caption,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: isAnswerRevealed ? 'Hide Solution' : 'Show Solution & Rubric',
                icon: isAnswerRevealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                onPressed: () => _toggleShowAnswer(q.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  AppBadgeVariant _bloomVariant(String level) {
    switch (level.toLowerCase()) {
      case 'knowledge':
        return AppBadgeVariant.neutral;
      case 'comprehension':
        return AppBadgeVariant.info;
      case 'application':
        return AppBadgeVariant.success;
      case 'analysis':
        return AppBadgeVariant.primary;
      case 'synthesis':
        return AppBadgeVariant.warning;
      case 'evaluation':
        return AppBadgeVariant.error;
      default:
        return AppBadgeVariant.neutral;
    }
  }

  AppBadgeVariant _difficultyVariant(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return AppBadgeVariant.success;
      case 'medium':
        return AppBadgeVariant.warning;
      case 'hard':
        return AppBadgeVariant.error;
      default:
        return AppBadgeVariant.neutral;
    }
  }
}
