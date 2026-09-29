import 'package:flutter/foundation.dart';

@immutable
class AnalyticsConfig {
  const AnalyticsConfig._({
    required this.observabilityEnabled,
    required this.posthogEnabled,
    required this.projectToken,
    required this.host,
    required this.debug,
  });

  static const euHost = 'https://eu.i.posthog.com';

  factory AnalyticsConfig.fromEnvironment() => AnalyticsConfig.fromValues(
        observability: const String.fromEnvironment('OBSERVABILITY_ENABLED'),
        posthog: const String.fromEnvironment('POSTHOG_ENABLED'),
        token: const String.fromEnvironment('POSTHOG_API_KEY'),
        host: const String.fromEnvironment('POSTHOG_HOST'),
        debug: const String.fromEnvironment('POSTHOG_DEBUG'),
        isDebug: kDebugMode,
        isProfile: kProfileMode,
        isRelease: kReleaseMode,
      );

  factory AnalyticsConfig.fromValues({
    required String observability,
    required String posthog,
    required String token,
    required String host,
    required String debug,
    required bool isDebug,
    required bool isProfile,
    required bool isRelease,
  }) {
    final explicitObservability = _parseBool(observability);
    final explicitPosthog = _parseBool(posthog);
    final enabledByDefault = isRelease;
    final enabled = (explicitObservability ?? enabledByDefault) &&
        (explicitPosthog ?? false) &&
        (isRelease ||
            (isDebug && explicitPosthog == true) ||
            (isProfile && explicitPosthog == true));
    final normalizedToken = token.trim();
    final normalizedHost = host.trim().isEmpty ? euHost : host.trim();
    final validHost = _isValidHttpsUrl(normalizedHost);
    final valid = enabled && normalizedToken.isNotEmpty && validHost;

    return AnalyticsConfig._(
      observabilityEnabled: valid,
      posthogEnabled: valid,
      projectToken: normalizedToken,
      host: validHost ? normalizedHost : euHost,
      debug: _parseBool(debug) ?? false,
    );
  }

  final bool observabilityEnabled;
  final bool posthogEnabled;
  final String projectToken;
  final String host;
  final bool debug;

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

  static bool _isValidHttpsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }
}
