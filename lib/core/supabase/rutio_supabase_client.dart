import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'rutio_supabase_config.dart';

class RutioSupabaseClient {
  const RutioSupabaseClient._();

  static bool _initialized = false;

  static Future<void> initializeIfConfigured() async {
    if (_initialized || !RutioSupabaseConfig.isConfigured) return;

    await Supabase.initialize(
      url: RutioSupabaseConfig.supabaseUrl,
      anonKey: RutioSupabaseConfig.supabasePublishableKey,
    );

    _initialized = true;
    if (kDebugMode) {
      debugPrint(
        '[supabase] initialized for ${RutioSupabaseConfig.supabaseUrl}',
      );
    }
  }
}
