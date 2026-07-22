const String shopCloudReadEnabledEnvKey = 'SHOP_CLOUD_READ_ENABLED';
const String shopCloudPurchaseEnabledEnvKey = 'SHOP_CLOUD_PURCHASE_ENABLED';
const String cloudCosmeticsEnabledEnvKey = 'CLOUD_COSMETICS_ENABLED';
const String cloudUtilityConsumptionEnabledEnvKey =
    'CLOUD_UTILITY_CONSUMPTION_ENABLED';
const String cloudMysteryBoxEnabledEnvKey = 'CLOUD_MYSTERY_BOX_ENABLED';

class ShopCloudRuntimeConfig {
  const ShopCloudRuntimeConfig({
    required this.shopReadEnabled,
    required this.shopPurchaseEnabled,
    required this.cloudCosmeticsEnabled,
    required this.cloudUtilityConsumptionEnabled,
    required this.cloudMysteryBoxEnabled,
  });

  factory ShopCloudRuntimeConfig.compiled() {
    return ShopCloudRuntimeConfig(
      shopReadEnabled: const bool.fromEnvironment(
        shopCloudReadEnabledEnvKey,
        defaultValue: false,
      ),
      shopPurchaseEnabled: const bool.fromEnvironment(
        shopCloudPurchaseEnabledEnvKey,
        defaultValue: false,
      ),
      cloudCosmeticsEnabled: const bool.fromEnvironment(
        cloudCosmeticsEnabledEnvKey,
        defaultValue: false,
      ),
      cloudUtilityConsumptionEnabled: const bool.fromEnvironment(
        cloudUtilityConsumptionEnabledEnvKey,
        defaultValue: false,
      ),
      cloudMysteryBoxEnabled: const bool.fromEnvironment(
        cloudMysteryBoxEnabledEnvKey,
        defaultValue: false,
      ),
    );
  }

  final bool shopReadEnabled;
  final bool shopPurchaseEnabled;
  final bool cloudCosmeticsEnabled;
  final bool cloudUtilityConsumptionEnabled;
  final bool cloudMysteryBoxEnabled;

  bool get isFullyCloud =>
      shopReadEnabled &&
      shopPurchaseEnabled &&
      cloudCosmeticsEnabled &&
      cloudUtilityConsumptionEnabled &&
      cloudMysteryBoxEnabled;

  bool get isFullyLegacy =>
      !shopReadEnabled &&
      !shopPurchaseEnabled &&
      !cloudCosmeticsEnabled &&
      !cloudUtilityConsumptionEnabled &&
      !cloudMysteryBoxEnabled;

  bool get isMixed => !isFullyCloud && !isFullyLegacy;

  Map<String, bool> get flags => <String, bool>{
        shopCloudReadEnabledEnvKey: shopReadEnabled,
        shopCloudPurchaseEnabledEnvKey: shopPurchaseEnabled,
        cloudCosmeticsEnabledEnvKey: cloudCosmeticsEnabled,
        cloudUtilityConsumptionEnabledEnvKey: cloudUtilityConsumptionEnabled,
        cloudMysteryBoxEnabledEnvKey: cloudMysteryBoxEnabled,
      };

  void validateForStartup({
    required bool isRelease,
  }) {
    if (isMixed) {
      throw StateError(
        'Invalid shop cloud startup configuration: mixed mode is not allowed. '
        'Flags: ${_describeFlags()}',
      );
    }

    if (isFullyLegacy && isRelease) {
      throw StateError(
        'Invalid shop cloud startup configuration: fully legacy mode is not '
        'allowed in release. Flags: ${_describeFlags()}',
      );
    }
  }

  String _describeFlags() {
    return flags.entries.map((entry) {
      return '${entry.key}=${entry.value}';
    }).join(', ');
  }
}
