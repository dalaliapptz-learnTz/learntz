import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../content_studio_models.dart';
import '../content_studio_providers.dart';

class LessonEditorStudioScreen extends ConsumerStatefulWidget {
  const LessonEditorStudioScreen({
    super.key,
    this.initialData,
  });

  final Map<String, dynamic>? initialData;

  @override
  ConsumerState<LessonEditorStudioScreen> createState() =>
      _LessonEditorStudioScreenState();
}

class _LessonEditorStudioScreenState
    extends ConsumerState<LessonEditorStudioScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _bodyController;
  late final TextEditingController _reviewNotesController;

  String? _selectedTopicId;
  int _estimatedMinutes = 10;
  bool _isFreePreview = false;
  ContentWorkflowStatus _status = ContentWorkflowStatus.draft;
  String? _lessonId;
  int _versionNumber = 1;

  bool _isSaving = false;
  String? _feedbackMessage;
  bool _isError = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    _lessonId = data['lessonId'] as String?;
    _selectedTopicId = data['topicId'] as String?;
    _titleController =
        TextEditingController(text: data['title'] as String? ?? '');
    _summaryController =
        TextEditingController(text: data['summary'] as String? ?? '');
    _bodyController = TextEditingController(
      text: data['bodyMarkdown'] as String? ??
          '# Introduction\n\nWelcome to this lesson. In this section, we explore key foundational principles.\n\n## Core Concepts\n\n- Essential principle one\n- Mathematical reasoning & formulas\n\n> **Key Takeaway**: Consistent practice and revision reinforce retention.\n',
    );
    _reviewNotesController = TextEditingController();

    if (data['minutes'] != null) {
      _estimatedMinutes = (data['minutes'] as num).toInt();
    }
    if (data['freePreview'] != null) {
      _isFreePreview = data['freePreview'] as bool;
    }
    if (data['status'] != null) {
      _status = ContentWorkflowStatus.fromString(data['status'] as String?);
    }
    if (data['versionNumber'] != null) {
      _versionNumber = (data['versionNumber'] as num).toInt();
    }

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _bodyController.dispose();
    _reviewNotesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _insertAtCursor(String snippet) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    if (selection.start >= 0 && selection.end >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, snippet);
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + snippet.length,
        ),
      );
    } else {
      _bodyController.value = TextEditingValue(
        text: text + snippet,
        selection: TextSelection.collapsed(offset: text.length + snippet.length),
      );
    }
    setState(() {});
  }

  Future<void> _saveLesson({required String targetStatus}) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _feedbackMessage = 'Lesson title cannot be empty.';
        _isError = true;
      });
      return;
    }

    final topicId = _selectedTopicId;
    if (topicId == null || topicId.isEmpty) {
      setState(() {
        _feedbackMessage = 'Please select a topic for this lesson.';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _feedbackMessage = null;
      _isError = false;
    });

    try {
      final repo = ref.read(contentStudioRepositoryProvider);
      final result = await repo.upsertStudioLesson(
        topicId: topicId,
        title: title,
        bodyMarkdown: _bodyController.text,
        summary: _summaryController.text.trim().isEmpty
            ? null
            : _summaryController.text.trim(),
        estimatedMinutes: _estimatedMinutes,
        isFreePreview: _isFreePreview,
        status: targetStatus,
        lessonId: _lessonId,
      );

      final newLessonId = result['id'] as String?;
      if (newLessonId != null) {
        _lessonId = newLessonId;
      }
      final newStatusStr = result['status'] as String?;
      if (newStatusStr != null) {
        _status = ContentWorkflowStatus.fromString(newStatusStr);
      }
      final newVer = (result['version_number'] as num?)?.toInt();
      if (newVer != null) {
        _versionNumber = newVer;
      }

      ref.invalidate(contentStudioMetricsProvider);
      ref.invalidate(contentStudioCatalogProvider);

      if (mounted) {
        setState(() {
          _feedbackMessage = targetStatus == 'published'
              ? 'Lesson successfully published to curriculum (v$_versionNumber)!'
              : targetStatus == 'in_review'
                  ? 'Lesson submitted for review (v$_versionNumber).'
                  : 'Draft saved successfully (v$_versionNumber).';
          _isError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedbackMessage = 'Save failed: ${e.toString()}';
          _isError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _submitReviewAction(String action) async {
    final lessonId = _lessonId;
    if (lessonId == null) {
      setState(() {
        _feedbackMessage = 'Please save the draft before submitting a review action.';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _feedbackMessage = null;
      _isError = false;
    });

    try {
      final repo = ref.read(contentStudioRepositoryProvider);
      final result = await repo.submitLessonReview(
        lessonId: lessonId,
        action: action,
        feedback: _reviewNotesController.text.trim().isEmpty
            ? null
            : _reviewNotesController.text.trim(),
      );

      final newStatusStr = result['status'] as String?;
      if (newStatusStr != null) {
        _status = ContentWorkflowStatus.fromString(newStatusStr);
      }

      ref.invalidate(contentStudioMetricsProvider);
      ref.invalidate(contentStudioCatalogProvider);

      if (mounted) {
        setState(() {
          _feedbackMessage = 'Review action "$action" applied successfully.';
          _isError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedbackMessage = 'Review action failed: ${e.toString()}';
          _isError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  AppBadgeVariant _getBadgeVariant(ContentWorkflowStatus status) {
    switch (status) {
      case ContentWorkflowStatus.published:
        return AppBadgeVariant.success;
      case ContentWorkflowStatus.inReview:
        return AppBadgeVariant.warning;
      case ContentWorkflowStatus.approved:
        return AppBadgeVariant.primary;
      case ContentWorkflowStatus.draft:
      case ContentWorkflowStatus.archived:
        return AppBadgeVariant.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(studioFlatTopicsProvider);

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      appBar: AppBar(
        backgroundColor: LearnTzColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              _lessonId != null ? 'Edit Lesson Studio' : 'Author New Lesson',
              style: LearnTzTypography.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            AppBadge(
              label: _status.displayName.toUpperCase(),
              variant: _getBadgeVariant(_status),
            ),
            AppBadge(
              label: 'v$_versionNumber',
              variant: AppBadgeVariant.neutral,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppButton(
                  label: 'Save Draft',
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.sm,
                  icon: Icons.save_outlined,
                  isLoading: _isSaving,
                  onPressed: _isSaving
                      ? null
                      : () => _saveLesson(targetStatus: 'draft'),
                ),
                AppButton(
                  label: 'Submit for Review',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  icon: Icons.rate_review_outlined,
                  isLoading: _isSaving,
                  onPressed: _isSaving
                      ? null
                      : () => _saveLesson(targetStatus: 'in_review'),
                ),
                AppButton(
                  label: 'Publish',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  icon: Icons.cloud_upload_outlined,
                  isLoading: _isSaving,
                  onPressed: _isSaving
                      ? null
                      : () => _saveLesson(targetStatus: 'published'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;

          return Column(
            children: [
              if (_feedbackMessage != null)
                Container(
                  width: double.infinity,
                  color: _isError ? LearnTzColors.errorBg : LearnTzColors.successBg,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        _isError
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: _isError
                            ? LearnTzColors.error
                            : LearnTzColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _feedbackMessage!,
                          style: LearnTzTypography.bodySmall.copyWith(
                            color: _isError
                                ? LearnTzColors.error
                                : LearnTzColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() => _feedbackMessage = null),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: isDesktop
                    ? _buildSplitScreen(topicsAsync)
                    : _buildTabbedScreen(topicsAsync),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSplitScreen(AsyncValue<List<FlatTopicOption>> topicsAsync) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Metadata & Markdown Editor
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMetadataCard(topicsAsync),
                const SizedBox(height: 16),
                _buildEditorToolbar(),
                const SizedBox(height: 8),
                _buildEditorCard(),
                const SizedBox(height: 16),
                _buildEditorialWorkflowCard(),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // Right Column: Live Student Reader Preview
        Expanded(
          flex: 5,
          child: Container(
            color: LearnTzColors.surface,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Live Student Reader Preview',
                      style: LearnTzTypography.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: LearnTzColors.textPrimary,
                      ),
                    ),
                    const AppBadge(
                      label: 'Student View Simulation',
                      variant: AppBadgeVariant.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildLivePreviewContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabbedScreen(AsyncValue<List<FlatTopicOption>> topicsAsync) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: LearnTzColors.primary,
          unselectedLabelColor: LearnTzColors.textSecondary,
          indicatorColor: LearnTzColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.edit_outlined), text: 'Authoring Studio'),
            Tab(icon: Icon(Icons.visibility_outlined), text: 'Live Preview'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMetadataCard(topicsAsync),
                    const SizedBox(height: 16),
                    _buildEditorToolbar(),
                    const SizedBox(height: 8),
                    _buildEditorCard(),
                    const SizedBox(height: 16),
                    _buildEditorialWorkflowCard(),
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildLivePreviewContent(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataCard(AsyncValue<List<FlatTopicOption>> topicsAsync) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lesson Information',
            style: LearnTzTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('lesson-title-field'),
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Lesson Title *',
              hintText: 'e.g. Structure and Function of Mitochondria',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Topic Selector
          topicsAsync.when(
            data: (topics) {
              final items = topics.map((t) {
                return DropdownMenuItem<String>(
                  value: t.topicId,
                  child: Text(
                    t.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList();

              final isValidValue =
                  topics.any((t) => t.topicId == _selectedTopicId);

              return DropdownButtonFormField<String>(
                key: const Key('lesson-topic-dropdown'),
                isExpanded: true,
                initialValue: isValidValue
                    ? _selectedTopicId
                    : (topics.isNotEmpty ? topics.first.topicId : null),
                decoration: const InputDecoration(
                  labelText: 'Curriculum Topic *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: items,
                onChanged: (val) {
                  setState(() => _selectedTopicId = val);
                },
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => TextField(
              decoration: const InputDecoration(
                labelText: 'Topic ID *',
                hintText: 'Enter topic UUID',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => _selectedTopicId = v.trim(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _summaryController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Abstract / Summary',
              hintText: 'Short synopsis introducing key lesson takeaways...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Study Time: $_estimatedMinutes min',
                      style: LearnTzTypography.bodySmall
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: _estimatedMinutes.toDouble(),
                      min: 5,
                      max: 90,
                      divisions: 17,
                      label: '$_estimatedMinutes min',
                      onChanged: (val) {
                        setState(() => _estimatedMinutes = val.round());
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Free Preview',
                    style: LearnTzTypography.bodySmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Switch(
                    value: _isFreePreview,
                    onChanged: (val) {
                      setState(() => _isFreePreview = val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditorToolbar() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _toolbarButton('H1', () => _insertAtCursor('\n# ')),
          _toolbarButton('H2', () => _insertAtCursor('\n## ')),
          _toolbarButton('H3', () => _insertAtCursor('\n### ')),
          const VerticalDivider(width: 12),
          IconButton(
            icon: const Icon(Icons.format_bold, size: 20),
            tooltip: 'Bold',
            onPressed: () => _insertAtCursor('**bold text**'),
          ),
          IconButton(
            icon: const Icon(Icons.format_italic, size: 20),
            tooltip: 'Italic',
            onPressed: () => _insertAtCursor('*italic text*'),
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted, size: 20),
            tooltip: 'Bullet List',
            onPressed: () => _insertAtCursor('\n- Item 1\n- Item 2\n'),
          ),
          IconButton(
            icon: const Icon(Icons.format_quote, size: 20),
            tooltip: 'Callout Quote',
            onPressed: () => _insertAtCursor('\n> **Note**: Key summary point.\n'),
          ),
          IconButton(
            icon: const Icon(Icons.code, size: 20),
            tooltip: 'Code Block',
            onPressed: () => _insertAtCursor('\n```text\nCode or snippet\n```\n'),
          ),
          IconButton(
            icon: const Icon(Icons.functions, size: 20),
            tooltip: 'KaTeX Math Formula',
            onPressed: () => _insertAtCursor('\n\$\$ E = mc^2 \$\$\n'),
          ),
          const VerticalDivider(width: 12),
          ActionChip(
            avatar: const Icon(Icons.lightbulb_outline, size: 16),
            label: const Text('Tip Callout'),
            onPressed: () => _insertAtCursor(
              '\n> **TIP**: Remember to apply units when calculating velocity.\n',
            ),
          ),
          ActionChip(
            avatar: const Icon(Icons.warning_amber_outlined, size: 16),
            label: const Text('Warning'),
            onPressed: () => _insertAtCursor(
              '\n> **WARNING**: Common pitfall in national exam questions!\n',
            ),
          ),
          ActionChip(
            avatar: const Icon(Icons.image_outlined, size: 16),
            label: const Text('Insert Diagram Link'),
            onPressed: () => _insertAtCursor(
              '\n![Diagram Caption](https://assets.learntz.org/diagrams/sample.png)\n',
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton(String label, VoidCallback onPressed) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size(36, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEditorCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lesson Body (Markdown)',
                style: LearnTzTypography.bodyLarge
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_bodyController.text.length} chars • ${_bodyController.text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length} words',
                style: LearnTzTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('lesson-markdown-body-field'),
            controller: _bodyController,
            maxLines: null,
            minLines: 16,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter lesson markdown content...',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorialWorkflowCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Editorial Governance & Review Actions',
                  style: LearnTzTypography.bodyLarge
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reviewNotesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Editorial Review Feedback / Notes',
              hintText:
                  'Enter constructive critique, revision guidance, or approval comments...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                label: 'Approve & Publish',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.sm,
                icon: Icons.check_circle_outline,
                isLoading: _isSaving,
                onPressed: _lessonId == null || _isSaving
                    ? null
                    : () => _submitReviewAction('approve_and_publish'),
              ),
              AppButton(
                label: 'Reject to Draft',
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.sm,
                icon: Icons.replay,
                isLoading: _isSaving,
                onPressed: _lessonId == null || _isSaving
                    ? null
                    : () => _submitReviewAction('reject_to_draft'),
              ),
              AppButton(
                label: 'Archive Lesson',
                variant: AppButtonVariant.destructive,
                size: AppButtonSize.sm,
                icon: Icons.archive_outlined,
                isLoading: _isSaving,
                onPressed: _lessonId == null || _isSaving
                    ? null
                    : () => _submitReviewAction('archive'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewContent() {
    final title = _titleController.text.trim();
    final summary = _summaryController.text.trim();
    final body = _bodyController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & metadata simulation
        Text(
          title.isEmpty ? 'Untitled Lesson' : title,
          style: LearnTzTypography.h2.copyWith(
            fontWeight: FontWeight.bold,
            color: LearnTzColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.timer_outlined, size: 16, color: LearnTzColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '$_estimatedMinutes min read',
              style: LearnTzTypography.caption,
            ),
            const SizedBox(width: 12),
            if (_isFreePreview)
              const AppBadge(
                label: 'FREE PREVIEW',
                variant: AppBadgeVariant.success,
                size: AppBadgeSize.sm,
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (summary.isNotEmpty) ...[
          AppCard(
            backgroundColor: LearnTzColors.primary50,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: LearnTzColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    summary,
                    style: LearnTzTypography.bodyRegular.copyWith(
                      fontStyle: FontStyle.italic,
                      color: LearnTzColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Markdown blocks simulation
        ..._renderMarkdownElements(body),
      ],
    );
  }

  List<Widget> _renderMarkdownElements(String markdown) {
    final widgets = <Widget>[];
    final lines = markdown.split('\n');
    final buffer = StringBuffer();

    void flushBuffer() {
      if (buffer.isNotEmpty) {
        final text = buffer.toString().trim();
        if (text.isNotEmpty) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              text,
              style: LearnTzTypography.bodyRegular.copyWith(height: 1.6),
            ),
          ));
        }
        buffer.clear();
      }
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('# ')) {
        flushBuffer();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            line.substring(2),
            style: LearnTzTypography.h2.copyWith(fontWeight: FontWeight.bold),
          ),
        ));
      } else if (line.startsWith('## ')) {
        flushBuffer();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            line.substring(3),
            style: LearnTzTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
        ));
      } else if (line.startsWith('### ')) {
        flushBuffer();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            line.substring(4),
            style: LearnTzTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
        ));
      } else if (line.startsWith('> ')) {
        flushBuffer();
        final quoteText = line.substring(2);
        final isWarning = quoteText.contains('WARNING');
        final isTip = quoteText.contains('TIP');

        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AppCard(
            backgroundColor: isWarning
                ? LearnTzColors.warningBg
                : isTip
                    ? LearnTzColors.secondary50
                    : LearnTzColors.neutral100,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  isWarning
                      ? Icons.warning_amber
                      : isTip
                          ? Icons.lightbulb_outline
                          : Icons.format_quote,
                  color: isWarning
                      ? LearnTzColors.warning
                      : isTip
                          ? LearnTzColors.secondary
                          : LearnTzColors.neutral600,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    quoteText.replaceAll('**', ''),
                    style: LearnTzTypography.bodyRegular.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        flushBuffer();
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: LearnTzTypography.bodyRegular,
                ),
              ),
            ],
          ),
        ));
      } else if (line.startsWith('\$\$') && line.endsWith('\$\$') && line.length > 4) {
        flushBuffer();
        final formula = line.substring(2, line.length - 2).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LearnTzColors.neutral100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LearnTzColors.neutral300),
            ),
            child: Center(
              child: Text(
                formula,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontStyle: FontStyle.italic,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ));
      } else if (line.startsWith('![') && line.contains('](') && line.endsWith(')')) {
        flushBuffer();
        final caption = line.substring(2, line.indexOf(']('));
        final url = line.substring(line.indexOf('](') + 2, line.length - 1);
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  height: 120,
                  color: LearnTzColors.neutral200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image, size: 36, color: LearnTzColors.neutral500),
                        const SizedBox(height: 4),
                        Text(
                          url,
                          style: LearnTzTypography.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                if (caption.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    caption,
                    style: LearnTzTypography.caption.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ));
      } else if (line.trim().isEmpty) {
        flushBuffer();
      } else {
        buffer.writeln(line);
      }
    }
    flushBuffer();

    return widgets;
  }
}
