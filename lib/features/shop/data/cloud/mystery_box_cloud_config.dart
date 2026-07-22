import 'shop_cloud_runtime_config.dart';

class MysteryBoxCloudConfig {
  const MysteryBoxCloudConfig._();

  static const String enabledEnvKey = cloudMysteryBoxEnabledEnvKey;

  static bool get isEnabled =>
      ShopCloudRuntimeConfig.compiled().cloudMysteryBoxEnabled;

  static bool resolveEnabled({bool? override}) {
    return override ?? isEnabled;
  }
}
