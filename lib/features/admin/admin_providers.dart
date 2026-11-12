import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/state/app_providers.dart';
import 'admin_models.dart';
import 'admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return AdminRepository(client);
});

final adminCapabilitiesProvider = FutureProvider<AdminCapabilities>((ref) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  if (repository == null) return const AdminCapabilities.empty();
  return repository.getCapabilities();
});

final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>((
  ref,
) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  if (repository == null) throw const AuthNotConfiguredException();
  return repository.getDashboardStats();
});

final adminAccountRequestsProvider =
    FutureProvider<List<AdminAccountRequest>>((ref) async {
      ref.watch(authStateChangesProvider);
      final repository = ref.watch(adminRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.listAccountRequests();
    });

final adminAuditLogsProvider =
    FutureProvider.family<List<AdminAuditLogEntry>, String?>((
      ref,
      actionFilter,
    ) async {
      ref.watch(authStateChangesProvider);
      final repository = ref.watch(adminRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      return repository.listAuditLogs(actionFilter: actionFilter);
    });
