import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';

void main() {
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
}
