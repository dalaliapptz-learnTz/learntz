import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/config/app_config.dart';
import '../../../core/errors/app_error.dart';

abstract interface class AuthRepository {
  bool get isRemote;

  Future<String> register({
    required String fullName,
    required String email,
    required String password,
  });

  Future<String> signIn({required String email, required String password});

  Future<void> signOut();
}

class LocalAuthRepository implements AuthRepository {
  String? _email;
  String? _password;
  String? _userId;

  @override
  bool get isRemote => false;

  @override
  Future<String> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _validate(email, password);
    _email = email.trim().toLowerCase();
    _password = password;
    _userId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    return _userId!;
  }

  @override
  Future<String> signIn({required String email, required String password}) async {
    _validate(email, password);
    if (_email != email.trim().toLowerCase() || _password != password) {
      throw const AppError('No local demo account matches those details.');
    }
    return _userId!;
  }

  @override
  Future<void> signOut() async {}

  void _validate(String email, String password) {
    if (!email.contains('@')) throw const AppError('Enter a valid email address.');
    if (password.length < 6) throw const AppError('Password must be at least 6 characters.');
  }
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);

  final SupabaseClient client;

  @override
  bool get isRemote => true;

  @override
  Future<String> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
      final userId = response.user?.id;
      if (userId == null) {
        throw const AppError('Registration needs email verification before you can sign in.');
      }
      return userId;
    } on AuthException catch (error) {
      throw AppError(error.message);
    }
  }

  @override
  Future<String> signIn({required String email, required String password}) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final userId = response.user?.id;
      if (userId == null) throw const AppError('Unable to sign in.');
      return userId;
    } on AuthException catch (error) {
      throw AppError(error.message);
    }
  }

  @override
  Future<void> signOut() async {
    await client.auth.signOut();
  }
}

AuthRepository createAuthRepository(AppConfig config) {
  if (config.hasSupabaseConfiguration) {
    return SupabaseAuthRepository(Supabase.instance.client);
  }
  return LocalAuthRepository();
}
