import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../organization_providers.dart';

class DevelopmentPartnerWorkspaceScreen extends ConsumerWidget {
  const DevelopmentPartnerWorkspaceScreen({
    required this.orgId,
    super.key,
  });

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(organizationDetailsProvider(orgId));
    final kpisAsync =
        ref.watch(developmentPartnerWorkspaceKpisProvider(orgId));

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
                              d?.name ?? 'Development Partner',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                            orElse: () => Text(
                              'Development Partner Workspace',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                          ),
                          const AppBadge(
                            label: 'SDG 4 Education Impact',
                            variant: AppBadgeVariant.accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Intervention Cohort Tracking, Equity Impact Metrics & Grant Accountability Cockpit',
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
                      label: 'Partner Staff',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.md,
                      icon: Icons.people_outline,
                      onPressed: () => context.push('/workspace/$orgId/staff'),
                    ),
                    AppButton(
                      label: 'Supported Schools',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.md,
                      icon: Icons.domain_verification,
                      onPressed: () => context.push('/enterprise/directory'),
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
                            label: 'Supported Schools',
                            value: '${kpis.supportedSchoolsCount}',
                            subtitle: 'Institutions under intervention',
                            icon: Icons.school_outlined,
                            color: const Color(0xFF0F4C81),
                          ),
                          _buildKpiCard(
                            label: 'Beneficiaries',
                            value: '${kpis.beneficiaryLearnersCount}',
                            subtitle: 'Learners reached across cohorts',
                            icon: Icons.groups_outlined,
                            color: const Color(0xFF15803D),
                          ),
                          _buildKpiCard(
                            label: 'Interventions',
                            value: '${kpis.activeInterventionProgramsCount}',
                            subtitle: 'Active grant funded programs',
                            icon: Icons.handshake_outlined,
                            color: const Color(0xFFF59E0B),
                          ),
                          _buildKpiCard(
                            label: 'SDG 4 Parity',
                            value:
                                '${kpis.sdg4Benchmarks['gender_parity_index'] ?? "0.99"}',
                            subtitle: 'Gender parity index ratio',
                            icon: Icons.balance_outlined,
                            color: const Color(0xFF0284C7),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // SDG 4 Benchmarks Card
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SDG 4 Key Performance Benchmarks',
                          style: LearnTzTypography.h3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: LearnTzColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 700;
                            return GridView.count(
                              crossAxisCount: isWide ? 3 : 1,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: isWide ? 2.2 : 3.0,
                              children: [
                                _buildMetricTile(
                                  title: 'Foundational Literacy Rate',
                                  value:
                                      '${kpis.sdg4Benchmarks['foundational_literacy_rate_pct'] ?? "81.2"}%',
                                  subtitle: 'Target: 85.0% by 2027',
                                  icon: Icons.auto_stories_outlined,
                                ),
                                _buildMetricTile(
                                  title: 'STEM Female Participation',
                                  value:
                                      '${kpis.sdg4Benchmarks['stem_female_participation_pct'] ?? "51.4"}%',
                                  subtitle: 'Gender parity in STEM tracks',
                                  icon: Icons.female_outlined,
                                ),
                                _buildMetricTile(
                                  title: 'Digital Engagement / Student',
                                  value:
                                      '${kpis.sdg4Benchmarks['average_study_hours_monthly'] ?? "16.8"} hrs',
                                  subtitle: 'Average monthly active platform use',
                                  icon: Icons.timer_outlined,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Active Intervention Programs Card
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Educational Interventions',
                          style: LearnTzTypography.h3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: LearnTzColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: kpis.interventions.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = kpis.interventions[index];
                            final progress =
                                ((item['completion_pct'] as num?)?.toDouble() ??
                                        0.0) /
                                    100.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['name'] as String? ?? 'Program',
                                          style: LearnTzTypography.bodyLarge
                                              .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${item['completion_pct'] ?? 0}% completed',
                                        style: LearnTzTypography.bodySmall
                                            .copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF15803D),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Region: ${item['target_region'] ?? "National"} • Beneficiaries: ${item['beneficiaries']} students',
                                    style:
                                        LearnTzTypography.bodySmall.copyWith(
                                      color: LearnTzColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: LearnTzColors.neutral200,
                                    color: const Color(0xFF15803D),
                                    minHeight: 6,
                                  ),
                                ],
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
                        'Failed to load Development Partner workspace: $err',
                        style: LearnTzTypography.bodyLarge.copyWith(
                          color: LearnTzColors.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Retry',
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.md,
                        onPressed: () => ref.invalidate(
                            developmentPartnerWorkspaceKpisProvider(orgId)),
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

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LearnTzColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LearnTzColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF0F4C81).withValues(alpha: 0.1),
            child: Icon(icon, color: const Color(0xFF0F4C81), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: LearnTzTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: LearnTzTypography.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: LearnTzColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: LearnTzTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
