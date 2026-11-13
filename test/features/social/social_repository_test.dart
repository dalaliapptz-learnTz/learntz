import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:learntz/features/social/social_models.dart';
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
}
