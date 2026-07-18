class ShopCloudConfig {
  const ShopCloudConfig._();

  static const String readEnabledEnvKey = 'SHOP_CLOUD_READ_ENABLED';
  static const String purchaseEnabledEnvKey = 'SHOP_CLOUD_PURCHASE_ENABLED';

  static bool get isReadEnabled =>
      const bool.fromEnvironment(readEnabledEnvKey, defaultValue: false);

  static bool get isPurchaseEnabled =>
      const bool.fromEnvironment(purchaseEnabledEnvKey, defaultValue: false);

  static bool resolveReadEnabled({bool? override}) {
    return override ?? isReadEnabled;
  }

  static bool resolvePurchaseEnabled({bool? override}) {
    return override ?? isPurchaseEnabled;
  }
}
