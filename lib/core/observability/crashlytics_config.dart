import 'package:flutter/foundation.dart';

@immutable
class CrashlyticsConfig {
  const CrashlyticsConfig._({
    required this.enabled,
    required this.collectionEnabled,
  });

  factory CrashlyticsConfig.fromEnvironment() => CrashlyticsConfig.fromValues(
        enabled: const String.fromEnvironment('CRASHLYTICS_ENABLED'),
        collectionEnabled:
            const String.fromEnvironment('CRASHLYTICS_COLLECTION_ENABLED'),
        isDebug: kDebugMode,
        isProfile: kProfileMode,
        isRelease: kReleaseMode,
      );

  factory CrashlyticsConfig.fromValues({
    required String enabled,
    required String collectionEnabled,
    required bool isDebug,
    required bool isProfile,
    required bool isRelease,
  }) {
    final explicitEnabled = _parseBool(enabled);
    final explicitCollection = _parseBool(collectionEnabled);
    // Collection is intentionally release-only. The explicit flags can turn
    // it off for a release build, but cannot enable it in debug/profile.
    final enabledValue = isRelease && explicitEnabled != false;
    return CrashlyticsConfig._(
      enabled: enabledValue,
      collectionEnabled: enabledValue && explicitCollection != false,
    );
  }

  final bool enabled;
  final bool collectionEnabled;

  static bool? _parseBool(String value) {
    switch (value.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'on':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'off':
        return false;
      default:
        return null;
    }
  }
}
