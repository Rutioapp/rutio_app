class ShopCloudConfig {
  const ShopCloudConfig._();

  static const String readEnabledEnvKey = 'SHOP_CLOUD_READ_ENABLED';

  static bool get isReadEnabled =>
      const bool.fromEnvironment(readEnabledEnvKey, defaultValue: false);

  static bool resolveReadEnabled({bool? override}) {
    return override ?? isReadEnabled;
  }
}
