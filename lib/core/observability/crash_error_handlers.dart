import 'dart:async';

import 'package:flutter/foundation.dart';

import 'crash_reporting_service.dart';
import 'crash_reporting_keys.dart';

/// Flutter framework errors are owned by [FlutterError.onError]. Errors that
/// escape async callbacks are owned by [PlatformDispatcher.instance.onError].
/// The two handlers intentionally report different error categories.
void installGlobalCrashErrorHandlers(CrashReportingService reporting) {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(reporting.recordFatal(
      details.exception,
      details.stack ?? StackTrace.current,
      reason: CrashReportingReasons.bootstrapFailure,
    ));
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(reporting.recordFatal(
      error,
      stack,
      reason: CrashReportingReasons.bootstrapFailure,
    ));
    return true;
  };
}
