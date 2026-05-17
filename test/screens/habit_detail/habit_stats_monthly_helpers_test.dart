import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_helpers.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';

void main() {
  group('buildHabitStatsMonthlyDataForCheck', () {
    test('daily habit tracks completed/skipped/missed/future and consistency',
        () {
      final data = buildHabitStatsMonthlyDataForCheck(
        habit: _habit(
          schedule: const {'type': 'daily'},
          createdAt: '2026-05-01',
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

      expect(data.completedDays, 3);
      expect(data.skippedDays, 1);
      expect(data.missedDays, 16);
      expect(data.totalTrackableDays, 31);
      expect(data.consistency, closeTo(0.15, 0.000001));

      expect(
        _statusForDate(data.days, DateTime(2026, 5, 3)),
        HabitStatsMonthDayStatus.skipped,
      );
      expect(
        _statusForDate(data.days, DateTime(2026, 5, 4)),
        HabitStatsMonthDayStatus.missed,
      );
      expect(
        _statusForDate(data.days, DateTime(2026, 5, 25)),
        HabitStatsMonthDayStatus.future,
      );
    });

    test('completed wins over skipped for overlapping day data', () {
      final data = buildHabitStatsMonthlyDataForCheck(
        habit: _habit(
          schedule: const {'type': 'daily'},
          createdAt: '2026-05-01',
        ),
        month: DateTime(2026, 5, 1),
        now: DateTime(2026, 5, 5),
        countsByDay: {
          DateTime(2026, 5, 2): 1,
        },
        skipsByDay: {
          DateTime(2026, 5, 2): true,
        },
      );

      expect(
        _statusForDate(data.days, DateTime(2026, 5, 2)),
        HabitStatsMonthDayStatus.completed,
      );
      expect(data.completedDays, 1);
      expect(data.skippedDays, 0);
    });

    test('weekly schedule marks non-selected weekdays as notScheduled', () {
      final data = buildHabitStatsMonthlyDataForCheck(
        habit: _habit(
          schedule: const {
            'type': 'weekly',
            'weekdays': [DateTime.monday, DateTime.wednesday],
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

      expect(
        _statusForDate(data.days, DateTime(2026, 5, 5)),
        HabitStatsMonthDayStatus.notScheduled,
      );
      expect(
        _statusForDate(data.days, DateTime(2026, 5, 4)),
        HabitStatsMonthDayStatus.completed,
      );
      expect(
        _statusForDate(data.days, DateTime(2026, 5, 6)),
        HabitStatsMonthDayStatus.missed,
      );
      expect(
        _statusForDate(data.days, DateTime(2026, 5, 11)),
        HabitStatsMonthDayStatus.future,
      );
      expect(data.totalTrackableDays, 8);
      expect(data.consistency, closeTo(0.5, 0.000001));
    });

    test('createdAt days before habit creation are notScheduled', () {
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

      expect(
        _statusForDate(data.days, DateTime(2026, 5, 14)),
        HabitStatsMonthDayStatus.notScheduled,
      );
      expect(
        _statusForDate(data.days, DateTime(2026, 5, 15)),
        HabitStatsMonthDayStatus.missed,
      );
      expect(data.totalTrackableDays, 17);
      expect(data.missedDays, 6);
    });

    test('best streak uses consecutive completed days and breaks on others', () {
      final data = buildHabitStatsMonthlyDataForCheck(
        habit: _habit(
          schedule: const {'type': 'daily'},
          createdAt: '2026-05-01',
        ),
        month: DateTime(2026, 5, 1),
        now: DateTime(2026, 5, 10),
        countsByDay: {
          DateTime(2026, 5, 1): 1,
          DateTime(2026, 5, 2): 1,
          DateTime(2026, 5, 3): 1,
          DateTime(2026, 5, 5): 1,
          DateTime(2026, 5, 6): 1,
        },
        skipsByDay: {
          DateTime(2026, 5, 7): true,
        },
      );

      expect(data.bestStreak, 3);
    });

    test('empty month stays safe with consistency 0', () {
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
      expect(data.completedDays, 0);
      expect(data.skippedDays, 0);
      expect(data.missedDays, 0);
      expect(data.totalTrackableDays, 0);
      expect(data.consistency, 0);
      expect(data.bestStreak, 0);
      expect(data.totalDone, 0);
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
