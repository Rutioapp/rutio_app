import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'rutio_supabase_config.dart';

class RutioSupabaseClient {
  const RutioSupabaseClient._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<bool> initialize({bool requireConfig = true}) async {
    if (_initialized) return true;

    if (_hasExistingSupabaseInstance()) {
      _initialized = true;
      if (kDebugMode) {
        debugPrint('[supabase] already initialized; reusing existing instance');
      }
      return true;
    }

    if (!RutioSupabaseConfig.hasValidConfig) {
      final message = RutioSupabaseConfig.missingConfigMessage.trim();
      if (kDebugMode) {
        debugPrint('[supabase] $message');
      }
      if (requireConfig) {
        throw StateError(message);
      }
      return false;
    }

    await Supabase.initialize(
      url: RutioSupabaseConfig.supabaseUrl,
      anonKey: RutioSupabaseConfig.supabaseAnonKey,
    );

    _initialized = true;

    if (kDebugMode) {
      debugPrint(
        '[supabase] initialized for ${RutioSupabaseConfig.supabaseUrl}',
      );
    }

    return true;
  }

  static Future<bool> initializeIfConfigured() =>
      initialize(requireConfig: false);

  static SupabaseClient get instance {
    if (!_initialized && !_hasExistingSupabaseInstance()) {
      throw StateError('Supabase client requested before initialization.');
    }

    _initialized = true;
    return Supabase.instance.client;
  }

  static bool _hasExistingSupabaseInstance() {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }
}
