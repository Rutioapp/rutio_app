import 'shop_cloud_runtime_config.dart';

class CloudCosmeticsConfig {
  const CloudCosmeticsConfig._();

  static const String enabledEnvKey = cloudCosmeticsEnabledEnvKey;

  static bool get isEnabled =>
      ShopCloudRuntimeConfig.compiled().cloudCosmeticsEnabled;

  static bool resolveEnabled({bool? override}) {
    return override ?? isEnabled;
  }
}
