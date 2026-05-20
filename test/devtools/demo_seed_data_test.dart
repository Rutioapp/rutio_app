import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/devtools/demo_seed/demo_seed_data.dart';
import 'package:rutio/devtools/demo_seed/demo_seed_dates.dart';

void main() {
  group('DemoSeedData', () {
    test('is deterministic with a fixed now', () {
      final now = DateTime(2026, 5, 20, 10, 30);
      final first = DemoSeedData.build(now: now);
      final second = DemoSeedData.build(now: now);

      expect(jsonEncode(first.state), equals(jsonEncode(second.state)));
    });

    test('contains realistic habit mix and families', () {
      final payload = DemoSeedData.build(now: DateTime(2026, 5, 20));
      final root = payload.state['userState'] as Map<String, dynamic>;
      final habits = (root['activeHabits'] as List).cast<Map<String, dynamic>>();

      expect(habits.length, inInclusiveRange(10, 14));
      expect(habits.where((h) => h['type'] == 'check').length, greaterThan(0));
      expect(habits.where((h) => h['type'] == 'count').length, greaterThan(0));

      final families = habits
          .map((habit) => (habit['familyId'] ?? '').toString())
          .where((familyId) => familyId.isNotEmpty)
          .toSet();
      expect(families.length, greaterThanOrEqualTo(5));
    });

    test('contains required edge-case habits', () {
      final payload = DemoSeedData.build(now: DateTime(2026, 5, 20));
      final root = payload.state['userState'] as Map<String, dynamic>;
      final habits = (root['activeHabits'] as List).cast<Map<String, dynamic>>();
      final byId = {for (final habit in habits) habit['id'].toString(): habit};

      final longNameHabit = byId['demo_habit_walk_focus'];
      expect(longNameHabit, isNotNull);
      expect(
        longNameHabit!['name'],
        equals('Caminar sin mirar el móvil durante media hora'),
      );

      final recentHabit = byId['demo_habit_plan_next_day'];
      expect(recentHabit, isNotNull);
      expect(recentHabit!['createdAt'], equals('2026-05-16'));

      final archivedHabit = byId['demo_habit_stretch_archived'];
      expect(archivedHabit, isNotNull);
      expect(archivedHabit!['archived'], isTrue);

      final timesPerWeekHabit = byId['demo_habit_gym'];
      expect(timesPerWeekHabit, isNotNull);
      expect(
        timesPerWeekHabit!['schedule'],
        equals(<String, dynamic>{
          'type': 'timesPerWeek',
          'timesPerWeek': 3,
          'weekStartsOn': 1,
        }),
      );

      final weeklySpecificDaysHabit = byId['demo_habit_walk_focus'];
      expect(
        weeklySpecificDaysHabit!['schedule'],
        equals(<String, dynamic>{
          'type': 'weekly',
          'weekdays': <int>[1, 3, 5],
        }),
      );
    });

    test('contains deterministic multi-month history and current month data', () {
      final now = DateTime(2026, 5, 20);
      final payload = DemoSeedData.build(now: now);
      final root = payload.state['userState'] as Map<String, dynamic>;
      final history = root['history'] as Map<String, dynamic>;
      final completions = history['habitCompletions'] as Map<String, dynamic>;
      final countValues = history['habitCountValues'] as Map<String, dynamic>;
      final skips = history['habitSkips'] as Map<String, dynamic>;
      final completionTimes =
          history['habitCompletionTimes'] as Map<String, dynamic>;

      expect(completions, isNotEmpty);
      expect(countValues, isNotEmpty);
      expect(completionTimes, isNotEmpty);

      final rangeStart = DemoSeedDates.firstDayOfMonthMonthsBack(
        now: now,
        monthsBack: 5,
      );
      final expectedStartKey = DemoSeedDates.dateKey(rangeStart);
      expect(completions.keys, contains(expectedStartKey));

      final hasCurrentMonthEntry = completions.keys.any((key) {
        final value = key.toString();
        return value.startsWith('2026-05-');
      });
      final hasPreviousMonthEntry = completions.keys.any((key) {
        final value = key.toString();
        return value.startsWith('2026-04-');
      });

      expect(hasCurrentMonthEntry, isTrue);
      expect(hasPreviousMonthEntry, isTrue);
      expect(skips.values.any((day) => (day as Map).isNotEmpty), isTrue);
    });

    test('contains over-target count values and no future entries', () {
      final now = DateTime(2026, 5, 20);
      final payload = DemoSeedData.build(now: now);
      final root = payload.state['userState'] as Map<String, dynamic>;
      final history = root['history'] as Map<String, dynamic>;
      final countValues = history['habitCountValues'] as Map<String, dynamic>;

      var hasOverTarget = false;
      for (final dayEntry in countValues.entries) {
        final date = _dateFromKey(dayEntry.key);
        expect(date.isAfter(now), isFalse);
        final dayMap = (dayEntry.value as Map).cast<String, dynamic>();
        final water = (dayMap['demo_habit_water'] as num?) ?? 0;
        final read = (dayMap['demo_habit_read'] as num?) ?? 0;
        if (water > 8 || read > 20) {
          hasOverTarget = true;
        }
      }
      expect(hasOverTarget, isTrue);
    });

    test('includes a habit with zero progress in current week', () {
      final now = DateTime(2026, 5, 20);
      final payload = DemoSeedData.build(now: now);
      final root = payload.state['userState'] as Map<String, dynamic>;
      final history = root['history'] as Map<String, dynamic>;
      final completions = history['habitCompletions'] as Map<String, dynamic>;
      final weekStart = DemoSeedDates.startOfWeek(now);

      var completionCount = 0;
      for (final day in DemoSeedDates.eachDayInclusive(start: weekStart, end: now)) {
        final dayKey = DemoSeedDates.dateKey(day);
        final dayMap = (completions[dayKey] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        if (dayMap['demo_habit_call_someone'] == true) {
          completionCount += 1;
        }
      }
      expect(completionCount, equals(0));
    });

    test('keeps archived habit history only before cutoff', () {
      final now = DateTime(2026, 5, 20);
      final payload = DemoSeedData.build(now: now);
      final root = payload.state['userState'] as Map<String, dynamic>;
      final history = root['history'] as Map<String, dynamic>;
      final completions = history['habitCompletions'] as Map<String, dynamic>;
      final cutoff = DateTime(2026, 3, 23);

      for (final entry in completions.entries) {
        final day = _dateFromKey(entry.key);
        final dayMap = (entry.value as Map).cast<String, dynamic>();
        final hasArchivedCompletion = dayMap['demo_habit_stretch_archived'] == true;
        if (hasArchivedCompletion) {
          expect(day.isAfter(cutoff), isFalse);
        }
      }
    });

    test('uses provided now value and does not rely on DateTime.now', () {
      final now = DateTime(2030, 1, 15, 17, 45);
      final payload = DemoSeedData.build(now: now);
      final root = payload.state['userState'] as Map<String, dynamic>;
      final daily = root['daily'] as Map<String, dynamic>;
      final history = root['history'] as Map<String, dynamic>;
      final completions = history['habitCompletions'] as Map<String, dynamic>;

      expect(daily['lastResetDate'], equals('2030-01-15'));
      expect(
        completions.values.any(
          (day) => (day as Map<String, dynamic>).values.contains(true),
        ),
        isTrue,
      );

      for (final key in completions.keys) {
        final date = _dateFromKey(key);
        expect(date.isAfter(DemoSeedDates.dateOnly(now)), isFalse);
      }
    });
  });
}

DateTime _dateFromKey(Object key) {
  final raw = key.toString();
  final parts = raw.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}
