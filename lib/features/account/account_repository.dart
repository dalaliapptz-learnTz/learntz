import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_repository.dart';

class ParentProfile {
  const ParentProfile({
    required this.userId,
    required this.fullName,
    required this.createdAt,
    required this.countryCode,
  });

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    return ParentProfile(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      countryCode: json['country_code'] as String,
    );
  }

  final String userId;
  final String fullName;
  final DateTime createdAt;
  final String countryCode;
}

class AccountRepository {
  const AccountRepository(this._client);

  final SupabaseClient _client;

  Future<ParentProfile> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const NotSignedInException();

    final data = await _client
        .from('profiles')
        .select('id, full_name, created_at')
        .eq('id', user.id)
        .single();
    final account = await _client
        .from('parent_accounts')
        .select('country_code')
        .eq('user_id', user.id)
        .single();
    return ParentProfile.fromJson({
      ...data,
      'user_id': data['id'],
      'country_code': account['country_code'],
    });
  }

  Future<ParentProfile> updateFullName(String fullName) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const NotSignedInException();

    final data = await _client
        .from('profiles')
        .update({'full_name': fullName.trim()})
        .eq('id', user.id)
        .select('id, full_name, created_at')
        .single();
    final account = await _client
        .from('parent_accounts')
        .select('country_code')
        .eq('user_id', user.id)
        .single();
    return ParentProfile.fromJson({
      ...data,
      'user_id': data['id'],
      'country_code': account['country_code'],
    });
  }
}
