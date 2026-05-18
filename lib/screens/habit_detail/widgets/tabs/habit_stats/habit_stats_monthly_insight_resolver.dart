import '../../../../../l10n/gen/app_localizations.dart';
import 'habit_stats_helpers.dart';
import 'habit_stats_models.dart';

HabitStatsInsight resolveHabitStatsMonthlyInsight(
  AppLocalizations l10n, {
  required HabitStatsMonthlyData monthlyData,
  HabitStatsMonthlyComparisonData? monthlyComparisonData,
}) {
  final objective = monthlyData.monthlyObjective;
  final completed = monthlyData.completedDays;
  final progressRatio = objective > 0 ? completed / objective : 0.0;

  HabitStatsInsight baseInsight;

  if (objective <= 0 || completed == 0) {
    baseInsight = HabitStatsInsight(
      title: l10n.habitStatsInsightMonthlyNotStartedTitle,
      body: l10n.habitStatsInsightMonthlyNotStartedBody,
      tone: HabitStatsInsightTone.neutral,
    );
  } else if (progressRatio < 0.25) {
    baseInsight = HabitStatsInsight(
      title: l10n.habitStatsInsightMonthlyInConstructionTitle,
      body: l10n.habitStatsInsightMonthlyInConstructionBody(
        completed,
        objective,
      ),
      tone: HabitStatsInsightTone.recovery,
    );
  } else if (progressRatio < 0.65) {
    baseInsight = HabitStatsInsight(
      title: l10n.habitStatsInsightMonthlyInProgressTitle,
      body: l10n.habitStatsInsightMonthlyInProgressBody(completed),
      tone: HabitStatsInsightTone.positive,
    );
  } else if (progressRatio < 1.0) {
    baseInsight = HabitStatsInsight(
      title: l10n.habitStatsInsightMonthlyStrongTitle,
      body: l10n.habitStatsInsightMonthlyStrongBody(completed, objective),
      tone: HabitStatsInsightTone.positive,
    );
  } else {
    baseInsight = HabitStatsInsight(
      title: l10n.habitStatsInsightMonthlyGoalCompletedTitle,
      body: l10n.habitStatsInsightMonthlyGoalCompletedBody,
      tone: HabitStatsInsightTone.positive,
    );
  }

  final suffixes = <String>[];
  final bestMoment = monthlyData.bestMoment;
  if (bestMoment != null &&
      bestMoment.slot != HabitStatsBestMomentSlot.unknown) {
    final momentLabel = habitStatsBestMomentLabelForSlot(
      l10n: l10n,
      slot: bestMoment.slot,
    );
    suffixes.add(l10n.habitStatsInsightMonthlyBestMomentBody(momentLabel));
  }

  final comparisonSentence = _comparisonSentence(
    l10n,
    monthlyComparisonData,
  );
  if (comparisonSentence != null) {
    suffixes.add(comparisonSentence);
  }

  if (suffixes.isEmpty) return baseInsight;

  return HabitStatsInsight(
    title: baseInsight.title,
    body: '${baseInsight.body} ${suffixes.join(' ')}',
    tone: baseInsight.tone,
  );
}

String? _comparisonSentence(
  AppLocalizations l10n,
  HabitStatsMonthlyComparisonData? comparison,
) {
  if (comparison == null ||
      !comparison.hasComparison ||
      comparison.trend == HabitStatsComparisonTrend.unavailable) {
    return null;
  }

  switch (comparison.trend) {
    case HabitStatsComparisonTrend.better:
      return l10n.habitStatsInsightMonthlyComparisonBetter;
    case HabitStatsComparisonTrend.same:
      return l10n.habitStatsInsightMonthlyComparisonSame;
    case HabitStatsComparisonTrend.worse:
      return l10n.habitStatsInsightMonthlyComparisonWorse;
    case HabitStatsComparisonTrend.unavailable:
      return null;
  }
}
