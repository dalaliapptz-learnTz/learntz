import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../organization_providers.dart';

class RegionalDistrictWorkspaceScreen extends ConsumerWidget {
  const RegionalDistrictWorkspaceScreen({
    required this.orgId,
    super.key,
  });

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(organizationDetailsProvider(orgId));
    final kpisAsync = ref.watch(governanceOfficeWorkspaceKpisProvider(orgId));

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
                              d?.name ?? 'Governance Office',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                            orElse: () => Text(
                              'Regional / District Education Office',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                          ),
                          const AppBadge(
                            label: 'Local Governance',
                            variant: AppBadgeVariant.accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jurisdictional School Oversight, Enrollment Analytics & District Mock Performance',
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
                      label: 'Schools Directory',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.md,
                      icon: Icons.domain,
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
                            label: 'Schools in Jurisdiction',
                            value: '${kpis.subordinateSchoolsCount}',
                            subtitle: 'Active schools under local office',
                            icon: Icons.school_outlined,
                            color: LearnTzColors.primary,
                          ),
                          _buildKpiCard(
                            label: 'Estimated Learners',
                            value: '${kpis.totalLearnersCount}',
                            subtitle: 'Enrolled students in district',
                            icon: Icons.groups_outlined,
                            color: LearnTzColors.secondary,
                          ),
                          _buildKpiCard(
                            label: 'Avg Mock Score',
                            value: '${kpis.averageMockPerformancePct.toStringAsFixed(1)}%',
                            subtitle: 'Latest regional assessments',
                            icon: Icons.analytics_outlined,
                            color: LearnTzColors.accent,
                          ),
                          _buildKpiCard(
                            label: 'Jurisdiction Level',
                            value: kpis.officeType.contains('district')
                                ? 'District'
                                : 'Region',
                            subtitle: '${kpis.countryCode} Administrative Zone',
                            icon: Icons.location_city,
                            color: LearnTzColors.textPrimary,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Schools in Jurisdiction
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Schools in Jurisdiction',
                              style: LearnTzTypography.h3.copyWith(
                                fontWeight: FontWeight.bold,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                            AppButton(
                              label: 'Add School',
                              variant: AppButtonVariant.ghost,
                              size: AppButtonSize.sm,
                              icon: Icons.add,
                              onPressed: () => context.push('/enterprise/register'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (kpis.schoolsInJurisdiction.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No subordinate schools linked yet under this governance office.',
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
                            itemCount: kpis.schoolsInJurisdiction.length,
                            separatorBuilder: (_, _) => const Divider(),
                            itemBuilder: (context, index) {
                              final school = kpis.schoolsInJurisdiction[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: LearnTzColors.primary.withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.school,
                                    color: LearnTzColors.primary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  school['name'] as String? ?? 'School',
                                  style: LearnTzTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Slug: ${school['slug'] ?? 'N/A'} • Status: ${(school['status'] as String? ?? 'active').toUpperCase()}',
                                  style: LearnTzTypography.bodySmall.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.people_outline),
                                  tooltip: 'Staff Directory',
                                  onPressed: () => context.push(
                                    '/workspace/${school['id']}/staff',
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
                        'Failed to load Governance Office workspace: $err',
                        style: LearnTzTypography.bodyLarge.copyWith(
                          color: LearnTzColors.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Retry',
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.md,
                        onPressed: () => ref.invalidate(governanceOfficeWorkspaceKpisProvider(orgId)),
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
