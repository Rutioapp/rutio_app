import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/devtools/rutio_calendar_clock.dart';

void main() {
  group('RutioCalendarClock', () {
    test('missing env value falls back to the real clock', () {
      final before = DateTime.now();
      final logs = <String>[];
      final provider = RutioCalendarClock.resolveFromValue(
        rawValue: null,
        releaseMode: false,
        debugLogger: logs.add,
      );
      final value = provider();
      final after = DateTime.now();

      expect(logs, isEmpty);
      expect(
          value.isAfter(before.subtract(const Duration(seconds: 2))), isTrue);
      expect(value.isBefore(after.add(const Duration(seconds: 2))), isTrue);
    });

    test('valid local ISO value is returned as the simulated calendar clock',
        () {
      final logs = <String>[];
      final provider = RutioCalendarClock.resolveFromValue(
        rawValue: '2026-07-26T10:00:00',
        releaseMode: false,
        debugLogger: logs.add,
      );

      expect(provider(), DateTime(2026, 7, 26, 10));
      expect(logs, hasLength(1));
      expect(logs.single, contains('[calendar-clock] simulated now='));
    });

    test('invalid env value logs once and safely falls back', () {
      final before = DateTime.now();
      final logs = <String>[];
      final provider = RutioCalendarClock.resolveFromValue(
        rawValue: 'not-a-date',
        releaseMode: false,
        debugLogger: logs.add,
      );
      final value = provider();
      final after = DateTime.now();

      expect(logs, hasLength(1));
      expect(
        logs.single,
        contains('[calendar-clock] invalid RUTIO_DEV_NOW="not-a-date"'),
      );
      expect(
          value.isAfter(before.subtract(const Duration(seconds: 2))), isTrue);
      expect(value.isBefore(after.add(const Duration(seconds: 2))), isTrue);
    });

    test('release mode ignores the simulated env value', () {
      final before = DateTime.now();
      final logs = <String>[];
      final provider = RutioCalendarClock.resolveFromValue(
        rawValue: '2026-07-26T10:00:00',
        releaseMode: true,
        debugLogger: logs.add,
      );
      final value = provider();
      final after = DateTime.now();

      expect(logs, isEmpty);
      expect(
          value.isAfter(before.subtract(const Duration(seconds: 2))), isTrue);
      expect(value.isBefore(after.add(const Duration(seconds: 2))), isTrue);
    });
  });
}
