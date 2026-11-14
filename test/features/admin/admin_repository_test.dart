import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:learntz/features/admin/admin_repository.dart';

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

Map<String, dynamic> _sessionPayload() => {
  'access_token': 'header.payload.signature',
  'token_type': 'bearer',
  'expires_in': 3600,
  'refresh_token': 'fake-refresh-token',
  'user': {
    'id': '00000000-0000-0000-0000-000000000001',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'admin@learntz.com',
    'created_at': '2026-11-12T00:00:00Z',
    'app_metadata': {'provider': 'email'},
    'user_metadata': {'full_name': 'Super Admin', 'country_code': 'TZ'},
  },
};

void main() {
  group('AdminRepository', () {
    late _FakeSupabaseServer server;
    late SupabaseClient client;
    late AdminRepository repository;

    setUp(() async {
      server = await _FakeSupabaseServer.start((request, body) async {
        final path = request.uri.path;
        if (path.contains('/auth/v1/token')) {
          _writeJson(request, 200, _sessionPayload());
          return;
        }

        if (path.contains('/rest/v1/countries')) {
          if (request.method == 'GET') {
            _writeJson(request, 200, [
              {
                'country_code': 'TZ',
                'display_name': 'Tanzania',
                'product_name': 'LearnTZ',
                'currency_code': 'TZS',
                'currency_symbol': 'TZS',
                'is_enabled': true,
              },
              {
                'country_code': 'KE',
                'display_name': 'Kenya',
                'product_name': 'LearnKE',
                'currency_code': 'KES',
                'currency_symbol': 'KSh',
                'is_enabled': false,
              },
            ]);
            return;
          }
          if (request.method == 'PATCH') {
            _writeJson(request, 200, []);
            return;
          }
        }

        if (path.contains('/rest/v1/rpc/get_admin_dashboard_stats')) {
          _writeJson(request, 200, {
            'enabled_countries': 6,
            'parent_accounts': 240,
            'active_learners': 450,
            'pending_account_requests': 3,
            'pending_curriculum_imports': 1,
          });
          return;
        }

        _writeJson(request, 404, {'message': 'Not found: $path'});
      });

      client = SupabaseClient(
        server.baseUrl,
        'test-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      await client.auth.signInWithPassword(
        email: 'admin@learntz.com',
        password: 'Password123!',
      );
      server.requests.clear();
      repository = AdminRepository(client);
    });

    tearDown(() async {
      await server.close();
    });

    test('listAllCountries returns all national configurations', () async {
      final countries = await repository.listAllCountries();

      expect(countries, hasLength(2));
      expect(countries.first['country_code'], 'TZ');
      expect(countries.first['is_enabled'], isTrue);
      expect(countries.last['country_code'], 'KE');
      expect(countries.last['is_enabled'], isFalse);

      final req = server.requests.firstWhere((r) => r.path.contains('/countries'));
      expect(req.method, 'GET');
    });

    test('toggleCountryEnabled sends PATCH update to countries table', () async {
      await repository.toggleCountryEnabled(countryCode: 'KE', isEnabled: true);

      final patchReq = server.requests.firstWhere(
        (r) => r.method == 'PATCH' && r.path.contains('/countries'),
      );
      expect(patchReq.body['is_enabled'], isTrue);
      expect(patchReq.body['updated_at'], isNotNull);
    });

    test('getDashboardStats fetches aggregated platform metrics', () async {
      final stats = await repository.getDashboardStats();

      expect(stats.enabledCountries, 6);
      expect(stats.parentAccounts, 240);
      expect(stats.activeLearners, 450);
      expect(stats.pendingAccountRequests, 3);
      expect(stats.pendingCurriculumImports, 1);
    });
  });
}
