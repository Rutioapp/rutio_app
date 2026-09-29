import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/premium/data/revenuecat/revenuecat_configuration.dart';

void main() {
  test('falls back to the centralized Test Store key', () {
    final configuration = RevenueCatConfiguration.fromEnvironment(
      environmentApiKey: '',
    );

    expect(
      configuration.testApiKey,
      RevenueCatConfiguration.revenueCatTestApiKey,
    );
  });

  test('uses a non-empty dart-define override', () {
    const override = 'test_store_override_key';
    final configuration = RevenueCatConfiguration.fromEnvironment(
      environmentApiKey: override,
    );

    expect(configuration.testApiKey, override);
    expect(configuration.isConfigured, isTrue);
  });

  test('treats the placeholder as missing configuration', () {
    const configuration = RevenueCatConfiguration(
      testApiKey: 'PASTE_REVENUECAT_TEST_KEY_HERE',
    );

    expect(configuration.isConfigured, isFalse);
  });
}
