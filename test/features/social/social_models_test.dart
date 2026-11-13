import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/social/social_models.dart';

void main() {
  group('AvatarPreset tests', () {
    test('kAvatarPresets contains 8 unique child-safe animal personas', () {
      expect(kAvatarPresets.length, 8);
      final keys = kAvatarPresets.map((p) => p.key).toSet();
      expect(keys.length, 8);
      expect(keys.contains('owl_scholar'), isTrue);
      expect(keys.contains('lion_reader'), isTrue);
      expect(keys.contains('falcon_scout'), isTrue);
    });

    test('getAvatarPreset returns matching preset or fallback', () {
      final owl = getAvatarPreset('owl_scholar');
      expect(owl.key, 'owl_scholar');
      expect(owl.name, 'Scholar Owl');

      final unknown = getAvatarPreset('non_existent');
      expect(unknown.key, 'owl_scholar');
    });
  });

  group('LearnerSocialProfile Model tests', () {
    final now = DateTime.now();

    test('fromJson and toJson round-trip preserves all fields', () {
      final json = {
        'id': 'profile-1',
        'learner_id': 'learner-123',
        'display_name': 'StarKid',
        'avatar_preset': 'lion_reader',
        'bio': 'Learning math every day!',
        'academic_interests': ['Mathematics', 'Science'],
        'points': 150,
        'badges_count': 3,
        'profile_visibility': 'school_only',
        'allow_follower_requests': true,
        'show_achievements': true,
        'show_communities': true,
        'grade_name': 'Standard 4',
        'school_name': 'Arusha Primary School',
        'country_code': 'TZ',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'is_private': false,
        'is_restricted': false,
      };

      final profile = LearnerSocialProfile.fromJson(json);
      expect(profile.id, 'profile-1');
      expect(profile.learnerId, 'learner-123');
      expect(profile.displayName, 'StarKid');
      expect(profile.avatarPreset, 'lion_reader');
      expect(profile.bio, 'Learning math every day!');
      expect(profile.academicInterests, ['Mathematics', 'Science']);
      expect(profile.points, 150);
      expect(profile.badgesCount, 3);
      expect(profile.profileVisibility, 'school_only');
      expect(profile.allowFollowerRequests, isTrue);
      expect(profile.showAchievements, isTrue);
      expect(profile.showCommunities, isTrue);
      expect(profile.gradeName, 'Standard 4');
      expect(profile.schoolName, 'Arusha Primary School');
      expect(profile.countryCode, 'TZ');
      expect(profile.isPrivate, isFalse);

      final serialized = profile.toJson();
      expect(serialized['display_name'], 'StarKid');
      expect(serialized['points'], 150);
      expect(serialized['avatar_preset'], 'lion_reader');
    });

    test('copyWith updates specified fields correctly', () {
      final profile = LearnerSocialProfile(
        id: 'p-1',
        learnerId: 'l-1',
        displayName: 'OldName',
        avatarPreset: 'owl_scholar',
        createdAt: now,
      );

      final updated = profile.copyWith(
        displayName: 'NewName',
        points: 40,
        profileVisibility: 'private',
      );

      expect(updated.displayName, 'NewName');
      expect(updated.points, 40);
      expect(updated.profileVisibility, 'private');
      expect(updated.avatarPreset, 'owl_scholar');
      expect(updated.id, 'p-1');
    });
  });

  group('SocialPost and PostComment Model tests', () {
    final now = DateTime.now();

    test('SocialPost serialization and deserialization', () {
      final json = {
        'id': 'post-101',
        'author_learner_id': 'learner-1',
        'author_display_name': 'Amani B.',
        'author_avatar_preset': 'owl_scholar',
        'community_id': 'comm-1',
        'subject_id': 'sub-1',
        'subject_name': 'Mathematics',
        'post_type': 'question',
        'title': 'How to calculate circle area?',
        'content': 'Can someone explain pi times r squared in simple terms?',
        'tags': ['math', 'geometry'],
        'likes_count': 5,
        'comments_count': 2,
        'bookmarks_count': 1,
        'viewer_has_reacted': true,
        'viewer_has_saved': false,
        'created_at': now.toIso8601String(),
      };

      final post = SocialPost.fromJson(json);
      expect(post.id, 'post-101');
      expect(post.title, 'How to calculate circle area?');
      expect(post.likesCount, 5);
      expect(post.viewerHasReacted, isTrue);
      expect(post.tags, ['math', 'geometry']);

      final serialized = post.toJson();
      expect(serialized['id'], 'post-101');
      expect(serialized['subject_name'], 'Mathematics');
    });

    test('PostComment serialization and deserialization', () {
      final json = {
        'id': 'comm-201',
        'post_id': 'post-101',
        'author_learner_id': 'learner-2',
        'author_display_name': 'Neema M.',
        'author_avatar_preset': 'lion_reader',
        'parent_comment_id': null,
        'content': 'Multiply 3.14159 by radius multiplied by itself!',
        'created_at': now.toIso8601String(),
      };

      final comment = PostComment.fromJson(json);
      expect(comment.id, 'comm-201');
      expect(comment.authorDisplayName, 'Neema M.');
      expect(comment.content, contains('3.14159'));

      final serialized = comment.toJson();
      expect(serialized['post_id'], 'post-101');
    });
  });
}
