import '../../../../../l10n/gen/app_localizations.dart';
import 'habit_stats_models.dart';

HabitStatsInsight resolveHabitStatsInsight(
  AppLocalizations l10n,
  HabitStatsShellData shellData,
) {
  final todayState = _todayState(shellData);
  final effectiveCurrentStreak =
      shellData.currentStreak < 0 ? 0 : shellData.currentStreak;

  if (todayState == HabitStatsDayState.skipped) {
    return HabitStatsInsight(
      title: l10n.habitStatsInsightTodaySkippedTitle,
      body: l10n.habitStatsInsightTodaySkippedBody,
      tone: HabitStatsInsightTone.paused,
    );
  }

  if (todayState == HabitStatsDayState.completed) {
    return HabitStatsInsight(
      title: l10n.habitStatsInsightTodayCompletedTitle,
      body: l10n.habitStatsInsightTodayCompletedBody,
      tone: HabitStatsInsightTone.positive,
    );
  }

  final todayIsPending = todayState == HabitStatsDayState.pending;
  if (effectiveCurrentStreak > 0 && todayIsPending) {
    return HabitStatsInsight(
      title: l10n.habitStatsInsightPendingStreakTitle,
      body: l10n.habitStatsInsightPendingStreakBody(effectiveCurrentStreak + 1),
      tone: HabitStatsInsightTone.neutral,
    );
  }

  if (shellData.weeklyTarget > 0 &&
      shellData.weeklyCompleted >= shellData.weeklyTarget) {
    return HabitStatsInsight(
      title: l10n.habitStatsInsightWeeklyGoalTitle,
      body: l10n.habitStatsInsightWeeklyGoalBody,
      tone: HabitStatsInsightTone.positive,
    );
  }

  if (shellData.weeklyConsistencyPct < 35) {
    return HabitStatsInsight(
      title: l10n.habitStatsInsightLowConsistencyTitle,
      body: l10n.habitStatsInsightLowConsistencyBody,
      tone: HabitStatsInsightTone.recovery,
    );
  }

  return HabitStatsInsight(
    title: l10n.habitStatsInsightFallbackTitle,
    body: l10n.habitStatsInsightFallbackBody,
    tone: HabitStatsInsightTone.neutral,
  );
}

HabitStatsDayState _todayState(HabitStatsShellData shellData) {
  if (shellData.last7Days.isEmpty) return HabitStatsDayState.pending;
  return shellData.last7Days.last.state;
}
