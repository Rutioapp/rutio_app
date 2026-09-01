import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/achievements/domain/models/habit_streak_snapshot.dart';
import 'package:rutio/features/habits/domain/metrics/habit_occurrence_result.dart';
import 'package:rutio/features/habits/domain/metrics/habit_snapshot.dart';
import 'package:rutio/features/habits/domain/metrics/weekly_habit_metrics.dart';
import 'package:rutio/features/habits/domain/metrics/weekly_report_week.dart';
import 'package:rutio/features/weekly_report/domain/weekly_report.dart';

void main() {
  group('Weekly Report domain', () {
    test('week boundary always resolves Monday through Sunday', () {
      final week = WeeklyReportWeek.fromDate(DateTime(2026, 9, 1));

      expect(week.weekStartDate, DateTime(2026, 8, 31));
      expect(week.weekEndDate, DateTime(2026, 9, 6));
      expect(week.weekStartsOn, DateTime.monday);
      expect(week.contains(DateTime(2026, 8, 31)), isTrue);
      expect(week.contains(DateTime(2026, 9, 6)), isTrue);
      expect(week.contains(DateTime(2026, 9, 7)), isFalse);
    });

    test('weekly summary keeps zero scheduled rate neutral', () {
      const summary = WeeklyReportSummary(
        scheduledCount: 0,
        completedCount: 0,
        completionRate: null,
      );

      expect(summary.hasScheduledCount, isFalse);
      expect(summary.bestDay, isNull);
    });

    test('weekly report day distinguishes no plan, partial, and completed', () {
      final noPlan = WeeklyReportDay(
        date: DateTime(2026, 9, 1),
        scheduledCount: 0,
        completedCount: 0,
        skippedCount: 0,
        completionRate: null,
        state: WeeklyReportDayState.noPlan,
      );
      final partial = WeeklyReportDay(
        date: DateTime(2026, 9, 2),
        scheduledCount: 3,
        completedCount: 1,
        skippedCount: 0,
        completionRate: 1 / 3,
        state: WeeklyReportDayState.partial,
      );
      final completed = WeeklyReportDay(
        date: DateTime(2026, 9, 3),
        scheduledCount: 3,
        completedCount: 3,
        skippedCount: 0,
        completionRate: 1,
        state: WeeklyReportDayState.completed,
      );

      expect(noPlan.isComparable, isFalse);
      expect(partial.isComparable, isTrue);
      expect(completed.isComparable, isTrue);
      expect(partial.state, WeeklyReportDayState.partial);
      expect(completed.state, WeeklyReportDayState.completed);
    });

    test('weekly report habit snapshots do not depend on the live habit model',
        () {
      final habit = HabitSnapshot(
        habitId: 'habit-1',
        name: 'Live habit name',
        emoji: '✨',
        kind: HabitKind.check,
        schedule: HabitSchedule.weekly(weekdays: [DateTime.monday]),
        createdAt: DateTime(2026, 8, 1),
      );
      final metrics = WeeklyHabitMetrics(
        scheduledCount: 1,
        completedCount: 1,
        skippedCount: 0,
        partialCount: 0,
        totalProgress: 1,
        totalTarget: 1,
        completionRate: 1,
        progressRate: 1,
        occurrences: [
          HabitOccurrenceResult(
            date: DateTime(2026, 9, 1),
            scope: HabitOccurrenceScope.dateBound,
            scheduleType: HabitScheduleType.weekly,
            scheduled: true,
            completed: true,
            skipped: false,
            progress: 1,
            target: 1,
          ),
        ],
      );
      final streak = HabitStreakSnapshot(
        habitId: 'habit-1',
        currentStreak: 4,
        bestStreak: 10,
        totalCompletedDays: 20,
      );

      final reportHabit = weeklyReportHabitFromMetrics(
        habit: habit,
        metrics: metrics,
        streakSnapshot: streak,
      );

      expect(reportHabit.habitId, 'habit-1');
      expect(reportHabit.name, 'Live habit name');
      expect(reportHabit.emoji, '✨');
      expect(reportHabit.type, HabitKind.check);
      expect(reportHabit.schedule.type, HabitScheduleType.weekly);
      expect(reportHabit.scheduledCount, 1);
      expect(reportHabit.completedCount, 1);
      expect(reportHabit.streakSnapshot, streak);
    });

    test('weekly report keeps recommendation and trend contracts compact', () {
      const trend = WeeklyReportTrend(
        kind: WeeklyReportTrendKind.improved,
        delta: 0.2,
        comparable: true,
        reason: 'more completions than last week',
      );
      const recommendation = WeeklyReportRecommendation(
        type: WeeklyReportRecommendationType.keepStable,
        reason: 'steady execution',
      );

      final report = WeeklyReport(
        id: 'weekly-report-1',
        userId: 'user-1',
        week: WeeklyReportWeek.fromDate(DateTime(2026, 9, 1)),
        timezoneId: 'Europe/Madrid',
        status: WeeklyReportStatus.provisional,
        firstPartialWeek: true,
        summary: const WeeklyReportSummary(
          scheduledCount: 2,
          completedCount: 1,
          completionRate: 0.5,
        ),
        days: const <WeeklyReportDay>[],
        habits: const <WeeklyReportHabit>[],
        trend: trend,
        schemaVersion: 1,
        metricsPolicyVersion: 1,
        contentVersion: 1,
        generatedAt: DateTime(2026, 9, 1, 10),
        recommendations: const [recommendation],
      );

      expect(report.isProvisional, isTrue);
      expect(report.firstPartialWeek, isTrue);
      expect(report.trend.kind, WeeklyReportTrendKind.improved);
      expect(report.recommendations.single.type,
          WeeklyReportRecommendationType.keepStable);
    });
  });
}
