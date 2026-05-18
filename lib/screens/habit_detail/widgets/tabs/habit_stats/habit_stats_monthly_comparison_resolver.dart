import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../../l10n/l10n.dart';
import 'habit_stats_models.dart';

class HabitStatsMonthlyComparisonCopy {
  final String title;
  final String mainText;
  final String secondaryText;

  const HabitStatsMonthlyComparisonCopy({
    required this.title,
    required this.mainText,
    required this.secondaryText,
  });
}

HabitStatsMonthlyComparisonCopy resolveHabitStatsMonthlyComparisonCopy(
  AppLocalizations l10n,
  HabitStatsMonthlyComparisonData comparison,
) {
  final title = l10n.habitStatsMonthlyComparisonTitle;

  if (!comparison.hasComparison ||
      comparison.trend == HabitStatsComparisonTrend.unavailable) {
    return HabitStatsMonthlyComparisonCopy(
      title: title,
      mainText: l10n.habitStatsMonthlyComparisonUnavailableTitle,
      secondaryText: l10n.habitStatsMonthlyComparisonUnavailableBody,
    );
  }

  if (comparison.trend == HabitStatsComparisonTrend.better) {
    return HabitStatsMonthlyComparisonCopy(
      title: title,
      mainText: l10n.habitStatsMonthlyComparisonBetterTitle,
      secondaryText:
          l10n.habitStatsMonthlyComparisonBetterDelta(comparison.delta),
    );
  }

  if (comparison.trend == HabitStatsComparisonTrend.worse) {
    return HabitStatsMonthlyComparisonCopy(
      title: title,
      mainText: l10n.habitStatsMonthlyComparisonWorseTitle,
      secondaryText: l10n.habitStatsMonthlyComparisonWorseDelta(
        comparison.delta.abs(),
      ),
    );
  }

  return HabitStatsMonthlyComparisonCopy(
    title: title,
    mainText: l10n.habitStatsMonthlyComparisonSameTitle,
    secondaryText: l10n.habitStatsMonthlyComparisonSameDelta,
  );
}
