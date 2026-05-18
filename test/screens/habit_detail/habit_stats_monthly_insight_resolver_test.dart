import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations_en.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_monthly_insight_resolver.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('resolveHabitStatsMonthlyInsight', () {
    test('monthly no progress insight when completed is zero', () {
      final insight = resolveHabitStatsMonthlyInsight(
        l10n,
        monthlyData: _monthlyData(monthlyObjective: 12, completedDays: 0),
      );

      expect(insight.title, l10n.habitStatsInsightMonthlyNotStartedTitle);
      expect(insight.body, l10n.habitStatsInsightMonthlyNotStartedBody);
      expect(insight.tone, HabitStatsInsightTone.neutral);
    });

    test('monthly low progress insight below 25 percent', () {
      final insight = resolveHabitStatsMonthlyInsight(
        l10n,
        monthlyData: _monthlyData(monthlyObjective: 12, completedDays: 2),
      );

      expect(insight.title, l10n.habitStatsInsightMonthlyInConstructionTitle);
      expect(
        insight.body,
        l10n.habitStatsInsightMonthlyInConstructionBody(2, 12),
      );
    });

    test('monthly good progress insight from 25 to 65 percent', () {
      final insight = resolveHabitStatsMonthlyInsight(
        l10n,
        monthlyData: _monthlyData(monthlyObjective: 12, completedDays: 4),
      );

      expect(insight.title, l10n.habitStatsInsightMonthlyInProgressTitle);
      expect(
        insight.body,
        l10n.habitStatsInsightMonthlyInProgressBody(4),
      );
    });

    test('monthly strong progress insight from 65 to 99 percent', () {
      final insight = resolveHabitStatsMonthlyInsight(
        l10n,
        monthlyData: _monthlyData(monthlyObjective: 12, completedDays: 9),
      );

      expect(insight.title, l10n.habitStatsInsightMonthlyStrongTitle);
      expect(
        insight.body,
        l10n.habitStatsInsightMonthlyStrongBody(9, 12),
      );
    });

    test('monthly completed objective insight at or above 100 percent', () {
      final insight = resolveHabitStatsMonthlyInsight(
        l10n,
        monthlyData: _monthlyData(monthlyObjective: 12, completedDays: 12),
      );

      expect(
        insight.title,
        l10n.habitStatsInsightMonthlyGoalCompletedTitle,
      );
      expect(
        insight.body,
        l10n.habitStatsInsightMonthlyGoalCompletedBody,
      );
    });

    test('monthly insight can append best moment and comparison sentence', () {
      final insight = resolveHabitStatsMonthlyInsight(
        l10n,
        monthlyData: _monthlyData(
          monthlyObjective: 12,
          completedDays: 4,
          bestMoment: const HabitStatsBestMoment(
            slot: HabitStatsBestMomentSlot.morning,
            completionCount: 3,
          ),
        ),
        monthlyComparisonData: const HabitStatsMonthlyComparisonData(
          currentCompleted: 4,
          previousCompleted: 2,
          delta: 2,
          hasComparison: true,
          trend: HabitStatsComparisonTrend.better,
        ),
      );

      expect(
        insight.body,
        contains(
          l10n.habitStatsInsightMonthlyBestMomentBody(
            l10n.statisticsV3MomentMorning,
          ),
        ),
      );
      expect(
        insight.body,
        contains(l10n.habitStatsInsightMonthlyComparisonBetter),
      );
      expect(insight.body, isNot(contains('null')));
    });
  });
}

HabitStatsMonthlyData _monthlyData({
  required int monthlyObjective,
  required int completedDays,
  HabitStatsBestMoment? bestMoment,
}) {
  return HabitStatsMonthlyData(
    monthlyObjective: monthlyObjective,
    elapsedTrackableDays: monthlyObjective,
    expectedToDate: monthlyObjective,
    futureScheduledDays: 0,
    objectiveUnit: HabitStatsMonthlyObjectiveUnit.days,
    completedDays: completedDays,
    skippedDays: 0,
    missedDays: monthlyObjective - completedDays < 0
        ? 0
        : monthlyObjective - completedDays,
    totalTrackableDays: monthlyObjective,
    consistency: monthlyObjective <= 0 ? 0.0 : completedDays / monthlyObjective,
    bestStreak: 0,
    totalDone: completedDays,
    bestMoment: bestMoment,
    days: const <HabitStatsMonthDayState>[],
  );
}
