import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:learntz/core/auth/auth_repository.dart';
import 'package:learntz/features/learners/learner_repository.dart';

class _CapturedRequest {
  _CapturedRequest({
    required this.method,
    required this.path,
    required this.body,
  });

  final String method;
  final String path;
  final dynamic body;
}

class _FakeSupabaseServer {
  _FakeSupabaseServer._(this._server, this._handler) {
    _server.listen((request) async {
      final rawBody = await utf8.decoder.bind(request).join();
      final decodedBody = rawBody.isEmpty ? null : jsonDecode(rawBody);
      requests.add(
        _CapturedRequest(
          method: request.method,
          path: request.uri.path,
          body: decodedBody,
        ),
      );
      await _handler(request, decodedBody);
    });
  }

  final HttpServer _server;
  final Future<void> Function(HttpRequest request, dynamic body) _handler;
  final List<_CapturedRequest> requests = [];

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

Map<String, dynamic> _learnerJson({
  String id = 'learner-1',
  String firstName = 'Amani',
  String lastName = 'Mushi',
  String gradeId = 'grade-1',
}) {
  return {
    'id': id,
    'first_name': firstName,
    'middle_name': null,
    'last_name': lastName,
    'date_of_birth': '2016-04-12',
    'gender': 'female',
    'country_code': 'TZ',
    'education_system_id': 'system-1',
    'curriculum_id': 'curriculum-1',
    'education_level_id': 'level-1',
    'grade_id': gradeId,
    'school_id': null,
    'status': 'active',
    'created_at': '2026-11-12T10:00:00Z',
    'updated_at': '2026-11-12T10:00:00Z',
  };
}

Future<SupabaseClient> _signedInClient(_FakeSupabaseServer server) async {
  final client = SupabaseClient(
    server.baseUrl,
    'test-anon-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  await client.auth.signInWithPassword(
    email: 'parent@example.com',
    password: 'Password123!',
  );
  server.requests.clear();
  return client;
}

Map<String, dynamic> _sessionPayload() => {
  'access_token': 'header.payload.signature',
  'token_type': 'bearer',
  'expires_in': 3600,
  'refresh_token': 'fake-refresh-token',
  'user': {
    'id': '00000000-0000-0000-0000-000000000101',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'parent@example.com',
    'created_at': '2026-11-12T00:00:00Z',
    'app_metadata': {'provider': 'email'},
    'user_metadata': {'full_name': 'Parent User', 'country_code': 'TZ'},
  },
};

void main() {
  setUp(() {
    HttpOverrides.global = null;
  });

  group('LearnerRepository integration', () {
    test('unauthenticated createLearner throws NotSignedInException without network call', () async {
      final server = await _FakeSupabaseServer.start((request, body) async {
        _writeJson(request, 200, _sessionPayload());
      });
      final client = SupabaseClient(
        server.baseUrl,
        'test-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(() async {
        await client.dispose();
        await server.close();
      });

      final repo = LearnerRepository(client);
      await expectLater(
        repo.createLearner(
          registrationRequestId: 'req-1',
          firstName: 'Amani',
          middleName: null,
          lastName: 'Mushi',
          dateOfBirth: DateTime(2016, 4, 12),
          gender: 'female',
          countryCode: 'TZ',
          educationSystemId: 'system-1',
          curriculumId: 'curriculum-1',
          educationLevelId: 'level-1',
          gradeId: 'grade-1',
          schoolId: null,
        ),
        throwsA(isA<NotSignedInException>()),
      );
      expect(server.requests, isEmpty);
    });

    test('createLearner and updateLearner send formatted RPC parameter payloads', () async {
      final server = await _FakeSupabaseServer.start((request, body) async {
        if (request.uri.path == '/auth/v1/token') {
          _writeJson(request, 200, _sessionPayload());
        } else if (request.uri.path == '/rest/v1/rpc/create_learner') {
          _writeJson(request, 200, _learnerJson());
        } else if (request.uri.path == '/rest/v1/rpc/update_learner') {
          _writeJson(
            request,
            200,
            _learnerJson(firstName: 'Amani Updated', gradeId: 'grade-2'),
          );
        } else {
          _writeJson(request, 404, {'message': 'Not found'});
        }
      });
      final client = await _signedInClient(server);
      addTearDown(() async {
        await client.dispose();
        await server.close();
      });

      final repo = LearnerRepository(client);
      final created = await repo.createLearner(
        registrationRequestId: 'req-1',
        firstName: '  Amani ',
        middleName: '  ',
        lastName: ' Mushi ',
        dateOfBirth: DateTime(2016, 4, 12),
        gender: 'female',
        countryCode: 'TZ',
        educationSystemId: 'system-1',
        curriculumId: 'curriculum-1',
        educationLevelId: 'level-1',
        gradeId: 'grade-1',
        schoolId: null,
      );

      expect(created.id, 'learner-1');
      expect(created.firstName, 'Amani');
      expect(server.requests.first.path, '/rest/v1/rpc/create_learner');
      expect(server.requests.first.body, {
        'p_registration_request_id': 'req-1',
        'p_first_name': 'Amani',
        'p_middle_name': '',
        'p_last_name': 'Mushi',
        'p_date_of_birth': '2016-04-12',
        'p_gender': 'female',
        'p_country_code': 'TZ',
        'p_education_system_id': 'system-1',
        'p_curriculum_id': 'curriculum-1',
        'p_education_level_id': 'level-1',
        'p_grade_id': 'grade-1',
        'p_school_id': null,
      });

      final updated = await repo.updateLearner(
        learnerId: 'learner-1',
        firstName: 'Amani Updated',
        middleName: null,
        lastName: 'Mushi',
        dateOfBirth: DateTime(2016, 4, 12),
        gender: 'female',
        countryCode: 'TZ',
        educationSystemId: 'system-1',
        curriculumId: 'curriculum-1',
        educationLevelId: 'level-1',
        gradeId: 'grade-2',
        schoolId: null,
      );

      expect(updated.gradeId, 'grade-2');
      expect(server.requests.last.path, '/rest/v1/rpc/update_learner');
      expect(
        (server.requests.last.body as Map<String, dynamic>)['p_learner_id'],
        'learner-1',
      );
      expect(
        (server.requests.last.body as Map<String, dynamic>)['p_grade_id'],
        'grade-2',
      );
    });

    test('inviteGuardianByEmail surfaces PostgrestException errors and parses invitation payload', () async {
      var rejectInvite = false;
      final server = await _FakeSupabaseServer.start((request, body) async {
        if (request.uri.path == '/auth/v1/token') {
          _writeJson(request, 200, _sessionPayload());
        } else if (rejectInvite) {
          _writeJson(request, 400, {
            'code': '22023',
            'message': 'An invitation is already pending for this email.',
            'details': null,
            'hint': null,
          });
        } else {
          _writeJson(request, 200, {
            'id': 'inv-1',
            'learner_id': 'learner-1',
            'invitee_email': 'coparent@example.com',
            'status': 'pending',
            'expires_at': '2026-11-19T10:00:00Z',
            'created_at': '2026-11-12T10:00:00Z',
          });
        }
      });
      final client = await _signedInClient(server);
      addTearDown(() async {
        await client.dispose();
        await server.close();
      });

      final repo = LearnerRepository(client);
      final invitation = await repo.inviteGuardianByEmail(
        learnerId: 'learner-1',
        email: '  coparent@example.com ',
      );

      expect(invitation.id, 'inv-1');
      expect(invitation.inviteeEmail, 'coparent@example.com');
      expect(server.requests.single.body, {
        'p_learner_id': 'learner-1',
        'p_invitee_email': 'coparent@example.com',
      });

      rejectInvite = true;
      await expectLater(
        repo.inviteGuardianByEmail(
          learnerId: 'learner-1',
          email: 'coparent@example.com',
        ),
        throwsA(
          isA<PostgrestException>()
              .having((e) => e.code, 'code', '22023')
              .having(
                (e) => e.message,
                'message',
                'An invitation is already pending for this email.',
              ),
        ),
      );
    });
  });
}
