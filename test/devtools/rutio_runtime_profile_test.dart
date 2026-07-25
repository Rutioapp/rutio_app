import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/devtools/rutio_calendar_clock.dart';
import 'package:rutio/devtools/rutio_runtime_profile.dart';

void main() {
  group('RutioRuntimeProfile', () {
    test('default is non-demo when no values are provided', () {
      final profile = RutioRuntimeProfile.parse();

      expect(profile.isDemoProfile, isFalse);
      expect(profile.shouldResetDemoProfile, isFalse);
      expect(profile.screenshotModeEnabled, isFalse);
      expect(profile.demoNowDate, isNull);
    });

    test('RUTIO_PROFILE=demo activates demo mode', () {
      final profile = RutioRuntimeProfile.parse(profileValue: 'demo');

      expect(profile.isDemoProfile, isTrue);
      expect(profile.shouldResetDemoProfile, isFalse);
    });

    test('RUTIO_RESET_DEMO=true is parsed correctly', () {
      final profile = RutioRuntimeProfile.parse(
        profileValue: 'demo',
        resetDemoValue: 'true',
      );

      expect(profile.isDemoProfile, isTrue);
      expect(profile.shouldResetDemoProfile, isTrue);
    });

    test('RUTIO_SCREENSHOT_MODE=true enables screenshot mode', () {
      final profile = RutioRuntimeProfile.parse(
        screenshotModeValue: 'true',
      );

      expect(profile.screenshotModeEnabled, isTrue);
      expect(profile.isDemoProfile, isFalse);
    });

    test('RUTIO_DEMO_NOW parses valid yyyy-mm-dd values', () {
      final profile = RutioRuntimeProfile.parse(
        demoNowValue: '2026-05-20',
      );

      expect(profile.demoNowDate, equals(DateTime(2026, 5, 20)));
    });

    test('invalid RUTIO_DEMO_NOW safely falls back to null', () {
      final profile = RutioRuntimeProfile.parse(
        demoNowValue: '2026-02-30',
      );

      expect(profile.demoNowDate, isNull);
    });

    test('RUTIO_DEV_NOW stays separate from the demo profile', () {
      final profile = RutioRuntimeProfile.parse();
      final calendarNow = RutioCalendarClock.resolveFromValue(
        rawValue: '2026-07-26T10:00:00',
        releaseMode: false,
      );

      expect(profile.isDemoProfile, isFalse);
      expect(profile.demoNowDate, isNull);
      expect(calendarNow(), DateTime(2026, 7, 26, 10));
    });

    test('demo mode and screenshot mode can be enabled independently', () {
      final screenshotOnly = RutioRuntimeProfile.parse(
        screenshotModeValue: 'true',
      );
      final demoOnly = RutioRuntimeProfile.parse(
        profileValue: 'demo',
      );

      expect(screenshotOnly.isDemoProfile, isFalse);
      expect(screenshotOnly.screenshotModeEnabled, isTrue);

      expect(demoOnly.isDemoProfile, isTrue);
      expect(demoOnly.screenshotModeEnabled, isFalse);
    });
  });
}
