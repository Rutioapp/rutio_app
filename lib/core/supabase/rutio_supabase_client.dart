import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'rutio_supabase_config.dart';

class RutioSupabaseClient {
  const RutioSupabaseClient._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    RutioSupabaseConfig.validate();

    await Supabase.initialize(
      url: RutioSupabaseConfig.supabaseUrl,
      anonKey: RutioSupabaseConfig.supabasePublishableKey,
    );

    _initialized = true;
    if (kDebugMode) {
      debugPrint(
        '[supabase] initialized successfully for ${RutioSupabaseConfig.supabaseUrl}',
      );
    }
  }

  static SupabaseClient get instance => Supabase.instance.client;
}
