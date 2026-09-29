class RevenueCatConfiguration {
  const RevenueCatConfiguration({required this.testApiKey});

  static const apiKeyEnvironmentKey = 'REVENUECAT_TEST_API_KEY';
  static const String revenueCatTestApiKey = 'test_ZNNmkZkUqmerHkxsaLikNbmkHGT';

  static const _placeholderApiKey = 'PASTE_REVENUECAT_TEST_KEY_HERE';

  factory RevenueCatConfiguration.fromEnvironment({
    String? environmentApiKey,
  }) {
    final override =
        environmentApiKey ?? const String.fromEnvironment(apiKeyEnvironmentKey);
    return RevenueCatConfiguration(
      testApiKey: _resolveApiKey(environmentApiKey: override),
    );
  }

  final String testApiKey;

  bool get isConfigured {
    final key = testApiKey.trim();
    return key.isNotEmpty && key != _placeholderApiKey;
  }

  static String _resolveApiKey({required String environmentApiKey}) {
    final override = environmentApiKey.trim();
    return override.isNotEmpty ? override : revenueCatTestApiKey;
  }
}
