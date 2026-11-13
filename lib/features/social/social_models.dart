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
