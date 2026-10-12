import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/premium/data/revenuecat/revenuecat_configuration.dart';

void main() {
  test('uses the debug Test Store key from dart-define', () {
    final configuration = RevenueCatConfiguration.fromEnvironment(
      environmentApiKey: 'test_debug_key',
      isRelease: false,
    );

    expect(configuration.testApiKey, 'test_debug_key');
  });

  test('accepts an Android production key in release', () {
    const override = 'goog_production_key';
    final configuration = RevenueCatConfiguration.fromEnvironment(
      androidApiKey: override,
      isRelease: true,
      platform: TargetPlatform.android,
    );

    expect(configuration.testApiKey, override);
    expect(configuration.isConfigured, isTrue);
  });

  test('accepts an iOS production key in release', () {
    final configuration = RevenueCatConfiguration.fromEnvironment(
      iosApiKey: 'appl_production_key',
      isRelease: true,
      platform: TargetPlatform.iOS,
    );

    expect(configuration.testApiKey, 'appl_production_key');
  });

  test('rejects a Test Store key in Android release', () {
    expect(
      () => RevenueCatConfiguration.fromEnvironment(
        androidApiKey: 'test_accidental_key',
        isRelease: true,
        platform: TargetPlatform.android,
      ),
      throwsA(isA<RevenueCatConfigurationException>()),
    );
  });

  test('rejects a Test Store key in iOS release', () {
    expect(
      () => RevenueCatConfiguration.fromEnvironment(
        iosApiKey: 'test_accidental_key',
        isRelease: true,
        platform: TargetPlatform.iOS,
      ),
      throwsA(isA<RevenueCatConfigurationException>()),
    );
  });

  test('rejects a missing release key', () {
    expect(
      () => RevenueCatConfiguration.fromEnvironment(
        isRelease: true,
        platform: TargetPlatform.android,
      ),
      throwsA(isA<RevenueCatConfigurationException>()),
    );
  });

  test('rejects a key for the wrong platform', () {
    expect(
      () => RevenueCatConfiguration.fromEnvironment(
        androidApiKey: 'appl_wrong_platform_key',
        isRelease: true,
        platform: TargetPlatform.android,
      ),
      throwsA(isA<RevenueCatConfigurationException>()),
    );
  });

  test('treats the placeholder as missing configuration', () {
    const configuration = RevenueCatConfiguration(
      testApiKey: 'PASTE_REVENUECAT_TEST_KEY_HERE',
    );

    expect(configuration.isConfigured, isFalse);
  });
}
