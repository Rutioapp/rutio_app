class UtilityConsumptionConfig {
  const UtilityConsumptionConfig._();

  static const String enabledEnvKey = 'CLOUD_UTILITY_CONSUMPTION_ENABLED';

  static bool get isEnabled =>
      const bool.fromEnvironment(enabledEnvKey, defaultValue: false);

  static bool resolveEnabled({bool? override}) {
    return override ?? isEnabled;
  }
}
