import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/application/count_habit_stats_adapter.dart';

void main() {
  group('CountHabitStatsAdapter', () {
    final habit = <String, dynamic>{
      'id': 'run',
      'type': 'count',
      'target': 8,
      'unit': 'km',
    };

    final scheduled = <DateTime>[
      DateTime(2026, 5, 1),
      DateTime(2026, 5, 2),
      DateTime(2026, 5, 3),
    ];

    test('6/8 is partial progress and not completed', () {
      final summary = CountHabitStatsAdapter.fromDayBuckets(
        habit: habit,
        habitId: 'run',
        scheduledDates: [DateTime(2026, 5, 1)],
        historyCountValuesByDay: const {
          '2026-05-01': {'run': 6}
        },
        historySkipsByDay: const {
          '2026-05-01': {'run': false}
        },
      );

      expect(summary.completedDays, 0);
      expect(summary.partialProgressDays, 1);
    });

    test('8/8 is completed', () {
      final summary = CountHabitStatsAdapter.fromDayBuckets(
        habit: habit,
        habitId: 'run',
        scheduledDates: [DateTime(2026, 5, 1)],
        historyCountValuesByDay: const {
          '2026-05-01': {'run': 8}
        },
        historySkipsByDay: const {
          '2026-05-01': {'run': false}
        },
      );

      expect(summary.completedDays, 1);
      expect(summary.partialProgressDays, 0);
    });

    test('mapper computes accumulated and partial days correctly', () {
      final summary = CountHabitStatsAdapter.fromDayBuckets(
        habit: habit,
        habitId: 'run',
        scheduledDates: scheduled,
        historyCountValuesByDay: const {
          '2026-05-01': {'run': 6},
          '2026-05-02': {'run': 8},
          '2026-05-03': {'run': 0},
        },
        historySkipsByDay: const {
          '2026-05-01': {'run': false},
          '2026-05-02': {'run': false},
          '2026-05-03': {'run': false},
        },
      );

      expect(summary.totalAccumulated, 14);
      expect(summary.partialProgressDays, 1);
      expect(summary.completedDays, 1);
      expect(summary.scheduledDays, 3);
    });

    test('skip excludes value from totals and progress counters', () {
      final summary = CountHabitStatsAdapter.fromDayBuckets(
        habit: habit,
        habitId: 'run',
        scheduledDates: [DateTime(2026, 5, 1)],
        historyCountValuesByDay: const {
          '2026-05-01': {'run': 6}
        },
        historySkipsByDay: const {
          '2026-05-01': {'run': true}
        },
      );

      expect(summary.skippedDays, 1);
      expect(summary.totalAccumulated, 0);
      expect(summary.completedDays, 0);
      expect(summary.partialProgressDays, 0);
    });

    test('single partial day in 7-day range is not repeated across all days', () {
      final week = List<DateTime>.generate(
        7,
        (index) => DateTime(2026, 5, 1 + index),
      );
      final summary = CountHabitStatsAdapter.fromDayBuckets(
        habit: habit,
        habitId: 'run',
        scheduledDates: week,
        historyCountValuesByDay: const {
          '2026-05-07': {'run': 6},
        },
        historySkipsByDay: const {
          '2026-05-07': {'run': false},
        },
      );

      expect(summary.completedDays, 0);
      expect(summary.partialProgressDays, 1);
      expect(summary.activityDays, 1);
      expect(summary.totalAccumulated, 6);
      expect(
        summary.seriesActualValues.map((point) => point.value).toList(),
        [0, 0, 0, 0, 0, 0, 6],
      );
    });

    test('single completed day in 7-day range is not repeated across all days', () {
      final week = List<DateTime>.generate(
        7,
        (index) => DateTime(2026, 5, 1 + index),
      );
      final summary = CountHabitStatsAdapter.fromDayBuckets(
        habit: habit,
        habitId: 'run',
        scheduledDates: week,
        historyCountValuesByDay: const {
          '2026-05-07': {'run': 8},
        },
        historySkipsByDay: const {
          '2026-05-07': {'run': false},
        },
      );

      expect(summary.completedDays, 1);
      expect(summary.partialProgressDays, 0);
      expect(summary.activityDays, 1);
      expect(summary.totalAccumulated, 8);
      expect(
        summary.seriesActualValues.map((point) => point.value).toList(),
        [0, 0, 0, 0, 0, 0, 8],
      );
    });

    test('does not repeat habit current value when day bucket is missing', () {
      final week = List<DateTime>.generate(
        7,
        (index) => DateTime(2026, 5, 1 + index),
      );
      final summary = CountHabitStatsAdapter.fromDayBuckets(
        habit: {
          ...habit,
          'progress': 8,
          'currentValue': 8,
          'value': 8,
        },
        habitId: 'run',
        scheduledDates: week,
        historyCountValuesByDay: const {
          '2026-05-07': {'run': 8},
        },
        historySkipsByDay: const {
          '2026-05-07': {'run': false},
        },
      );

      expect(summary.completedDays, 1);
      expect(summary.totalAccumulated, 8);
      expect(
        summary.seriesActualValues.map((point) => point.value).toList(),
        [0, 0, 0, 0, 0, 0, 8],
      );
    });

    test('formatValueWithUnit avoids trailing .0 for whole numbers', () {
      expect(
        CountHabitStatsAdapter.formatValueWithUnit(32.0, unit: 'km'),
        '32 km',
      );
      expect(
        CountHabitStatsAdapter.formatValueWithUnit(4.6, unit: 'km'),
        '4.6 km',
      );
    });
  });
}
