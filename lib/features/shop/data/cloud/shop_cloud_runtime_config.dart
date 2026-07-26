const String shopCloudReadEnabledEnvKey = 'SHOP_CLOUD_READ_ENABLED';
const String shopCloudPurchaseEnabledEnvKey = 'SHOP_CLOUD_PURCHASE_ENABLED';
const String cloudCosmeticsEnabledEnvKey = 'CLOUD_COSMETICS_ENABLED';
const String cloudUtilityConsumptionEnabledEnvKey =
    'CLOUD_UTILITY_CONSUMPTION_ENABLED';
const String cloudMysteryBoxEnabledEnvKey = 'CLOUD_MYSTERY_BOX_ENABLED';
const String rutioProfileEnvKey = 'RUTIO_PROFILE';
const String rutioScreenshotModeEnvKey = 'RUTIO_SCREENSHOT_MODE';

enum ShopRuntimeMode {
  cloud,
  localDemo,
}

class ShopCloudRuntimeConfig {
  const ShopCloudRuntimeConfig({
    required this.shopReadEnabled,
    required this.shopPurchaseEnabled,
    required this.cloudCosmeticsEnabled,
    required this.cloudUtilityConsumptionEnabled,
    required this.cloudMysteryBoxEnabled,
    ShopRuntimeMode? runtimeMode,
  }) : _runtimeMode = runtimeMode;

  factory ShopCloudRuntimeConfig.compiled({
    bool isRelease = const bool.fromEnvironment('dart.vm.product'),
  }) {
    return ShopCloudRuntimeConfig.resolve(
      isRelease: isRelease,
      profileValue: const String.fromEnvironment(rutioProfileEnvKey),
      screenshotModeValue:
          const String.fromEnvironment(rutioScreenshotModeEnvKey),
    );
  }

  factory ShopCloudRuntimeConfig.resolve({
    required bool isRelease,
    String? profileValue,
    String? screenshotModeValue,
  }) {
    final explicitLocalMode = !isRelease &&
        (_isDemoProfile(profileValue) || _isTruthy(screenshotModeValue));
    if (explicitLocalMode) {
      return const ShopCloudRuntimeConfig(
        shopReadEnabled: false,
        shopPurchaseEnabled: false,
        cloudCosmeticsEnabled: false,
        cloudUtilityConsumptionEnabled: false,
        cloudMysteryBoxEnabled: false,
        runtimeMode: ShopRuntimeMode.localDemo,
      );
    }

    return const ShopCloudRuntimeConfig(
      shopReadEnabled: true,
      shopPurchaseEnabled: true,
      cloudCosmeticsEnabled: true,
      cloudUtilityConsumptionEnabled: true,
      cloudMysteryBoxEnabled: true,
      runtimeMode: ShopRuntimeMode.cloud,
    );
  }

  final bool shopReadEnabled;
  final bool shopPurchaseEnabled;
  final bool cloudCosmeticsEnabled;
  final bool cloudUtilityConsumptionEnabled;
  final bool cloudMysteryBoxEnabled;
  final ShopRuntimeMode? _runtimeMode;

  ShopRuntimeMode get runtimeMode {
    final configuredMode = _runtimeMode;
    if (configuredMode != null) return configuredMode;
    return isFullyLegacy ? ShopRuntimeMode.localDemo : ShopRuntimeMode.cloud;
  }

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
    if (runtimeMode == ShopRuntimeMode.localDemo && isRelease) {
      throw StateError(
        'Invalid shop cloud startup configuration: local/demo mode is not '
        'allowed in release. Flags: ${_describeFlags()}',
      );
    }

    if (isMixed) {
      throw StateError(
        'Invalid shop cloud startup configuration: mixed mode is not allowed. '
        'Flags: ${_describeFlags()}',
      );
    }

    if (runtimeMode == ShopRuntimeMode.cloud && !isFullyCloud) {
      throw StateError(
        'Invalid shop cloud startup configuration: cloud mode requires every '
        'shop cloud route. Flags: ${_describeFlags()}',
      );
    }
  }

  String _describeFlags() {
    return flags.entries.map((entry) {
      return '${entry.key}=${entry.value}';
    }).join(', ');
  }

  static bool _isDemoProfile(String? value) {
    return (value ?? '').trim().toLowerCase() == 'demo';
  }

  static bool _isTruthy(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'on':
        return true;
      default:
        return false;
    }
  }
}
