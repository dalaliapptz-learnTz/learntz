import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../organization_models.dart';
import '../organization_providers.dart';

class OrganizationDirectoryScreen extends ConsumerStatefulWidget {
  const OrganizationDirectoryScreen({super.key});

  @override
  ConsumerState<OrganizationDirectoryScreen> createState() =>
      _OrganizationDirectoryScreenState();
}

class _OrganizationDirectoryScreenState
    extends ConsumerState<OrganizationDirectoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(organizationFilterProvider);
    final orgsAsync = ref.watch(organizationsListProvider);

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
                final isWide = constraints.maxWidth >= 800;
                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      key: const Key('register-organization-btn'),
                      label: 'Register Institution',
                      icon: Icons.add_business_outlined,
                      size: AppButtonSize.md,
                      onPressed: () => context.go('/enterprise/register'),
                    ),
                  ],
                );

                final headerInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.corporate_fare,
                          color: LearnTzColors.primary,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Enterprise Institutional Directory',
                            style: LearnTzTypography.h2.copyWith(
                              fontWeight: FontWeight.w800,
                              color: LearnTzColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Multi-tenant governance connecting Ministries, Examination Authorities, Regional/District Offices, and Accredited Schools across East Africa.',
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

            // Filter Bar: Country Chips, Type Filter & Search
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country Filter Chips
                  Row(
                    children: [
                      Text(
                        'Country:',
                        style: LearnTzTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: LearnTzColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All Countries'),
                            selected: filter.countryCode == null,
                            onSelected: (selected) {
                              if (selected) {
                                ref
                                    .read(organizationFilterProvider.notifier)
                                    .setCountry(null);
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('🇹🇿 Tanzania'),
                            selected: filter.countryCode == 'TZ',
                            onSelected: (selected) {
                              ref
                                  .read(organizationFilterProvider.notifier)
                                  .setCountry(selected ? 'TZ' : null);
                            },
                          ),
                          ChoiceChip(
                            label: const Text('🇰🇪 Kenya'),
                            selected: filter.countryCode == 'KE',
                            onSelected: (selected) {
                              ref
                                  .read(organizationFilterProvider.notifier)
                                  .setCountry(selected ? 'KE' : null);
                            },
                          ),
                          ChoiceChip(
                            label: const Text('🇺🇬 Uganda'),
                            selected: filter.countryCode == 'UG',
                            onSelected: (selected) {
                              ref
                                  .read(organizationFilterProvider.notifier)
                                  .setCountry(selected ? 'UG' : null);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Search Field
                  AppTextField(
                    hint: 'Search organizations by name or slug...',
                    prefixIcon: Icons.search,
                    controller: _searchController,
                    onChanged: (val) {
                      ref
                          .read(organizationFilterProvider.notifier)
                          .setSearch(val.isEmpty ? null : val);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Type Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('All Types'),
                            selected: filter.type == null,
                            onSelected: (selected) {
                              if (selected) {
                                ref
                                    .read(organizationFilterProvider.notifier)
                                    .setType(null);
                              }
                            },
                          ),
                        ),
                        for (final t in OrganizationType.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(t.label),
                              selected: filter.type == t,
                              onSelected: (selected) {
                                ref
                                    .read(organizationFilterProvider.notifier)
                                    .setType(selected ? t : null);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Organizations List
            orgsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error loading directory: $err'),
                  ),
                ),
              ),
              data: (organizations) {
                if (organizations.isEmpty) {
                  return AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off_outlined,
                              size: 48,
                              color: LearnTzColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No organizations found matching filter.',
                              style: LearnTzTypography.h4,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try clearing filters or search term.',
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
                  itemCount: organizations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final org = organizations[index];
                    return _buildOrganizationCard(context, org);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationCard(BuildContext context, Organization org) {
    final flag = switch (org.countryCode) {
      'TZ' => '🇹🇿',
      'KE' => '🇰🇪',
      'UG' => '🇺🇬',
      _ => '🌍',
    };

    final badgeVariant = switch (org.type) {
      OrganizationType.ministry => AppBadgeVariant.primary,
      OrganizationType.examinationAuthority => AppBadgeVariant.success,
      OrganizationType.regionalOffice => AppBadgeVariant.neutral,
      OrganizationType.districtOffice => AppBadgeVariant.neutral,
      OrganizationType.schoolNetwork => AppBadgeVariant.warning,
      OrganizationType.school => AppBadgeVariant.neutral,
      OrganizationType.researchInstitution => AppBadgeVariant.neutral,
      OrganizationType.developmentPartner => AppBadgeVariant.primary,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: LearnTzColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(flag, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppBadge(
                          label: org.type.label,
                          variant: badgeVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${org.countryCode} • ${org.slug}',
                          style: LearnTzTypography.caption.copyWith(
                            color: LearnTzColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      org.name,
                      style: LearnTzTypography.h4.copyWith(
                        fontWeight: FontWeight.bold,
                        color: LearnTzColors.textPrimary,
                      ),
                    ),
                    if (org.parentName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Parent Body: ${org.parentName}',
                        style: LearnTzTypography.caption.copyWith(
                          color: LearnTzColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showSubordinatesModal(context, org),
                icon: const Icon(Icons.account_tree_outlined, size: 16),
                label: const Text('Hierarchy'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSubordinatesModal(BuildContext context, Organization org) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final detailsAsync = ref.watch(organizationDetailsProvider(org.id));
            final subsAsync = ref.watch(
              subordinateOrganizationsProvider((orgId: org.id, type: null)),
            );

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.85,
              minChildSize: 0.4,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              org.name,
                              style: LearnTzTypography.h3.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      detailsAsync.maybeWhen(
                        data: (details) {
                          if (details == null) return const SizedBox.shrink();
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 160,
                                child: AppStatCard(
                                  label: 'Direct Children',
                                  value: '${details.directChildrenCount}',
                                  icon: Icons.share_outlined,
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: AppStatCard(
                                  label: 'Total Descendants',
                                  value: '${details.totalDescendantsCount}',
                                  icon: Icons.account_tree_outlined,
                                ),
                              ),
                            ],
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Nested Hierarchy Subtree:',
                        style: LearnTzTypography.h4.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      subsAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, _) => Text('Error loading hierarchy: $err'),
                        data: (items) {
                          if (items.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('No subordinate entities registered.'),
                            );
                          }
                          return Column(
                            children: [
                              for (final item in items)
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: item.depth * 20.0,
                                    bottom: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.depth == 0
                                            ? Icons.radio_button_checked
                                            : Icons.subdirectory_arrow_right,
                                        size: 16,
                                        color: LearnTzColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${item.name} (${item.type.label})',
                                          style: LearnTzTypography.bodyRegular.copyWith(
                                            fontWeight: item.depth == 0
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
