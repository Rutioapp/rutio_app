import 'shop_cloud_runtime_config.dart';

class UtilityConsumptionConfig {
  const UtilityConsumptionConfig._();

  static const String enabledEnvKey = cloudUtilityConsumptionEnabledEnvKey;

  static bool get isEnabled =>
      ShopCloudRuntimeConfig.compiled().cloudUtilityConsumptionEnabled;

  static bool resolveEnabled({bool? override}) {
    return override ?? isEnabled;
  }
}
