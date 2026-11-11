import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/app_providers.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;

  final environment = ref.watch(appEnvironmentProvider);
  return AuthRepository(client, redirectUrl: environment.authRedirectUrl);
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const Stream.empty();
  return client.auth.onAuthStateChange;
});

final passwordRecoveryModeProvider =
    NotifierProvider<PasswordRecoveryModeNotifier, bool>(
      PasswordRecoveryModeNotifier.new,
    );

class PasswordRecoveryModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(authStateChangesProvider, (previous, next) {
      final event = next.asData?.value.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        state = true;
      } else if (event == AuthChangeEvent.signedOut) {
        state = false;
      }
    });
    return ref.read(authStateChangesProvider).asData?.value.event ==
        AuthChangeEvent.passwordRecovery;
  }

  void complete() => state = false;
}

class AuthNotConfiguredException implements Exception {
  const AuthNotConfiguredException();
}
