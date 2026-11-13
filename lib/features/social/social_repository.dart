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

  /// Fetches communities the learner is a member of (class, school, national, subject).
  Future<List<Community>> getLearnerCommunities(String learnerId) async {
    final response = await _supabase.rpc(
      'get_learner_communities',
      params: {'p_learner_id': learnerId},
    );

    if (response is List) {
      return response
          .map((item) =>
              Community.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return const [];
  }

  /// Fetches discoverable communities for learner's country.
  Future<List<Community>> getDiscoverableCommunities({
    required String learnerId,
    String? tier,
  }) async {
    final response = await _supabase.rpc(
      'get_discoverable_communities',
      params: {
        'p_learner_id': learnerId,
        'p_tier': ?tier,
      },
    );

    if (response is List) {
      return response
          .map((item) =>
              Community.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return const [];
  }

  /// Joins a discoverable community (e.g. subject club).
  Future<bool> joinCommunity({
    required String communityId,
    required String learnerId,
  }) async {
    final response = await _supabase.rpc(
      'join_community',
      params: {
        'p_community_id': communityId,
        'p_learner_id': learnerId,
      },
    );

    return response as bool? ?? false;
  }

  /// Leaves an optional community.
  Future<bool> leaveCommunity({
    required String communityId,
    required String learnerId,
  }) async {
    final response = await _supabase.rpc(
      'leave_community',
      params: {
        'p_community_id': communityId,
        'p_learner_id': learnerId,
      },
    );

    return response as bool? ?? false;
  }

  /// Fetches channels in a community (#general, #q-and-a, #announcements).
  Future<List<CommunityChannel>> getCommunityChannels(
      String communityId) async {
    final response = await _supabase.rpc(
      'get_community_channels',
      params: {'p_community_id': communityId},
    );

    if (response is List) {
      return response
          .map((item) =>
              CommunityChannel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return const [];
  }

  /// Fetches messages in a channel.
  Future<List<ChannelMessage>> getChannelMessages({
    required String channelId,
    String? viewerLearnerId,
    int limit = 50,
  }) async {
    final response = await _supabase.rpc(
      'get_channel_messages',
      params: {
        'p_channel_id': channelId,
        'p_viewer_learner_id': ?viewerLearnerId,
        'p_limit': limit,
      },
    );

    if (response is List) {
      return response
          .map((item) =>
              ChannelMessage.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return const [];
  }

  /// Sends a child-safe educational message in a channel.
  Future<ChannelMessage> sendChannelMessage({
    required String channelId,
    required String authorLearnerId,
    required String content,
  }) async {
    final response = await _supabase.rpc(
      'send_channel_message',
      params: {
        'p_channel_id': channelId,
        'p_author_learner_id': authorLearnerId,
        'p_content': content,
      },
    );

    if (response is Map<String, dynamic>) {
      return ChannelMessage.fromJson(response);
    } else if (response is Map) {
      return ChannelMessage.fromJson(Map<String, dynamic>.from(response));
    }
    throw StateError('Invalid response when sending channel message: $response');
  }

  /// Fetches active academic challenges and competitions for a learner.
  Future<List<AcademicChallenge>> getActiveChallenges(String learnerId) async {
    final response = await _supabase.rpc(
      'get_active_challenges',
      params: {'p_learner_id': learnerId},
    );

    if (response is List) {
      return response
          .map((item) =>
              AcademicChallenge.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return const [];
  }

  /// Enters a challenge attempt.
  Future<Map<String, dynamic>> participateInChallenge({
    required String challengeId,
    required String learnerId,
  }) async {
    final response = await _supabase.rpc(
      'participate_in_challenge',
      params: {
        'p_challenge_id': challengeId,
        'p_learner_id': learnerId,
      },
    );

    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'status': 'in_progress'};
  }

  /// Submits completed challenge attempt, awarding points and badges.
  Future<Map<String, dynamic>> submitChallengeAttempt({
    required String challengeId,
    required String learnerId,
    required int score,
    required int timeSpentSeconds,
    List<dynamic> answers = const [],
  }) async {
    final response = await _supabase.rpc(
      'submit_challenge_attempt',
      params: {
        'p_challenge_id': challengeId,
        'p_learner_id': learnerId,
        'p_score': score,
        'p_time_spent_seconds': timeSpentSeconds,
        'p_answers': answers,
      },
    );

    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'score': score};
  }

  /// Fetches educational leaderboard (ranked pseudonyms, points, badges).
  Future<List<LeaderboardEntry>> getLeaderboard({
    String scope = 'national',
    String scopeId = 'TZ',
    int limit = 25,
  }) async {
    final response = await _supabase.rpc(
      'get_community_leaderboard',
      params: {
        'p_scope': scope,
        'p_scope_id': scopeId,
        'p_limit': limit,
      },
    );

    if (response is List) {
      return response
          .map((item) =>
              LeaderboardEntry.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return const [];
  }

  /// Reports inappropriate educational content for staff moderation.
  Future<SocialModerationReport> reportContent({
    required String reporterLearnerId,
    required String targetType,
    required String targetId,
    required String reasonCategory,
    String? details,
  }) async {
    final response = await _supabase.rpc(
      'report_social_content',
      params: {
        'p_reporter_learner_id': reporterLearnerId,
        'p_target_type': targetType,
        'p_target_id': targetId,
        'p_reason_category': reasonCategory,
        'p_details': ?details,
      },
    );

    if (response is Map<String, dynamic>) {
      return SocialModerationReport.fromJson(response);
    } else if (response is Map) {
      return SocialModerationReport.fromJson(Map<String, dynamic>.from(response));
    }
    throw StateError('Invalid response when filing report: $response');
  }

  /// Fetches pending moderation reports for staff review.
  Future<List<SocialModerationReport>> getModerationQueue({
    String? status = 'pending',
    int limit = 25,
  }) async {
    final response = await _supabase.rpc(
      'get_moderation_queue',
      params: {
        'p_status': ?status,
        'p_limit': limit,
      },
    );

    if (response is List) {
      return response
          .map((item) => SocialModerationReport.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return const [];
  }

  /// Resolves a moderation report with action taken.
  Future<Map<String, dynamic>> reviewModerationReport({
    required String reportId,
    required String action,
    String? notes,
  }) async {
    final response = await _supabase.rpc(
      'review_moderation_report',
      params: {
        'p_report_id': reportId,
        'p_action': action,
        'p_notes': ?notes,
      },
    );

    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'action_taken': action};
  }

  /// Fetches social notifications for a learner.
  Future<List<SocialNotification>> getNotifications({
    required String learnerId,
    bool unreadOnly = false,
    int limit = 25,
  }) async {
    final response = await _supabase.rpc(
      'get_learner_social_notifications',
      params: {
        'p_learner_id': learnerId,
        'p_unread_only': unreadOnly,
        'p_limit': limit,
      },
    );

    if (response is List) {
      return response
          .map((item) =>
              SocialNotification.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return const [];
  }

  /// Marks notifications as read.
  Future<int> markNotificationsRead({
    required String learnerId,
    List<String>? notificationIds,
  }) async {
    final response = await _supabase.rpc(
      'mark_notifications_read',
      params: {
        'p_learner_id': learnerId,
        'p_notification_ids': ?notificationIds,
      },
    );

    return (response as num?)?.toInt() ?? 0;
  }
}
