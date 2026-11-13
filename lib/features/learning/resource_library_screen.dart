import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../learners/learner_providers.dart';
import 'learning_providers.dart';

class ResourceLibraryScreen extends ConsumerStatefulWidget {
  const ResourceLibraryScreen({super.key});

  @override
  ConsumerState<ResourceLibraryScreen> createState() =>
      _ResourceLibraryScreenState();
}

class _ResourceLibraryScreenState extends ConsumerState<ResourceLibraryScreen> {
  String? _selectedResourceType;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final Set<String> _downloadedResourceIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _iconForResourceType(String type) {
    switch (type) {
      case 'textbook':
        return Icons.menu_book_outlined;
      case 'study_guide':
      case 'revision_summary':
        return Icons.auto_stories_outlined;
      case 'worksheet':
        return Icons.assignment_outlined;
      case 'audio_lesson':
        return Icons.headphones_outlined;
      case 'video_guide':
        return Icons.play_circle_outline;
      case 'past_paper':
        return Icons.history_edu_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeLearner = ref.watch(activeLearnerProvider);
    final countryCode = activeLearner?.countryCode ?? 'TZ';
    final curriculumId = activeLearner?.curriculumId;

    final resourcesAsync = ref.watch(
      learningResourcesProvider((
        countryCode: countryCode,
        curriculumId: curriculumId,
        subjectId: null,
        resourceType: _selectedResourceType,
      )),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.learn),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.resourceLibraryTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          l10n.resourceLibrarySubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.revisionCentre),
                    icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                    label: Text(l10n.revisionCentreTitle),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Search & filter bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l10n.searchResourcesHint,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.allFilter),
                      selected: _selectedResourceType == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedResourceType = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.textbooksFilter),
                      selected: _selectedResourceType == 'textbook',
                      onSelected: (selected) {
                        setState(() {
                          _selectedResourceType = selected ? 'textbook' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.studyGuidesFilter),
                      selected: _selectedResourceType == 'revision_summary',
                      onSelected: (selected) {
                        setState(() {
                          _selectedResourceType =
                              selected ? 'revision_summary' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.worksheetsFilter),
                      selected: _selectedResourceType == 'worksheet',
                      onSelected: (selected) {
                        setState(() {
                          _selectedResourceType = selected ? 'worksheet' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.audioLessonsFilter),
                      selected: _selectedResourceType == 'audio_lesson',
                      onSelected: (selected) {
                        setState(() {
                          _selectedResourceType =
                              selected ? 'audio_lesson' : null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Resources list
              resourcesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('${l10n.requestFailed}: $e'),
                  ),
                ),
                data: (allResources) {
                  final filtered = allResources.where((r) {
                    if (_searchQuery.isEmpty) return true;
                    return r.title.toLowerCase().contains(_searchQuery) ||
                        r.description.toLowerCase().contains(_searchQuery) ||
                        r.subjectName.toLowerCase().contains(_searchQuery) ||
                        r.authorOrPublisher.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.find_in_page_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.noResourcesFound,
                                style: Theme.of(context).textTheme.titleMedium,
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
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isDownloaded =
                          _downloadedResourceIds.contains(item.id);
                      final icon = _iconForResourceType(item.resourceType);

                      return AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.subjectName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (item.isOfficial) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              l10n.officialBadge,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        Text(
                                          item.fileFormat.toUpperCase(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        if (item.fileSizeBytes != null) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            '• ${_formatFileSize(item.fileSizeBytes)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (item.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      '${l10n.publisherLabel}: ${item.authorOrPublisher}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  setState(() {
                                    if (isDownloaded) {
                                      _downloadedResourceIds.remove(item.id);
                                    } else {
                                      _downloadedResourceIds.add(item.id);
                                    }
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isDownloaded
                                            ? l10n.resourceRemovedOffline
                                            : l10n.resourceSavedOffline,
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  isDownloaded
                                      ? Icons.check_circle
                                      : Icons.download,
                                  size: 18,
                                ),
                                label: Text(
                                  isDownloaded
                                      ? l10n.downloadedAction
                                      : l10n.downloadAction,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
