import 'package:supabase_flutter/supabase_flutter.dart';

class NotSignedInException implements Exception {
  const NotSignedInException();
}

class AuthRepository {
  const AuthRepository(this._client, {this.redirectUrl});

  final SupabaseClient _client;
  final String? redirectUrl;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
    required String countryCode,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: redirectUrl,
      data: {'full_name': fullName.trim(), 'country_code': countryCode},
    );
  }

  Future<void> resendVerificationEmail(String email) {
    return _client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: redirectUrl,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> requestPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectUrl,
    );
  }

  Future<void> updatePassword(String password) {
    return _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _client.auth.currentUser;
    final email = user?.email;
    if (email == null) throw const NotSignedInException();

    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    await updatePassword(newPassword);
  }

  Future<void> requestEmailChange(String email) {
    return _client.auth.updateUser(
      UserAttributes(email: email.trim()),
      emailRedirectTo: redirectUrl,
    );
  }

  Future<String> requestAccountStatus({
    required String status,
    String? reason,
  }) async {
    final data = await _client.rpc(
      'request_account_status',
      params: {'p_status': status, 'p_reason': reason},
    );
    return data['status'] as String;
  }

  Future<void> signOut() => _client.auth.signOut();
}
