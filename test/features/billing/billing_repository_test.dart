import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:learntz/core/auth/auth_repository.dart';
import 'package:learntz/features/billing/billing_repository.dart';

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
    'id': '00000000-0000-0000-0000-000000000501',
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

  group('BillingRepository integration', () {
    test('startCheckout sends trimmed phone and parses MobileMoneyCheckoutResult', () async {
      final server = await _FakeSupabaseServer.start((request, body) async {
        if (request.uri.path == '/auth/v1/token') {
          _writeJson(request, 200, _sessionPayload());
        } else if (request.uri.path == '/rest/v1/rpc/start_parent_subscription_checkout') {
          _writeJson(request, 200, {
            'subscription_id': 'sub-1',
            'transaction_id': 'tx-1',
            'reference': 'LTZ-ABCDEF123456',
            'provider': 'mpesa_tz',
            'amount': 1500000,
            'currency': 'TZS',
            'status': 'pending',
            'subscription_status': 'pending_payment',
            'plan_name': 'LearnTZ Family Monthly',
            'billing_interval': 'monthly',
          });
        } else {
          _writeJson(request, 404, {'message': 'Not found'});
        }
      });

      final client = SupabaseClient(server.baseUrl, 'anon-key');
      await client.auth.signInWithPassword(
        email: 'parent@example.com',
        password: 'password123',
      );
      final repo = BillingRepository(client);
      final checkout = await repo.startCheckout(
        planId: 'plan-1',
        provider: 'mpesa_tz',
        msisdn: ' +255712345678 ',
      );

      expect(checkout.reference, 'LTZ-ABCDEF123456');
      expect(checkout.provider, 'mpesa_tz');
      expect(checkout.amount, 1500000);
      expect(checkout.status, 'pending');

      final rpcReq = server.requests.last;
      expect(rpcReq.body['p_plan_id'], 'plan-1');
      expect(rpcReq.body['p_provider'], 'mpesa_tz');
      expect(rpcReq.body['p_msisdn'], '+255712345678');

      await client.dispose();
      await server.close();
    });

    test('startCheckout throws NotSignedInException when signed out', () async {
      final client = SupabaseClient('http://127.0.0.1:9', 'anon-key');
      final repo = BillingRepository(client);
      expect(
        () => repo.startCheckout(planId: 'plan-1', provider: 'tigo_pesa'),
        throwsA(isA<NotSignedInException>()),
      );
      await client.dispose();
    });
  });
}
