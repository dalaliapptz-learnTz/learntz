import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../organization_providers.dart';

class SchoolNetworkWorkspaceScreen extends ConsumerWidget {
  const SchoolNetworkWorkspaceScreen({
    required this.orgId,
    super.key,
  });

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(organizationDetailsProvider(orgId));
    final kpisAsync = ref.watch(schoolNetworkWorkspaceKpisProvider(orgId));

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
                              d?.name ?? 'School Network',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                            orElse: () => Text(
                              'School Network Workspace',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                          ),
                          const AppBadge(
                            label: 'Independent Multi-Campus Network',
                            variant: AppBadgeVariant.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Multi-Campus Governance, Cross-Campus Performance & Teacher Talent Mobility Console',
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
                      label: 'Network Staff',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.md,
                      icon: Icons.people_outline,
                      onPressed: () => context.push('/workspace/$orgId/staff'),
                    ),
                    AppButton(
                      label: 'Add Campus',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.md,
                      icon: Icons.add_business_outlined,
                      onPressed: () => context.push('/enterprise/register'),
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
                            label: 'Campus Network',
                            value: '${kpis.campusesCount}',
                            subtitle: 'Active affiliated campuses',
                            icon: Icons.domain,
                            color: const Color(0xFF059669),
                          ),
                          _buildKpiCard(
                            label: 'Total Enrolled',
                            value: '${kpis.totalEnrolledLearners}',
                            subtitle: 'Learners across campuses',
                            icon: Icons.school_outlined,
                            color: LearnTzColors.primary,
                          ),
                          _buildKpiCard(
                            label: 'Teaching Faculty',
                            value: '${kpis.totalTeachingStaff}',
                            subtitle: 'Active certified educators',
                            icon: Icons.badge_outlined,
                            color: LearnTzColors.secondary,
                          ),
                          _buildKpiCard(
                            label: 'Average Score',
                            value: '${kpis.networkAveragePerformancePct.toStringAsFixed(1)}%',
                            subtitle: 'Cross-campus academic benchmark',
                            icon: Icons.trending_up,
                            color: LearnTzColors.accent,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Campuses Directory Card
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Network Campuses & Branches',
                              style: LearnTzTypography.h3.copyWith(
                                fontWeight: FontWeight.bold,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                            AppButton(
                              label: 'Register Campus',
                              variant: AppButtonVariant.ghost,
                              size: AppButtonSize.sm,
                              icon: Icons.add,
                              onPressed: () => context.push('/enterprise/register'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (kpis.campuses.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No campuses registered under this network yet.',
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
                            itemCount: kpis.campuses.length,
                            separatorBuilder: (_, _) => const Divider(),
                            itemBuilder: (context, index) {
                              final campus = kpis.campuses[index];
                              final isBoarding =
                                  campus['is_boarding'] as bool? ?? false;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      const Color(0xFF059669).withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.school,
                                    color: Color(0xFF059669),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  campus['name'] as String? ?? 'Campus',
                                  style: LearnTzTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Reg: ${campus['registration_number'] ?? 'N/A'} • Type: ${isBoarding ? "Boarding & Day" : "Day Campus"}',
                                  style: LearnTzTypography.bodySmall.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.people_outline),
                                  tooltip: 'Campus Staff',
                                  onPressed: () => context.push(
                                    '/workspace/${campus['id']}/staff',
                                  ),
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
                        'Failed to load School Network workspace: $err',
                        style: LearnTzTypography.bodyLarge.copyWith(
                          color: LearnTzColors.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Retry',
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.md,
                        onPressed: () => ref.invalidate(schoolNetworkWorkspaceKpisProvider(orgId)),
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
