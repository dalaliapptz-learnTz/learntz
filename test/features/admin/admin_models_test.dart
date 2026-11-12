import 'package:flutter_test/flutter_test.dart';

import 'package:learntz/features/admin/admin_models.dart';

void main() {
  group('AdminCapabilities', () {
    test('parses capabilities and role assignments from RPC payload', () {
      final capabilities = AdminCapabilities.fromJson({
        'can_access_admin': true,
        'is_super_admin': false,
        'is_country_admin': false,
        'is_support_admin': true,
        'is_curriculum_staff': true,
        'roles': [
          {'role': 'support_admin', 'country_code': null},
          {'role': 'curriculum_reviewer', 'country_code': 'TZ'},
        ],
      });

      expect(capabilities.canAccessAdmin, isTrue);
      expect(capabilities.isSuperAdmin, isFalse);
      expect(capabilities.isSupportAdmin, isTrue);
      expect(capabilities.isCurriculumStaff, isTrue);
      expect(capabilities.canManageAccountRequests, isTrue);
      expect(capabilities.roles, hasLength(2));
      expect(capabilities.roles.first.role, 'support_admin');
      expect(capabilities.roles.first.countryCode, isNull);
      expect(capabilities.roles.last.countryCode, 'TZ');
    });

    test('disallows account request management for curriculum-only staff', () {
      final capabilities = AdminCapabilities.fromJson({
        'can_access_admin': true,
        'is_super_admin': false,
        'is_country_admin': false,
        'is_support_admin': false,
        'is_curriculum_staff': true,
        'roles': [
          {'role': 'curriculum_editor', 'country_code': 'KE'},
        ],
      });

      expect(capabilities.canAccessAdmin, isTrue);
      expect(capabilities.canManageAccountRequests, isFalse);
    });
  });

  group('AdminDashboardStats', () {
    test('parses numeric summary metrics with safe defaults', () {
      final stats = AdminDashboardStats.fromJson({
        'enabled_countries': 3,
        'parent_accounts': 120,
        'active_learners': 185,
        'pending_account_requests': 2,
        'pending_curriculum_imports': 4,
      });

      expect(stats.enabledCountries, 3);
      expect(stats.parentAccounts, 120);
      expect(stats.activeLearners, 185);
      expect(stats.pendingAccountRequests, 2);
      expect(stats.pendingCurriculumImports, 4);
    });
  });

  group('AdminAccountRequest & AdminAuditLogEntry', () {
    test('parses account request and audit log entries', () {
      final request = AdminAccountRequest.fromJson({
        'user_id': 'user-123',
        'full_name': 'Amina Juma',
        'country_code': 'TZ',
        'status': 'pending_deactivation',
        'request_reason': 'Taking a break',
        'requested_at': '2026-11-12T10:15:30Z',
      });

      expect(request.userId, 'user-123');
      expect(request.fullName, 'Amina Juma');
      expect(request.countryCode, 'TZ');
      expect(request.status, 'pending_deactivation');
      expect(request.requestReason, 'Taking a break');
      expect(request.requestedAt.toUtc().year, 2026);

      final logEntry = AdminAuditLogEntry.fromJson({
        'id': 42,
        'actor_user_id': 'admin-1',
        'target_user_id': 'user-123',
        'action': 'admin_resolved_account_status',
        'metadata': {'new_status': 'active'},
        'created_at': '2026-11-12T11:00:00Z',
      });

      expect(logEntry.id, 42);
      expect(logEntry.actorUserId, 'admin-1');
      expect(logEntry.targetUserId, 'user-123');
      expect(logEntry.action, 'admin_resolved_account_status');
      expect(logEntry.metadata['new_status'], 'active');
    });
  });
}
