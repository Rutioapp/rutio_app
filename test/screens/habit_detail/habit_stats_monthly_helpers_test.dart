import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_helpers.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';

void main() {
  group('buildHabitStatsMonthlyDataForCheck', () {
    test('daily habit uses full-month objective and excludes future from consistency', () {
      final data = buildHabitStatsMonthlyDataForCheck(
        habit: _habit(
          schedule: const {'type': 'daily'},
          createdAt: '2026-01-01',
        ),
        month: DateTime(2026, 5, 1),
        now: DateTime(2026, 5, 20, 10),
        countsByDay: {
          DateTime(2026, 5, 1): 1,
          DateTime(2026, 5, 2): 1,
          DateTime(2026, 5, 5): 1,
        },
        skipsByDay: {
          DateTime(2026, 5, 3): true,
        },
      );

      expect(data.objectiveUnit, HabitStatsMonthlyObjectiveUnit.days);
      expect(data.monthlyObjective, 31);
      expect(data.totalTrackableDays, 31);
      expect(data.elapsedTrackableDays, 20);
      expect(data.futureScheduledDays, 11);
      expect(data.completedDays, 3);
      expect(data.skippedDays, 1);
      expect(data.missedDays, 16);
      expect(data.expectedToDate, 20);
      expect(data.consistency, closeTo(0.15, 0.000001));
    });

    test('daily habit objective follows month length', () {
      final may = buildHabitStatsMonthlyDataForCheck(
        habit: _habit(
          schedule: const {'type': 'daily'},
          createdAt: '2025-01-01',
        ),
        month: DateTime(2026, 5, 1),
        now: DateTime(2026, 5, 10),
        countsByDay: const {},
        skipsByDay: const {},
      );
      final april = buildHabitStatsMonthlyDataForCheck(
        habit: _habit(
          schedule: const {'type': 'daily'},
          createdAt: '2025-01-01',
        ),
        month: DateTime(2026, 4, 1),
        now: DateTime(2026, 4, 10),
        countsByDay: const {},
        skipsByDay: const {},
      );

      expect(may.monthlyObjective, 31);
      expect(april.monthlyObjective, 30);
    });

    test('daily habit created mid-month only counts active days from createdAt', () {
      final data = buildHabitStatsMonthlyDataForCheck(
        habit: _habit(
          schedule: const {'type': 'daily'},
          createdAt: '2026-05-15',
        ),
        month: DateTime(2026, 5, 1),
        now: DateTime(2026, 5, 20),
        countsByDay: const {},
        skipsByDay: const {},
      );

      expect(data.monthlyObjective, 17);
      expect(data.elapsedTrackableDays, 6);
      expect(data.futureScheduledDays, 11);
      expect(
        _statusForDate(data.days, DateTime(2026, 5, 14)),
        HabitStatsMonthDayStatus.notScheduled,
      );
      expect(
        _statusForDate(data.days, DateTime(2026, 5, 15)),
        HabitStatsMonthDayStatus.missed,
      );
    });

    test('specific weekdays objective counts only scheduled weekdays in month', () {
      final data = buildHabitStatsMonthlyDataForCheck(
        habit: _habit(
          schedule: const {
            'type': 'weekly',
            'weekdays': [DateTime.monday, DateTime.wednesday, DateTime.friday],
          },
          createdAt: '2026-05-01',
        ),
        month: DateTime(2026, 5, 1),
        now: DateTime(2026, 5, 10),
        countsByDay: {
          DateTime(2026, 5, 4): 1,
        },
        skipsByDay: const {},
      );

      expect(data.objectiveUnit, HabitStatsMonthlyObjectiveUnit.days);
      expect(data.monthlyObjective, 13);
      expect(data.elapsedTrackableDays, 4);
      expect(data.futureScheduledDays, 9);
      expect(data.expectedToDate, 4);
      expect(data.consistency, closeTo(0.25, 0.000001));
      expect(
        _statusForDate(data.days, DateTime(2026, 5, 5)),
        HabitStatsMonthDayStatus.notScheduled,
      );
    });

    test('times-per-week objective uses monthly quota formula for 31-day month', () {
      final data = buildHabitStatsMonthlyDataForCheck(
        habit: _habit(
          schedule: const {'type': 'timesPerWeek', 'timesPerWeek': 4},
          createdAt: '2026-01-01',
        ),
        month: DateTime(2026, 5, 1),
        now: DateTime(2026, 5, 10),
        countsByDay: {
          DateTime(2026, 5, 3): 1,
          DateTime(2026, 5, 7): 1,
        },
        skipsByDay: const {},
      );

      expect(data.objectiveUnit, HabitStatsMonthlyObjectiveUnit.times);
      expect(data.monthlyObjective, 18);
      expect(data.totalTrackableDays, 18);
      expect(data.elapsedTrackableDays, 6);
      expect(data.expectedToDate, 6);
      expect(data.futureScheduledDays, 21);
      expect(data.completedDays, 2);
      expect(data.consistency, closeTo(2 / 6, 0.000001));
    });

    test('times-per-week objective uses monthly quota formula for 30-day month', () {
      final data = buildHabitStatsMonthlyDataForCheck(
        habit: _habit(
          schedule: const {'type': 'timesPerWeek', 'timesPerWeek': 4},
          createdAt: '2026-01-01',
        ),
        month: DateTime(2026, 4, 1),
        now: DateTime(2026, 4, 10),
        countsByDay: const {},
        skipsByDay: const {},
      );

      expect(data.monthlyObjective, 17);
    });

    test('times-per-week objective uses monthly quota formula for target 3', () {
      final data = buildHabitStatsMonthlyDataForCheck(
        habit: _habit(
          schedule: const {'type': 'timesPerWeek', 'timesPerWeek': 3},
          createdAt: '2026-01-01',
        ),
        month: DateTime(2026, 5, 1),
        now: DateTime(2026, 5, 10),
        countsByDay: const {},
        skipsByDay: const {},
      );

      expect(data.monthlyObjective, 13);
    });

    test('empty month before createdAt stays safe with zero objective', () {
      final data = buildHabitStatsMonthlyDataForCheck(
        habit: _habit(
          schedule: const {'type': 'daily'},
          createdAt: '2026-06-01',
        ),
        month: DateTime(2026, 5, 1),
        now: DateTime(2026, 5, 20),
        countsByDay: const {},
        skipsByDay: const {},
      );

      expect(data.days, hasLength(31));
      expect(data.monthlyObjective, 0);
      expect(data.elapsedTrackableDays, 0);
      expect(data.futureScheduledDays, 0);
      expect(data.completedDays, 0);
      expect(data.skippedDays, 0);
      expect(data.missedDays, 0);
      expect(data.totalTrackableDays, 0);
      expect(data.consistency, 0);
      expect(data.bestStreak, 0);
      expect(data.totalDone, 0);
    });
  });

  group('buildHabitStatsMonthlyMetricCardConsistencyPct', () {
    test('returns 11 for completed 2 of monthly objective 18', () {
      final monthlyData = _monthlyData(
        monthlyObjective: 18,
        completedDays: 2,
      );

      expect(
        buildHabitStatsMonthlyMetricCardConsistencyPct(monthlyData: monthlyData),
        11,
      );
    });

    test('returns 15 for completed 2 of monthly objective 13', () {
      final monthlyData = _monthlyData(
        monthlyObjective: 13,
        completedDays: 2,
      );

      expect(
        buildHabitStatsMonthlyMetricCardConsistencyPct(monthlyData: monthlyData),
        15,
      );
    });

    test('returns 13 for completed 4 of monthly objective 31', () {
      final monthlyData = _monthlyData(
        monthlyObjective: 31,
        completedDays: 4,
      );

      expect(
        buildHabitStatsMonthlyMetricCardConsistencyPct(monthlyData: monthlyData),
        13,
      );
    });

    test('returns 18 for completed 4 of monthly objective 22', () {
      final monthlyData = _monthlyData(
        monthlyObjective: 22,
        completedDays: 4,
      );

      expect(
        buildHabitStatsMonthlyMetricCardConsistencyPct(monthlyData: monthlyData),
        18,
      );
    });

    test('returns 0 when monthly objective is zero', () {
      final monthlyData = _monthlyData(
        monthlyObjective: 0,
        completedDays: 4,
      );

      expect(
        buildHabitStatsMonthlyMetricCardConsistencyPct(monthlyData: monthlyData),
        0,
      );
    });
  });
}

HabitStatsMonthDayStatus _statusForDate(
  List<HabitStatsMonthDayState> days,
  DateTime date,
) {
  final day = days.singleWhere((entry) =>
      entry.date.year == date.year &&
      entry.date.month == date.month &&
      entry.date.day == date.day);
  return day.status;
}

Map<String, dynamic> _habit({
  required Map<String, dynamic> schedule,
  String? createdAt,
}) {
  return {
    'id': 'habit-1',
    'type': 'check',
    'title': 'Habit',
    if (createdAt != null) 'createdAt': createdAt,
    'schedule': schedule,
  };
}

HabitStatsMonthlyData _monthlyData({
  required int monthlyObjective,
  required int completedDays,
}) {
  return HabitStatsMonthlyData(
    monthlyObjective: monthlyObjective,
    elapsedTrackableDays: 0,
    expectedToDate: 0,
    futureScheduledDays: 0,
    objectiveUnit: HabitStatsMonthlyObjectiveUnit.days,
    completedDays: completedDays,
    skippedDays: 0,
    missedDays: 0,
    totalTrackableDays: monthlyObjective,
    consistency: 0,
    bestStreak: 0,
    totalDone: completedDays,
    bestMoment: null,
    days: const <HabitStatsMonthDayState>[],
  );
}
