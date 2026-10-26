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
  const RevenueCatConfiguration({
    required this.testApiKey,
    this.billingTarget = productionBillingTarget,
  });

  static const testApiKeyEnvironmentKey = 'REVENUECAT_TEST_API_KEY';
  static const androidApiKeyEnvironmentKey = 'REVENUECAT_ANDROID_API_KEY';
  static const androidSandboxApiKeyEnvironmentKey =
      'REVENUECAT_ANDROID_SANDBOX_API_KEY';
  static const iosApiKeyEnvironmentKey = 'REVENUECAT_IOS_API_KEY';
  static const billingTargetEnvironmentKey = 'REVENUECAT_BILLING_TARGET';

  static const testStoreBillingTarget = 'test_store';
  static const googlePlaySandboxBillingTarget = 'google_play_sandbox';
  static const productionBillingTarget = 'production';

  static const _placeholderApiKey = 'PASTE_REVENUECAT_TEST_KEY_HERE';

  factory RevenueCatConfiguration.fromEnvironment({
    String? environmentApiKey,
    String? androidApiKey,
    String? androidSandboxApiKey,
    String? iosApiKey,
    String? billingTarget,
    bool? isRelease,
    TargetPlatform? platform,
  }) {
    final release = isRelease ?? kReleaseMode;
    final targetPlatform = platform ?? defaultTargetPlatform;
    final configuredTarget = (billingTarget ??
            const String.fromEnvironment(billingTargetEnvironmentKey))
        .trim();
    final target = configuredTarget.isEmpty
        ? (release ? productionBillingTarget : testStoreBillingTarget)
        : configuredTarget;

    if (!release) {
      if (target == productionBillingTarget) {
        return _productionConfiguration(
          targetPlatform,
          androidApiKey: androidApiKey,
          iosApiKey: iosApiKey,
          modeLabel: 'debug',
        );
      }
      return switch (target) {
        testStoreBillingTarget => RevenueCatConfiguration(
            testApiKey: (environmentApiKey ??
                    const String.fromEnvironment(testApiKeyEnvironmentKey))
                .trim(),
            billingTarget: target,
          ).._validateDebugTestStoreKey(),
        googlePlaySandboxBillingTarget => _googlePlaySandboxConfiguration(
            targetPlatform,
            androidSandboxApiKey,
          ),
        _ => throw RevenueCatConfigurationException(
            'Unsupported RevenueCat billing target for debug build.',
          ),
      };
    }

    if (target != productionBillingTarget) {
      throw const RevenueCatConfigurationException(
        'Non-production RevenueCat billing targets are not allowed in release builds.',
      );
    }

    return _productionConfiguration(
      targetPlatform,
      androidApiKey: androidApiKey,
      iosApiKey: iosApiKey,
      modeLabel: 'release',
    );
  }

  static RevenueCatConfiguration _productionConfiguration(
    TargetPlatform targetPlatform, {
    String? androidApiKey,
    String? iosApiKey,
    required String modeLabel,
  }) {
    final key = switch (targetPlatform) {
      TargetPlatform.android => (androidApiKey ??
              const String.fromEnvironment(androidApiKeyEnvironmentKey))
          .trim(),
      TargetPlatform.iOS =>
        (iosApiKey ?? const String.fromEnvironment(iosApiKeyEnvironmentKey))
            .trim(),
      _ => throw const RevenueCatConfigurationException(
          'RevenueCat production configuration is only supported for Android '
          'and iOS builds.',
        ),
    };

    if (key.isEmpty) {
      throw RevenueCatConfigurationException(
        'Missing RevenueCat production API key for ${targetPlatform.name} '
        '$modeLabel build. Configure the platform-specific dart-define.',
      );
    }
    if (key.startsWith('test_')) {
      throw RevenueCatConfigurationException(
        'A RevenueCat Test Store key cannot be used for a production target. '
        'Configure the public production key for ${targetPlatform.name}.',
      );
    }

    final expectedPrefix =
        targetPlatform == TargetPlatform.android ? 'goog_' : 'appl_';
    if (!key.startsWith(expectedPrefix)) {
      throw RevenueCatConfigurationException(
        'Invalid RevenueCat API key for ${targetPlatform.name} $modeLabel build: '
        'expected a public $expectedPrefix key.',
      );
    }

    return RevenueCatConfiguration(
      testApiKey: key,
      billingTarget: productionBillingTarget,
    );
  }

  final String testApiKey;
  final String billingTarget;

  bool get isConfigured {
    final key = testApiKey.trim();
    return key.isNotEmpty && key != _placeholderApiKey;
  }

  RevenueCatConfiguration _validateDebugTestStoreKey() {
    _validateDebugKey(testApiKey, 'Test Store');
    return this;
  }

  static RevenueCatConfiguration _googlePlaySandboxConfiguration(
    TargetPlatform platform,
    String? override,
  ) {
    if (platform != TargetPlatform.android) {
      throw const RevenueCatConfigurationException(
        'Google Play Sandbox billing target requires Android.',
      );
    }
    final key = (override ??
            const String.fromEnvironment(androidSandboxApiKeyEnvironmentKey))
        .trim();
    if (key.isEmpty) {
      throw const RevenueCatConfigurationException(
        'Missing RevenueCat Android Sandbox API key for debug build.',
      );
    }
    if (!key.startsWith('goog_')) {
      throw const RevenueCatConfigurationException(
        'Invalid RevenueCat Android Sandbox API key: expected a public goog_ key.',
      );
    }
    return RevenueCatConfiguration(
      testApiKey: key,
      billingTarget: googlePlaySandboxBillingTarget,
    );
  }

  static void _validateDebugKey(String key, String label) {
    if (key.isEmpty) {
      throw RevenueCatConfigurationException(
        'Missing RevenueCat $label API key for debug/dev.',
      );
    }
    if (!key.startsWith('test_')) {
      throw RevenueCatConfigurationException(
        'Invalid RevenueCat $label API key: expected a public test_ key.',
      );
    }
  }
}
