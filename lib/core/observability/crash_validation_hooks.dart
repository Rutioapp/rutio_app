import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'crash_reporting_service.dart';

/// Developer-only hooks for manual Crashlytics validation. They are not wired
/// into production UI and are inert outside debug builds.
Future<void> recordDebugNonFatal(CrashReportingService reporting) async {
  if (!kDebugMode) return;
  await reporting.recordNonFatal(
    StateError('debug_crashlytics_non_fatal'),
    StackTrace.current,
    reason: 'bootstrap_failure',
  );
}

void throwDebugFatal() {
  if (!kDebugMode) return;
  throw StateError('debug_crashlytics_fatal');
}

/// Temporary release-only hook for validating a physical-device Crashlytics
/// report. It is inert unless the build is created with
/// `--dart-define=CRASHLYTICS_TEST_CRASH=true`
/// and `--dart-define=INTERNAL_BUILD=true`. It must be called temporarily
/// from a developer-only code path, then removed after verification. The
/// second compile-time gate keeps the hook inert in public release builds.
void triggerReleaseTestCrash() {
  if (!kReleaseMode ||
      !const bool.fromEnvironment('INTERNAL_BUILD') ||
      !const bool.fromEnvironment('CRASHLYTICS_TEST_CRASH')) {
    return;
  }
  FirebaseCrashlytics.instance.crash();
}

/// Schedules the controlled crash only for an explicitly marked internal
/// release build. Public builds do not schedule anything.
void scheduleReleaseTestCrashIfEnabled() {
  if (!kReleaseMode ||
      !const bool.fromEnvironment('INTERNAL_BUILD') ||
      !const bool.fromEnvironment('CRASHLYTICS_TEST_CRASH')) {
    return;
  }
  Timer(const Duration(seconds: 3), triggerReleaseTestCrash);
}
