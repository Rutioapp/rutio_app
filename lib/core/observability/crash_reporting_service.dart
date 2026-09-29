import 'package:flutter/foundation.dart';

abstract interface class CrashReportingService {
  Future<void> initialize();

  Future<void> setUserId(String? userId);

  Future<void> setKey(String key, Object value);

  Future<void> recordFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  });

  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  });
}

class NoopCrashReportingService implements CrashReportingService {
  const NoopCrashReportingService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setKey(String key, Object value) async {}

  @override
  Future<void> recordFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {}

  @override
  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {}
}

@immutable
class CrashReportingCall {
  const CrashReportingCall({
    required this.kind,
    this.error,
    this.reason,
    this.key,
    this.value,
  });

  final String kind;
  final Object? error;
  final String? reason;
  final String? key;
  final Object? value;
}

class FakeCrashReportingService implements CrashReportingService {
  bool initialized = false;
  final List<CrashReportingCall> calls = <CrashReportingCall>[];

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<void> setUserId(String? userId) async {
    // V1 deliberately does not correlate Crashlytics with Supabase UUIDs.
    calls.add(const CrashReportingCall(kind: 'user_id_ignored'));
  }

  @override
  Future<void> setKey(String key, Object value) async {
    calls.add(CrashReportingCall(kind: 'key', key: key, value: value));
  }

  @override
  Future<void> recordFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    calls.add(CrashReportingCall(
      kind: 'fatal',
      error: error,
      reason: reason,
    ));
  }

  @override
  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    calls.add(CrashReportingCall(
      kind: 'non_fatal',
      error: error,
      reason: reason,
    ));
  }
}
