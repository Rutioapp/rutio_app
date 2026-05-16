import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations_en.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_insight_resolver.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('resolveHabitStatsInsight', () {
    test('todaySkipped returns paused insight', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(todayState: HabitStatsDayState.skipped),
      );

      expect(insight.title, l10n.habitStatsInsightTodaySkippedTitle);
      expect(insight.body, l10n.habitStatsInsightTodaySkippedBody);
      expect(insight.tone, HabitStatsInsightTone.paused);
    });

    test('todayCompleted returns completed insight', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(todayState: HabitStatsDayState.completed),
      );

      expect(insight.title, l10n.habitStatsInsightTodayCompletedTitle);
      expect(insight.body, l10n.habitStatsInsightTodayCompletedBody);
      expect(insight.tone, HabitStatsInsightTone.positive);
    });

    test('active streak with today pending returns keep rhythm and streak+1',
        () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          currentStreak: 4,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightPendingStreakTitle);
      expect(insight.body, l10n.habitStatsInsightPendingStreakBody(5));
      expect(insight.tone, HabitStatsInsightTone.neutral);
    });

    test('weekly target achieved returns weekly goal insight', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          weeklyTarget: 4,
          weeklyCompleted: 4,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightWeeklyGoalTitle);
      expect(insight.body, l10n.habitStatsInsightWeeklyGoalBody);
      expect(insight.tone, HabitStatsInsightTone.positive);
    });

    test('low consistency returns recovery insight', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          weeklyTarget: 7,
          weeklyCompleted: 1,
          weeklyConsistencyPct: 34,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightLowConsistencyTitle);
      expect(insight.body, l10n.habitStatsInsightLowConsistencyBody);
      expect(insight.tone, HabitStatsInsightTone.recovery);
    });

    test('fallback returns default insight', () {
      final insight = resolveHabitStatsInsight(
        l10n,
        _shell(
          todayState: HabitStatsDayState.pending,
          weeklyTarget: 7,
          weeklyCompleted: 2,
          weeklyConsistencyPct: 40,
        ),
      );

      expect(insight.title, l10n.habitStatsInsightFallbackTitle);
      expect(insight.body, l10n.habitStatsInsightFallbackBody);
      expect(insight.tone, HabitStatsInsightTone.neutral);
    });
  });
}

HabitStatsShellData _shell({
  required HabitStatsDayState todayState,
  int currentStreak = 0,
  int weeklyTarget = 0,
  int weeklyCompleted = 0,
  int weeklyConsistencyPct = 60,
}) {
  final today = DateTime.now();
  final recent = List<HabitStatsLast7DayItem>.generate(
    7,
    (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final state = index == 6 ? todayState : HabitStatsDayState.pending;
      return HabitStatsLast7DayItem(
        date: date,
        weekdayLabel: '',
        state: state,
      );
    },
    growable: false,
  );

  return HabitStatsShellData(
    habitId: 'habit-1',
    title: 'Habit',
    familyName: 'Mind',
    objectiveSummary: '',
    typeLabel: 'Check',
    isCounter: false,
    currentStreak: currentStreak,
    bestStreak: currentStreak,
    weeklyTarget: weeklyTarget,
    weeklyCompleted: weeklyCompleted,
    weeklyConsistencyPct: weeklyConsistencyPct,
    weeklyComparisonDeltaPct: null,
    bestMomentLabel: '',
    bestMomentSlot: HabitStatsBestMomentSlot.unknown,
    hasBestMomentData: false,
    last7Days: recent,
    countLast7Days: const <HabitStatsCountLast7DayItem>[],
    countDailyTarget: 0,
    countUnitLabel: '',
    countsByDay: const <DateTime, int>{},
    countValuesByDay: const <DateTime, num>{},
    skipsByDay: const <DateTime, bool>{},
  );
}
