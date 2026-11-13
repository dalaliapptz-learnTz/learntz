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
