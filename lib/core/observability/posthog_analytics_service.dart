import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'analytics_config.dart';
import 'analytics_sanitizer.dart';
import 'analytics_service.dart';

class PostHogAnalyticsService implements AnalyticsService {
  PostHogAnalyticsService({
    required AnalyticsConfig config,
    void Function(String message)? logger,
  })  : _config = config,
        _logger = logger ?? _defaultLogger;

  final AnalyticsConfig _config;
  final void Function(String message) _logger;
  Future<void>? _initialization;
  bool _appStartedEmitted = false;

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (!_config.observabilityEnabled) {
      _debug('[analytics] disabled');
      return;
    }
    try {
      final posthogConfig = PostHogConfig(_config.projectToken)
        ..host = _config.host
        ..debug = _config.debug
        ..sessionReplay = false
        ..captureApplicationLifecycleEvents = false
        ..preloadFeatureFlags = false
        ..personProfiles = PostHogPersonProfiles.identifiedOnly;
      await Posthog().setup(posthogConfig);
      _debug('[analytics] initialized');
    } catch (error) {
      _debug('[analytics] initialization failed: ${error.runtimeType}');
    }
  }

  @override
  Future<void> identifyUser(String userId) async {
    await initialize();
    if (!_config.observabilityEnabled || userId.trim().isEmpty) return;
    try {
      await Posthog().identify(userId: userId.trim());
      _debug('[analytics] identified user=${_shortId(userId)}');
    } catch (error) {
      _debug('[analytics] identify failed: ${error.runtimeType}');
    }
  }

  @override
  Future<void> resetIdentity() async {
    await initialize();
    if (!_config.observabilityEnabled) return;
    try {
      await Posthog().reset();
      _debug('[analytics] identity reset');
    } catch (error) {
      _debug('[analytics] reset failed: ${error.runtimeType}');
    }
  }

  @override
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {
    await initialize();
    if (!_config.observabilityEnabled || event.trim().isEmpty) return;
    if (event == AnalyticsEventNames.appStarted) {
      if (_appStartedEmitted) return;
      _appStartedEmitted = true;
    }
    try {
      await Posthog().capture(
        eventName: event,
        properties: AnalyticsPropertySanitizer.sanitize(properties),
      );
    } catch (error) {
      _debug('[analytics] track failed: ${error.runtimeType}');
    }
  }

  @override
  Future<void> screen(
    String name, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {
    await initialize();
    if (!_config.observabilityEnabled || name.trim().isEmpty) return;
    try {
      await Posthog().screen(
        screenName: name,
        properties: AnalyticsPropertySanitizer.sanitize(properties),
      );
    } catch (error) {
      _debug('[analytics] screen failed: ${error.runtimeType}');
    }
  }

  @override
  Future<void> setUserContext(Map<String, Object?> properties) async {
    await initialize();
    if (!_config.observabilityEnabled) return;
    final sanitized = AnalyticsPropertySanitizer.sanitize(properties);
    if (sanitized.isEmpty) return;
    try {
      await Posthog().setPersonProperties(userPropertiesToSet: sanitized);
    } catch (error) {
      _debug('[analytics] context failed: ${error.runtimeType}');
    }
  }

  void _debug(String message) {
    if (kDebugMode) _logger(message);
  }

  static String _shortId(String value) {
    final normalized = value.trim();
    return normalized.length <= 8
        ? normalized
        : '${normalized.substring(0, 8)}…';
  }

  static void _defaultLogger(String message) => debugPrint(message);
}
