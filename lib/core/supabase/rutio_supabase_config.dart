class RutioSupabaseConfig {
  const RutioSupabaseConfig._();

  static const String supabaseUrlEnv = 'SUPABASE_URL';
  static const String supabaseAnonKeyEnv = 'SUPABASE_ANON_KEY';

  static const String supabaseUrl = String.fromEnvironment(supabaseUrlEnv);
  static const String supabaseAnonKey =
      String.fromEnvironment(supabaseAnonKeyEnv);

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
