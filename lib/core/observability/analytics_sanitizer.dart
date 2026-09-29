abstract final class AnalyticsPropertySanitizer {
  static const Set<String> allowedKeys = <String>{
    'app_version',
    'build_number',
    'platform',
    'premium_status',
    'onboarding_completed',
    'locale',
    'method',
    'step',
    'habit_type',
    'target_period',
    'entry_type',
    'period',
    'premium_feature',
    'upgrade_source',
    'plan',
    'purchase_result',
    'prepared_habit',
  };

  static const Set<String> deniedFragments = <String>{
    'email',
    'token',
    'session',
    'password',
    'journal_text',
    'habit_name',
    'notes',
    'content',
  };

  static Map<String, Object> sanitize(Map<String, Object?> input) {
    final result = <String, Object>{};
    for (final entry in input.entries) {
      final key = entry.key.trim().toLowerCase();
      if (!_isAllowedKey(key) || _isDeniedKey(key)) continue;
      final value = entry.value;
      if (value is String) {
        if (value.isEmpty || value.length > 64) continue;
        result[key] = value;
      } else if (value is bool || value is int || value is double) {
        result[key] = value as Object;
      }
    }
    return result;
  }

  static bool _isAllowedKey(String key) => allowedKeys.contains(key);

  static bool _isDeniedKey(String key) =>
      deniedFragments.any((fragment) => key.contains(fragment));
}
