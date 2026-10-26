import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../firebase_options.dart';
import 'crash_reporting_service.dart';
import 'crash_reporting_keys.dart';
import 'crashlytics_config.dart';

class FirebaseCrashReportingService implements CrashReportingService {
  FirebaseCrashReportingService({required this.config});

  final CrashlyticsConfig config;
  Future<void>? _initialization;
  FirebaseCrashlytics? _crashlytics;
  String? _initializationDiagnostic;

  /// Safe diagnostic intended for local logs and tests. It never contains the
  /// original Firebase exception or its message.
  String? get initializationDiagnostic => _initializationDiagnostic;

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (!config.enabled) {
      _initializationDiagnostic = 'disabled_by_build_configuration';
      return;
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(
        config.collectionEnabled,
      );
      _crashlytics = crashlytics;
    } catch (error) {
      _initializationDiagnostic = 'initialization_failed:${error.runtimeType}';
      // Crashlytics must never prevent the application from starting.
      _crashlytics = null;
    }
  }

  FirebaseCrashlytics? get _client => _crashlytics;

  @override
  Future<void> setUserId(String? userId) async {
    await initialize();
    // V1 intentionally keeps the Crashlytics identifier empty.
    await _runSafely(
      'set_user_identifier',
      () => _client?.setUserIdentifier('') ?? Future<void>.value(),
    );
  }

  @override
  Future<void> setKey(String key, Object value) async {
    if (!_allowedKeys.contains(key) || !_safeValue(value)) return;
    await initialize();
    await _runSafely(
      'set_custom_key',
      () => _client?.setCustomKey(key, value) ?? Future<void>.value(),
    );
  }

  @override
  Future<void> recordFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    await initialize();
    await _runSafely(
      'record_fatal',
      () => _client?.recordError(
            _safeErrorForReport(error),
            stackTrace,
            fatal: true,
            reason: reason,
          ) ??
          Future<void>.value(),
    );
  }

  @override
  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    await initialize();
    await _runSafely(
      'record_non_fatal',
      () => _client?.recordError(
            _safeErrorForReport(error),
            stackTrace,
            fatal: false,
            reason: reason,
          ) ??
          Future<void>.value(),
    );
  }

  Future<void> _runSafely(
    String operation,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      _initializationDiagnostic ??=
          'operation_failed:$operation:${error.runtimeType}';
    }
  }

  static Object _safeErrorForReport(Object error) =>
      StateError('reported_error_type:${error.runtimeType}');

  static const _allowedKeys = <String>{
    CrashReportingKeys.authState,
    CrashReportingKeys.premiumStatus,
    CrashReportingKeys.currentFeature,
    CrashReportingKeys.onboardingState,
    CrashReportingKeys.appVersion,
    CrashReportingKeys.buildNumber,
    CrashReportingKeys.platform,
  };

  static bool _safeValue(Object value) =>
      value is String || value is bool || value is num;
}
