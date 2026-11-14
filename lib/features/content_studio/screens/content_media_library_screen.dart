import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../content_studio_models.dart';
import '../content_studio_providers.dart';

class ContentMediaLibraryScreen extends ConsumerStatefulWidget {
  const ContentMediaLibraryScreen({super.key});

  @override
  ConsumerState<ContentMediaLibraryScreen> createState() =>
      _ContentMediaLibraryScreenState();
}

class _ContentMediaLibraryScreenState
    extends ConsumerState<ContentMediaLibraryScreen> {
  String _selectedType = 'ALL';
  String _searchFilter = '';

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 2),
        backgroundColor: LearnTzColors.primary,
      ),
    );
  }

  void _showAddAssetDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => _AddMediaAssetDialog(
        onSaved: () {
          ref.invalidate(contentMediaAssetsProvider);
          ref.invalidate(contentStudioMetricsProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(contentMediaAssetsProvider);
    final selectedCountry = ref.watch(contentStudioCountryFilterProvider);

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      appBar: AppBar(
        backgroundColor: LearnTzColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Media & Diagram Asset Library',
          style: LearnTzTypography.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AppButton(
              key: const Key('add-media-asset-btn'),
              label: 'Add Media Asset',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.sm,
              icon: Icons.add_photo_alternate_outlined,
              onPressed: () => _showAddAssetDialog(context),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Bar
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Market:',
                        style: LearnTzTypography.bodySmall
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      ...['ALL', 'TZ', 'KE', 'UG'].map((code) {
                        return ChoiceChip(
                          label: Text(code == 'ALL' ? 'All Markets' : code),
                          selected: selectedCountry == code,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(contentStudioCountryFilterProvider
                                      .notifier)
                                  .setCountry(code);
                            }
                          },
                        );
                      }),
                      const SizedBox(width: 16),
                      Text(
                        'Media Type:',
                        style: LearnTzTypography.bodySmall
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      ...['ALL', 'diagram', 'image', 'document', 'audio']
                          .map((type) {
                        return ChoiceChip(
                          label: Text(type.toUpperCase()),
                          selected: _selectedType == type,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedType = type);
                            }
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search assets by title or keywords...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) {
                      setState(() => _searchFilter = val.trim().toLowerCase());
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Media Assets Grid
            assetsAsync.when(
              data: (assets) {
                var filtered = assets;
                if (_selectedType != 'ALL') {
                  filtered = filtered
                      .where((a) =>
                          a.mediaType.toLowerCase() ==
                          _selectedType.toLowerCase())
                      .toList();
                }
                if (_searchFilter.isNotEmpty) {
                  filtered = filtered.where((a) {
                    final t = a.title.toLowerCase();
                    final alt = (a.altText ?? '').toLowerCase();
                    return t.contains(_searchFilter) ||
                        alt.contains(_searchFilter);
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return AppCard(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.perm_media_outlined,
                              size: 48, color: LearnTzColors.neutral400),
                          const SizedBox(height: 12),
                          Text(
                            'No media assets match your criteria.',
                            style: LearnTzTypography.bodyLarge
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          AppButton(
                            label: 'Register First Asset',
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.sm,
                            onPressed: () => _showAddAssetDialog(context),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 900;
                    final isTablet = constraints.maxWidth >= 600;
                    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isDesktop ? 1.05 : 1.15,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final asset = filtered[index];
                        return _buildAssetCard(context, asset);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load media assets: $err'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetCard(BuildContext context, MediaAssetItem asset) {
    final sizeKb = (asset.fileSizeBytes / 1024).toStringAsFixed(1);
    final markdownSnippet =
        '![${asset.title.replaceAll('"', '')}](${asset.fileUrl})';

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail / Header
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: LearnTzColors.neutral100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LearnTzColors.neutral200),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _getMediaIcon(asset.mediaType),
                    size: 40,
                    color: LearnTzColors.primary,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: AppBadge(
                    label: asset.countryCode,
                    variant: AppBadgeVariant.neutral,
                    size: AppBadgeSize.sm,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: AppBadge(
                    label: asset.mediaType.toUpperCase(),
                    variant: AppBadgeVariant.primary,
                    size: AppBadgeSize.sm,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            asset.title,
            style: LearnTzTypography.bodyRegular.copyWith(
              fontWeight: FontWeight.bold,
              color: LearnTzColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Alt text / details
          if (asset.altText != null && asset.altText!.isNotEmpty)
            Text(
              asset.altText!,
              style: LearnTzTypography.caption.copyWith(
                color: LearnTzColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            'Size: $sizeKb KB',
            style: LearnTzTypography.caption,
          ),
          const Spacer(),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.code, size: 16),
                  label: const Text('Markdown Link', style: TextStyle(fontSize: 12)),
                  onPressed: () => _copyToClipboard(
                    context,
                    markdownSnippet,
                    'Markdown snippet',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.link, size: 20),
                tooltip: 'Copy direct URL',
                onPressed: () => _copyToClipboard(
                  context,
                  asset.fileUrl,
                  'Direct URL',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getMediaIcon(String type) {
    switch (type.toLowerCase()) {
      case 'diagram':
        return Icons.account_tree_outlined;
      case 'image':
        return Icons.image_outlined;
      case 'audio':
        return Icons.audiotrack_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'document':
      default:
        return Icons.description_outlined;
    }
  }
}

class _AddMediaAssetDialog extends ConsumerStatefulWidget {
  const _AddMediaAssetDialog({required this.onSaved});

  final VoidCallback onSaved;

  @override
  ConsumerState<_AddMediaAssetDialog> createState() =>
      _AddMediaAssetDialogState();
}

class _AddMediaAssetDialogState extends ConsumerState<_AddMediaAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _altTextController = TextEditingController();

  String _countryCode = 'TZ';
  String _mediaType = 'diagram';
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _altTextController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(contentStudioRepositoryProvider);
      await repo.createMediaAsset(
        title: _titleController.text.trim(),
        countryCode: _countryCode,
        mediaType: _mediaType,
        fileUrl: _urlController.text.trim(),
        altText: _altTextController.text.trim().isEmpty
            ? null
            : _altTextController.text.trim(),
        fileSizeBytes: 102400, // placeholder size
      );

      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Media / Diagram Asset'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: LearnTzColors.errorBg,
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: LearnTzColors.error),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  key: const Key('media-title-input'),
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Asset Title *',
                    hintText: 'e.g. Periodic Table Elements Kidato 3',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _countryCode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Country Market',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'TZ', child: Text('Tanzania (TZ)')),
                    DropdownMenuItem(value: 'KE', child: Text('Kenya (KE)')),
                    DropdownMenuItem(value: 'UG', child: Text('Uganda (UG)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _countryCode = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _mediaType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Media Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'diagram', child: Text('Diagram / Schema')),
                    DropdownMenuItem(value: 'image', child: Text('Image / Photo')),
                    DropdownMenuItem(
                        value: 'document', child: Text('Document (PDF/DOC)')),
                    DropdownMenuItem(value: 'audio', child: Text('Audio Recording')),
                    DropdownMenuItem(value: 'video', child: Text('Video Lecture')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _mediaType = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('media-url-input'),
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Asset CDN File URL *',
                    hintText: 'https://assets.learntz.org/diagrams/...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _altTextController,
                  decoration: const InputDecoration(
                    labelText: 'Alt Text / Description',
                    hintText: 'Accessibility description for screen readers',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          key: const Key('media-submit-btn'),
          label: 'Register Asset',
          variant: AppButtonVariant.primary,
          size: AppButtonSize.sm,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _submit,
        ),
      ],
    );
  }
}
