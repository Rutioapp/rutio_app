class GlobalCloudWalletConfig {
  const GlobalCloudWalletConfig._();

  static const String enabledEnvKey = 'GLOBAL_CLOUD_WALLET_ENABLED';

  static bool get isEnabled =>
      const bool.fromEnvironment(enabledEnvKey, defaultValue: false);

  static bool resolveEnabled({bool? override}) {
    return override ?? isEnabled;
  }
}
