import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../learners/learner_providers.dart';
import '../social_models.dart';
import '../social_providers.dart';

class CommunitiesHubScreen extends ConsumerStatefulWidget {
  const CommunitiesHubScreen({super.key});

  @override
  ConsumerState<CommunitiesHubScreen> createState() =>
      _CommunitiesHubScreenState();
}

class _CommunitiesHubScreenState extends ConsumerState<CommunitiesHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeLearner = ref.watch(activeLearnerProvider);

    if (activeLearner == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Educational Communities')),
        body: const Center(
          child: Text('Please select an active learner to view communities.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Educational Communities Hub'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.groups_outlined), text: 'My Communities'),
            Tab(icon: Icon(Icons.explore_outlined), text: 'Explore & Clubs'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(learnerCommunitiesProvider(activeLearner.id));
              ref.invalidate(discoverableCommunitiesProvider((
                learnerId: activeLearner.id,
                tier: null,
              )));
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyCommunitiesTab(learnerId: activeLearner.id),
          _DiscoverCommunitiesTab(learnerId: activeLearner.id),
        ],
      ),
    );
  }
}

class _MyCommunitiesTab extends ConsumerWidget {
  final String learnerId;

  const _MyCommunitiesTab({required this.learnerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communitiesAsync =
        ref.watch(learnerCommunitiesProvider(learnerId));

    return communitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (communities) {
        if (communities.isEmpty) {
          return const Center(
            child: Text('You are not currently enrolled in any community.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: communities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final community = communities[index];
            return _CommunityCard(
              community: community,
              learnerId: learnerId,
              isMember: true,
              onTapped: () => _openCommunityChannels(context, community, learnerId),
            );
          },
        );
      },
    );
  }

  void _openCommunityChannels(
    BuildContext context,
    Community community,
    String learnerId,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _CommunityDetailScreen(
          community: community,
          learnerId: learnerId,
        ),
      ),
    );
  }
}

class _DiscoverCommunitiesTab extends ConsumerWidget {
  final String learnerId;

  const _DiscoverCommunitiesTab({required this.learnerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoverAsync = ref.watch(
      discoverableCommunitiesProvider((learnerId: learnerId, tier: null)),
    );

    return discoverAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (communities) {
        if (communities.isEmpty) {
          return const Center(
            child: Text('No discoverable clubs or communities found.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: communities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final community = communities[index];
            return _CommunityCard(
              community: community,
              learnerId: learnerId,
              isMember: community.isMember,
              onTapped: community.isMember
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => _CommunityDetailScreen(
                            community: community,
                            learnerId: learnerId,
                          ),
                        ),
                      );
                    }
                  : null,
            );
          },
        );
      },
    );
  }
}

class _CommunityCard extends ConsumerWidget {
  final Community community;
  final String learnerId;
  final bool isMember;
  final VoidCallback? onTapped;

  const _CommunityCard({
    required this.community,
    required this.learnerId,
    required this.isMember,
    this.onTapped,
  });

  String _formatTier(String tier) {
    switch (tier) {
      case 'national':
        return 'National 🇹🇿';
      case 'school':
        return 'School 🏫';
      case 'class':
        return 'Class 📚';
      case 'district':
        return 'District 🏛️';
      case 'region':
        return 'Region 🌍';
      case 'subject':
        return 'Subject Club 🔬';
      default:
        return tier.toUpperCase();
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier) {
      case 'national':
        return Icons.flag;
      case 'school':
        return Icons.school;
      case 'class':
        return Icons.class_;
      case 'subject':
        return Icons.menu_book;
      default:
        return Icons.groups;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTapped,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      _getTierIcon(community.communityTier),
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTier(community.communityTier),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMember)
                    FilledButton.tonal(
                      onPressed: () async {
                        try {
                          await ref
                              .read(socialRepositoryProvider)
                              .joinCommunity(
                                communityId: community.id,
                                learnerId: learnerId,
                              );
                          ref.invalidate(
                            learnerCommunitiesProvider(learnerId),
                          );
                          ref.invalidate(
                            discoverableCommunitiesProvider((
                              learnerId: learnerId,
                              tier: null,
                            )),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Join failed: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Join'),
                    )
                  else
                    const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              if (community.description != null &&
                  community.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  community.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people_alt_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${community.membersCount} members',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  if (community.learnerRole != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        community.learnerRole!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityDetailScreen extends ConsumerStatefulWidget {
  final Community community;
  final String learnerId;

  const _CommunityDetailScreen({
    required this.community,
    required this.learnerId,
  });

  @override
  ConsumerState<_CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState
    extends ConsumerState<_CommunityDetailScreen> {
  String? _selectedChannelId;

  @override
  Widget build(BuildContext context) {
    final channelsAsync =
        ref.watch(communityChannelsProvider(widget.community.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.community.name),
      ),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading channels: $err')),
        data: (channels) {
          if (channels.isEmpty) {
            return const Center(child: Text('No channels available in this community.'));
          }

          final activeChannel = channels.firstWhere(
            (c) => c.id == _selectedChannelId,
            orElse: () => channels.first,
          );

          return Column(
            children: [
              // Channel Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: channels.map((channel) {
                    final isSelected = activeChannel.id == channel.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('#${channel.name}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedChannelId = channel.id);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),

              // Messages Area
              Expanded(
                child: _ChannelChatView(
                  channel: activeChannel,
                  learnerId: widget.learnerId,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChannelChatView extends ConsumerStatefulWidget {
  final CommunityChannel channel;
  final String learnerId;

  const _ChannelChatView({
    required this.channel,
    required this.learnerId,
  });

  @override
  ConsumerState<_ChannelChatView> createState() => _ChannelChatViewState();
}

class _ChannelChatViewState extends ConsumerState<_ChannelChatView> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
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

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_containsProhibitedInfo(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Child safety protection: Phone numbers, emails, and external links are prohibited.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref.read(socialRepositoryProvider).sendChannelMessage(
            channelId: widget.channel.id,
            authorLearnerId: widget.learnerId,
            content: text,
          );
      _messageController.clear();
      ref.invalidate(channelMessagesProvider((
        channelId: widget.channel.id,
        viewerId: widget.learnerId,
      )));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(channelMessagesProvider((
      channelId: widget.channel.id,
      viewerId: widget.learnerId,
    )));

    return Column(
      children: [
        // Messages list
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (messages) {
              if (messages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Welcome to #${widget.channel.name}! Share questions or study notes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.authorLearnerId == widget.learnerId;
                  final avatar = getAvatarPreset(msg.authorAvatarPreset);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: avatar.primaryColor,
                          child: Icon(avatar.icon,
                              size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.12)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  msg.authorDisplayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                msg.content,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
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

        // Message input bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    hintText: 'Message #${widget.channel.name}...',
                    counterText: '',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: _isSending
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                onPressed: _isSending ? null : _handleSendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
