import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/state/app_providers.dart';
import '../exam_models.dart';
import '../exam_providers.dart';

class NationalExaminationCentreScreen extends ConsumerStatefulWidget {
  const NationalExaminationCentreScreen({super.key});

  @override
  ConsumerState<NationalExaminationCentreScreen> createState() =>
      _NationalExaminationCentreScreenState();
}

class _NationalExaminationCentreScreenState
    extends ConsumerState<NationalExaminationCentreScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountry = ref.watch(selectedCountryProvider);
    final catalogAsync = ref.watch(
      examinationCentreCatalogProvider(selectedCountry.countryCode),
    );
    final papersAsync = ref.watch(filteredExaminationPapersProvider);
    final filter = ref.watch(examFilterProvider);

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 840;
                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      label: 'Intelligence',
                      icon: Icons.insights_outlined,
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.md,
                      onPressed: () => context.go(AppRoutes.mockIntelligence),
                    ),
                    AppButton(
                      label: 'Question Bank',
                      icon: Icons.quiz_outlined,
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.md,
                      onPressed: () => context.go(AppRoutes.examBank),
                    ),
                    AppButton(
                      key: const Key('upload-mock-exam-btn'),
                      label: 'Upload Mock Exam',
                      icon: Icons.cloud_upload_outlined,
                      size: AppButtonSize.md,
                      onPressed: () => context.go(AppRoutes.examUpload),
                    ),
                  ],
                );

                final headerInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          selectedCountry.countryCode == 'TZ'
                              ? '🇹🇿'
                              : selectedCountry.countryCode == 'KE'
                                  ? '🇰🇪'
                                  : '🇺🇬',
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'National Examination Centre',
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
                      'Access official past papers, regional mocks, and timed exam simulations across East Africa.',
                      style: LearnTzTypography.bodyRegular.copyWith(
                        color: LearnTzColors.textSecondary,
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: headerInfo),
                      const SizedBox(width: 16),
                      actions,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerInfo,
                    const SizedBox(height: 16),
                    actions,
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Metrics / Tier Summary Row
            catalogAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Error loading catalog: $err'),
              ),
              data: (catalog) {
                if (catalog == null) return const SizedBox.shrink();
                final counts = catalog.tierCounts;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 175,
                      child: AppStatCard(
                        label: 'Official National',
                        value: '${counts['national'] ?? 0}',
                        icon: Icons.verified_outlined,
                        iconColor: LearnTzColors.primary,
                        iconBackgroundColor: LearnTzColors.primary50,
                      ),
                    ),
                    SizedBox(
                      width: 175,
                      child: AppStatCard(
                        label: 'Regional Mocks',
                        value: '${counts['regional'] ?? 0}',
                        icon: Icons.location_city_outlined,
                        iconColor: LearnTzColors.secondary,
                        iconBackgroundColor: LearnTzColors.secondary50,
                      ),
                    ),
                    SizedBox(
                      width: 175,
                      child: AppStatCard(
                        label: 'District Mocks',
                        value: '${counts['district'] ?? 0}',
                        icon: Icons.account_balance_outlined,
                        iconColor: LearnTzColors.accent,
                        iconBackgroundColor: LearnTzColors.accent50,
                      ),
                    ),
                    SizedBox(
                      width: 175,
                      child: AppStatCard(
                        label: 'School Mocks',
                        value: '${counts['school'] ?? 0}',
                        icon: Icons.school_outlined,
                        iconColor: LearnTzColors.info,
                        iconBackgroundColor: LearnTzColors.infoBg,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Authority Selection Tabs
            catalogAsync.maybeWhen(
              data: (catalog) {
                if (catalog == null || catalog.authorities.isEmpty) {
                  return const SizedBox.shrink();
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All Authorities'),
                          selected: filter.authorityId == null,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(examFilterProvider.notifier)
                                  .setAuthority(null);
                            }
                          },
                        ),
                      ),
                      for (final auth in catalog.authorities)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${auth.id} (${auth.countryCode})'),
                            selected: filter.authorityId == auth.id,
                            onSelected: (selected) {
                              ref
                                  .read(examFilterProvider.notifier)
                                  .setAuthority(selected ? auth.id : null);
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Search and Tier Filter Row
            AppCard(
              variant: AppCardVariant.flat,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _searchController,
                          hint: 'Search by subject, examination title, region...',
                          prefixIcon: Icons.search,
                          onChanged: (val) {
                            ref
                                .read(examFilterProvider.notifier)
                                .setSearch(val.trim());
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_searchController.text.isNotEmpty)
                        AppIconButton(
                          icon: Icons.clear,
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(examFilterProvider.notifier)
                                .setSearch('');
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTierChip('all', 'All Tiers', filter.tier == null),
                      _buildTierChip(
                          'national', 'Official National', filter.tier == 'national'),
                      _buildTierChip(
                          'regional', 'Regional Mocks', filter.tier == 'regional'),
                      _buildTierChip(
                          'district', 'District Mocks', filter.tier == 'district'),
                      _buildTierChip(
                          'school', 'School Mocks', filter.tier == 'school'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Examination Papers Grid
            Text(
              'Available Examination Papers',
              style: LearnTzTypography.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            papersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => AppEmptyState(
                icon: Icons.error_outline,
                title: 'Unable to Load Papers',
                message: err.toString(),
                actionLabel: 'Retry',
                onAction: () =>
                    ref.refresh(filteredExaminationPapersProvider),
              ),
              data: (papers) {
                if (papers.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.folder_open_outlined,
                    title: 'No Examination Papers Found',
                    message:
                        'No papers match your active tier, authority, or search filters. Try adjusting your search or upload a new mock examination.',
                    actionLabel: 'Clear Filters',
                    onAction: () {
                      _searchController.clear();
                      ref.read(examFilterProvider.notifier).reset();
                    },
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 768;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 2 : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isWide ? 1.65 : 1.35,
                      ),
                      itemCount: papers.length,
                      itemBuilder: (context, index) {
                        final paper = papers[index];
                        return _ExaminationPaperCard(paper: paper);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierChip(String tierKey, String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(examFilterProvider.notifier).setTier(
              tierKey == 'all' ? null : tierKey,
            );
      },
    );
  }
}

class _ExaminationPaperCard extends StatelessWidget {
  const _ExaminationPaperCard({required this.paper});

  final ExaminationPaper paper;

  @override
  Widget build(BuildContext context) {
    final isNational = paper.tier == 'national';
    final tierVariant = isNational
        ? AppBadgeVariant.primary
        : paper.tier == 'regional'
            ? AppBadgeVariant.success
            : AppBadgeVariant.neutral;

    final locationSubtitle = [
      if (paper.region != null && paper.region!.isNotEmpty) paper.region,
      if (paper.district != null && paper.district!.isNotEmpty) paper.district,
      if (paper.schoolName != null && paper.schoolName!.isNotEmpty)
        paper.schoolName,
    ].join(' • ');

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AppBadge(
                    label: paper.authorityId,
                    variant: AppBadgeVariant.primary,
                    size: AppBadgeSize.sm,
                  ),
                  const SizedBox(width: 8),
                  AppBadge(
                    label: paper.tier.toUpperCase(),
                    variant: tierVariant,
                    size: AppBadgeSize.sm,
                  ),
                ],
              ),
              Text(
                '${paper.year}',
                style: LearnTzTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: LearnTzColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            paper.paperTitle,
            style: LearnTzTypography.h4.copyWith(
              fontWeight: FontWeight.w700,
              color: LearnTzColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            paper.subjectName,
            style: LearnTzTypography.bodySmall.copyWith(
              color: LearnTzColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (locationSubtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              locationSubtitle,
              style: LearnTzTypography.caption.copyWith(
                color: LearnTzColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 16, color: LearnTzColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${paper.durationMinutes} min',
                    style: LearnTzTypography.caption.copyWith(
                      color: LearnTzColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.grade_outlined,
                      size: 16, color: LearnTzColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${paper.totalMarks.toInt()} Marks',
                    style: LearnTzTypography.caption.copyWith(
                      color: LearnTzColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              AppButton(
                label: 'View Exam',
                icon: Icons.play_arrow_outlined,
                size: AppButtonSize.sm,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Starting simulation: ${paper.paperTitle}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
