import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:learntz/core/auth/auth_repository.dart';

class _CapturedRequest {
  _CapturedRequest({
    required this.method,
    required this.path,
    required this.queryParameters,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, String> queryParameters;
  final Map<String, dynamic> body;
}

class _FakeSupabaseServer {
  _FakeSupabaseServer._(this._server, this._handler) {
    _server.listen((request) async {
      final rawBody = await utf8.decoder.bind(request).join();
      final decodedBody = rawBody.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(rawBody) as Map);
      requests.add(
        _CapturedRequest(
          method: request.method,
          path: request.uri.path,
          queryParameters: request.uri.queryParameters,
          body: decodedBody,
        ),
      );
      await _handler(request, decodedBody);
    });
  }

  final HttpServer _server;
  final Future<void> Function(HttpRequest request, Map<String, dynamic> body)
      _handler;
  final List<_CapturedRequest> requests = [];

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  static Future<_FakeSupabaseServer> start(
    Future<void> Function(HttpRequest request, Map<String, dynamic> body)
        handler,
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

Map<String, dynamic> _fakeSessionJson({
  String userId = '00000000-0000-0000-0000-000000000001',
  String email = 'parent@example.com',
}) {
  return {
    'access_token': 'header.payload.signature',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'fake-refresh-token',
    'user': {
      'id': userId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': email,
      'created_at': '2026-11-12T00:00:00Z',
      'app_metadata': {'provider': 'email'},
      'user_metadata': {'full_name': 'Amina Juma', 'country_code': 'TZ'},
    },
  };
}

class _MemoryAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> getItem({required String key}) async => _store[key];

  @override
  Future<void> removeItem({required String key}) async {
    _store.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _store[key] = value;
  }
}

void main() {
  setUp(() {
    HttpOverrides.global = null;
  });

  group('AuthRepository integration', () {
    test('signUp trims inputs and sends profile metadata and redirect URL', () async {
      final server = await _FakeSupabaseServer.start((request, body) async {
        _writeJson(request, 200, _fakeSessionJson(email: 'amina@example.com'));
      });
      final client = SupabaseClient(
        server.baseUrl,
        'test-anon-key',
        authOptions: AuthClientOptions(
          autoRefreshToken: false,
          pkceAsyncStorage: _MemoryAsyncStorage(),
        ),
      );
      addTearDown(() async {
        await client.dispose();
        await server.close();
      });

      final repo = AuthRepository(
        client,
        redirectUrl: 'learnapp://login-callback/',
      );

      final response = await repo.signUp(
        fullName: '  Amina Juma  ',
        email: '  amina@example.com  ',
        password: 'Password123!',
        countryCode: 'KE',
      );

      expect(response.user?.email, 'amina@example.com');
      final captured = server.requests.single;
      expect(captured.method, 'POST');
      expect(captured.path, '/auth/v1/signup');
      expect(
        captured.queryParameters['redirect_to'],
        'learnapp://login-callback/',
      );
      expect(captured.body['email'], 'amina@example.com');
      expect(captured.body['data'], {
        'full_name': 'Amina Juma',
        'country_code': 'KE',
      });
    });

    test('changePassword requires a signed-in user and re-authenticates before update', () async {
      final server = await _FakeSupabaseServer.start((request, body) async {
        if (request.uri.path == '/auth/v1/token') {
          _writeJson(request, 200, _fakeSessionJson(email: 'amina@example.com'));
        } else if (request.uri.path == '/auth/v1/user') {
          _writeJson(request, 200, _fakeSessionJson(email: 'amina@example.com')['user']!);
        } else {
          _writeJson(request, 404, {'message': 'Unexpected path'});
        }
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

      final repo = AuthRepository(client);
      await expectLater(
        repo.changePassword(
          currentPassword: 'OldPassword123!',
          newPassword: 'NewPassword123!',
        ),
        throwsA(isA<NotSignedInException>()),
      );

      await repo.signIn(email: ' amina@example.com ', password: 'OldPassword123!');
      await repo.changePassword(
        currentPassword: 'OldPassword123!',
        newPassword: 'NewPassword123!',
      );

      expect(server.requests.map((r) => '${r.method} ${r.path}'), [
        'POST /auth/v1/token',
        'POST /auth/v1/token',
        'PUT /auth/v1/user',
      ]);
      expect(server.requests.last.body['password'], 'NewPassword123!');
    });

    test('requestAccountStatus invokes RPC and surfaces PostgrestException on failure', () async {
      var rejectNext = false;
      final server = await _FakeSupabaseServer.start((request, body) async {
        if (rejectNext) {
          _writeJson(request, 400, {
            'code': '22023',
            'message': 'An active reason is required',
            'details': null,
            'hint': null,
          });
          return;
        }
        _writeJson(request, 200, {'status': 'pending_deactivation'});
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

      final repo = AuthRepository(client);
      final status = await repo.requestAccountStatus(
        status: 'pending_deactivation',
        reason: 'Term break',
      );
      expect(status, 'pending_deactivation');
      expect(server.requests.single.path, '/rest/v1/rpc/request_account_status');
      expect(server.requests.single.body, {
        'p_status': 'pending_deactivation',
        'p_reason': 'Term break',
      });

      rejectNext = true;
      await expectLater(
        repo.requestAccountStatus(status: 'invalid'),
        throwsA(
          isA<PostgrestException>()
              .having((e) => e.code, 'code', '22023')
              .having((e) => e.message, 'message', 'An active reason is required'),
        ),
      );
    });
  });
}
