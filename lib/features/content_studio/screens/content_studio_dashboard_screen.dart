import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../content_studio_models.dart';
import '../content_studio_providers.dart';

class ContentStudioDashboardScreen extends ConsumerWidget {
  const ContentStudioDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(contentStudioMetricsProvider);
    final catalogAsync = ref.watch(contentStudioCatalogProvider);
    final selectedCountry = ref.watch(contentStudioCountryFilterProvider);

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
                  onPressed: () => context.go('/home'),
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
                          Text(
                            'Content Management Studio',
                            style: LearnTzTypography.h2.copyWith(
                              fontWeight: FontWeight.w800,
                              color: LearnTzColors.textPrimary,
                            ),
                          ),
                          const AppBadge(
                            label: 'Authoring & Editorial Cockpit',
                            variant: AppBadgeVariant.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Interactive Curriculum Authoring, Markdown Lesson Studio, Version History & Two-Party Review',
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
                      label: 'Media Library',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.md,
                      icon: Icons.photo_library_outlined,
                      onPressed: () => context.push('/content/studio/media'),
                    ),
                    AppButton(
                      key: const Key('create-new-lesson-btn'),
                      label: 'New Lesson',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.md,
                      icon: Icons.add,
                      onPressed: () => context.push('/content/studio/editor'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Metrics Grid
            metricsAsync.when(
              data: (m) => LayoutBuilder(
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
                        label: 'Total Lessons',
                        value: '${m.totalLessons}',
                        subtitle: '${m.totalTopics} topics across ${m.totalSubjects} subjects',
                        icon: Icons.auto_stories,
                        color: LearnTzColors.primary,
                      ),
                      _buildKpiCard(
                        label: 'Published Lessons',
                        value: '${m.publishedLessons}',
                        subtitle: 'Active curriculum material',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF15803D),
                      ),
                      _buildKpiCard(
                        label: 'Drafts & Revisions',
                        value: '${m.draftLessons}',
                        subtitle: '${m.inReviewLessons} in review queue',
                        icon: Icons.edit_note,
                        color: LearnTzColors.accent,
                      ),
                      _buildKpiCard(
                        label: 'Media Assets',
                        value: '${m.totalMediaAssets}',
                        subtitle: 'Diagrams, audio, & illustrations',
                        icon: Icons.perm_media_outlined,
                        color: const Color(0xFF7C3AED),
                      ),
                    ],
                  );
                },
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Filter Bar (Country Chips & Search)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Market Filter:',
                    style: LearnTzTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    children: ['ALL', 'TZ', 'KE', 'UG'].map((code) {
                      final isSelected = selectedCountry == code;
                      return ChoiceChip(
                        label: Text(code == 'ALL' ? 'All Markets' : code),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            ref
                                .read(contentStudioCountryFilterProvider.notifier)
                                .setCountry(code);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 250,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search subjects, topics...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) {
                        ref
                            .read(contentStudioSearchQueryProvider.notifier)
                            .setQuery(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Curriculum Catalog Tree
            Text(
              'Curriculum Content Tree',
              style: LearnTzTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: LearnTzColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            catalogAsync.when(
              data: (subjects) {
                if (subjects.isEmpty) {
                  return AppCard(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.menu_book,
                              size: 48, color: LearnTzColors.neutral400),
                          const SizedBox(height: 12),
                          Text(
                            'No curriculum content found matching filters.',
                            style: LearnTzTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppButton(
                            label: 'Author First Lesson',
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.sm,
                            onPressed: () =>
                                context.push('/content/studio/editor'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subjects.length,
                  itemBuilder: (context, sIndex) {
                    final subject = subjects[sIndex];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Subject Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: LearnTzColors.primary
                                          .withValues(alpha: 0.1),
                                      child: const Icon(
                                        Icons.subject,
                                        color: LearnTzColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subject.subjectName,
                                          style: LearnTzTypography.h3.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Code: ${subject.subjectCode} • Country: ${subject.countryCode}',
                                          style: LearnTzTypography.bodySmall
                                              .copyWith(
                                            color: LearnTzColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                AppBadge(
                                  label: '${subject.topics.length} Topics',
                                  variant: AppBadgeVariant.neutral,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),

                            // Topics & Lessons
                            if (subject.topics.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No topics yet under this subject.',
                                  style: LearnTzTypography.bodySmall.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: subject.topics.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, tIndex) {
                                  final topic = subject.topics[tIndex];
                                  return ExpansionTile(
                                    tilePadding: EdgeInsets.zero,
                                    title: Text(
                                      'Topic ${topic.topicOrder}: ${topic.topicTitle}',
                                      style:
                                          LearnTzTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${topic.lessons.length} lessons',
                                      style: LearnTzTypography.caption,
                                    ),
                                    trailing: Wrap(
                                      spacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        AppBadge(
                                          label: topic.isPublished
                                              ? 'PUBLISHED'
                                              : 'DRAFT',
                                          variant: topic.isPublished
                                              ? AppBadgeVariant.success
                                              : AppBadgeVariant.warning,
                                          size: AppBadgeSize.sm,
                                        ),
                                        const Icon(Icons.expand_more),
                                      ],
                                    ),
                                    children: [
                                      if (topic.lessons.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            'No lessons in this topic yet.',
                                            style: LearnTzTypography.bodySmall
                                                .copyWith(
                                              color:
                                                  LearnTzColors.textSecondary,
                                            ),
                                          ),
                                        )
                                      else
                                        ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: topic.lessons.length,
                                          separatorBuilder: (_, _) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, lIndex) {
                                            final lesson =
                                                topic.lessons[lIndex];
                                            return ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              leading: CircleAvatar(
                                                radius: 14,
                                                backgroundColor:
                                                    LearnTzColors.neutral200,
                                                child: Text(
                                                  '${lesson.lessonOrder}',
                                                  style: LearnTzTypography
                                                      .caption
                                                      .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                lesson.lessonTitle,
                                                style: LearnTzTypography
                                                    .bodyRegular
                                                    .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                '~${lesson.estimatedMinutes} min • v${lesson.versionNumber} ${lesson.isFreePreview ? "• Free Preview" : ""}',
                                                style:
                                                    LearnTzTypography.bodySmall,
                                              ),
                                              trailing: Wrap(
                                                spacing: 8,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  AppBadge(
                                                    label: lesson
                                                        .status.displayName
                                                        .toUpperCase(),
                                                    variant: _getBadgeVariant(
                                                        lesson.status),
                                                    size: AppBadgeSize.sm,
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.edit_outlined),
                                                    tooltip: 'Edit in Studio',
                                                    onPressed: () =>
                                                        context.push(
                                                      '/content/studio/editor',
                                                      extra: {
                                                        'lessonId':
                                                            lesson.lessonId,
                                                        'topicId':
                                                            topic.topicId,
                                                        'title':
                                                            lesson.lessonTitle,
                                                        'summary': lesson
                                                            .lessonSummary,
                                                        'minutes': lesson
                                                            .estimatedMinutes,
                                                        'freePreview': lesson
                                                            .isFreePreview,
                                                        'status': lesson
                                                            .status.dbValue,
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: LearnTzColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load content studio catalog: $err',
                        style: LearnTzTypography.bodyLarge.copyWith(
                          color: LearnTzColors.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Retry',
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.md,
                        onPressed: () =>
                            ref.invalidate(contentStudioCatalogProvider),
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

  AppBadgeVariant _getBadgeVariant(ContentWorkflowStatus status) {
    return switch (status) {
      ContentWorkflowStatus.published => AppBadgeVariant.success,
      ContentWorkflowStatus.inReview => AppBadgeVariant.info,
      ContentWorkflowStatus.approved => AppBadgeVariant.accent,
      ContentWorkflowStatus.archived => AppBadgeVariant.neutral,
      ContentWorkflowStatus.draft => AppBadgeVariant.warning,
    };
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
