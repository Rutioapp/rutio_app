import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/application/count_habit_stats_aggregator.dart';

void main() {
  group('CountHabitStatsAggregator', () {
    final habit = <String, dynamic>{
      'id': 'run',
      'type': 'count',
      'target': 8,
      'unit': 'km',
    };

    final week = List<DateTime>.generate(
      7,
      (index) => DateTime(2026, 5, 1 + index),
    );

    test('7-day mixed scenario computes all key metrics correctly', () {
      final summary = CountHabitStatsAggregator.aggregate(
        habit: habit,
        startDate: week.first,
        endDate: week.last,
        scheduledDates: week,
        countValuesByDate: const {
          '2026-05-01': 0,
          '2026-05-02': 6,
          '2026-05-03': 8,
          '2026-05-04': 10,
          '2026-05-05': 4,
          '2026-05-06': 6,
          '2026-05-07': 0,
        },
        skipsByDate: const {
          '2026-05-06': true,
        },
      );

      expect(summary.completedDays, 2);
      expect(summary.partialProgressDays, 2);
      expect(summary.activityDays, 4);
      expect(summary.skippedDays, 1);
      expect(summary.scheduledDays, 7);
      expect(summary.totalAccumulated, 28);
      expect(summary.bestDayValue, 10);
      expect(summary.bestDayDate, DateTime(2026, 5, 4));
      expect(summary.dailyAverage, 4);
      expect(summary.activeDayAverage, 7);
      expect(summary.averageCompletionRatio, closeTo(0.541666, 0.000001));
      expect(summary.averageCompletionPercent, closeTo(54.1666, 0.001));
    });

    test('6/8 is not counted as completed', () {
      final summary = CountHabitStatsAggregator.aggregate(
        habit: habit,
        startDate: DateTime(2026, 5, 2),
        endDate: DateTime(2026, 5, 2),
        scheduledDates: [DateTime(2026, 5, 2)],
        countValuesByDate: const {'2026-05-02': 6},
      );

      expect(summary.completedDays, 0);
      expect(summary.partialProgressDays, 1);
    });

    test('8/8 is counted as completed', () {
      final summary = CountHabitStatsAggregator.aggregate(
        habit: habit,
        startDate: DateTime(2026, 5, 3),
        endDate: DateTime(2026, 5, 3),
        scheduledDates: [DateTime(2026, 5, 3)],
        countValuesByDate: const {'2026-05-03': 8},
      );

      expect(summary.completedDays, 1);
      expect(summary.partialProgressDays, 0);
    });

    test('skip with value does not add total or completion/partial/activity', () {
      final summary = CountHabitStatsAggregator.aggregate(
        habit: habit,
        startDate: DateTime(2026, 5, 6),
        endDate: DateTime(2026, 5, 6),
        scheduledDates: [DateTime(2026, 5, 6)],
        countValuesByDate: const {'2026-05-06': 9},
        skipsByDate: const {'2026-05-06': true},
      );

      expect(summary.skippedDays, 1);
      expect(summary.totalAccumulated, 0);
      expect(summary.completedDays, 0);
      expect(summary.partialProgressDays, 0);
      expect(summary.activityDays, 0);
      expect(summary.seriesActualValues.single.value, 9);
    });

    test('invalid target does not crash', () {
      final summary = CountHabitStatsAggregator.aggregate(
        habit: const {
          'id': 'run',
          'type': 'count',
          'target': 0,
        },
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 1),
        scheduledDates: [DateTime(2026, 5, 1)],
        countValuesByDate: const {'2026-05-01': 2},
      );

      expect(summary.scheduledDays, 1);
      expect(summary.completedDays, 1);
      expect(summary.averageCompletionRatio, 1);
      expect(summary.targetReferenceSeries.single.value, 1);
    });

    test('decimal support works (2.5/5)', () {
      final summary = CountHabitStatsAggregator.aggregate(
        habit: const {
          'id': 'water',
          'type': 'count',
          'target': 5,
        },
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 1),
        scheduledDates: [DateTime(2026, 5, 1)],
        countValuesByDate: const {'2026-05-01': 2.5},
      );

      expect(summary.totalAccumulated, 2.5);
      expect(summary.partialProgressDays, 1);
      expect(summary.averageCompletionRatio, 0.5);
    });

    test('empty scheduledDates is safe', () {
      final summary = CountHabitStatsAggregator.aggregate(
        habit: habit,
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 7),
        scheduledDates: const <DateTime>[],
        countValuesByDate: const {'2026-05-02': 6},
      );

      expect(summary.scheduledDays, 0);
      expect(summary.totalAccumulated, 0);
      expect(summary.seriesActualValues, isEmpty);
      expect(summary.targetReferenceSeries, isEmpty);
    });

    test('non-scheduled days are ignored even if they have values', () {
      final summary = CountHabitStatsAggregator.aggregate(
        habit: habit,
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 3),
        scheduledDates: [
          DateTime(2026, 5, 1),
          DateTime(2026, 5, 3),
        ],
        countValuesByDate: const {
          '2026-05-01': 8,
          '2026-05-02': 100,
          '2026-05-03': 0,
        },
      );

      expect(summary.scheduledDays, 2);
      expect(summary.totalAccumulated, 8);
      expect(summary.completedDays, 1);
    });

    test('seriesActualValues preserves dates and values', () {
      final summary = CountHabitStatsAggregator.aggregate(
        habit: habit,
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 3),
        scheduledDates: [
          DateTime(2026, 5, 1),
          DateTime(2026, 5, 2),
          DateTime(2026, 5, 3),
        ],
        countValuesByDate: const {
          '2026-05-01': 1,
          '2026-05-02': 2,
          '2026-05-03': 3,
        },
      );

      expect(summary.seriesActualValues.length, 3);
      expect(summary.seriesActualValues[0].date, DateTime(2026, 5, 1));
      expect(summary.seriesActualValues[0].value, 1);
      expect(summary.seriesActualValues[2].date, DateTime(2026, 5, 3));
      expect(summary.seriesActualValues[2].value, 3);
    });

    test('targetReferenceSeries preserves daily effective target', () {
      final summary = CountHabitStatsAggregator.aggregate(
        habit: habit,
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 2),
        scheduledDates: [
          DateTime(2026, 5, 1),
          DateTime(2026, 5, 2),
        ],
      );

      expect(summary.targetReferenceSeries.length, 2);
      expect(summary.targetReferenceSeries[0].date, DateTime(2026, 5, 1));
      expect(summary.targetReferenceSeries[0].value, 8);
      expect(summary.targetReferenceSeries[1].date, DateTime(2026, 5, 2));
      expect(summary.targetReferenceSeries[1].value, 8);
    });
  });
}
