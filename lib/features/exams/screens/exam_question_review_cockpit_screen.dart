import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../exam_models.dart';
import '../exam_providers.dart';

class ExamQuestionReviewCockpitScreen extends ConsumerStatefulWidget {
  const ExamQuestionReviewCockpitScreen({super.key});

  @override
  ConsumerState<ExamQuestionReviewCockpitScreen> createState() =>
      _ExamQuestionReviewCockpitScreenState();
}

class _ExamQuestionReviewCockpitScreenState
    extends ConsumerState<ExamQuestionReviewCockpitScreen> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _statusMessage;
  bool _isSuccess = true;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleDecision({
    required String questionId,
    required String decision,
  }) async {
    final repo = ref.read(examRepositoryProvider);
    if (repo == null) return;

    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });

    try {
      final res = await repo.reviewQuestion(
        questionId: questionId,
        decision: decision,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      setState(() {
        _isSuccess = true;
        _statusMessage =
            'Question successfully transitioned to ${res.verificationStatus.toUpperCase()}.';
        _notesController.clear();
      });

      // Invalidate to refresh the question bank
      ref.invalidate(approvedExamQuestionsProvider);
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _statusMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(approvedExamQuestionsProvider);

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top breadcrumbs & header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go(AppRoutes.examBank),
                  tooltip: 'Back to Question Bank',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-Party Question Review Cockpit',
                        style: LearnTzTypography.h2.copyWith(
                          color: LearnTzColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dual-signature quality gate: Questions must be independently verified and approved prior to learner bank publication.',
                        style: LearnTzTypography.bodyRegular.copyWith(
                          color: LearnTzColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Status Banner if available
            if (_statusMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? LearnTzColors.success.withValues(alpha: 0.12)
                      : LearnTzColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess
                        ? LearnTzColors.success
                        : LearnTzColors.error,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error_outline,
                      color: _isSuccess
                          ? LearnTzColors.success
                          : LearnTzColors.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: LearnTzTypography.bodyRegular.copyWith(
                          color: _isSuccess
                              ? LearnTzColors.success
                              : LearnTzColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _statusMessage = null),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Governance Guideline Banner
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: LearnTzColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: LearnTzColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quality & Pedagogy Standards',
                          style: LearnTzTypography.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stage 1 (Verifier): Check question formulation, syllabus topic mapping, and marks.\n'
                          'Stage 2 (Approver): Second staff member confirms pedagogical soundness and publishes.',
                          style: LearnTzTypography.caption.copyWith(
                            color: LearnTzColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Review Note input field
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reviewer Feedback & Notes',
                    style: LearnTzTypography.h4,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter remarks for corrections or verification sign-off:',
                    style: LearnTzTypography.caption.copyWith(
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _notesController,
                    label: 'Audit Notes',
                    hint: 'E.g. Verified against NECTA Form 4 Physics syllabus 2024...',
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // List of questions available for review
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
                    child: Text(
                      'Failed to load questions: $err',
                      style: LearnTzTypography.bodyRegular,
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
                              Icons.task_alt,
                              size: 48,
                              color: LearnTzColors.success,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Review Queue Clean',
                              style: LearnTzTypography.h3,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All extracted questions have completed two-party review.',
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
                    return _buildReviewCard(q);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ExamExtractedQuestion q) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    AppBadge(
                      label: 'STATUS: ${q.verificationStatus.toUpperCase()}',
                      variant: q.isApproved
                          ? AppBadgeVariant.success
                          : q.isVerified
                              ? AppBadgeVariant.info
                              : AppBadgeVariant.warning,
                    ),
                    AppBadge(
                      label: 'BLOOM: ${q.bloomLevel.toUpperCase()}',
                      variant: AppBadgeVariant.neutral,
                    ),
                    AppBadge(
                      label: 'DIFF: ${q.difficulty.toUpperCase()}',
                      variant: AppBadgeVariant.neutral,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${q.marks.toStringAsFixed(0)} Marks',
                style: LearnTzTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: LearnTzColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (q.paperTitle != null)
            Text(
              '${q.subjectName ?? ''} • ${q.paperTitle!} (${q.year ?? ''})',
              style: LearnTzTypography.caption.copyWith(
                color: LearnTzColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),

          const SizedBox(height: 12),

          SelectableText(
            q.questionText,
            style: LearnTzTypography.bodyRegular.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),

          if (q.rubricGuide.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: LearnTzColors.neutral50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rubric Breakdown (${q.rubricGuide.length} steps):',
                    style: LearnTzTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...q.rubricGuide.map((step) => Text(
                        '• Step ${step.step} (${step.marksAwarded}m): ${step.description}',
                        style: LearnTzTypography.caption,
                      )),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action buttons: Verify, Approve, Reject
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                label: '1. Verify Question',
                icon: Icons.check,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                isLoading: _isSubmitting,
                onPressed: () => _handleDecision(
                  questionId: q.id,
                  decision: 'verified',
                ),
              ),
              AppButton(
                label: '2. Approve & Publish',
                icon: Icons.verified,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.sm,
                isLoading: _isSubmitting,
                onPressed: () => _handleDecision(
                  questionId: q.id,
                  decision: 'approved',
                ),
              ),
              AppButton(
                label: 'Request Changes',
                icon: Icons.replay,
                variant: AppButtonVariant.destructive,
                size: AppButtonSize.sm,
                isLoading: _isSubmitting,
                onPressed: () => _handleDecision(
                  questionId: q.id,
                  decision: 'changes_requested',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
