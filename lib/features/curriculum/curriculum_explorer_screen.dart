import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/state/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/auth_screens.dart';
import '../learners/learner_providers.dart';
import '../learning/learning_models.dart';
import '../learning/learning_providers.dart';

class CurriculumExplorerScreen extends ConsumerStatefulWidget {
  const CurriculumExplorerScreen({super.key});

  @override
  ConsumerState<CurriculumExplorerScreen> createState() =>
      _CurriculumExplorerScreenState();
}

class _CurriculumExplorerScreenState
    extends ConsumerState<CurriculumExplorerScreen> {
  String? _selectedCountryCode;
  String? _selectedSystemId;
  String? _selectedLevelId;
  String? _selectedGradeId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final defaultCountry = ref.watch(selectedCountryProvider).countryCode;
    final currentCountry = _selectedCountryCode ?? defaultCountry;

    final catalogAsync = ref.watch(educationCatalogProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.curriculumExplorerTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.curriculumExplorerSubtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              catalogAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AuthInlineMessage(
                  message: l10n.requestFailed,
                  isError: true,
                ),
                data: (catalog) {
                  final systems = catalog.systems
                      .where((s) => s.countryCode == currentCountry && s.isEnabled)
                      .toList();
                  final selectedSystemId = _selectedSystemId ??
                      (systems.isNotEmpty ? systems.first.id : null);

                  final levels = catalog.levels
                      .where((lvl) => lvl.isEnabled)
                      .toList();
                  final grades = catalog.grades
                      .where(
                        (g) =>
                            g.isEnabled &&
                            (_selectedLevelId == null ||
                                g.educationLevelId == _selectedLevelId),
                      )
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter bar
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.filterCurriculumLabel,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                // Country Dropdown
                                SizedBox(
                                  width: 180,
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('country-$currentCountry'),
                                    initialValue: currentCountry,
                                    decoration: InputDecoration(
                                      labelText: l10n.countryLabel,
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    items: catalog.countries.map((c) {
                                      return DropdownMenuItem(
                                        value: c.code,
                                        child: Text(c.name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedCountryCode = val;
                                          _selectedSystemId = null;
                                          _selectedLevelId = null;
                                          _selectedGradeId = null;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                // Education System Dropdown
                                if (systems.isNotEmpty)
                                  SizedBox(
                                    width: 240,
                                    child: DropdownButtonFormField<String>(
                                      key: ValueKey('system-$selectedSystemId'),
                                      initialValue: selectedSystemId,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: l10n.educationSystemLabel,
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                      ),
                                      items: systems.map((s) {
                                        return DropdownMenuItem(
                                          value: s.id,
                                          child: Text(s.name),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedSystemId = val;
                                          _selectedLevelId = null;
                                          _selectedGradeId = null;
                                        });
                                      },
                                    ),
                                  ),
                                // Level Dropdown
                                if (levels.isNotEmpty)
                                  SizedBox(
                                    width: 200,
                                    child: DropdownButtonFormField<String?>(
                                      key: ValueKey('level-$_selectedLevelId'),
                                      initialValue: _selectedLevelId,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: l10n.educationLevelLabel,
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: null,
                                          child: Text(l10n.allLevelsOption),
                                        ),
                                        ...levels.map((lvl) {
                                          return DropdownMenuItem(
                                            value: lvl.id,
                                            child: Text(lvl.name),
                                          );
                                        }),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedLevelId = val;
                                          _selectedGradeId = null;
                                        });
                                      },
                                    ),
                                  ),
                                // Grade Dropdown
                                if (grades.isNotEmpty)
                                  SizedBox(
                                    width: 200,
                                    child: DropdownButtonFormField<String?>(
                                      key: ValueKey('grade-$_selectedGradeId'),
                                      initialValue: _selectedGradeId,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: l10n.gradeClassLabel,
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: null,
                                          child: Text(l10n.allGradesOption),
                                        ),
                                        ...grades.map((g) {
                                          return DropdownMenuItem(
                                            value: g.id,
                                            child: Text(g.name),
                                          );
                                        }),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedGradeId = val;
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (selectedSystemId == null)
                        AppCard(child: Text(l10n.noSystemConfigured))
                      else
                        _SubjectTreeList(
                          countryCode: currentCountry,
                          systemId: selectedSystemId,
                          levelId: _selectedLevelId,
                          gradeId: _selectedGradeId,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectTreeList extends ConsumerWidget {
  const _SubjectTreeList({
    required this.countryCode,
    required this.systemId,
    this.levelId,
    this.gradeId,
  });

  final String countryCode;
  final String systemId;
  final String? levelId;
  final String? gradeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final treeAsync = ref.watch(
      curriculumExplorerTreeProvider((
        countryCode: countryCode,
        educationSystemId: systemId,
        educationLevelId: levelId,
        gradeId: gradeId,
      )),
    );

    return treeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AuthInlineMessage(
        message: l10n.requestFailed,
        isError: true,
      ),
      data: (subjects) {
        if (subjects.isEmpty) {
          return AppCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.noSubjectsPublished)),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subjects.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return _SubjectTreeCard(subject: subject);
          },
        );
      },
    );
  }
}

class _SubjectTreeCard extends StatelessWidget {
  const _SubjectTreeCard({required this.subject});

  final CurriculumExplorerSubject subject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      child: ExpansionTile(
        title: Text(
          subject.subjectName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${subject.subjectCode} • ${subject.topics.length} ${l10n.topicsLabel} • ${subject.totalLessons} ${l10n.lessonsLabel}',
        ),
        childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
        children: [
          if (subject.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              child: Text(
                subject.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          for (final topic in subject.topics)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (topic.summary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          topic.summary,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 8),
                      for (final lesson in topic.lessons)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.menu_book, size: 20),
                          title: Text(lesson.title),
                          subtitle: Text('${lesson.estimatedMinutes} mins'),
                          trailing: FilledButton.tonal(
                            onPressed: () => context.go(AppRoutes.lessonReader(lesson.lessonId)),
                            child: Text(l10n.studyLessonAction),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
