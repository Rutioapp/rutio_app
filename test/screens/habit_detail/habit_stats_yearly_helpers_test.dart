import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_helpers.dart';

void main() {
  group('resolveHabitStatsYearMetrics', () {
    test(
        'check yearly consistency uses completed over expected (3 completions of 5 expected = 60%)',
        () {
      final metrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-01-01',
          schedule: const {
            'type': 'weekly',
            'weekdays': [
              DateTime.monday,
              DateTime.tuesday,
              DateTime.wednesday,
              DateTime.thursday,
              DateTime.friday,
            ],
          },
        ),
        year: 2026,
        now: DateTime(2026, 1, 7, 10),
        countsByDay: {
          DateTime(2026, 1, 1): 1,
          DateTime(2026, 1, 2): 1,
          DateTime(2026, 1, 5): 1,
        },
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(metrics.completedTotal, 3);
      expect(metrics.trackableTotal, 5);
      expect(metrics.consistencyPct, 60);
    });

    test(
        'check daily: uses active range, avoids future dates, and resolves best month',
        () {
      final metrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-03-15',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: {
          DateTime(2026, 3, 16): 1,
          DateTime(2026, 4, 1): 1,
          DateTime(2026, 4, 2): 1,
          DateTime(2026, 5, 10): 1,
        },
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(metrics.completedTotal, 4);
      expect(metrics.trackableTotal, 66);
      expect(metrics.consistencyPct, 6);
      expect(metrics.activeMonths, 3);
      expect(metrics.bestMonth?.month, 4);
      expect(metrics.bestMonth?.completedDays, 2);
    });

    test('check weekly schedule: consistency uses scheduled days only', () {
      final metrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-01-01',
          schedule: const {
            'type': 'weekly',
            'weekdays': [DateTime.monday, DateTime.wednesday],
          },
        ),
        year: 2026,
        now: DateTime(2026, 1, 10, 10),
        countsByDay: {
          DateTime(2026, 1, 5): 1,
        },
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(metrics.completedTotal, 1);
      expect(metrics.trackableTotal, 2);
      expect(metrics.consistencyPct, 50);
      expect(metrics.activeMonths, 1);
      expect(metrics.bestMonth?.month, 1);
    });

    test('check times-per-week: consistency uses quota formula', () {
      final metrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2026-01-01',
          schedule: const {'type': 'timesPerWeek', 'timesPerWeek': 4},
        ),
        year: 2026,
        now: DateTime(2026, 1, 10, 10),
        countsByDay: {
          DateTime(2026, 1, 3): 1,
          DateTime(2026, 1, 9): 1,
        },
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(metrics.completedTotal, 2);
      expect(metrics.trackableTotal, 6);
      expect(metrics.consistencyPct, 33);
      expect(metrics.activeMonths, 1);
      expect(metrics.bestMonth?.month, 1);
    });

    test('count: uses yearly accumulated value and best month by accumulation',
        () {
      final metrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'count',
          target: 10,
          createdAt: '2026-01-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: const {},
        countValuesByDay: {
          DateTime(2026, 1, 1): 8,
          DateTime(2026, 1, 2): 4,
          DateTime(2026, 2, 1): 15,
          DateTime(2026, 5, 1): 5,
        },
        skipsByDay: const {},
      );

      expect(metrics.accumulatedTotal, 32);
      expect(metrics.trackableTotal, 139);
      expect(metrics.consistencyPct, 1);
      expect(metrics.activeMonths, 3);
      expect(metrics.bestMonth?.month, 2);
      expect(metrics.bestMonth?.accumulatedValue, 15);
    });

    test(
        'count consistency uses goal-reaching occurrences, not raw accumulation ratio',
        () {
      final metrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'count',
          target: 10,
          createdAt: '2026-01-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 1, 2, 10),
        countsByDay: const {},
        countValuesByDay: {
          DateTime(2026, 1, 1): 9,
          DateTime(2026, 1, 2): 11,
        },
        skipsByDay: const {},
      );

      expect(metrics.accumulatedTotal, 20);
      expect(metrics.trackableTotal, 2);
      expect(metrics.consistencyPct, 50);
    });

    test('future-created habit in selected year stays empty and safe', () {
      final metrics = resolveHabitStatsYearMetrics(
        habit: _habit(
          type: 'check',
          target: 1,
          createdAt: '2027-01-01',
          schedule: const {'type': 'daily'},
        ),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: const {},
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      expect(metrics.completedTotal, 0);
      expect(metrics.trackableTotal, 0);
      expect(metrics.accumulatedTotal, 0);
      expect(metrics.consistencyPct, 0);
      expect(metrics.activeMonths, 0);
      expect(metrics.bestMonth, isNull);
      expect(metrics.months, hasLength(12));
    });
  });
}

Map<String, dynamic> _habit({
  required String type,
  required int target,
  required String createdAt,
  required Map<String, dynamic> schedule,
}) {
  return <String, dynamic>{
    'id': 'habit-1',
    'title': 'Habit',
    'type': type,
    'target': target,
    'createdAt': createdAt,
    'schedule': schedule,
  };
}
