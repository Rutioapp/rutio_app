import '../../../../../l10n/gen/app_localizations.dart';
import 'habit_stats_models.dart';

const double _yearComparisonTrendThreshold = 0.15;
const double _yearComparisonAverageThreshold = 0.12;
const int _yearStrongMonthPctThreshold = 75;
const int _yearLowMonthPctThreshold = 30;
const int _yearIrregularSpreadThreshold = 35;

class HabitStatsYearComparisonCopy {
  final String title;
  final String mainText;

  const HabitStatsYearComparisonCopy({
    required this.title,
    required this.mainText,
  });
}

HabitStatsYearComparison resolveHabitStatsYearComparison({
  required List<HabitStatsYearMonthSummary> monthSummaries,
  HabitStatsYearActivitySummary? activitySummary,
}) {
  final validMonths = monthSummaries
      .where(
        (month) =>
            month.status != HabitStatsYearMonthStatus.future &&
            month.status != HabitStatsYearMonthStatus.unavailable &&
            month.performancePct != null,
      )
      .toList(growable: false)
    ..sort((a, b) => a.month.compareTo(b.month));
  final activeMonths = validMonths
      .where((month) => month.status.hasActivity)
      .toList(growable: false);

  if (validMonths.isEmpty || activeMonths.isEmpty) {
    return const HabitStatsYearComparison(
      state: HabitStatsYearComparisonState.noData,
    );
  }
  if (activeMonths.length < 2) {
    final onlyMonthPct = activeMonths.first.performancePct;
    return HabitStatsYearComparison(
      state: HabitStatsYearComparisonState.starting,
      annualAvgPct: onlyMonthPct,
      latestMonthPct: onlyMonthPct,
    );
  }

  final sortedActive = [...activeMonths]..sort((a, b) => a.month - b.month);
  final splitIndex = sortedActive.length ~/ 2;
  final earlier = sortedActive.take(splitIndex).toList(growable: false);
  final later = sortedActive.skip(splitIndex).toList(growable: false);
  final annualAvg = _averagePerformancePct(sortedActive);
  final latestPct = sortedActive.last.performancePct;

  if (earlier.isEmpty || later.isEmpty) {
    return HabitStatsYearComparison(
      state: HabitStatsYearComparisonState.stable,
      annualAvgPct: annualAvg,
      latestMonthPct: latestPct,
    );
  }

  final earlierAvg = _averagePerformancePct(earlier);
  final laterAvg = _averagePerformancePct(later);
  final difference = (laterAvg - earlierAvg) / 100;

  final trend = activitySummary?.trend;
  if (difference >= _yearComparisonTrendThreshold ||
      trend == HabitStatsYearTrend.improving) {
    return HabitStatsYearComparison(
      state: HabitStatsYearComparisonState.improving,
      earlierAvgPct: earlierAvg,
      laterAvgPct: laterAvg,
      annualAvgPct: annualAvg,
      latestMonthPct: latestPct,
    );
  }
  if (difference <= -_yearComparisonTrendThreshold ||
      trend == HabitStatsYearTrend.declining) {
    return HabitStatsYearComparison(
      state: HabitStatsYearComparisonState.declining,
      earlierAvgPct: earlierAvg,
      laterAvgPct: laterAvg,
      annualAvgPct: annualAvg,
      latestMonthPct: latestPct,
    );
  }

  final latestVsAverage = ((latestPct ?? annualAvg) - annualAvg) / 100;
  if (latestVsAverage >= _yearComparisonAverageThreshold) {
    return HabitStatsYearComparison(
      state: HabitStatsYearComparisonState.aboveAverage,
      earlierAvgPct: earlierAvg,
      laterAvgPct: laterAvg,
      annualAvgPct: annualAvg,
      latestMonthPct: latestPct,
    );
  }
  if (latestVsAverage <= -_yearComparisonAverageThreshold) {
    return HabitStatsYearComparison(
      state: HabitStatsYearComparisonState.belowAverage,
      earlierAvgPct: earlierAvg,
      laterAvgPct: laterAvg,
      annualAvgPct: annualAvg,
      latestMonthPct: latestPct,
    );
  }

  return HabitStatsYearComparison(
    state: HabitStatsYearComparisonState.stable,
    earlierAvgPct: earlierAvg,
    laterAvgPct: laterAvg,
    annualAvgPct: annualAvg,
    latestMonthPct: latestPct,
  );
}

HabitStatsYearComparisonCopy resolveHabitStatsYearComparisonCopy(
  AppLocalizations l10n,
  HabitStatsYearComparison comparison,
) {
  final title = l10n.habitStatsYearlyComparisonTitle;
  switch (comparison.state) {
    case HabitStatsYearComparisonState.improving:
      return HabitStatsYearComparisonCopy(
        title: title,
        mainText: l10n.habitStatsYearlyComparisonImproving,
      );
    case HabitStatsYearComparisonState.stable:
      return HabitStatsYearComparisonCopy(
        title: title,
        mainText: l10n.habitStatsYearlyComparisonStable,
      );
    case HabitStatsYearComparisonState.declining:
      return HabitStatsYearComparisonCopy(
        title: title,
        mainText: l10n.habitStatsYearlyComparisonDeclining,
      );
    case HabitStatsYearComparisonState.aboveAverage:
      return HabitStatsYearComparisonCopy(
        title: title,
        mainText: l10n.habitStatsYearlyComparisonAboveAverage,
      );
    case HabitStatsYearComparisonState.belowAverage:
      return HabitStatsYearComparisonCopy(
        title: title,
        mainText: l10n.habitStatsYearlyComparisonBelowAverage,
      );
    case HabitStatsYearComparisonState.starting:
      return HabitStatsYearComparisonCopy(
        title: title,
        mainText: l10n.habitStatsYearlyComparisonStarting,
      );
    case HabitStatsYearComparisonState.noData:
      return HabitStatsYearComparisonCopy(
        title: title,
        mainText: l10n.habitStatsYearlyComparisonNoData,
      );
  }
}

HabitStatsYearInsightResult resolveHabitStatsYearInsight(
  AppLocalizations l10n, {
  required List<HabitStatsYearMonthSummary> monthSummaries,
  required HabitStatsYearComparison comparison,
}) {
  final validMonths = monthSummaries
      .where(
        (month) =>
            month.status != HabitStatsYearMonthStatus.future &&
            month.status != HabitStatsYearMonthStatus.unavailable &&
            month.performancePct != null,
      )
      .toList(growable: false);
  final activeMonths = validMonths
      .where((month) => month.status.hasActivity)
      .toList(growable: false);

  if (validMonths.isEmpty) {
    return HabitStatsYearInsightResult(
      state: HabitStatsYearInsightState.noData,
      insight: HabitStatsInsight(
        title: l10n.habitStatsYearlyInsightNoDataTitle,
        body: l10n.habitStatsYearlyInsightNoDataBody,
        tone: HabitStatsInsightTone.neutral,
      ),
    );
  }
  if (activeMonths.isEmpty) {
    return HabitStatsYearInsightResult(
      state: HabitStatsYearInsightState.quietYear,
      insight: HabitStatsInsight(
        title: l10n.habitStatsYearlyInsightQuietTitle,
        body: l10n.habitStatsYearlyInsightQuietBody,
        tone: HabitStatsInsightTone.paused,
      ),
    );
  }
  if (activeMonths.length == 1) {
    return HabitStatsYearInsightResult(
      state: HabitStatsYearInsightState.startingYear,
      insight: HabitStatsInsight(
        title: l10n.habitStatsYearlyInsightStartingTitle,
        body: l10n.habitStatsYearlyInsightStartingBody,
        tone: HabitStatsInsightTone.neutral,
      ),
    );
  }

  final avg = _averagePerformancePct(activeMonths);
  final strongMonths = activeMonths
      .where((month) =>
          (month.performancePct ?? 0) >= _yearStrongMonthPctThreshold)
      .length;
  final lowMonths = activeMonths
      .where(
          (month) => (month.performancePct ?? 0) <= _yearLowMonthPctThreshold)
      .length;
  final maxPct = activeMonths
      .map((month) => month.performancePct ?? 0)
      .fold<int>(0, (best, value) => value > best ? value : best);
  final minPct = activeMonths
      .map((month) => month.performancePct ?? 100)
      .fold<int>(100, (weakest, value) => value < weakest ? value : weakest);
  final spread = maxPct - minPct;

  if (avg >= _yearStrongMonthPctThreshold &&
      strongMonths >= ((activeMonths.length / 2).ceil())) {
    return HabitStatsYearInsightResult(
      state: HabitStatsYearInsightState.strongYear,
      insight: HabitStatsInsight(
        title: l10n.habitStatsYearlyInsightStrongTitle,
        body: l10n.habitStatsYearlyInsightStrongBody,
        tone: HabitStatsInsightTone.positive,
      ),
    );
  }
  if (comparison.state == HabitStatsYearComparisonState.improving) {
    return HabitStatsYearInsightResult(
      state: HabitStatsYearInsightState.improvingYear,
      insight: HabitStatsInsight(
        title: l10n.habitStatsYearlyInsightImprovingTitle,
        body: l10n.habitStatsYearlyInsightImprovingBody,
        tone: HabitStatsInsightTone.positive,
      ),
    );
  }
  if (comparison.state == HabitStatsYearComparisonState.declining ||
      spread >= _yearIrregularSpreadThreshold ||
      lowMonths > (activeMonths.length / 2).floor()) {
    return HabitStatsYearInsightResult(
      state: HabitStatsYearInsightState.irregularYear,
      insight: HabitStatsInsight(
        title: l10n.habitStatsYearlyInsightIrregularTitle,
        body: l10n.habitStatsYearlyInsightIrregularBody,
        tone: HabitStatsInsightTone.recovery,
      ),
    );
  }
  if (avg < _yearLowMonthPctThreshold) {
    return HabitStatsYearInsightResult(
      state: HabitStatsYearInsightState.quietYear,
      insight: HabitStatsInsight(
        title: l10n.habitStatsYearlyInsightQuietTitle,
        body: l10n.habitStatsYearlyInsightQuietBody,
        tone: HabitStatsInsightTone.paused,
      ),
    );
  }

  return HabitStatsYearInsightResult(
    state: HabitStatsYearInsightState.steadyYear,
    insight: HabitStatsInsight(
      title: l10n.habitStatsYearlyInsightSteadyTitle,
      body: l10n.habitStatsYearlyInsightSteadyBody,
      tone: HabitStatsInsightTone.neutral,
    ),
  );
}

int _averagePerformancePct(List<HabitStatsYearMonthSummary> months) {
  if (months.isEmpty) return 0;
  final total = months.fold<int>(0, (sum, month) {
    final value = month.performancePct;
    return sum + (value == null || value < 0 ? 0 : value);
  });
  return (total / months.length).round().clamp(0, 100);
}
