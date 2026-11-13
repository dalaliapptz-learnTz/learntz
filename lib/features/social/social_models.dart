import 'package:flutter/material.dart';

/// Pre-approved avatar presets for child safety (no real photos permitted).
class AvatarPreset {
  final String key;
  final String name;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;

  const AvatarPreset({
    required this.key,
    required this.name,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

const List<AvatarPreset> kAvatarPresets = [
  AvatarPreset(
    key: 'owl_scholar',
    name: 'Scholar Owl',
    icon: Icons.school,
    primaryColor: Color(0xFF1E3A8A),
    secondaryColor: Color(0xFF93C5FD),
  ),
  AvatarPreset(
    key: 'lion_reader',
    name: 'Reader Lion',
    icon: Icons.menu_book,
    primaryColor: Color(0xFFD97706),
    secondaryColor: Color(0xFFFDE68A),
  ),
  AvatarPreset(
    key: 'cheetah_runner',
    name: 'Sprint Cheetah',
    icon: Icons.bolt,
    primaryColor: Color(0xFFDC2626),
    secondaryColor: Color(0xFFFECACA),
  ),
  AvatarPreset(
    key: 'giraffe_thinker',
    name: 'Thinker Giraffe',
    icon: Icons.psychology,
    primaryColor: Color(0xFF059669),
    secondaryColor: Color(0xFFA7F3D0),
  ),
  AvatarPreset(
    key: 'elephant_math',
    name: 'Math Elephant',
    icon: Icons.calculate,
    primaryColor: Color(0xFF4F46E5),
    secondaryColor: Color(0xFFC7D2FE),
  ),
  AvatarPreset(
    key: 'zebra_writer',
    name: 'Writer Zebra',
    icon: Icons.edit_note,
    primaryColor: Color(0xFF0F172A),
    secondaryColor: Color(0xFFE2E8F0),
  ),
  AvatarPreset(
    key: 'falcon_scout',
    name: 'Explorer Falcon',
    icon: Icons.explore,
    primaryColor: Color(0xFF0284C7),
    secondaryColor: Color(0xFFBAE6FD),
  ),
  AvatarPreset(
    key: 'rhino_builder',
    name: 'Builder Rhino',
    icon: Icons.handyman,
    primaryColor: Color(0xFF7C3AED),
    secondaryColor: Color(0xFFDDD6FE),
  ),
];

AvatarPreset getAvatarPreset(String? key) {
  return kAvatarPresets.firstWhere(
    (p) => p.key == key,
    orElse: () => kAvatarPresets.first,
  );
}

/// Learner social profile model representing child-safe academic identity.
class LearnerSocialProfile {
  final String id;
  final String learnerId;
  final String displayName;
  final String avatarPreset;
  final String? bio;
  final List<String> academicInterests;
  final int points;
  final int badgesCount;
  final String profileVisibility; // 'public' | 'school_only' | 'private'
  final bool allowFollowerRequests;
  final bool showAchievements;
  final bool showCommunities;
  final String? gradeName;
  final String? schoolName;
  final String? countryCode;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPrivate;
  final bool isRestricted;

  const LearnerSocialProfile({
    required this.id,
    required this.learnerId,
    required this.displayName,
    required this.avatarPreset,
    this.bio,
    this.academicInterests = const [],
    this.points = 0,
    this.badgesCount = 0,
    this.profileVisibility = 'school_only',
    this.allowFollowerRequests = true,
    this.showAchievements = true,
    this.showCommunities = true,
    this.gradeName,
    this.schoolName,
    this.countryCode,
    required this.createdAt,
    this.updatedAt,
    this.isPrivate = false,
    this.isRestricted = false,
  });

  factory LearnerSocialProfile.fromJson(Map<String, dynamic> json) {
    return LearnerSocialProfile(
      id: json['id'] as String? ?? '',
      learnerId: json['learner_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Learner',
      avatarPreset: json['avatar_preset'] as String? ?? 'owl_scholar',
      bio: json['bio'] as String?,
      academicInterests: (json['academic_interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      points: (json['points'] as num?)?.toInt() ?? 0,
      badgesCount: (json['badges_count'] as num?)?.toInt() ?? 0,
      profileVisibility:
          json['profile_visibility'] as String? ?? 'school_only',
      allowFollowerRequests:
          json['allow_follower_requests'] as bool? ?? true,
      showAchievements: json['show_achievements'] as bool? ?? true,
      showCommunities: json['show_communities'] as bool? ?? true,
      gradeName: json['grade_name'] as String?,
      schoolName: json['school_name'] as String?,
      countryCode: json['country_code'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      isPrivate: json['is_private'] as bool? ?? false,
      isRestricted: json['is_restricted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'learner_id': learnerId,
        'display_name': displayName,
        'avatar_preset': avatarPreset,
        'bio': bio,
        'academic_interests': academicInterests,
        'points': points,
        'badges_count': badgesCount,
        'profile_visibility': profileVisibility,
        'allow_follower_requests': allowFollowerRequests,
        'show_achievements': showAchievements,
        'show_communities': showCommunities,
        'grade_name': gradeName,
        'school_name': schoolName,
        'country_code': countryCode,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'is_private': isPrivate,
        'is_restricted': isRestricted,
      };

  LearnerSocialProfile copyWith({
    String? id,
    String? learnerId,
    String? displayName,
    String? avatarPreset,
    String? bio,
    List<String>? academicInterests,
    int? points,
    int? badgesCount,
    String? profileVisibility,
    bool? allowFollowerRequests,
    bool? showAchievements,
    bool? showCommunities,
    String? gradeName,
    String? schoolName,
    String? countryCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPrivate,
    bool? isRestricted,
  }) {
    return LearnerSocialProfile(
      id: id ?? this.id,
      learnerId: learnerId ?? this.learnerId,
      displayName: displayName ?? this.displayName,
      avatarPreset: avatarPreset ?? this.avatarPreset,
      bio: bio ?? this.bio,
      academicInterests: academicInterests ?? this.academicInterests,
      points: points ?? this.points,
      badgesCount: badgesCount ?? this.badgesCount,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      allowFollowerRequests:
          allowFollowerRequests ?? this.allowFollowerRequests,
      showAchievements: showAchievements ?? this.showAchievements,
      showCommunities: showCommunities ?? this.showCommunities,
      gradeName: gradeName ?? this.gradeName,
      schoolName: schoolName ?? this.schoolName,
      countryCode: countryCode ?? this.countryCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPrivate: isPrivate ?? this.isPrivate,
      isRestricted: isRestricted ?? this.isRestricted,
    );
  }
}

/// Educational post model representing a question, explanation, or learning tip.
class SocialPost {
  final String id;
  final String authorLearnerId;
  final String authorDisplayName;
  final String authorAvatarPreset;
  final String? communityId;
  final String? subjectId;
  final String? subjectName;
  final String? topicId;
  final String postType; // 'question' | 'concept_explanation' | 'study_tip' | 'revision_notes' | 'discovery' | 'resource_share'
  final String title;
  final String content;
  final List<String> tags;
  final int likesCount;
  final int commentsCount;
  final int bookmarksCount;
  final bool viewerHasReacted;
  final bool viewerHasSaved;
  final DateTime createdAt;

  const SocialPost({
    required this.id,
    required this.authorLearnerId,
    required this.authorDisplayName,
    required this.authorAvatarPreset,
    this.communityId,
    this.subjectId,
    this.subjectName,
    this.topicId,
    required this.postType,
    required this.title,
    required this.content,
    this.tags = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.bookmarksCount = 0,
    this.viewerHasReacted = false,
    this.viewerHasSaved = false,
    required this.createdAt,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    return SocialPost(
      id: json['id'] as String? ?? '',
      authorLearnerId: json['author_learner_id'] as String? ?? '',
      authorDisplayName: json['author_display_name'] as String? ?? 'Learner',
      authorAvatarPreset:
          json['author_avatar_preset'] as String? ?? 'owl_scholar',
      communityId: json['community_id'] as String?,
      subjectId: json['subject_id'] as String?,
      subjectName: json['subject_name'] as String?,
      topicId: json['topic_id'] as String?,
      postType: json['post_type'] as String? ?? 'question',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      bookmarksCount: (json['bookmarks_count'] as num?)?.toInt() ?? 0,
      viewerHasReacted: json['viewer_has_reacted'] as bool? ?? false,
      viewerHasSaved: json['viewer_has_saved'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_learner_id': authorLearnerId,
        'author_display_name': authorDisplayName,
        'author_avatar_preset': authorAvatarPreset,
        'community_id': communityId,
        'subject_id': subjectId,
        'subject_name': subjectName,
        'topic_id': topicId,
        'post_type': postType,
        'title': title,
        'content': content,
        'tags': tags,
        'likes_count': likesCount,
        'comments_count': commentsCount,
        'bookmarks_count': bookmarksCount,
        'viewer_has_reacted': viewerHasReacted,
        'viewer_has_saved': viewerHasSaved,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Comment on an educational post.
class PostComment {
  final String id;
  final String postId;
  final String authorLearnerId;
  final String authorDisplayName;
  final String authorAvatarPreset;
  final String? parentCommentId;
  final String content;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.postId,
    required this.authorLearnerId,
    required this.authorDisplayName,
    required this.authorAvatarPreset,
    this.parentCommentId,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      authorLearnerId: json['author_learner_id'] as String? ?? '',
      authorDisplayName: json['author_display_name'] as String? ?? 'Learner',
      authorAvatarPreset:
          json['author_avatar_preset'] as String? ?? 'owl_scholar',
      parentCommentId: json['parent_comment_id'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'post_id': postId,
        'author_learner_id': authorLearnerId,
        'author_display_name': authorDisplayName,
        'author_avatar_preset': authorAvatarPreset,
        'parent_comment_id': parentCommentId,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Hierarchical learning community model.
class Community {
  final String id;
  final String communityTier; // 'school' | 'class' | 'district' | 'region' | 'national' | 'subject'
  final String name;
  final String? description;
  final String countryCode;
  final String? schoolId;
  final String? gradeId;
  final String? districtName;
  final String? regionName;
  final String? subjectId;
  final String iconName;
  final int membersCount;
  final int postsCount;
  final bool isOfficial;
  final String? learnerRole;
  final bool isMember;

  const Community({
    required this.id,
    required this.communityTier,
    required this.name,
    this.description,
    required this.countryCode,
    this.schoolId,
    this.gradeId,
    this.districtName,
    this.regionName,
    this.subjectId,
    this.iconName = 'school',
    this.membersCount = 0,
    this.postsCount = 0,
    this.isOfficial = true,
    this.learnerRole,
    this.isMember = false,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as String? ?? '',
      communityTier: json['community_tier'] as String? ?? 'school',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      countryCode: json['country_code'] as String? ?? 'TZ',
      schoolId: json['school_id'] as String?,
      gradeId: json['grade_id'] as String?,
      districtName: json['district_name'] as String?,
      regionName: json['region_name'] as String?,
      subjectId: json['subject_id'] as String?,
      iconName: json['icon_name'] as String? ?? 'school',
      membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
      postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
      isOfficial: json['is_official'] as bool? ?? true,
      learnerRole: json['learner_role'] as String?,
      isMember: json['is_member'] as bool? ?? (json['learner_role'] != null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'community_tier': communityTier,
        'name': name,
        'description': description,
        'country_code': countryCode,
        'school_id': schoolId,
        'grade_id': gradeId,
        'district_name': districtName,
        'region_name': regionName,
        'subject_id': subjectId,
        'icon_name': iconName,
        'members_count': membersCount,
        'posts_count': postsCount,
        'is_official': isOfficial,
        'learner_role': learnerRole,
        'is_member': isMember,
      };
}

/// Channel inside a community (e.g. #general, #q-and-a, #announcements).
class CommunityChannel {
  final String id;
  final String communityId;
  final String name;
  final String channelType;
  final String? description;

  const CommunityChannel({
    required this.id,
    required this.communityId,
    required this.name,
    required this.channelType,
    this.description,
  });

  factory CommunityChannel.fromJson(Map<String, dynamic> json) {
    return CommunityChannel(
      id: json['id'] as String? ?? '',
      communityId: json['community_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      channelType: json['channel_type'] as String? ?? 'general',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'community_id': communityId,
        'name': name,
        'channel_type': channelType,
        'description': description,
      };
}

/// Message in a community channel.
class ChannelMessage {
  final String id;
  final String channelId;
  final String authorLearnerId;
  final String authorDisplayName;
  final String authorAvatarPreset;
  final String content;
  final DateTime createdAt;

  const ChannelMessage({
    required this.id,
    required this.channelId,
    required this.authorLearnerId,
    required this.authorDisplayName,
    required this.authorAvatarPreset,
    required this.content,
    required this.createdAt,
  });

  factory ChannelMessage.fromJson(Map<String, dynamic> json) {
    return ChannelMessage(
      id: json['id'] as String? ?? '',
      channelId: json['channel_id'] as String? ?? '',
      authorLearnerId: json['author_learner_id'] as String? ?? '',
      authorDisplayName: json['author_display_name'] as String? ?? 'Learner',
      authorAvatarPreset:
          json['author_avatar_preset'] as String? ?? 'owl_scholar',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel_id': channelId,
        'author_learner_id': authorLearnerId,
        'author_display_name': authorDisplayName,
        'author_avatar_preset': authorAvatarPreset,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Academic challenge and competition model.
class AcademicChallenge {
  final String id;
  final String title;
  final String description;
  final String challengeType; // 'daily_quiz' | 'weekly_olympiad' | 'monthly_championship' | 'speed_math' | 'science_quest'
  final int rewardPoints;
  final String? badgeKey;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final int totalQuestions;
  final String? subjectName;
  final String? attemptId;
  final String? attemptStatus;
  final int? learnerScore;
  final DateTime? completedAt;

  const AcademicChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.challengeType,
    this.rewardPoints = 50,
    this.badgeKey,
    required this.startsAt,
    required this.endsAt,
    this.status = 'active',
    this.totalQuestions = 5,
    this.subjectName,
    this.attemptId,
    this.attemptStatus,
    this.learnerScore,
    this.completedAt,
  });

  factory AcademicChallenge.fromJson(Map<String, dynamic> json) {
    return AcademicChallenge(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      challengeType: json['challenge_type'] as String? ?? 'daily_quiz',
      rewardPoints: (json['reward_points'] as num?)?.toInt() ?? 50,
      badgeKey: json['badge_key'] as String?,
      startsAt: json['starts_at'] != null
          ? DateTime.tryParse(json['starts_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endsAt: json['ends_at'] != null
          ? DateTime.tryParse(json['ends_at'].toString()) ??
              DateTime.now().add(const Duration(days: 7))
          : DateTime.now().add(const Duration(days: 7)),
      status: json['status'] as String? ?? 'active',
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 5,
      subjectName: json['subject_name'] as String?,
      attemptId: json['attempt_id'] as String?,
      attemptStatus: json['attempt_status'] as String?,
      learnerScore: (json['learner_score'] as num?)?.toInt(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'challenge_type': challengeType,
        'reward_points': rewardPoints,
        'badge_key': badgeKey,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
        'status': status,
        'total_questions': totalQuestions,
        'subject_name': subjectName,
        'attempt_id': attemptId,
        'attempt_status': attemptStatus,
        'learner_score': learnerScore,
        'completed_at': completedAt?.toIso8601String(),
      };
}

/// Educational leaderboard entry.
class LeaderboardEntry {
  final int rank;
  final String learnerId;
  final String displayName;
  final String avatarPreset;
  final int points;
  final int badgesCount;
  final String? gradeName;
  final String? schoolName;
  final String countryCode;

  const LeaderboardEntry({
    required this.rank,
    required this.learnerId,
    required this.displayName,
    required this.avatarPreset,
    required this.points,
    required this.badgesCount,
    this.gradeName,
    this.schoolName,
    required this.countryCode,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      learnerId: json['learner_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Scholar',
      avatarPreset: json['avatar_preset'] as String? ?? 'owl_scholar',
      points: (json['points'] as num?)?.toInt() ?? 0,
      badgesCount: (json['badges_count'] as num?)?.toInt() ?? 0,
      gradeName: json['grade_name'] as String?,
      schoolName: json['school_name'] as String?,
      countryCode: json['country_code'] as String? ?? 'TZ',
    );
  }

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'learner_id': learnerId,
        'display_name': displayName,
        'avatar_preset': avatarPreset,
        'points': points,
        'badges_count': badgesCount,
        'grade_name': gradeName,
        'school_name': schoolName,
        'country_code': countryCode,
      };
}

/// Achievement Badge catalog item.
class AchievementBadge {
  final String badgeKey;
  final String name;
  final String description;
  final String category;
  final String iconName;
  final int pointsRequired;

  const AchievementBadge({
    required this.badgeKey,
    required this.name,
    required this.description,
    required this.category,
    required this.iconName,
    required this.pointsRequired,
  });

  factory AchievementBadge.fromJson(Map<String, dynamic> json) {
    return AchievementBadge(
      badgeKey: json['badge_key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'learning',
      iconName: json['icon_name'] as String? ?? 'military_tech',
      pointsRequired: (json['points_required'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'badge_key': badgeKey,
        'name': name,
        'description': description,
        'category': category,
        'icon_name': iconName,
        'points_required': pointsRequired,
      };
}

