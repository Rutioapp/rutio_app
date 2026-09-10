class RutioSupabaseConfig {
  const RutioSupabaseConfig._();

  /// Canonical contract only. Native/web configuration is AUTH-4C.
  static const String authCallbackUri =
      'https://www.rutioapp.com/auth/callback';

  static const String supabaseUrlEnv = 'SUPABASE_URL';
  static const String supabaseAnonKeyEnv = 'SUPABASE_ANON_KEY';
  static const String googleWebClientIdEnv = 'GOOGLE_WEB_CLIENT_ID';
  static const String googleIosClientIdEnv = 'GOOGLE_IOS_CLIENT_ID';

  static const String supabaseUrl = String.fromEnvironment(supabaseUrlEnv);
  static const String supabaseAnonKey =
      String.fromEnvironment(supabaseAnonKeyEnv);
  static const String googleWebClientId =
      String.fromEnvironment(googleWebClientIdEnv);
  static const String googleIosClientId =
      String.fromEnvironment(googleIosClientIdEnv);

  static String? get googleWebClientIdOrNull =>
      googleWebClientId.trim().isEmpty ? null : googleWebClientId.trim();

  static String? get googleIosClientIdOrNull =>
      googleIosClientId.trim().isEmpty ? null : googleIosClientId.trim();

  static bool get hasValidConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static bool get isConfigured => hasValidConfig;

  static List<String> get missingVariables {
    final missing = <String>[];

    if (supabaseUrl.trim().isEmpty) {
      missing.add(supabaseUrlEnv);
    }
    if (supabaseAnonKey.trim().isEmpty) {
      missing.add(supabaseAnonKeyEnv);
    }

    return missing;
  }

  static String get missingConfigMessage {
    final missing = missingVariables;
    final missingList = missing.map((name) => '- $name').join('\n');

    return '''
Supabase configuration is missing.

Provide these --dart-define values:
$missingList

Example:
flutter run --dart-define=SUPABASE_URL=https://xxxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxxxx
''';
  }
}
