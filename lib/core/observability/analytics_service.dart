import 'package:flutter/foundation.dart';

abstract interface class AnalyticsService {
  Future<void> initialize();

  Future<void> identifyUser(String userId);

  Future<void> resetIdentity();

  Future<void> track(
    String event, {
    Map<String, Object?> properties = const <String, Object?>{},
  });

  Future<void> screen(
    String name, {
    Map<String, Object?> properties = const <String, Object?>{},
  });

  Future<void> setUserContext(Map<String, Object?> properties);
}

abstract final class AnalyticsEventNames {
  static const appStarted = 'app_started';
}

/// Keeps the first process-start event idempotent if bootstrap code is retried.
abstract interface class AppStartTracker {
  Future<void> emitOnce({
    Map<String, Object?> properties = const <String, Object?>{},
  });
}

class AnalyticsAppStartTracker implements AppStartTracker {
  AnalyticsAppStartTracker(this._analytics);

  final AnalyticsService _analytics;
  bool _emitted = false;

  @override
  Future<void> emitOnce({
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {
    if (_emitted) return;
    _emitted = true;
    await _analytics.track(
      AnalyticsEventNames.appStarted,
      properties: properties,
    );
  }
}

class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> identifyUser(String userId) async {}

  @override
  Future<void> resetIdentity() async {}

  @override
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {}

  @override
  Future<void> screen(
    String name, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {}

  @override
  Future<void> setUserContext(Map<String, Object?> properties) async {}
}

/// Test implementation. It never performs network I/O.
class FakeAnalyticsService implements AnalyticsService {
  bool initialized = false;
  final List<String> identifiedUsers = <String>[];
  int resetCount = 0;
  final List<AnalyticsCall> calls = <AnalyticsCall>[];

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> identifyUser(String userId) async {
    identifiedUsers.add(userId);
  }

  @override
  Future<void> resetIdentity() async {
    resetCount++;
  }

  @override
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {
    calls.add(AnalyticsCall.track(event, properties));
  }

  @override
  Future<void> screen(
    String name, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {
    calls.add(AnalyticsCall.screen(name, properties));
  }

  @override
  Future<void> setUserContext(Map<String, Object?> properties) async {
    calls.add(AnalyticsCall.context(properties));
  }
}

@immutable
class AnalyticsCall {
  const AnalyticsCall._(this.kind, this.name, this.properties);

  factory AnalyticsCall.track(String name, Map<String, Object?> properties) =>
      AnalyticsCall._('track', name, Map.unmodifiable(properties));

  factory AnalyticsCall.screen(String name, Map<String, Object?> properties) =>
      AnalyticsCall._('screen', name, Map.unmodifiable(properties));

  factory AnalyticsCall.context(Map<String, Object?> properties) =>
      AnalyticsCall._('context', null, Map.unmodifiable(properties));

  final String kind;
  final String? name;
  final Map<String, Object?> properties;
}
