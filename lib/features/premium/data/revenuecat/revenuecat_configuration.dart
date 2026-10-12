import 'package:flutter/foundation.dart';

class RevenueCatConfigurationException implements Exception {
  const RevenueCatConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'RevenueCatConfigurationException: $message';
}

class RevenueCatConfiguration {
  // Retained for the existing PremiumRepository API; its value is selected
  // from the appropriate environment-specific dart-define.
  const RevenueCatConfiguration({required this.testApiKey});

  static const testApiKeyEnvironmentKey = 'REVENUECAT_TEST_API_KEY';
  static const androidApiKeyEnvironmentKey = 'REVENUECAT_ANDROID_API_KEY';
  static const iosApiKeyEnvironmentKey = 'REVENUECAT_IOS_API_KEY';

  static const _placeholderApiKey = 'PASTE_REVENUECAT_TEST_KEY_HERE';

  factory RevenueCatConfiguration.fromEnvironment({
    String? environmentApiKey,
    String? androidApiKey,
    String? iosApiKey,
    bool? isRelease,
    TargetPlatform? platform,
  }) {
    final release = isRelease ?? kReleaseMode;
    final targetPlatform = platform ?? defaultTargetPlatform;

    if (!release) {
      final key = (environmentApiKey ??
              const String.fromEnvironment(testApiKeyEnvironmentKey))
          .trim();
      _validateDebugKey(key);
      return RevenueCatConfiguration(testApiKey: key);
    }

    final key = switch (targetPlatform) {
      TargetPlatform.android => (androidApiKey ??
              const String.fromEnvironment(androidApiKeyEnvironmentKey))
          .trim(),
      TargetPlatform.iOS =>
        (iosApiKey ?? const String.fromEnvironment(iosApiKeyEnvironmentKey))
            .trim(),
      _ => throw const RevenueCatConfigurationException(
          'RevenueCat production configuration is only supported for Android '
          'and iOS release builds.',
        ),
    };

    if (key.isEmpty) {
      throw RevenueCatConfigurationException(
        'Missing RevenueCat production API key for ${targetPlatform.name} '
        'release build. Configure the platform-specific dart-define.',
      );
    }
    if (key.startsWith('test_')) {
      throw RevenueCatConfigurationException(
        'A RevenueCat Test Store key cannot be used in a release build. '
        'Configure the public production key for ${targetPlatform.name}.',
      );
    }

    final expectedPrefix =
        targetPlatform == TargetPlatform.android ? 'goog_' : 'appl_';
    if (!key.startsWith(expectedPrefix)) {
      throw RevenueCatConfigurationException(
        'Invalid RevenueCat API key for ${targetPlatform.name} release build: '
        'expected a public $expectedPrefix key.',
      );
    }

    return RevenueCatConfiguration(testApiKey: key);
  }

  final String testApiKey;

  bool get isConfigured {
    final key = testApiKey.trim();
    return key.isNotEmpty && key != _placeholderApiKey;
  }

  static void _validateDebugKey(String key) {
    if (key.isEmpty) {
      throw const RevenueCatConfigurationException(
        'Missing RevenueCat Test Store API key for debug/dev. Configure '
        'REVENUECAT_TEST_API_KEY in the dart-define file.',
      );
    }
    if (!key.startsWith('test_')) {
      throw const RevenueCatConfigurationException(
        'Invalid RevenueCat debug API key: expected a Test Store key with '
        'the test_ prefix.',
      );
    }
  }
}
