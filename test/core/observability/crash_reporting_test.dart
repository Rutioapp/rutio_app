import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/core/observability/crash_reporting_keys.dart';
import 'package:rutio/core/observability/crash_reporting_service.dart';
import 'package:rutio/core/observability/crashlytics_config.dart';

void main() {
  test('Crashlytics is disabled by default outside explicit release config',
      () {
    final config = CrashlyticsConfig.fromValues(
      enabled: '',
      collectionEnabled: '',
      isDebug: true,
      isProfile: false,
      isRelease: false,
    );

    expect(config.enabled, isFalse);
    expect(config.collectionEnabled, isFalse);
  });

  test('Crashlytics remains disabled in debug even when explicitly enabled',
      () {
    final config = CrashlyticsConfig.fromValues(
      enabled: 'true',
      collectionEnabled: 'true',
      isDebug: true,
      isProfile: false,
      isRelease: false,
    );

    expect(config.enabled, isFalse);
    expect(config.collectionEnabled, isFalse);
  });

  test('Crashlytics is enabled by default in release', () {
    final config = CrashlyticsConfig.fromValues(
      enabled: '',
      collectionEnabled: '',
      isDebug: false,
      isProfile: false,
      isRelease: true,
    );

    expect(config.enabled, isTrue);
    expect(config.collectionEnabled, isTrue);
  });

  test('noop never throws and fake records fatal/non-fatal deterministically',
      () async {
    const noop = NoopCrashReportingService();
    await noop.initialize();
    await noop.setUserId('uuid-must-not-be-used');
    await noop.setKey(CrashReportingKeys.authState, 'anonymous');
    await noop.recordFatal(StateError('fatal'), StackTrace.empty);
    await noop.recordNonFatal(StateError('nonfatal'), StackTrace.empty);

    final fake = FakeCrashReportingService();
    await fake.initialize();
    await fake.setUserId('uuid-must-not-be-used');
    await fake.setKey(CrashReportingKeys.authState, 'anonymous');
    await fake.recordFatal(StateError('fatal'), StackTrace.empty,
        reason: CrashReportingReasons.bootstrapFailure);
    await fake.recordNonFatal(StateError('nonfatal'), StackTrace.empty,
        reason: CrashReportingReasons.supabaseInitializationFailure);

    expect(fake.initialized, isTrue);
    expect(fake.calls.map((call) => call.kind), <String>[
      'user_id_ignored',
      'key',
      'fatal',
      'non_fatal',
    ]);
    expect(fake.calls[2].reason, CrashReportingReasons.bootstrapFailure);
    expect(fake.calls[3].reason,
        CrashReportingReasons.supabaseInitializationFailure);
  });

  test('safe key vocabulary and categorical contexts are centralized', () {
    expect(CrashReportingKeys.authState, 'auth_state');
    expect(CrashReportingKeys.premiumStatus, 'premium_status');
    expect(CrashReportingValues.anonymous, 'anonymous');
    expect(CrashReportingValues.authenticated, 'authenticated');
    expect(CrashReportingValues.expired, 'expired');
  });
}
