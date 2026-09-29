import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/core/observability/analytics_config.dart';
import 'package:rutio/core/observability/analytics_identity_lifecycle.dart';
import 'package:rutio/core/observability/analytics_sanitizer.dart';
import 'package:rutio/core/observability/analytics_service.dart';

AnalyticsConfig _config({
  String observability = '',
  String posthog = '',
  String token = '',
  String debug = '',
  bool isDebug = false,
  bool isProfile = false,
  bool isRelease = false,
}) {
  return AnalyticsConfig.fromValues(
    observability: observability,
    posthog: posthog,
    token: token,
    host: AnalyticsConfig.euHost,
    debug: debug,
    isDebug: isDebug,
    isProfile: isProfile,
    isRelease: isRelease,
  );
}

void main() {
  group('AnalyticsConfig', () {
    test('debug analytics is disabled by default', () {
      final config = _config(isDebug: true);

      expect(config.observabilityEnabled, isFalse);
      expect(config.posthogEnabled, isFalse);
    });

    test('explicit debug enable works with valid configuration', () {
      final config = _config(
        observability: 'true',
        posthog: 'true',
        token: 'phc_test',
        debug: 'true',
        isDebug: true,
      );

      expect(config.observabilityEnabled, isTrue);
      expect(config.host, AnalyticsConfig.euHost);
      expect(config.debug, isTrue);
    });

    test('incomplete configuration falls back safely', () {
      final config = _config(
        observability: 'true',
        posthog: 'true',
        isRelease: true,
      );

      expect(config.observabilityEnabled, isFalse);
      expect(config.projectToken, isEmpty);
    });
  });

  group('AnalyticsPropertySanitizer', () {
    test('keeps approved scalar properties', () {
      final result = AnalyticsPropertySanitizer.sanitize({
        'platform': 'android',
        'premium_status': 'free',
        'onboarding_completed': false,
        'build_number': 7,
      });

      expect(result, {
        'platform': 'android',
        'premium_status': 'free',
        'onboarding_completed': false,
        'build_number': 7,
      });
    });

    test('removes sensitive and unsupported values', () {
      final result = AnalyticsPropertySanitizer.sanitize({
        'email': 'user@example.com',
        'session_id': 'private-session',
        'journal_text': 'private text',
        'habit_name': 'private habit',
        'content': 'private content',
        'platform': <String>['android'],
        'locale': 'es',
      });

      expect(result, {'locale': 'es'});
    });
  });

  group('analytics services', () {
    test('noop service never fails', () async {
      const service = NoopAnalyticsService();

      await service.initialize();
      await service.identifyUser('user-id');
      await service.resetIdentity();
      await service.track('app_started');
      await service.screen('home');
      await service.setUserContext({'locale': 'es'});
    });

    test('fake service records deterministic calls', () async {
      final service = FakeAnalyticsService();

      await service.initialize();
      await service.track('app_started', properties: {'platform': 'ios'});

      expect(service.initialized, isTrue);
      expect(service.calls.single.name, 'app_started');
      expect(service.calls.single.properties, {'platform': 'ios'});
    });

    test('identity lifecycle isolates authenticated users', () async {
      final service = FakeAnalyticsService();
      final lifecycle = AnalyticsIdentityLifecycle(service);

      await lifecycle.resolveUser('user-a');
      await lifecycle.resolveUser('user-a');
      await lifecycle.resolveUser(null);
      await lifecycle.resolveUser('user-b');

      expect(service.identifiedUsers, ['user-a', 'user-b']);
      expect(service.resetCount, 1);
    });

    test('app started is emitted once per tracker', () async {
      final service = FakeAnalyticsService();
      final tracker = AnalyticsAppStartTracker(service);

      await tracker.emitOnce(properties: {'platform': 'android'});
      await tracker.emitOnce(properties: {'platform': 'android'});

      expect(
        service.calls.where((call) => call.name == 'app_started'),
        hasLength(1),
      );
    });
  });
}
