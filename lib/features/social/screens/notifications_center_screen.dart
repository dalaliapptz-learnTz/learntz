import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../learners/learner_providers.dart';
import '../social_providers.dart';

class NotificationsCenterScreen extends ConsumerStatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  ConsumerState<NotificationsCenterScreen> createState() =>
      _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState
    extends ConsumerState<NotificationsCenterScreen> {
  bool _unreadOnly = false;

  IconData _getIconForType(String type) {
    switch (type) {
      case 'reaction_received':
        return Icons.thumb_up_alt_outlined;
      case 'comment_received':
        return Icons.chat_bubble_outline;
      case 'challenge_available':
        return Icons.emoji_events_outlined;
      case 'badge_awarded':
        return Icons.military_tech_outlined;
      case 'community_announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'reaction_received':
        return Colors.blue;
      case 'comment_received':
        return Colors.green;
      case 'challenge_available':
        return Colors.orange;
      case 'badge_awarded':
        return Colors.amber.shade800;
      case 'community_announcement':
        return Colors.purple;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLearner = ref.watch(activeLearnerProvider);

    if (activeLearner == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(
          child: Text('Please select an active learner to view notifications.'),
        ),
      );
    }

    final notifsAsync = ref.watch(learnerNotificationsProvider((
      learnerId: activeLearner.id,
      unreadOnly: _unreadOnly,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning & Social Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await ref
                  .read(socialRepositoryProvider)
                  .markNotificationsRead(learnerId: activeLearner.id);
              ref.invalidate(learnerNotificationsProvider((
                learnerId: activeLearner.id,
                unreadOnly: _unreadOnly,
              )));
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(learnerNotificationsProvider((
              learnerId: activeLearner.id,
              unreadOnly: _unreadOnly,
            ))),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Unread Only'),
                  selected: _unreadOnly,
                  onSelected: (val) => setState(() => _unreadOnly = val),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: notifsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (notifs) {
                if (notifs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications right now',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Activity on your posts and challenge updates will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final notif = notifs[index];
                    final icon = _getIconForType(notif.notificationType);
                    final color = _getColorForType(notif.notificationType);

                    return Card(
                      elevation: notif.isRead ? 0 : 2,
                      color: notif.isRead
                          ? Colors.grey.shade50
                          : Colors.blue.shade50.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: notif.isRead
                            ? BorderSide(color: Colors.grey.shade200)
                            : BorderSide(color: Colors.blue.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        title: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(notif.body),
                        trailing: notif.isRead
                            ? null
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        onTap: () async {
                          if (!notif.isRead) {
                            await ref
                                .read(socialRepositoryProvider)
                                .markNotificationsRead(
                                  learnerId: activeLearner.id,
                                  notificationIds: [notif.id],
                                );
                            ref.invalidate(learnerNotificationsProvider((
                              learnerId: activeLearner.id,
                              unreadOnly: _unreadOnly,
                            )));
                          }
                          if (notif.targetRoute != null && context.mounted) {
                            context.go(notif.targetRoute!);
                          }
                        },
                      ),
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
}
