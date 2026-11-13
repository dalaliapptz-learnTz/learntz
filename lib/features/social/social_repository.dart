import 'package:supabase_flutter/supabase_flutter.dart';
import 'social_models.dart';

class SocialRepository {
  final SupabaseClient _supabase;

  SocialRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Retrieves or auto-provisions the learner's social profile.
  Future<LearnerSocialProfile> getOrCreateProfile(String learnerId) async {
    final response = await _supabase.rpc(
      'get_or_create_learner_social_profile',
      params: {'p_learner_id': learnerId},
    );

    if (response is Map<String, dynamic>) {
      return LearnerSocialProfile.fromJson(response);
    } else if (response is Map) {
      return LearnerSocialProfile.fromJson(Map<String, dynamic>.from(response));
    }
    throw StateError('Invalid response when fetching social profile: $response');
  }

  /// Updates the child's social profile with safety restrictions enforced.
  Future<LearnerSocialProfile> updateProfile({
    required String learnerId,
    required String displayName,
    required String avatarPreset,
    String? bio,
    List<String> academicInterests = const [],
    String profileVisibility = 'school_only',
    bool allowFollowerRequests = true,
    bool showAchievements = true,
    bool showCommunities = true,
  }) async {
    final response = await _supabase.rpc(
      'update_learner_social_profile',
      params: {
        'p_learner_id': learnerId,
        'p_display_name': displayName,
        'p_avatar_preset': avatarPreset,
        'p_bio': bio,
        'p_academic_interests': academicInterests,
        'p_profile_visibility': profileVisibility,
        'p_allow_follower_requests': allowFollowerRequests,
        'p_show_achievements': showAchievements,
        'p_show_communities': showCommunities,
      },
    );

    if (response is Map<String, dynamic>) {
      return LearnerSocialProfile.fromJson(response);
    } else if (response is Map) {
      return LearnerSocialProfile.fromJson(Map<String, dynamic>.from(response));
    }
    throw StateError('Invalid response when updating social profile: $response');
  }

  /// Fetches a child-safe public educational profile respecting privacy settings.
  Future<LearnerSocialProfile?> getPublicProfile({
    required String targetLearnerId,
    String? viewerLearnerId,
  }) async {
    final response = await _supabase.rpc(
      'get_public_learner_social_profile',
      params: {
        'p_target_learner_id': targetLearnerId,
        'p_viewer_learner_id': ?viewerLearnerId,
      },
    );

    if (response == null) return null;
    if (response is Map<String, dynamic>) {
      return LearnerSocialProfile.fromJson(response);
    } else if (response is Map) {
      return LearnerSocialProfile.fromJson(Map<String, dynamic>.from(response));
    }
    return null;
  }

  /// Fetches the educational activity feed for a learner.
  Future<List<SocialPost>> getSocialFeed({
    required String viewerLearnerId,
    String? postType,
    String? subjectId,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase.rpc(
      'get_social_feed',
      params: {
        'p_viewer_learner_id': viewerLearnerId,
        'p_post_type': ?postType,
        'p_subject_id': ?subjectId,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    if (response is List) {
      return response
          .map((item) => SocialPost.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return const [];
  }

  /// Creates a structured educational post (question, concept explanation, tip).
  Future<SocialPost> createPost({
    required String authorLearnerId,
    required String postType,
    required String title,
    required String content,
    String? subjectId,
    String? topicId,
    List<String> tags = const [],
  }) async {
    final response = await _supabase.rpc(
      'create_social_post',
      params: {
        'p_author_learner_id': authorLearnerId,
        'p_post_type': postType,
        'p_title': title,
        'p_content': content,
        'p_subject_id': ?subjectId,
        'p_topic_id': ?topicId,
        'p_tags': tags,
      },
    );

    if (response is Map<String, dynamic>) {
      return SocialPost.fromJson(response);
    } else if (response is Map) {
      return SocialPost.fromJson(Map<String, dynamic>.from(response));
    }
    throw StateError('Invalid response when creating post: $response');
  }

  /// Toggles an educational reaction (helpful, insightful, brilliant, curious, clap).
  Future<Map<String, dynamic>> toggleReaction({
    required String postId,
    required String learnerId,
    required String reactionType,
  }) async {
    final response = await _supabase.rpc(
      'toggle_post_reaction',
      params: {
        'p_post_id': postId,
        'p_learner_id': learnerId,
        'p_reaction_type': reactionType,
      },
    );

    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'action': 'none'};
  }

  /// Fetches comments and replies for a post.
  Future<List<PostComment>> getPostComments({
    required String postId,
    String? viewerLearnerId,
  }) async {
    final response = await _supabase.rpc(
      'get_post_comments',
      params: {
        'p_post_id': postId,
        'p_viewer_learner_id': ?viewerLearnerId,
      },
    );

    if (response is List) {
      return response
          .map((item) =>
              PostComment.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return const [];
  }

  /// Adds a comment or nested reply to a post.
  Future<PostComment> addComment({
    required String postId,
    required String authorLearnerId,
    required String content,
    String? parentCommentId,
  }) async {
    final response = await _supabase.rpc(
      'add_post_comment',
      params: {
        'p_post_id': postId,
        'p_author_learner_id': authorLearnerId,
        'p_content': content,
        'p_parent_comment_id': ?parentCommentId,
      },
    );

    if (response is Map<String, dynamic>) {
      return PostComment.fromJson(response);
    } else if (response is Map) {
      return PostComment.fromJson(Map<String, dynamic>.from(response));
    }
    throw StateError('Invalid response when adding comment: $response');
  }

  /// Toggles saving/bookmarking a post for future revision.
  Future<bool> toggleSavePost({
    required String postId,
    required String learnerId,
  }) async {
    final response = await _supabase.rpc(
      'toggle_save_post',
      params: {
        'p_post_id': postId,
        'p_learner_id': learnerId,
      },
    );

    return response as bool? ?? false;
  }

  /// Follows or unfollows a learner.
  Future<Map<String, dynamic>> toggleFollow({
    required String followerLearnerId,
    required String targetLearnerId,
  }) async {
    final response = await _supabase.rpc(
      'toggle_follow_learner',
      params: {
        'p_follower_learner_id': followerLearnerId,
        'p_target_learner_id': targetLearnerId,
      },
    );

    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'is_following': false};
  }

  /// Blocks a learner to exclude their posts and comments.
  Future<bool> blockLearner({
    required String blockerLearnerId,
    required String blockedLearnerId,
    String? reason,
  }) async {
    final response = await _supabase.rpc(
      'block_learner',
      params: {
        'p_blocker_learner_id': blockerLearnerId,
        'p_blocked_learner_id': blockedLearnerId,
        'p_reason': ?reason,
      },
    );

    return response as bool? ?? false;
  }
}
