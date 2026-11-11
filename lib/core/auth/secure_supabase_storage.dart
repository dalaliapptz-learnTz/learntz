import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureSupabaseStorage extends LocalStorage implements GotrueAsyncStorage {
  SecureSupabaseStorage({
    required String supabaseUrl,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _keyPrefix = 'learntz.supabase.${Uri.parse(supabaseUrl).host}.';

  final FlutterSecureStorage _storage;
  final String _keyPrefix;

  String get _sessionKey => '${_keyPrefix}session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);

  @override
  Future<String?> getItem({required String key}) =>
      _storage.read(key: '${_keyPrefix}pkce.$key');

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: '${_keyPrefix}pkce.$key', value: value);

  @override
  Future<void> removeItem({required String key}) =>
      _storage.delete(key: '${_keyPrefix}pkce.$key');
}
