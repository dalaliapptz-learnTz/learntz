import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../organization_providers.dart';

class ResearchInstitutionWorkspaceScreen extends ConsumerStatefulWidget {
  const ResearchInstitutionWorkspaceScreen({
    required this.orgId,
    super.key,
  });

  final String orgId;

  @override
  ConsumerState<ResearchInstitutionWorkspaceScreen> createState() =>
      _ResearchInstitutionWorkspaceScreenState();
}

class _ResearchInstitutionWorkspaceScreenState
    extends ConsumerState<ResearchInstitutionWorkspaceScreen> {
  String? _exportSuccessMessage;
  bool _isExporting = false;

  Future<void> _exportDataset(String datasetKey) async {
    setState(() {
      _isExporting = true;
      _exportSuccessMessage = null;
    });

    try {
      final repo = ref.read(organizationRepositoryProvider);
      final result = await repo.exportAnonymizedResearchDataset(
        orgId: widget.orgId,
        datasetKey: datasetKey,
      );

      if (mounted) {
        setState(() {
          _exportSuccessMessage =
              'Export generated: ${result.datasetKey} (${result.recordsCount} records) via ${result.privacyStandard}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_exportSuccessMessage!),
            backgroundColor: LearnTzColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dataset export failed: $e'),
            backgroundColor: LearnTzColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(organizationDetailsProvider(widget.orgId));
    final kpisAsync =
        ref.watch(researchInstitutionWorkspaceKpisProvider(widget.orgId));

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
                              d?.name ?? 'Educational Research Think Tank',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                            orElse: () => Text(
                              'Educational Research Think Tank',
                              style: LearnTzTypography.h2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                          ),
                          const AppBadge(
                            label: 'Differential Privacy (Zero PII)',
                            variant: AppBadgeVariant.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Longitudinal Cohort Analytics, Statistical Psychometrics & De-identified Research Repository',
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
                      label: 'Research Staff',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.md,
                      icon: Icons.people_outline,
                      onPressed: () =>
                          context.push('/workspace/${widget.orgId}/staff'),
                    ),
                    AppButton(
                      label: 'Privacy Charter',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.md,
                      icon: Icons.security,
                      onPressed: () => context.push('/help'),
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
                            label: 'Anonymized Cohorts',
                            value: '${kpis.anonymizedCohortsCount}',
                            subtitle: 'Aggregated regional groups (k>=25)',
                            icon: Icons.biotech_outlined,
                            color: const Color(0xFF7C3AED),
                          ),
                          _buildKpiCard(
                            label: 'Observations',
                            value: '${kpis.totalAnonymizedObservations}',
                            subtitle: 'Statistical assessment datapoints',
                            icon: Icons.scatter_plot_outlined,
                            color: LearnTzColors.primary,
                          ),
                          _buildKpiCard(
                            label: 'Mastery Index',
                            value: '${(kpis.statisticalMasteryIndex * 100).toStringAsFixed(1)}%',
                            subtitle: 'Population-wide cognitive index',
                            icon: Icons.psychology_outlined,
                            color: LearnTzColors.secondary,
                          ),
                          _buildKpiCard(
                            label: 'Privacy Standard',
                            value: 'k >= 25',
                            subtitle: 'Strict zero PII exposure policy',
                            icon: Icons.verified_user_outlined,
                            color: const Color(0xFF0284C7),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Differential Privacy Datasets Card
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available De-Identified Research Datasets',
                          style: LearnTzTypography.h3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: LearnTzColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'All datasets enforce differential privacy and k-anonymity (k >= 25). No student IDs, names, or individual locations are stored.',
                          style: LearnTzTypography.bodySmall.copyWith(
                            color: LearnTzColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: kpis.availableDatasets.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final dataset = kpis.availableDatasets[index];
                            final key = dataset['key'] as String? ?? '';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.table_chart_outlined,
                                  color: Color(0xFF7C3AED),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                dataset['title'] as String? ?? 'Dataset',
                                style: LearnTzTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Format: ${dataset['format'] ?? "CSV"} • Sample Size: ${dataset['sample_size']} observations • Privacy: ${dataset['privacy_level']}',
                                style: LearnTzTypography.bodySmall.copyWith(
                                  color: LearnTzColors.textSecondary,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.download_outlined),
                                tooltip: 'Export Data',
                                onPressed: _isExporting ? null : () => _exportDataset(key),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subject Mastery Distribution Card
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subject Mastery Statistical Distribution',
                          style: LearnTzTypography.h3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: LearnTzColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: kpis.subjectMasteryDistribution.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final subject =
                                kpis.subjectMasteryDistribution[index];
                            final mean =
                                (subject['mean_mastery'] as num?)?.toDouble() ??
                                    0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      subject['subject'] as String? ?? '',
                                      style:
                                          LearnTzTypography.bodyRegular.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Cohort: ${subject['cohort_size']}',
                                      style:
                                          LearnTzTypography.bodySmall.copyWith(
                                        color: LearnTzColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: mean,
                                            backgroundColor:
                                                LearnTzColors.neutral200,
                                            color: const Color(0xFF7C3AED),
                                            minHeight: 8,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${(mean * 100).toStringAsFixed(0)}%',
                                          style: LearnTzTypography.bodySmall
                                              .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
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
                        'Failed to load Research Think Tank workspace: $err',
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
                            researchInstitutionWorkspaceKpisProvider(
                                widget.orgId)),
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

