import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
  });

  group('IANA timezone ids', () {
    test('accepts valid identifiers', () {
      expect(isValidIanaTimezoneId('Europe/Madrid'), isTrue);
      expect(isValidIanaTimezoneId('Asia/Tokyo'), isTrue);
      expect(isValidIanaTimezoneId('America/New_York'), isTrue);
      expect(isValidIanaTimezoneId('UTC'), isTrue);
    });

    test('rejects abbreviations and invalid identifiers', () {
      expect(isValidIanaTimezoneId('CEST'), isFalse);
      expect(isValidIanaTimezoneId('CET'), isFalse);
      expect(isValidIanaTimezoneId('Mars/Olympus_Mons'), isFalse);
      expect(isValidIanaTimezoneId(''), isFalse);
    });
  });

  group('FakeNotificationClock', () {
    test('returns and advances the configured time', () {
      final clock = FakeNotificationClock(
        currentTime: DateTime(2026, 8, 28, 10, 15),
      );

      expect(clock.now(), DateTime(2026, 8, 28, 10, 15));

      clock.advance(const Duration(minutes: 45));

      expect(clock.now(), DateTime(2026, 8, 28, 11, 0));
      expect(clock.localDate(), DateTime(2026, 8, 28));
    });

    test('allows changing timezone id explicitly', () {
      final clock = FakeNotificationClock(
        currentTime: DateTime(2026, 8, 28, 10, 15),
        timezoneId: 'Europe/Madrid',
      );

      clock.setTimezoneId('America/New_York');

      expect(clock.timezoneId(), 'America/New_York');
    });

    test('rejects blank timezone ids', () {
      final clock = FakeNotificationClock(
        currentTime: DateTime(2026, 8, 28, 10, 15),
      );

      expect(
        () => clock.setTimezoneId(' '),
        throwsArgumentError,
      );
    });
  });

  group('SystemNotificationClock', () {
    test('reads the initialized local IANA timezone', () {
      tz.setLocalLocation(tz.getLocation('Europe/Madrid'));

      final clock = SystemNotificationClock();

      expect(clock.timezoneId(), 'Europe/Madrid');
    });
  });
}
