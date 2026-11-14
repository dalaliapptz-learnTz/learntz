import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../organization_providers.dart';

class InstitutionalBillingScreen extends ConsumerWidget {
  const InstitutionalBillingScreen({
    required this.orgId,
    super.key,
  });

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(organizationDetailsProvider(orgId));
    final subAsync = ref.watch(organizationSubscriptionStatusProvider(orgId));

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
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
                              d?.name ?? 'Institutional Billing',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                            orElse: () => Text(
                              'Institutional Billing & Licensing',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                          ),
                          const AppBadge(
                            label: 'Enterprise Subscription',
                            variant: AppBadgeVariant.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seat Licensing, Storage Quotas, Multi-Currency Billing & VAT / Tax Invoices',
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
                      label: 'Support Desk',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.md,
                      icon: Icons.support_agent_outlined,
                      onPressed: () =>
                          context.push('/workspace/$orgId/support'),
                    ),
                    AppButton(
                      label: 'Staff Directory',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.md,
                      icon: Icons.people_outline,
                      onPressed: () =>
                          context.push('/workspace/$orgId/staff'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Subscription Status Card
            subAsync.when(
              data: (sub) {
                final studentSeatPct = sub.allocatedStudentSeats > 0
                    ? sub.usedStudentSeats / sub.allocatedStudentSeats
                    : 0.0;
                final teacherSeatPct = sub.allocatedTeacherSeats > 0
                    ? sub.usedTeacherSeats / sub.allocatedTeacherSeats
                    : 0.0;
                final storagePct = sub.allocatedStorageGb > 0
                    ? sub.usedStorageGb / sub.allocatedStorageGb
                    : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Summary Card
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sub.planName,
                                    style: LearnTzTypography.h2.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: LearnTzColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Billing Cycle: ${sub.billingCycle.toUpperCase()} • Currency: ${sub.currency}',
                                    style:
                                        LearnTzTypography.bodySmall.copyWith(
                                      color: LearnTzColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              AppBadge(
                                label: sub.status.toUpperCase(),
                                variant: sub.status == 'active'
                                    ? AppBadgeVariant.success
                                    : AppBadgeVariant.warning,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Annual Rate',
                                    style: LearnTzTypography.caption,
                                  ),
                                  Text(
                                    '${sub.currency} ${sub.currentPrice.toStringAsFixed(0)}',
                                    style: LearnTzTypography.h3.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: LearnTzColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SLA Guarantee',
                                    style: LearnTzTypography.caption,
                                  ),
                                  Text(
                                    '${sub.slaResponseHours}h Response Time',
                                    style: LearnTzTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Renewal Date',
                                    style: LearnTzTypography.caption,
                                  ),
                                  Text(
                                    sub.periodEnd != null
                                        ? '${sub.periodEnd!.year}-${sub.periodEnd!.month.toString().padLeft(2, '0')}-${sub.periodEnd!.day.toString().padLeft(2, '0')}'
                                        : 'Active Continuous',
                                    style: LearnTzTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (sub.taxId != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tax / TIN Number',
                                      style: LearnTzTypography.caption,
                                    ),
                                    Text(
                                      sub.taxId!,
                                      style:
                                          LearnTzTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quotas & Utilization Grid
                    Text(
                      'Institutional Seat & Quota Allocation',
                      style: LearnTzTypography.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: LearnTzColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 800;
                        return GridView.count(
                          crossAxisCount: isWide ? 3 : 1,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isWide ? 1.8 : 2.5,
                          children: [
                            _buildQuotaCard(
                              title: 'Student Seats',
                              used: sub.usedStudentSeats,
                              allocated: sub.allocatedStudentSeats,
                              unit: 'seats',
                              percentage: studentSeatPct,
                              icon: Icons.school_outlined,
                              color: LearnTzColors.primary,
                            ),
                            _buildQuotaCard(
                              title: 'Teacher Faculty Seats',
                              used: sub.usedTeacherSeats,
                              allocated: sub.allocatedTeacherSeats,
                              unit: 'seats',
                              percentage: teacherSeatPct,
                              icon: Icons.badge_outlined,
                              color: LearnTzColors.secondary,
                            ),
                            _buildQuotaCard(
                              title: 'Storage Capacity',
                              used: sub.usedStorageGb,
                              allocated: sub.allocatedStorageGb,
                              unit: 'GB',
                              percentage: storagePct,
                              icon: Icons.cloud_done_outlined,
                              color: LearnTzColors.accent,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // Plan Actions Card
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need Additional Seats or Dedicated Infrastructure?',
                                  style: LearnTzTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Upgrade to Network Enterprise or Sovereign Government tiers for unmetered seats and 1-hour response SLA.',
                                  style:
                                      LearnTzTypography.bodySmall.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppButton(
                            label: 'Contact Account Executive',
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.md,
                            icon: Icons.arrow_forward,
                            onPressed: () => context.push('/help'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
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
                        'Failed to load subscription status: $err',
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
                            organizationSubscriptionStatusProvider(orgId)),
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

  Widget _buildQuotaCard({
    required String title,
    required int used,
    required int allocated,
    required String unit,
    required double percentage,
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
                  title,
                  style: LearnTzTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: LearnTzColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$used',
                style: LearnTzTypography.h1.copyWith(
                  fontWeight: FontWeight.w800,
                  color: LearnTzColors.textPrimary,
                ),
              ),
              Text(
                ' / $allocated $unit',
                style: LearnTzTypography.bodySmall.copyWith(
                  color: LearnTzColors.textSecondary,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Utilization',
                    style: LearnTzTypography.caption,
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: LearnTzTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: percentage > 0.9
                          ? LearnTzColors.error
                          : LearnTzColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                backgroundColor: LearnTzColors.neutral200,
                color: percentage > 0.9 ? LearnTzColors.error : color,
                minHeight: 6,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
