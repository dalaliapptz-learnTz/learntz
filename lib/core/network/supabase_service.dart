import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/config/app_config.dart';

class SupabaseService {
  const SupabaseService(this.config);

  final AppConfig config;

  bool get isConfigured => config.hasSupabaseConfiguration;

  Future<void> initialize() async {
    if (!isConfigured) return;

    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
    );
  }
}
