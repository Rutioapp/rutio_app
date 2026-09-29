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

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (!config.enabled) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(
        config.collectionEnabled,
      );
      _crashlytics = crashlytics;
    } catch (_) {
      // Firebase configuration is optional until platform files are installed.
      _crashlytics = null;
    }
  }

  FirebaseCrashlytics? get _client => _crashlytics;

  @override
  Future<void> setUserId(String? userId) async {
    await initialize();
    // V1 intentionally keeps the Crashlytics identifier empty.
    await _client?.setUserIdentifier('');
  }

  @override
  Future<void> setKey(String key, Object value) async {
    if (!_allowedKeys.contains(key) || !_safeValue(value)) return;
    await initialize();
    await _client?.setCustomKey(key, value);
  }

  @override
  Future<void> recordFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    await initialize();
    await _client?.recordError(error, stackTrace, fatal: true, reason: reason);
  }

  @override
  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    await initialize();
    await _client?.recordError(error, stackTrace, fatal: false, reason: reason);
  }

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
