class MysteryBoxCloudConfig {
  const MysteryBoxCloudConfig._();

  static const String enabledEnvKey = 'CLOUD_MYSTERY_BOX_ENABLED';

  static bool get isEnabled =>
      const bool.fromEnvironment(enabledEnvKey, defaultValue: false);

  static bool resolveEnabled({bool? override}) {
    return override ?? isEnabled;
  }
}
