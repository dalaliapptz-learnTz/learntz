import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/state/app_providers.dart';
import '../exam_models.dart';
import '../exam_providers.dart';

class MockIntelligenceDashboardScreen extends ConsumerStatefulWidget {
  const MockIntelligenceDashboardScreen({super.key});

  @override
  ConsumerState<MockIntelligenceDashboardScreen> createState() =>
      _MockIntelligenceDashboardScreenState();
}

class _MockIntelligenceDashboardScreenState
    extends ConsumerState<MockIntelligenceDashboardScreen> {
  int? _selectedYear = 2024;

  @override
  Widget build(BuildContext context) {
    final selectedCountry = ref.watch(selectedCountryProvider);
    final countryCode = selectedCountry.countryCode;

    final leaderboardAsync = ref.watch(
      mockIntelligenceLeaderboardProvider((
        countryCode: countryCode,
        year: _selectedYear,
      )),
    );

    final topicFrequencyAsync = ref.watch(
      historicalTopicFrequencyProvider((
        subjectId: null,
        countryCode: countryCode,
      )),
    );

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation & Header
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
                            Icons.insights,
                            color: LearnTzColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mock-to-Real Examination Intelligence',
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
                        'Empirical calibration measuring how closely regional & district mocks predict official national exams.',
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
                      label: 'Question Bank',
                      icon: Icons.auto_stories,
                      variant: AppButtonVariant.primary,
                      onPressed: () => context.go(AppRoutes.examBank),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Filter Bar (Year Filter & Stats)
            AppCard(
              child: Row(
                children: [
                  Text(
                    'Examination Year:',
                    style: LearnTzTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildYearFilterChip(null, 'All Years'),
                      _buildYearFilterChip(2026, '2026 (Live)'),
                      _buildYearFilterChip(2025, '2025'),
                      _buildYearFilterChip(2024, '2024 (Calibrated)'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Methodology Guideline
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: LearnTzColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      color: LearnTzColors.accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Predictive Validity Calibration Engine',
                          style: LearnTzTypography.h4.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The Predictive Validity Index evaluates: (1) Jaccard topic set overlap with the real national examination (60% weight), and (2) Bloom taxonomy cognitive difficulty alignment (40% weight).',
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

            // Section 1: Regional Mock Predictive Validity Leaderboard
            Text(
              'Regional & District Mock Predictive Leaderboard',
              style: LearnTzTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Rankings show which regional and district mocks provided the most accurate forecast for the real examination.',
              style: LearnTzTypography.bodyRegular.copyWith(
                color: LearnTzColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),

            leaderboardAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Failed to load leaderboard: $err'),
                  ),
                ),
              ),
              data: (leaderboard) {
                if (leaderboard == null || leaderboard.rankings.isEmpty) {
                  return AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.assessment_outlined,
                              size: 48,
                              color: LearnTzColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No calibration models found for this filter.',
                              style: LearnTzTypography.h4,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select 2024 to inspect vetted regional comparisons.',
                              style: LearnTzTypography.caption,
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
                  itemCount: leaderboard.rankings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = leaderboard.rankings[index];
                    return _buildLeaderboardCard(item);
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // Section 2: Historical Topic Frequency & Recurring Concepts
            Text(
              'Historical Recurring Topic Frequency & Weighting',
              style: LearnTzTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Recurring concepts across national examination papers to optimize high-yield revision focus.',
              style: LearnTzTypography.bodyRegular.copyWith(
                color: LearnTzColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),

            topicFrequencyAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Failed to load topic frequency: $err'),
                  ),
                ),
              ),
              data: (data) {
                if (data == null || data.topicFrequency.isEmpty) {
                  return AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'No historical topic trends recorded yet.',
                          style: LearnTzTypography.bodyRegular,
                        ),
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 420,
                    mainAxisExtent: 160,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: data.topicFrequency.length,
                  itemBuilder: (context, index) {
                    final item = data.topicFrequency[index];
                    return _buildTopicFrequencyCard(item);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearFilterChip(int? year, String label) {
    final isSelected = _selectedYear == year;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedYear = year;
        });
      },
      selectedColor: LearnTzColors.primary.withValues(alpha: 0.15),
      checkmarkColor: LearnTzColors.primary,
    );
  }

  Widget _buildLeaderboardCard(MockLeaderboardEntry item) {
    final isTop1 = item.rank == 1;
    final indexPct = (item.predictiveValidityIndex * 100).toStringAsFixed(0);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Rank Badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTop1
                  ? LearnTzColors.accent.withValues(alpha: 0.2)
                  : LearnTzColors.neutral100,
              border: Border.all(
                color: isTop1 ? LearnTzColors.accent : LearnTzColors.border,
                width: isTop1 ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '#${item.rank}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: isTop1
                    ? LearnTzColors.accent
                    : LearnTzColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppBadge(
                      label: item.tier.toUpperCase(),
                      variant: isTop1
                          ? AppBadgeVariant.primary
                          : AppBadgeVariant.neutral,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.locationSubtitle,
                        style: LearnTzTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: LearnTzColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.mockTitle,
                  style: LearnTzTypography.h4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Calibrated against: ${item.realPaperTitle} (${item.year})',
                  style: LearnTzTypography.caption.copyWith(
                    color: LearnTzColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Validity Index Gauge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isTop1
                  ? LearnTzColors.success.withValues(alpha: 0.12)
                  : LearnTzColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isTop1
                    ? LearnTzColors.success
                    : LearnTzColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$indexPct%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isTop1
                        ? LearnTzColors.success
                        : LearnTzColors.primary,
                  ),
                ),
                Text(
                  'VALIDITY',
                  style: LearnTzTypography.caption.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isTop1
                        ? LearnTzColors.success
                        : LearnTzColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicFrequencyCard(TopicFrequencyItem item) {
    final isHigh = item.recurrenceRate == 'High Recurrence';
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.topicTitle,
                  style: LearnTzTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppBadge(
                label: item.recurrenceRate,
                variant: isHigh
                    ? AppBadgeVariant.success
                    : AppBadgeVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '${item.questionCount} Questions in Bank',
                style: LearnTzTypography.caption.copyWith(
                  color: LearnTzColors.textSecondary,
                ),
              ),
              Text(
                '${item.totalMarks.toStringAsFixed(0)} Total Marks',
                style: LearnTzTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: LearnTzColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
