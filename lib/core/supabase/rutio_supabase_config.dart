import 'package:flutter/foundation.dart';

class RutioSupabaseConfig {
  const RutioSupabaseConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty && supabasePublishableKey.trim().isNotEmpty;

  static void validate() {
    if (isConfigured) return;

    const message = '''
Supabase configuration is missing.

Provide these --dart-define values:
- SUPABASE_URL
- SUPABASE_PUBLISHABLE_KEY

Example:
flutter run --dart-define=SUPABASE_URL=https://xxxxx.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxxx
''';

    if (kDebugMode) {
      throw FlutterError(message);
    }

    throw StateError('Supabase configuration is missing.');
  }
}
