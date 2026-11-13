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
}
