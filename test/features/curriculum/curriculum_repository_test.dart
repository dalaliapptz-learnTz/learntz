import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:learntz/features/curriculum/curriculum_repository.dart';

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
    'id': '00000000-0000-0000-0000-000000000402',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'editor@example.com',
    'created_at': '2026-11-12T00:00:00Z',
    'app_metadata': {'provider': 'email'},
    'user_metadata': {'full_name': 'Editor User', 'country_code': 'KE'},
  },
};

void main() {
  setUp(() {
    HttpOverrides.global = null;
  });

  group('CurriculumRepository integration', () {
    test('getStaffCapabilities scopes RPC checks to selected countryCode', () async {
      final server = await _FakeSupabaseServer.start((request, body) async {
        if (request.uri.path == '/auth/v1/token') {
          _writeJson(request, 200, _sessionPayload());
        } else if (request.uri.path == '/rest/v1/rpc/has_curriculum_role') {
          final roles = List<String>.from((body as Map)['p_roles'] as List);
          final isEditorOrReviewer = roles.contains('curriculum_editor') ||
              roles.contains('curriculum_reviewer');
          _writeJson(request, 200, isEditorOrReviewer);
        } else {
          _writeJson(request, 404, {'message': 'Not found'});
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

      final repo = CurriculumRepository(client);
      final unauthenticated = await repo.getStaffCapabilities(countryCode: 'KE');
      expect(unauthenticated.canAccess, isFalse);
      expect(server.requests, isEmpty);

      await client.auth.signInWithPassword(
        email: 'editor@example.com',
        password: 'Password123!',
      );
      server.requests.clear();

      final capabilities = await repo.getStaffCapabilities(countryCode: 'KE');
      expect(capabilities.canAccess, isTrue);
      expect(capabilities.canEdit, isTrue);
      expect(capabilities.canReview, isTrue);
      expect(capabilities.canApprove, isFalse);

      expect(server.requests, hasLength(4));
      for (final req in server.requests) {
        expect(req.path, '/rest/v1/rpc/has_curriculum_role');
        expect((req.body as Map<String, dynamic>)['p_country_code'], 'KE');
      }
    });

    test('registerImport sends metadata RPC parameters and maps PostgrestException on failure', () async {
      var rejectImport = false;
      final server = await _FakeSupabaseServer.start((request, body) async {
        if (request.uri.path == '/auth/v1/token') {
          _writeJson(request, 200, _sessionPayload());
        } else if (rejectImport) {
          _writeJson(request, 403, {
            'code': '42501',
            'message': 'A matching independently verified source with cleared usage rights is required',
            'details': null,
            'hint': null,
          });
        } else {
          _writeJson(request, 200, {
            'id': 'job-1',
            'source_id': 'source-1',
            'version_id': 'version-1',
            'storage_bucket': 'curriculum-source-documents',
            'storage_object_path': 'KE/source-1/job-1.pdf',
            'file_sha256': 'a' * 64,
            'document_format': 'application/pdf',
            'original_filename': 'kicd_primary.pdf',
            'file_size_bytes': 4096,
            'upload_complete': false,
            'page_count': null,
            'extraction_engine': null,
            'status': 'queued',
            'validation_errors': [],
            'attempt_count': 0,
            'created_at': '2026-11-12T10:00:00Z',
          });
        }
      });

      final client = SupabaseClient(
        server.baseUrl,
        'test-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      await client.auth.signInWithPassword(
        email: 'editor@example.com',
        password: 'Password123!',
      );
      server.requests.clear();
      addTearDown(() async {
        await client.dispose();
        await server.close();
      });

      final repo = CurriculumRepository(client);
      final job = await repo.registerImport(
        versionId: 'version-1',
        sourceId: 'source-1',
        checksum: 'a' * 64,
        documentFormat: 'application/pdf',
        filename: 'kicd_primary.pdf',
        fileSizeBytes: 4096,
      );

      expect(job.id, 'job-1');
      expect(job.storageObjectPath, 'KE/source-1/job-1.pdf');
      expect(
        server.requests.single.path,
        '/rest/v1/rpc/register_curriculum_import_document',
      );
      expect(server.requests.single.body, {
        'p_version_id': 'version-1',
        'p_source_id': 'source-1',
        'p_file_sha256': 'a' * 64,
        'p_document_format': 'application/pdf',
        'p_original_filename': 'kicd_primary.pdf',
        'p_file_size_bytes': 4096,
      });

      rejectImport = true;
      await expectLater(
        repo.registerImport(
          versionId: 'version-1',
          sourceId: 'source-1',
          checksum: 'a' * 64,
          documentFormat: 'application/pdf',
          filename: 'kicd_primary.pdf',
          fileSizeBytes: 4096,
        ),
        throwsA(
          isA<PostgrestException>()
              .having((e) => e.code, 'code', '42501')
              .having(
                (e) => e.message,
                'message',
                'A matching independently verified source with cleared usage rights is required',
              ),
        ),
      );
    });
  });
}
