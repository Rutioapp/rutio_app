import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/premium/data/revenuecat/revenuecat_configuration.dart';

void main() {
  test('debug test_store uses the Test Store key', () {
    final configuration = RevenueCatConfiguration.fromEnvironment(
      environmentApiKey: 'test_debug_key',
      billingTarget: RevenueCatConfiguration.testStoreBillingTarget,
      isRelease: false,
    );

    expect(configuration.testApiKey, 'test_debug_key');
    expect(configuration.billingTarget,
        RevenueCatConfiguration.testStoreBillingTarget);
  });

  test('debug test_store rejects the staging placeholder', () {
    expect(
      () => RevenueCatConfiguration.fromEnvironment(
        environmentApiKey: 'PASTE_REVENUECAT_TEST_KEY_HERE',
        billingTarget: RevenueCatConfiguration.testStoreBillingTarget,
        isRelease: false,
      ),
      throwsA(isA<RevenueCatConfigurationException>()),
    );
  });

  test('debug google_play_sandbox uses the Android public key', () {
    final configuration = RevenueCatConfiguration.fromEnvironment(
      androidSandboxApiKey: 'goog_android_sandbox_key',
      billingTarget: RevenueCatConfiguration.googlePlaySandboxBillingTarget,
      isRelease: false,
      platform: TargetPlatform.android,
    );

    expect(configuration.testApiKey, 'goog_android_sandbox_key');
    expect(configuration.billingTarget,
        RevenueCatConfiguration.googlePlaySandboxBillingTarget);
  });

  test('debug google_play_sandbox rejects a Test Store key', () {
    expect(
      () => RevenueCatConfiguration.fromEnvironment(
        androidSandboxApiKey: 'test_accidental_key',
        billingTarget: RevenueCatConfiguration.googlePlaySandboxBillingTarget,
        isRelease: false,
        platform: TargetPlatform.android,
      ),
      throwsA(isA<RevenueCatConfigurationException>()),
    );
  });

  test('debug google_play_sandbox rejects a missing key', () {
    expect(
      () => RevenueCatConfiguration.fromEnvironment(
        billingTarget: RevenueCatConfiguration.googlePlaySandboxBillingTarget,
        isRelease: false,
        platform: TargetPlatform.android,
      ),
      throwsA(isA<RevenueCatConfigurationException>()),
    );
  });

  test('debug google_play_sandbox rejects non-Android platforms', () {
    expect(
      () => RevenueCatConfiguration.fromEnvironment(
        androidSandboxApiKey: 'goog_android_sandbox_key',
        billingTarget: RevenueCatConfiguration.googlePlaySandboxBillingTarget,
        isRelease: false,
        platform: TargetPlatform.iOS,
      ),
      throwsA(isA<RevenueCatConfigurationException>()),
    );
  });

  test('release rejects non-production billing targets', () {
    for (final target in [
      RevenueCatConfiguration.testStoreBillingTarget,
      RevenueCatConfiguration.googlePlaySandboxBillingTarget,
    ]) {
      expect(
        () => RevenueCatConfiguration.fromEnvironment(
          androidApiKey: 'goog_production_key',
          billingTarget: target,
          isRelease: true,
          platform: TargetPlatform.android,
        ),
        throwsA(isA<RevenueCatConfigurationException>()),
      );
    }
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

  test('configuration errors do not include API key values', () {
    const key = 'test_secret_value_that_must_not_be_logged';
    try {
      RevenueCatConfiguration.fromEnvironment(
        environmentApiKey: key,
        billingTarget: RevenueCatConfiguration.googlePlaySandboxBillingTarget,
        isRelease: false,
        platform: TargetPlatform.android,
      );
      fail('expected configuration failure');
    } on RevenueCatConfigurationException catch (error) {
      expect(error.message, isNot(contains(key)));
    }
  });
}
