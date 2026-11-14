import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../organization_providers.dart';

class ExamAuthorityWorkspaceScreen extends ConsumerWidget {
  const ExamAuthorityWorkspaceScreen({
    required this.orgId,
    super.key,
  });

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(organizationDetailsProvider(orgId));
    final kpisAsync = ref.watch(examAuthorityWorkspaceKpisProvider(orgId));

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation & Breadcrumb
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/enterprise/directory'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          detailsAsync.maybeWhen(
                            data: (d) => Text(
                              d?.name ?? 'Examination Authority',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                            orElse: () => Text(
                              'Examination Authority Workspace',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                          ),
                          const AppBadge(
                            label: 'Standardized Assessment',
                            variant: AppBadgeVariant.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'National Question Bank, Blueprint Standard Calibration & Mock Validation Console',
                        style: LearnTzTypography.bodyRegular.copyWith(
                          color: LearnTzColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    AppButton(
                      label: 'Staff Directory',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.md,
                      icon: Icons.people_outline,
                      onPressed: () => context.push('/workspace/$orgId/staff'),
                    ),
                    AppButton(
                      label: 'Exam Repository',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.md,
                      icon: Icons.quiz_outlined,
                      onPressed: () => context.push('/exams/repository'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // KPIs Grid
            kpisAsync.when(
              data: (kpis) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;
                      return GridView.count(
                        crossAxisCount: isWide ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isWide ? 1.6 : 1.3,
                        children: [
                          _buildKpiCard(
                            label: 'Archived Papers',
                            value: '${kpis.archivedPapersCount}',
                            subtitle: 'Official national past papers',
                            icon: Icons.archive_outlined,
                            color: LearnTzColors.primary,
                          ),
                          _buildKpiCard(
                            label: 'Approved Items',
                            value: '${kpis.approvedQuestionsCount}',
                            subtitle: 'Calibrated question bank items',
                            icon: Icons.check_circle_outline,
                            color: LearnTzColors.secondary,
                          ),
                          _buildKpiCard(
                            label: 'Active Blueprints',
                            value: '${kpis.activeBlueprintsCount}',
                            subtitle: 'Standardized assessment structures',
                            icon: Icons.architecture,
                            color: LearnTzColors.accent,
                          ),
                          _buildKpiCard(
                            label: 'Predictive Validity',
                            value: '${(kpis.averagePredictiveValidityIndex * 100).toStringAsFixed(1)}%',
                            subtitle: 'Mock-to-real correlation score',
                            icon: Icons.trending_up,
                            color: const Color(0xFF0284C7),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Recent Examination Papers
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Standardized National Examination Papers',
                              style: LearnTzTypography.h3.copyWith(
                                fontWeight: FontWeight.bold,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                            AppButton(
                              label: 'View Repository',
                              variant: AppButtonVariant.ghost,
                              size: AppButtonSize.sm,
                              icon: Icons.arrow_forward,
                              onPressed: () => context.push('/exams/repository'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (kpis.recentPapers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No standardized papers archived for this authority yet.',
                                style: LearnTzTypography.bodyRegular.copyWith(
                                  color: LearnTzColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: kpis.recentPapers.length,
                            separatorBuilder: (_, _) => const Divider(),
                            itemBuilder: (context, index) {
                              final paper = kpis.recentPapers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    color: Color(0xFF0284C7),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  paper['title'] as String? ?? 'Examination Paper',
                                  style: LearnTzTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Year: ${paper['year'] ?? 'N/A'} • Tier: ${(paper['tier'] as String? ?? 'national').toUpperCase()} • Marks: ${paper['total_marks'] ?? 100}',
                                  style: LearnTzTypography.bodySmall.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  tooltip: 'Inspect',
                                  onPressed: () => context.push('/exams/repository'),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => AppCard(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: LearnTzColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load Examination Authority workspace: $err',
                        style: LearnTzTypography.bodyLarge.copyWith(
                          color: LearnTzColors.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Retry',
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.md,
                        onPressed: () => ref.invalidate(examAuthorityWorkspaceKpisProvider(orgId)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: LearnTzTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: LearnTzColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: LearnTzTypography.h1.copyWith(
              fontWeight: FontWeight.w800,
              color: LearnTzColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: LearnTzTypography.bodySmall.copyWith(
              color: LearnTzColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
