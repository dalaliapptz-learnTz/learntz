import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/state/app_providers.dart';
import 'account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : AccountRepository(client);
});

final parentProfileProvider = FutureProvider.autoDispose<ParentProfile>((
  ref,
) async {
  final repository = ref.watch(accountRepositoryProvider);
  if (repository == null) throw const AuthNotConfiguredException();
  return repository.getProfile();
});

final accountStatusProvider = FutureProvider.autoDispose<String>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw const AuthNotConfiguredException();
  final user = client.auth.currentUser;
  if (user == null) throw const NotSignedInException();
  final data = await client
      .from('account_status')
      .select('status')
      .eq('user_id', user.id)
      .single();
  return data['status'] as String;
});
