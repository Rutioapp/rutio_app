import 'shop_cloud_runtime_config.dart';

class ShopCloudConfig {
  const ShopCloudConfig._();

  static const String readEnabledEnvKey = shopCloudReadEnabledEnvKey;
  static const String purchaseEnabledEnvKey = shopCloudPurchaseEnabledEnvKey;

  static bool get isReadEnabled =>
      ShopCloudRuntimeConfig.compiled().shopReadEnabled;

  static bool get isPurchaseEnabled =>
      ShopCloudRuntimeConfig.compiled().shopPurchaseEnabled;

  static bool resolveReadEnabled({bool? override}) {
    return override ?? isReadEnabled;
  }

  static bool resolvePurchaseEnabled({bool? override}) {
    return override ?? isPurchaseEnabled;
  }
}
