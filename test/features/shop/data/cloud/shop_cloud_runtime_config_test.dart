import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_config.dart';
import 'package:rutio/features/shop/data/cloud/mystery_box_cloud_config.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_config.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_runtime_config.dart';
import 'package:rutio/features/shop/data/cloud/utility_consumption_config.dart';

void main() {
  group('ShopCloudRuntimeConfig', () {
    test('five enabled flags yield fully cloud', () {
      const config = ShopCloudRuntimeConfig(
        shopReadEnabled: true,
        shopPurchaseEnabled: true,
        cloudCosmeticsEnabled: true,
        cloudUtilityConsumptionEnabled: true,
        cloudMysteryBoxEnabled: true,
      );

      expect(config.isFullyCloud, isTrue);
      expect(config.isFullyLegacy, isFalse);
      expect(config.isMixed, isFalse);
    });

    test('five disabled flags yield fully legacy', () {
      const config = ShopCloudRuntimeConfig(
        shopReadEnabled: false,
        shopPurchaseEnabled: false,
        cloudCosmeticsEnabled: false,
        cloudUtilityConsumptionEnabled: false,
        cloudMysteryBoxEnabled: false,
      );

      expect(config.isFullyCloud, isFalse);
      expect(config.isFullyLegacy, isTrue);
      expect(config.isMixed, isFalse);
    });

    test('any partial combination yields mixed', () {
      const config = ShopCloudRuntimeConfig(
        shopReadEnabled: true,
        shopPurchaseEnabled: false,
        cloudCosmeticsEnabled: true,
        cloudUtilityConsumptionEnabled: false,
        cloudMysteryBoxEnabled: true,
      );

      expect(config.isFullyCloud, isFalse);
      expect(config.isFullyLegacy, isFalse);
      expect(config.isMixed, isTrue);
    });

    test('fully cloud is valid in release and debug', () {
      const config = ShopCloudRuntimeConfig(
        shopReadEnabled: true,
        shopPurchaseEnabled: true,
        cloudCosmeticsEnabled: true,
        cloudUtilityConsumptionEnabled: true,
        cloudMysteryBoxEnabled: true,
      );

      expect(
          () => config.validateForStartup(isRelease: false), returnsNormally);
      expect(() => config.validateForStartup(isRelease: true), returnsNormally);
    });

    test('fully legacy is valid in debug', () {
      const config = ShopCloudRuntimeConfig(
        shopReadEnabled: false,
        shopPurchaseEnabled: false,
        cloudCosmeticsEnabled: false,
        cloudUtilityConsumptionEnabled: false,
        cloudMysteryBoxEnabled: false,
      );

      expect(
          () => config.validateForStartup(isRelease: false), returnsNormally);
    });

    test('fully legacy is rejected in release', () {
      const config = ShopCloudRuntimeConfig(
        shopReadEnabled: false,
        shopPurchaseEnabled: false,
        cloudCosmeticsEnabled: false,
        cloudUtilityConsumptionEnabled: false,
        cloudMysteryBoxEnabled: false,
      );

      expect(
        () => config.validateForStartup(isRelease: true),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('fully legacy mode is not allowed in release'),
          ),
        ),
      );
    });

    test('mixed mode is rejected in debug', () {
      const config = ShopCloudRuntimeConfig(
        shopReadEnabled: true,
        shopPurchaseEnabled: false,
        cloudCosmeticsEnabled: true,
        cloudUtilityConsumptionEnabled: false,
        cloudMysteryBoxEnabled: true,
      );

      expect(
        () => config.validateForStartup(isRelease: false),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('mixed mode is not allowed'),
              contains('SHOP_CLOUD_READ_ENABLED=true'),
              contains('SHOP_CLOUD_PURCHASE_ENABLED=false'),
              contains('CLOUD_COSMETICS_ENABLED=true'),
              contains('CLOUD_UTILITY_CONSUMPTION_ENABLED=false'),
              contains('CLOUD_MYSTERY_BOX_ENABLED=true'),
            ),
          ),
        ),
      );
    });

    test('mixed mode is rejected in release', () {
      const config = ShopCloudRuntimeConfig(
        shopReadEnabled: true,
        shopPurchaseEnabled: false,
        cloudCosmeticsEnabled: true,
        cloudUtilityConsumptionEnabled: false,
        cloudMysteryBoxEnabled: true,
      );

      expect(
        () => config.validateForStartup(isRelease: true),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('mixed mode is not allowed'),
          ),
        ),
      );
    });

    test('flags map exposes the five shop flags', () {
      const config = ShopCloudRuntimeConfig(
        shopReadEnabled: true,
        shopPurchaseEnabled: false,
        cloudCosmeticsEnabled: true,
        cloudUtilityConsumptionEnabled: false,
        cloudMysteryBoxEnabled: true,
      );

      expect(config.flags, <String, bool>{
        shopCloudReadEnabledEnvKey: true,
        shopCloudPurchaseEnabledEnvKey: false,
        cloudCosmeticsEnabledEnvKey: true,
        cloudUtilityConsumptionEnabledEnvKey: false,
        cloudMysteryBoxEnabledEnvKey: true,
      });
    });
  });

  group('Shop cloud config adapters', () {
    test('resolve methods still honor explicit overrides', () {
      expect(ShopCloudConfig.resolveReadEnabled(override: true), isTrue);
      expect(ShopCloudConfig.resolvePurchaseEnabled(override: false), isFalse);
      expect(CloudCosmeticsConfig.resolveEnabled(override: true), isTrue);
      expect(UtilityConsumptionConfig.resolveEnabled(override: false), isFalse);
      expect(MysteryBoxCloudConfig.resolveEnabled(override: true), isTrue);
    });
  });
}
