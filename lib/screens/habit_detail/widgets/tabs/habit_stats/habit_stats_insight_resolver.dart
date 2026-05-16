import '../../../../../l10n/gen/app_localizations.dart';
import 'habit_stats_hero_milestone.dart';
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

  final nextMilestone =
      habitStatsHeroMilestoneProgressForStreak(effectiveCurrentStreak).to;
  final daysToNextMilestone =
      (nextMilestone - effectiveCurrentStreak).clamp(0, nextMilestone);
  if (effectiveCurrentStreak > 0 &&
      (daysToNextMilestone == 1 || daysToNextMilestone == 2) &&
      todayState != HabitStatsDayState.skipped) {
    return HabitStatsInsight(
      title: l10n.habitStatsInsightNearMilestoneTitle,
      body: l10n.habitStatsInsightNearMilestoneBody(
        daysToNextMilestone,
        nextMilestone,
      ),
      tone: HabitStatsInsightTone.amber,
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

  if (_hasCountPartialProgressToday(shellData, todayState)) {
    return HabitStatsInsight(
      title: l10n.habitStatsInsightCountPartialTitle,
      body: l10n.habitStatsInsightCountPartialBody,
      tone: HabitStatsInsightTone.amber,
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

  if (_isPositiveWeeklyTrend(shellData)) {
    return HabitStatsInsight(
      title: l10n.habitStatsInsightWeeklyTrendPositiveTitle,
      body: l10n.habitStatsInsightWeeklyTrendPositiveBody,
      tone: HabitStatsInsightTone.positive,
    );
  }

  if (_isNegativeWeeklyTrend(shellData, todayState)) {
    return HabitStatsInsight(
      title: l10n.habitStatsInsightWeeklyTrendNegativeTitle,
      body: l10n.habitStatsInsightWeeklyTrendNegativeBody,
      tone: HabitStatsInsightTone.recovery,
    );
  }

  if (shellData.weeklyConsistencyPct >= 75) {
    return HabitStatsInsight(
      title: l10n.habitStatsInsightStrongConsistencyTitle,
      body: l10n.habitStatsInsightStrongConsistencyBody,
      tone: HabitStatsInsightTone.positive,
    );
  }

  if (_hasBestMomentPattern(shellData)) {
    final moment = _momentLabelForSlot(l10n, shellData.bestMomentSlot);
    return HabitStatsInsight(
      title: l10n.habitStatsInsightBestMomentTitle,
      body: l10n.habitStatsInsightBestMomentBody(moment.toLowerCase()),
      tone: HabitStatsInsightTone.neutral,
    );
  }

  if (_shouldShowRecoveryInsight(
    shellData,
    todayState: todayState,
    effectiveCurrentStreak: effectiveCurrentStreak,
  )) {
    return HabitStatsInsight(
      title: l10n.habitStatsInsightRecoveryTitle,
      body: l10n.habitStatsInsightRecoveryBody,
      tone: HabitStatsInsightTone.recovery,
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

bool _hasCountPartialProgressToday(
  HabitStatsShellData shellData,
  HabitStatsDayState todayState,
) {
  if (!shellData.isCounter) return false;
  if (todayState != HabitStatsDayState.pending) return false;
  final todayTarget = shellData.countDailyTarget;
  if (todayTarget <= 0) return false;
  final todayCount = shellData.countValueForDate(DateTime.now());
  return todayCount > 0 && todayCount < todayTarget;
}

bool _isPositiveWeeklyTrend(HabitStatsShellData shellData) {
  final currentWeekCompleted = shellData.currentWeekCompleted;
  final previousWeekCompleted = shellData.previousWeekCompleted;
  if (shellData.weeklyComparisonDeltaPct == null) return false;
  if (currentWeekCompleted == null || previousWeekCompleted == null) {
    return false;
  }
  return currentWeekCompleted > previousWeekCompleted;
}

bool _isNegativeWeeklyTrend(
  HabitStatsShellData shellData,
  HabitStatsDayState todayState,
) {
  final currentWeekCompleted = shellData.currentWeekCompleted;
  final previousWeekCompleted = shellData.previousWeekCompleted;
  if (shellData.weeklyComparisonDeltaPct == null) return false;
  if (todayState == HabitStatsDayState.completed) return false;
  if (currentWeekCompleted == null || previousWeekCompleted == null) {
    return false;
  }
  return currentWeekCompleted < previousWeekCompleted;
}

bool _hasBestMomentPattern(HabitStatsShellData shellData) {
  return shellData.hasBestMomentData &&
      shellData.bestMomentSlot != HabitStatsBestMomentSlot.unknown;
}

String _momentLabelForSlot(
  AppLocalizations l10n,
  HabitStatsBestMomentSlot slot,
) {
  switch (slot) {
    case HabitStatsBestMomentSlot.morning:
      return l10n.statisticsV3MomentMorning;
    case HabitStatsBestMomentSlot.noon:
      return l10n.statisticsV3MomentAfternoon;
    case HabitStatsBestMomentSlot.afternoon:
      return l10n.statisticsV3MomentEvening;
    case HabitStatsBestMomentSlot.night:
      return l10n.statisticsV3MomentNight;
    case HabitStatsBestMomentSlot.unknown:
      return l10n.habitStatsNoData;
  }
}

bool _shouldShowRecoveryInsight(
  HabitStatsShellData shellData, {
  required HabitStatsDayState todayState,
  required int effectiveCurrentStreak,
}) {
  if (todayState == HabitStatsDayState.completed ||
      todayState == HabitStatsDayState.skipped) {
    return false;
  }

  final hasHistory = shellData.countsByDay.values.any((count) => count > 0) ||
      shellData.countValuesByDay.values.any((value) => value > 0) ||
      shellData.skipsByDay.values.any((isSkipped) => isSkipped);
  if (!hasHistory) return false;

  final hasRecentCompletion = shellData.last7Days.reversed
      .take(3)
      .any((day) => day.state == HabitStatsDayState.completed);
  if (!hasRecentCompletion) return true;

  return effectiveCurrentStreak == 0;
}
