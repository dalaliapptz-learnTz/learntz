import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../learners/learner_providers.dart';
import '../social_models.dart';
import '../social_providers.dart';

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() =>
      _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  String? _selectedPostType;
  String? _selectedSubjectId;

  static const _filterTypes = [
    (null, 'All'),
    ('question', 'Questions ❓'),
    ('concept_explanation', 'Explanations 💡'),
    ('study_tip', 'Study Tips 🎯'),
    ('revision_notes', 'Notes 📝'),
    ('discovery', 'Discoveries 🔬'),
    ('resource_share', 'Resources 📚'),
  ];

  @override
  Widget build(BuildContext context) {
    final activeLearner = ref.watch(activeLearnerProvider);

    if (activeLearner == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Community Feed')),
        body: const Center(
          child: Text('Please select an active learner to access the feed.'),
        ),
      );
    }

    final feedAsync = ref.watch(
      socialFeedProvider((
        viewerId: activeLearner.id,
        postType: _selectedPostType,
        subjectId: _selectedSubjectId,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Educational Community Feed'),
        actions: [
          IconButton(
            tooltip: 'Refresh Feed',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(
              socialFeedProvider((
                viewerId: activeLearner.id,
                postType: _selectedPostType,
                subjectId: _selectedSubjectId,
              )),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Ask / Share'),
        onPressed: () => _showCreatePostDialog(context, activeLearner.id),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _filterTypes.map((entry) {
                final isSelected = _selectedPostType == entry.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.$2),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPostType = selected ? entry.$1 : null;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Posts Feed List
          Expanded(
            child: feedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error loading posts: $err'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(
                          socialFeedProvider((
                            viewerId: activeLearner.id,
                            postType: _selectedPostType,
                            subjectId: _selectedSubjectId,
                          )),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.forum_outlined,
                              size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No educational posts in this category yet.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to ask an academic question or share a study tip!',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _PostCard(
                      post: post,
                      viewerLearnerId: activeLearner.id,
                      onReactionChanged: () {
                        ref.invalidate(
                          socialFeedProvider((
                            viewerId: activeLearner.id,
                            postType: _selectedPostType,
                            subjectId: _selectedSubjectId,
                          )),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context, String learnerId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CreatePostSheet(
        authorLearnerId: learnerId,
        onCreated: () {
          ref.invalidate(
            socialFeedProvider((
              viewerId: learnerId,
              postType: _selectedPostType,
              subjectId: _selectedSubjectId,
            )),
          );
        },
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final SocialPost post;
  final String viewerLearnerId;
  final VoidCallback onReactionChanged;

  const _PostCard({
    required this.post,
    required this.viewerLearnerId,
    required this.onReactionChanged,
  });

  String _formatPostType(String type) {
    switch (type) {
      case 'question':
        return 'Question';
      case 'concept_explanation':
        return 'Explanation';
      case 'study_tip':
        return 'Study Tip';
      case 'revision_notes':
        return 'Notes';
      case 'discovery':
        return 'Discovery';
      case 'resource_share':
        return 'Resource';
      default:
        return 'Post';
    }
  }

  Color _getPostTypeColor(String type) {
    switch (type) {
      case 'question':
        return Colors.orange;
      case 'concept_explanation':
        return Colors.green;
      case 'study_tip':
        return Colors.purple;
      case 'revision_notes':
        return Colors.blue;
      case 'discovery':
        return Colors.teal;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final avatar = getAvatarPreset(post.authorAvatarPreset);
    final typeColor = _getPostTypeColor(post.postType);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: avatar.primaryColor,
                  child: Icon(avatar.icon, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorDisplayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        avatar.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatPostType(post.postType),
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title & Content
            Text(
              post.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              post.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade800,
              ),
            ),
            if (post.subjectName != null) ...[
              const SizedBox(height: 10),
              Chip(
                label: Text(post.subjectName!),
                labelStyle: const TextStyle(fontSize: 11),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Interactions row
            Row(
              children: [
                // Helpful Reaction
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(socialRepositoryProvider).toggleReaction(
                            postId: post.id,
                            learnerId: viewerLearnerId,
                            reactionType: 'helpful',
                          );
                      onReactionChanged();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Reaction error: $e')),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    post.viewerHasReacted
                        ? Icons.thumb_up_alt
                        : Icons.thumb_up_alt_outlined,
                    size: 18,
                    color: post.viewerHasReacted ? theme.primaryColor : null,
                  ),
                  label: Text('${post.likesCount}'),
                ),

                // Comment Button
                TextButton.icon(
                  onPressed: () => _showCommentsSheet(context, ref),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text('${post.commentsCount}'),
                ),

                const Spacer(),

                // Save / Bookmark Button
                IconButton(
                  tooltip: 'Save for revision',
                  icon: Icon(
                    post.viewerHasSaved
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: post.viewerHasSaved ? Colors.amber.shade800 : null,
                  ),
                  onPressed: () async {
                    try {
                      await ref.read(socialRepositoryProvider).toggleSavePost(
                            postId: post.id,
                            learnerId: viewerLearnerId,
                          );
                      onReactionChanged();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Save error: $e')),
                        );
                      }
                    }
                  },
                ),

                // Block Author Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) async {
                    if (val == 'block') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Block Learner?'),
                          content: const Text(
                            'Their posts and comments will no longer appear in your feed.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Block'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await ref.read(socialRepositoryProvider).blockLearner(
                              blockerLearnerId: viewerLearnerId,
                              blockedLearnerId: post.authorLearnerId,
                            );
                        onReactionChanged();
                      }
                    }
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(
                      value: 'block',
                      child: Text('Block Contributor'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CommentsSheet(
        postId: post.id,
        viewerLearnerId: viewerLearnerId,
        onCommentAdded: onReactionChanged,
      ),
    );
  }
}

class _CreatePostSheet extends ConsumerStatefulWidget {
  final String authorLearnerId;
  final VoidCallback onCreated;

  const _CreatePostSheet({
    required this.authorLearnerId,
    required this.onCreated,
  });

  @override
  ConsumerState<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<_CreatePostSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _postType = 'question';
  String? _selectedSubjectId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool _containsProhibitedInfo(String text) {
    final phoneRegex = RegExp(r'([0-9]{3,}.*[0-9]{4,})');
    final emailRegex = RegExp(r'@');
    final linkRegex = RegExp(r'https?://');
    return phoneRegex.hasMatch(text) ||
        emailRegex.hasMatch(text) ||
        linkRegex.hasMatch(text);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(socialRepositoryProvider).createPost(
            authorLearnerId: widget.authorLearnerId,
            postType: _postType,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            subjectId: _selectedSubjectId,
          );

      if (mounted) {
        widget.onCreated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Educational post shared successfully! (+10 pts)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share with Educational Community',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Child safety shield: No phone numbers, external links, or emails allowed.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Post Type selector
              DropdownButtonFormField<String>(
                initialValue: _postType,
                decoration: const InputDecoration(
                  labelText: 'Post Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'question',
                    child: Text('Academic Question ❓'),
                  ),
                  DropdownMenuItem(
                    value: 'concept_explanation',
                    child: Text('Concept Explanation 💡'),
                  ),
                  DropdownMenuItem(
                    value: 'study_tip',
                    child: Text('Study Tip 🎯'),
                  ),
                  DropdownMenuItem(
                    value: 'revision_notes',
                    child: Text('Revision Notes 📝'),
                  ),
                  DropdownMenuItem(
                    value: 'discovery',
                    child: Text('Educational Discovery 🔬'),
                  ),
                  DropdownMenuItem(
                    value: 'resource_share',
                    child: Text('Resource Recommendation 📚'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _postType = val);
                },
              ),
              const SizedBox(height: 14),

              // Subject selector (optional)
              DropdownButtonFormField<String>(
                initialValue: _selectedSubjectId,
                decoration: const InputDecoration(
                  labelText: 'Subject Focus (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text('General / Cross-Subject'),
                  ),
                  DropdownMenuItem(
                    value: 'Mathematics',
                    child: Text('Mathematics'),
                  ),
                  DropdownMenuItem(
                    value: 'Science',
                    child: Text('Science'),
                  ),
                  DropdownMenuItem(
                    value: 'Physics',
                    child: Text('Physics'),
                  ),
                  DropdownMenuItem(
                    value: 'Chemistry',
                    child: Text('Chemistry'),
                  ),
                  DropdownMenuItem(
                    value: 'Biology',
                    child: Text('Biology'),
                  ),
                  DropdownMenuItem(
                    value: 'English',
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: 'Kiswahili',
                    child: Text('Kiswahili'),
                  ),
                  DropdownMenuItem(
                    value: 'History',
                    child: Text('History'),
                  ),
                  DropdownMenuItem(
                    value: 'Geography',
                    child: Text('Geography'),
                  ),
                ],
                onChanged: (val) =>
                    setState(() => _selectedSubjectId = val),
              ),
              const SizedBox(height: 14),

              // Title
              TextFormField(
                controller: _titleController,
                maxLength: 140,
                decoration: const InputDecoration(
                  labelText: 'Title / Subject of Discussion',
                  hintText: 'e.g. How does photosynthesis work in cold climates?',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 4) {
                    return 'Title must be at least 4 characters';
                  }
                  if (_containsProhibitedInfo(val)) {
                    return 'Child safety rule: Phone numbers, emails, or links are not allowed.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Content
              TextFormField(
                controller: _contentController,
                maxLength: 2000,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Explanation / Question Details',
                  hintText: 'Describe clearly so peers and educators can help or learn.',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 10) {
                    return 'Content must be at least 10 characters';
                  }
                  if (_containsProhibitedInfo(val)) {
                    return 'Child safety rule: Phone numbers, emails, or links are not allowed.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Publish to Community',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  final String viewerLearnerId;
  final VoidCallback onCommentAdded;

  const _CommentsSheet({
    required this.postId,
    required this.viewerLearnerId,
    required this.onCommentAdded,
  });

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool _containsProhibitedInfo(String text) {
    final phoneRegex = RegExp(r'([0-9]{3,}.*[0-9]{4,})');
    final emailRegex = RegExp(r'@');
    final linkRegex = RegExp(r'https?://');
    return phoneRegex.hasMatch(text) ||
        emailRegex.hasMatch(text) ||
        linkRegex.hasMatch(text);
  }

  Future<void> _handlePostComment() async {
    final text = _commentController.text.trim();
    if (text.length < 2) return;

    if (_containsProhibitedInfo(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone numbers, emails, and links are prohibited.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      await ref.read(socialRepositoryProvider).addComment(
            postId: widget.postId,
            authorLearnerId: widget.viewerLearnerId,
            content: text,
          );

      _commentController.clear();
      ref.invalidate(postCommentsProvider((
        postId: widget.postId,
        viewerId: widget.viewerLearnerId,
      )));
      widget.onCommentAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comment failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsAsync = ref.watch(postCommentsProvider((
      postId: widget.postId,
      viewerId: widget.viewerLearnerId,
    )));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Academic Discussion & Answers',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),

          // Comments List
          Expanded(
            child: commentsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('No replies yet. Be the first to help out!'),
                  );
                }

                return ListView.separated(
                  itemCount: comments.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final avatar =
                        getAvatarPreset(comment.authorAvatarPreset);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: avatar.primaryColor,
                          child: Icon(avatar.icon,
                              size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.authorDisplayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                comment.content,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Comment Composer
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  maxLength: 600,
                  decoration: const InputDecoration(
                    hintText: 'Write a helpful academic answer or tip...',
                    counterText: '',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: _isPosting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                onPressed: _isPosting ? null : _handlePostComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
