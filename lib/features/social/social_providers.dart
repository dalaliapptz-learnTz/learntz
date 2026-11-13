import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'social_models.dart';
import 'social_repository.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository();
});

final learnerSocialProfileProvider =
    FutureProvider.family<LearnerSocialProfile, String>((ref, learnerId) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getOrCreateProfile(learnerId);
});

final publicLearnerSocialProfileProvider = FutureProvider.family<
    LearnerSocialProfile?,
    ({String targetId, String? viewerId})>((ref, args) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getPublicProfile(
    targetLearnerId: args.targetId,
    viewerLearnerId: args.viewerId,
  );
});

final socialFeedProvider = FutureProvider.family<
    List<SocialPost>,
    ({String viewerId, String? postType, String? subjectId})>((ref, args) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getSocialFeed(
    viewerLearnerId: args.viewerId,
    postType: args.postType,
    subjectId: args.subjectId,
  );
});

final postCommentsProvider = FutureProvider.family<
    List<PostComment>,
    ({String postId, String? viewerId})>((ref, args) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getPostComments(
    postId: args.postId,
    viewerLearnerId: args.viewerId,
  );
});

final learnerCommunitiesProvider =
    FutureProvider.family<List<Community>, String>((ref, learnerId) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getLearnerCommunities(learnerId);
});

final discoverableCommunitiesProvider = FutureProvider.family<
    List<Community>,
    ({String learnerId, String? tier})>((ref, args) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getDiscoverableCommunities(
    learnerId: args.learnerId,
    tier: args.tier,
  );
});

final communityChannelsProvider =
    FutureProvider.family<List<CommunityChannel>, String>((ref, communityId) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getCommunityChannels(communityId);
});

final channelMessagesProvider = FutureProvider.family<
    List<ChannelMessage>,
    ({String channelId, String? viewerId})>((ref, args) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getChannelMessages(
    channelId: args.channelId,
    viewerLearnerId: args.viewerId,
  );
});

final activeChallengesProvider =
    FutureProvider.family<List<AcademicChallenge>, String>((ref, learnerId) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getActiveChallenges(learnerId);
});

final communityLeaderboardProvider = FutureProvider.family<
    List<LeaderboardEntry>,
    ({String scope, String scopeId, int limit})>((ref, args) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getLeaderboard(
    scope: args.scope,
    scopeId: args.scopeId,
    limit: args.limit,
  );
});

final learnerNotificationsProvider = FutureProvider.family<
    List<SocialNotification>,
    ({String learnerId, bool unreadOnly})>((ref, args) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getNotifications(
    learnerId: args.learnerId,
    unreadOnly: args.unreadOnly,
  );
});

final moderationQueueProvider = FutureProvider.family<
    List<SocialModerationReport>,
    String?>((ref, status) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getModerationQueue(status: status);
});
