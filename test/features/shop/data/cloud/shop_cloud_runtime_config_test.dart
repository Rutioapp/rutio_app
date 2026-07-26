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
      expect(config.runtimeMode, ShopRuntimeMode.cloud);
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
      expect(config.runtimeMode, ShopRuntimeMode.localDemo);
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

    test('release resolves to cloud even without legacy flags', () {
      final config = ShopCloudRuntimeConfig.resolve(
        isRelease: true,
        profileValue: '',
        screenshotModeValue: '',
      );

      expect(config.runtimeMode, ShopRuntimeMode.cloud);
      expect(config.isFullyCloud, isTrue);
      expect(() => config.validateForStartup(isRelease: true), returnsNormally);
    });

    test('release ignores explicit local profiles and stays cloud', () {
      final demoConfig = ShopCloudRuntimeConfig.resolve(
        isRelease: true,
        profileValue: 'demo',
        screenshotModeValue: '',
      );
      final screenshotConfig = ShopCloudRuntimeConfig.resolve(
        isRelease: true,
        profileValue: '',
        screenshotModeValue: 'true',
      );

      expect(demoConfig.runtimeMode, ShopRuntimeMode.cloud);
      expect(demoConfig.isFullyCloud, isTrue);
      expect(screenshotConfig.runtimeMode, ShopRuntimeMode.cloud);
      expect(screenshotConfig.isFullyCloud, isTrue);
    });

    test('debug normal resolves to cloud by default', () {
      final config = ShopCloudRuntimeConfig.resolve(
        isRelease: false,
        profileValue: '',
        screenshotModeValue: '',
      );

      expect(config.runtimeMode, ShopRuntimeMode.cloud);
      expect(config.isFullyCloud, isTrue);
      expect(
          () => config.validateForStartup(isRelease: false), returnsNormally);
    });

    test('debug demo profile resolves to explicit local demo mode', () {
      final config = ShopCloudRuntimeConfig.resolve(
        isRelease: false,
        profileValue: 'demo',
        screenshotModeValue: '',
      );

      expect(config.runtimeMode, ShopRuntimeMode.localDemo);
      expect(config.isFullyLegacy, isTrue);
      expect(
          () => config.validateForStartup(isRelease: false), returnsNormally);
    });

    test('debug screenshot mode resolves to explicit local demo mode', () {
      final config = ShopCloudRuntimeConfig.resolve(
        isRelease: false,
        profileValue: '',
        screenshotModeValue: 'true',
      );

      expect(config.runtimeMode, ShopRuntimeMode.localDemo);
      expect(config.isFullyLegacy, isTrue);
      expect(
          () => config.validateForStartup(isRelease: false), returnsNormally);
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

    test('fully legacy is valid in debug as explicit local demo mode', () {
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
        runtimeMode: ShopRuntimeMode.localDemo,
      );

      expect(
        () => config.validateForStartup(isRelease: true),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('local/demo mode is not allowed in release'),
          ),
        ),
      );
    });

    test('cloud mode without every cloud route fails closed', () {
      const config = ShopCloudRuntimeConfig(
        shopReadEnabled: false,
        shopPurchaseEnabled: false,
        cloudCosmeticsEnabled: false,
        cloudUtilityConsumptionEnabled: false,
        cloudMysteryBoxEnabled: false,
        runtimeMode: ShopRuntimeMode.cloud,
      );

      expect(
        () => config.validateForStartup(isRelease: false),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('cloud mode requires every shop cloud route'),
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
