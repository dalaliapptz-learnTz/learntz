import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_repository.dart';
import 'admin_models.dart';

class AdminRepository {
  const AdminRepository(this._client);

  final SupabaseClient _client;

  Future<AdminCapabilities> getCapabilities() async {
    if (_client.auth.currentUser == null) {
      return const AdminCapabilities.empty();
    }
    final data = await _client.rpc<Map<String, dynamic>>(
      'get_admin_capabilities',
    );
    return AdminCapabilities.fromJson(data);
  }

  Future<AdminDashboardStats> getDashboardStats() async {
    _requireUser();
    final data = await _client.rpc<Map<String, dynamic>>(
      'get_admin_dashboard_stats',
    );
    return AdminDashboardStats.fromJson(data);
  }

  Future<List<AdminAccountRequest>> listAccountRequests() async {
    _requireUser();
    final rows = await _client.rpc<List<dynamic>>(
      'list_admin_account_requests',
    );
    return rows
        .whereType<Map<String, dynamic>>()
        .map(AdminAccountRequest.fromJson)
        .toList();
  }

  Future<void> resolveAccountRequest({
    required String userId,
    required String newStatus,
  }) async {
    _requireUser();
    await _client.rpc<void>(
      'resolve_admin_account_request',
      params: {
        'p_user_id': userId,
        'p_new_status': newStatus,
      },
    );
  }

  Future<List<AdminAuditLogEntry>> listAuditLogs({
    int limit = 50,
    int offset = 0,
    String? actionFilter,
  }) async {
    _requireUser();
    final trimmedFilter = actionFilter?.trim();
    final rows = await _client.rpc<List<dynamic>>(
      'list_admin_audit_logs',
      params: {
        'p_limit': limit,
        'p_offset': offset,
        'p_action_filter':
            (trimmedFilter == null || trimmedFilter.isEmpty) ? null : trimmedFilter,
      },
    );
    return rows
        .whereType<Map<String, dynamic>>()
        .map(AdminAuditLogEntry.fromJson)
        .toList();
  }

  Future<List<Map<String, dynamic>>> listAllCountries() async {
    _requireUser();
    final rows = await _client
        .from('countries')
        .select()
        .order('country_code', ascending: true);
    return (rows as List<dynamic>)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  Future<void> toggleCountryEnabled({
    required String countryCode,
    required bool isEnabled,
  }) async {
    _requireUser();
    await _client
        .from('countries')
        .update({
          'is_enabled': isEnabled,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('country_code', countryCode);
  }

  void _requireUser() {
    if (_client.auth.currentUser == null) {
      throw const NotSignedInException();
    }
  }
}
