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
