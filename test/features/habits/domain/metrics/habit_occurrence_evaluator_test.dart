import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/metrics/habit_occurrence_evaluator.dart';
import 'package:rutio/features/habits/domain/metrics/habit_occurrence_result.dart';
import 'package:rutio/features/habits/domain/metrics/habit_snapshot.dart';
import 'package:rutio/features/habits/domain/metrics/times_per_week_quota_policy.dart';
import 'package:rutio/features/habits/domain/metrics/weekly_habit_metrics.dart';
import 'package:rutio/features/habits/domain/metrics/weekly_report_week.dart';

void main() {
  const evaluator = HabitOccurrenceEvaluator();

  group('HabitOccurrenceEvaluator', () {
    test('timesPerWeek proratedCeil matches the approved quota matrix', () {
      final week = WeeklyReportWeek.fromDate(DateTime(2026, 9, 1));
      const policy = TimesPerWeekQuotaPolicy.proratedCeil();

      const configuredThree = <int, int>{
        0: 0,
        1: 1,
        2: 1,
        3: 2,
        4: 2,
        5: 3,
        6: 3,
        7: 3,
      };
      for (final entry in configuredThree.entries) {
        final result = calculateEffectiveScheduledQuota(
          configuredTimesPerWeek: 3,
          week: week,
          activeFrom:
              entry.key == 0 ? DateTime(2026, 9, 8) : week.weekStartDate,
          activeUntil: entry.key == 0
              ? DateTime(2026, 9, 7)
              : entry.key == 7
                  ? null
                  : week.weekStartDate.add(Duration(days: entry.key - 1)),
          policy: policy,
        );
        expect(result.eligibleDays, entry.key);
        expect(result.scheduledCount, entry.value);
      }

      for (var eligibleDays = 0; eligibleDays <= 7; eligibleDays++) {
        final result = calculateEffectiveScheduledQuota(
          configuredTimesPerWeek: 7,
          week: week,
          activeFrom:
              eligibleDays == 0 ? DateTime(2026, 9, 8) : week.weekStartDate,
          activeUntil: eligibleDays == 0
              ? DateTime(2026, 9, 7)
              : week.weekStartDate.add(Duration(days: eligibleDays - 1)),
          policy: policy,
        );
        expect(result.scheduledCount, eligibleDays);
      }

      for (var eligibleDays = 1; eligibleDays <= 7; eligibleDays++) {
        final result = calculateEffectiveScheduledQuota(
          configuredTimesPerWeek: 1,
          week: week,
          activeFrom: week.weekStartDate,
          activeUntil: week.weekStartDate.add(Duration(days: eligibleDays - 1)),
          policy: policy,
        );
        expect(result.scheduledCount, 1);
      }
    });

    test('check daily supports completed, incomplete, and skipped states', () {
      final habit = HabitSnapshot(
        habitId: 'check-daily',
        name: 'Check Daily',
        kind: HabitKind.check,
        schedule: HabitSchedule.daily(),
      );

      final incomplete = evaluator.evaluate(
        habit: habit,
        date: DateTime(2026, 9, 1),
        completed: false,
        skipped: false,
      );
      final completed = evaluator.evaluate(
        habit: habit,
        date: DateTime(2026, 9, 1),
        completed: true,
        skipped: false,
      );
      final skipped = evaluator.evaluate(
        habit: habit,
        date: DateTime(2026, 9, 1),
        completed: true,
        skipped: true,
      );

      expect(incomplete.scheduled, isTrue);
      expect(incomplete.completed, isFalse);
      expect(incomplete.skipped, isFalse);

      expect(completed.scheduled, isTrue);
      expect(completed.completed, isTrue);
      expect(completed.skipped, isFalse);

      expect(skipped.scheduled, isTrue);
      expect(skipped.completed, isFalse);
      expect(skipped.skipped, isTrue);
    });

    test('count daily treats partial progress as visible but incomplete', () {
      final habit = HabitSnapshot(
        habitId: 'count-daily',
        name: 'Count Daily',
        kind: HabitKind.count,
        target: 10,
        schedule: HabitSchedule.daily(),
      );

      final partial = evaluator.evaluate(
        habit: habit,
        date: DateTime(2026, 9, 1),
        completed: false,
        skipped: false,
        progress: 5,
      );
      final exact = evaluator.evaluate(
        habit: habit,
        date: DateTime(2026, 9, 1),
        completed: false,
        skipped: false,
        progress: 10,
      );
      final over = evaluator.evaluate(
        habit: habit,
        date: DateTime(2026, 9, 1),
        completed: false,
        skipped: false,
        progress: 12,
      );

      expect(partial.scheduled, isTrue);
      expect(partial.completed, isFalse);
      expect(partial.isPartialProgress, isTrue);
      expect(partial.target, 10);

      expect(exact.completed, isTrue);
      expect(exact.isPartialProgress, isFalse);

      expect(over.completed, isTrue);
      expect(over.isPartialProgress, isFalse);
    });

    test('weekly and once schedules use date-bound scheduling', () {
      final weeklyHabit = HabitSnapshot(
        habitId: 'weekly',
        name: 'Weekly',
        kind: HabitKind.check,
        schedule: HabitSchedule.weekly(
            weekdays: [DateTime.monday, DateTime.wednesday]),
      );
      final onceHabit = HabitSnapshot(
        habitId: 'once',
        name: 'Once',
        kind: HabitKind.check,
        schedule: HabitSchedule.once(date: DateTime(2026, 9, 3)),
      );

      final weeklyMonday = evaluator.evaluate(
        habit: weeklyHabit,
        date: DateTime(2026, 8, 31),
        completed: true,
        skipped: false,
      );
      final weeklyTuesday = evaluator.evaluate(
        habit: weeklyHabit,
        date: DateTime(2026, 9, 2),
        completed: true,
        skipped: false,
      );
      final onceExact = evaluator.evaluate(
        habit: onceHabit,
        date: DateTime(2026, 9, 3),
        completed: true,
        skipped: false,
      );
      final onceBefore = evaluator.evaluate(
        habit: onceHabit,
        date: DateTime(2026, 9, 2),
        completed: true,
        skipped: false,
      );
      final onceAfter = evaluator.evaluate(
        habit: onceHabit,
        date: DateTime(2026, 9, 4),
        completed: true,
        skipped: false,
      );

      expect(weeklyMonday.scheduled, isTrue);
      expect(weeklyTuesday.scheduled, isTrue);
      expect(onceExact.scheduled, isTrue);
      expect(onceBefore.scheduled, isFalse);
      expect(onceAfter.scheduled, isFalse);
    });

    test('timesPerWeek uses a separate weekly quota contract', () {
      final habit = HabitSnapshot(
        habitId: 'tpw',
        name: 'Times Per Week',
        kind: HabitKind.check,
        schedule: HabitSchedule.timesPerWeek(timesPerWeek: 3),
        createdAt: DateTime(2026, 9, 1),
      );
      final week = WeeklyReportWeek.fromDate(DateTime(2026, 9, 1));

      final quota = evaluator.effectiveScheduledQuota(
        habit: habit,
        week: week,
      );

      expect(quota.configuredTimesPerWeek, 3);
      expect(quota.eligibleDays, 6);
      expect(quota.scheduledCount, 3);

      final weeklyMetrics = evaluator.evaluateWeeklyMetrics(
        habit: habit,
        week: week,
        occurrences: List<HabitOccurrenceResult>.generate(7, (index) {
          final completed = index < 5;
          return HabitOccurrenceResult(
            date: week.weekStartDate.add(Duration(days: index)),
            scope: HabitOccurrenceScope.weeklyQuota,
            scheduleType: HabitScheduleType.timesPerWeek,
            scheduled: false,
            completed: completed,
            skipped: false,
            progress: completed ? 1 : 0,
            target: 1,
          );
        }),
      );

      expect(weeklyMetrics.scheduledCount, 3);
      expect(weeklyMetrics.completedCount, 3);
      expect(weeklyMetrics.completionRate, 1);
      expect(weeklyMetrics.isComparable, isTrue);
    });

    test('partial weekly quota is prorated from eligible days', () {
      final habit = HabitSnapshot(
        habitId: 'tpw-partial',
        name: 'Times Per Week Partial',
        kind: HabitKind.check,
        schedule: HabitSchedule.timesPerWeek(timesPerWeek: 3),
        createdAt: DateTime(2026, 9, 4),
      );
      final week = WeeklyReportWeek.fromDate(DateTime(2026, 9, 1));

      final quota = evaluator.effectiveScheduledQuota(
        habit: habit,
        week: week,
      );

      expect(quota.eligibleDays, 3);
      expect(quota.scheduledCount, 2);
      expect(quota.scheduledCount, lessThanOrEqualTo(3));
    });

    test('zero scheduled quota yields a neutral completion rate', () {
      final habit = HabitSnapshot(
        habitId: 'tpw-zero',
        name: 'Times Per Week Zero',
        kind: HabitKind.check,
        schedule: HabitSchedule.timesPerWeek(timesPerWeek: 3),
        createdAt: DateTime(2026, 9, 8),
      );
      final week = WeeklyReportWeek.fromDate(DateTime(2026, 9, 1));

      final metrics = evaluator.evaluateWeeklyMetrics(
        habit: habit,
        week: week,
        occurrences: const <HabitOccurrenceResult>[],
        activeUntil: DateTime(2026, 9, 1),
      );

      expect(metrics.scheduledCount, 0);
      expect(metrics.completedCount, 0);
      expect(metrics.completionRate, isNull);
      expect(metrics.isComparable, isFalse);
    });
  });
}
