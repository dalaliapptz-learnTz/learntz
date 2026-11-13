import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:learntz/features/social/social_repository.dart';

class _FakeSupabaseServer {
  _FakeSupabaseServer._(this._server, this._handler) {
    _server.listen((request) async {
      final rawBody = await utf8.decoder.bind(request).join();
      final decodedBody = rawBody.isEmpty ? null : jsonDecode(rawBody);
      await _handler(request, decodedBody);
    });
  }

  final HttpServer _server;
  final Future<void> Function(HttpRequest request, dynamic body) _handler;

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  static Future<_FakeSupabaseServer> start(
    Future<void> Function(HttpRequest request, dynamic body) handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _FakeSupabaseServer._(server, handler);
  }

  Future<void> close() => _server.close(force: true);
}

void _writeJson(HttpRequest request, int statusCode, Object body) {
  request.response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
  request.response.close();
}

void main() {
  late _FakeSupabaseServer server;
  late SupabaseClient client;
  late SocialRepository repository;

  final recordedCalls = <String, dynamic>{};

  setUp(() async {
    recordedCalls.clear();
    server = await _FakeSupabaseServer.start((request, body) async {
      final path = request.uri.path;
      if (path == '/rest/v1/rpc/get_or_create_learner_social_profile') {
        recordedCalls['get_or_create'] = body;
        _writeJson(request, 200, {
          'id': 'profile-1',
          'learner_id': body['p_learner_id'],
          'display_name': 'Baraka P.',
          'avatar_preset': 'owl_scholar',
          'bio': 'Learning every day!',
          'academic_interests': ['Mathematics'],
          'points': 50,
          'badges_count': 1,
          'profile_visibility': 'school_only',
          'allow_follower_requests': true,
          'show_achievements': true,
          'show_communities': true,
          'created_at': DateTime.now().toIso8601String(),
        });
        return;
      }

      if (path == '/rest/v1/rpc/update_learner_social_profile') {
        recordedCalls['update'] = body;
        _writeJson(request, 200, {
          'id': 'profile-1',
          'learner_id': body['p_learner_id'],
          'display_name': body['p_display_name'],
          'avatar_preset': body['p_avatar_preset'],
          'bio': body['p_bio'],
          'academic_interests': body['p_academic_interests'],
          'points': 50,
          'badges_count': 1,
          'profile_visibility': body['p_profile_visibility'],
          'allow_follower_requests': body['p_allow_follower_requests'],
          'show_achievements': body['p_show_achievements'],
          'show_communities': body['p_show_communities'],
          'created_at': DateTime.now().toIso8601String(),
        });
        return;
      }

      if (path == '/rest/v1/rpc/get_public_learner_social_profile') {
        recordedCalls['get_public'] = body;
        _writeJson(request, 200, {
          'learner_id': body['p_target_learner_id'],
          'display_name': 'Baraka P.',
          'avatar_preset': 'owl_scholar',
          'points': 50,
          'badges_count': 1,
          'profile_visibility': 'school_only',
          'grade_name': 'Standard 1',
          'school_name': 'Mlimani Primary',
          'country_code': 'TZ',
          'created_at': DateTime.now().toIso8601String(),
        });
        return;
      }

      if (path == '/rest/v1/rpc/get_social_feed') {
        recordedCalls['get_feed'] = body;
        _writeJson(request, 200, [
          {
            'id': 'post-1',
            'author_learner_id': 'learner-1',
            'author_display_name': 'Amani B.',
            'author_avatar_preset': 'owl_scholar',
            'post_type': 'question',
            'title': 'Photosynthesis question',
            'content': 'How does light intensity affect growth?',
            'tags': ['biology'],
            'likes_count': 3,
            'comments_count': 1,
            'bookmarks_count': 0,
            'viewer_has_reacted': false,
            'viewer_has_saved': false,
            'created_at': DateTime.now().toIso8601String(),
          }
        ]);
        return;
      }

      if (path == '/rest/v1/rpc/create_social_post') {
        recordedCalls['create_post'] = body;
        _writeJson(request, 200, {
          'id': 'post-2',
          'author_learner_id': body['p_author_learner_id'],
          'author_display_name': 'Amani B.',
          'author_avatar_preset': 'owl_scholar',
          'post_type': body['p_post_type'],
          'title': body['p_title'],
          'content': body['p_content'],
          'tags': body['p_tags'] ?? [],
          'likes_count': 0,
          'comments_count': 0,
          'bookmarks_count': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
        return;
      }

      if (path == '/rest/v1/rpc/toggle_post_reaction') {
        recordedCalls['reaction'] = body;
        _writeJson(request, 200, {
          'action': 'added',
          'post_id': body['p_post_id'],
          'reaction_type': body['p_reaction_type'],
        });
        return;
      }

      if (path == '/rest/v1/rpc/add_post_comment') {
        recordedCalls['comment'] = body;
        _writeJson(request, 200, {
          'id': 'c-1',
          'post_id': body['p_post_id'],
          'author_learner_id': body['p_author_learner_id'],
          'author_display_name': 'Neema M.',
          'author_avatar_preset': 'lion_reader',
          'content': body['p_content'],
          'created_at': DateTime.now().toIso8601String(),
        });
        return;
      }

      if (path == '/rest/v1/rpc/toggle_save_post') {
        recordedCalls['save_post'] = body;
        _writeJson(request, 200, true);
        return;
      }

      if (path == '/rest/v1/rpc/block_learner') {
        recordedCalls['block'] = body;
        _writeJson(request, 200, true);
        return;
      }

      if (path == '/rest/v1/rpc/get_learner_communities') {
        recordedCalls['get_communities'] = body;
        _writeJson(request, 200, [
          {
            'id': 'comm-1',
            'community_tier': 'national',
            'name': 'Tanzania National Learning Community',
            'country_code': 'TZ',
            'members_count': 1000,
            'is_official': true,
            'learner_role': 'member',
          }
        ]);
        return;
      }

      if (path == '/rest/v1/rpc/join_community') {
        recordedCalls['join'] = body;
        _writeJson(request, 200, true);
        return;
      }

      if (path == '/rest/v1/rpc/get_community_channels') {
        recordedCalls['channels'] = body;
        _writeJson(request, 200, [
          {
            'id': 'ch-1',
            'community_id': body['p_community_id'],
            'name': 'general',
            'channel_type': 'general',
          }
        ]);
        return;
      }

      if (path == '/rest/v1/rpc/send_channel_message') {
        recordedCalls['send_msg'] = body;
        _writeJson(request, 200, {
          'id': 'msg-1',
          'channel_id': body['p_channel_id'],
          'author_learner_id': body['p_author_learner_id'],
          'content': body['p_content'],
          'created_at': DateTime.now().toIso8601String(),
        });
        return;
      }

      _writeJson(request, 404, {'message': 'Not found: $path'});
    });

    client = SupabaseClient(
      server.baseUrl,
      'fake-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    repository = SocialRepository(supabase: client);
  });

  tearDown(() async {
    client.dispose();
    await server.close();
  });

  test('getOrCreateProfile invokes RPC with learner id', () async {
    final profile = await repository.getOrCreateProfile('learner-999');
    expect(profile.learnerId, 'learner-999');
    expect(profile.displayName, 'Baraka P.');
    expect(profile.avatarPreset, 'owl_scholar');
    expect(recordedCalls['get_or_create'], {'p_learner_id': 'learner-999'});
  });

  test('updateProfile invokes update RPC with updated parameters', () async {
    final profile = await repository.updateProfile(
      learnerId: 'learner-999',
      displayName: 'MathGenius',
      avatarPreset: 'lion_reader',
      bio: 'Ready for challenges!',
      academicInterests: ['Physics', 'Mathematics'],
      profileVisibility: 'public',
      allowFollowerRequests: true,
      showAchievements: true,
      showCommunities: false,
    );

    expect(profile.displayName, 'MathGenius');
    expect(profile.avatarPreset, 'lion_reader');
    expect(recordedCalls['update']['p_display_name'], 'MathGenius');
    expect(recordedCalls['update']['p_avatar_preset'], 'lion_reader');
    expect(recordedCalls['update']['p_show_communities'], false);
  });

  test('getPublicProfile invokes public profile RPC', () async {
    final publicProfile = await repository.getPublicProfile(
      targetLearnerId: 'learner-888',
      viewerLearnerId: 'learner-999',
    );

    expect(publicProfile, isNotNull);
    expect(publicProfile!.displayName, 'Baraka P.');
    expect(publicProfile.gradeName, 'Standard 1');
    expect(publicProfile.schoolName, 'Mlimani Primary');
    expect(recordedCalls['get_public']['p_target_learner_id'], 'learner-888');
    expect(recordedCalls['get_public']['p_viewer_learner_id'], 'learner-999');
  });

  test('getSocialFeed invokes RPC and parses posts', () async {
    final posts = await repository.getSocialFeed(
      viewerLearnerId: 'learner-1',
      postType: 'question',
    );

    expect(posts.length, 1);
    expect(posts.first.title, 'Photosynthesis question');
    expect(recordedCalls['get_feed']['p_viewer_learner_id'], 'learner-1');
    expect(recordedCalls['get_feed']['p_post_type'], 'question');
  });

  test('createPost invokes create RPC', () async {
    final post = await repository.createPost(
      authorLearnerId: 'learner-1',
      postType: 'question',
      title: 'New question',
      content: 'Detailed explanation needed',
      tags: ['biology'],
    );

    expect(post.title, 'New question');
    expect(recordedCalls['create_post']['p_title'], 'New question');
  });

  test('toggleReaction invokes reaction RPC', () async {
    final res = await repository.toggleReaction(
      postId: 'post-1',
      learnerId: 'learner-2',
      reactionType: 'helpful',
    );

    expect(res['action'], 'added');
    expect(recordedCalls['reaction']['p_reaction_type'], 'helpful');
  });

  test('addComment invokes comment RPC', () async {
    final comm = await repository.addComment(
      postId: 'post-1',
      authorLearnerId: 'learner-2',
      content: 'Here is the answer!',
    );

    expect(comm.content, 'Here is the answer!');
    expect(recordedCalls['comment']['p_content'], 'Here is the answer!');
  });

  test('toggleSavePost invokes save RPC', () async {
    final saved = await repository.toggleSavePost(
      postId: 'post-1',
      learnerId: 'learner-2',
    );

    expect(saved, isTrue);
    expect(recordedCalls['save_post']['p_post_id'], 'post-1');
  });

  test('blockLearner invokes block RPC', () async {
    final blocked = await repository.blockLearner(
      blockerLearnerId: 'learner-1',
      blockedLearnerId: 'learner-2',
      reason: 'Spam',
    );

    expect(blocked, isTrue);
    expect(recordedCalls['block']['p_blocker_learner_id'], 'learner-1');
    expect(recordedCalls['block']['p_blocked_learner_id'], 'learner-2');
  });

  test('getLearnerCommunities invokes RPC and returns communities', () async {
    final communities = await repository.getLearnerCommunities('learner-1');
    expect(communities.length, 1);
    expect(communities.first.communityTier, 'national');
    expect(recordedCalls['get_communities']['p_learner_id'], 'learner-1');
  });

  test('joinCommunity invokes join RPC', () async {
    final success = await repository.joinCommunity(
      communityId: 'comm-1',
      learnerId: 'learner-1',
    );
    expect(success, isTrue);
    expect(recordedCalls['join']['p_community_id'], 'comm-1');
  });

  test('getCommunityChannels and sendChannelMessage invoke RPCs', () async {
    final channels = await repository.getCommunityChannels('comm-1');
    expect(channels.length, 1);
    expect(channels.first.name, 'general');

    final msg = await repository.sendChannelMessage(
      channelId: 'ch-1',
      authorLearnerId: 'learner-1',
      content: 'Study session at 4pm!',
    );
    expect(msg.content, 'Study session at 4pm!');
    expect(recordedCalls['send_msg']['p_content'], 'Study session at 4pm!');
  });
}
