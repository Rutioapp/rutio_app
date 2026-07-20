class CloudCosmeticsConfig {
  const CloudCosmeticsConfig._();

  static const String enabledEnvKey = 'CLOUD_COSMETICS_ENABLED';

  static bool get isEnabled =>
      const bool.fromEnvironment(enabledEnvKey, defaultValue: false);

  static bool resolveEnabled({bool? override}) {
    return override ?? isEnabled;
  }
}
