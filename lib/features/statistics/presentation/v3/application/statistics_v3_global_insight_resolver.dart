import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_global_insight.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';

const int _minConsistencyForPositiveInsight = 72;
const int _minCompletionsForPositiveInsight = 3;
const int _minFamilyCompletionsForFeaturedInsight = 2;
const int _minMomentCompletionsForInsight = 2;
const int _maxConsistencyForLowActivityInsight = 35;
const int _maxCompletionsForLowActivityInsight = 1;

StatisticsV3GlobalInsight resolveStatisticsV3GlobalInsight(
  StatisticsV3ViewData viewData,
) {
  if (viewData.totalDays <= 0 || viewData.completedHabits <= 0) {
    return const StatisticsV3GlobalInsight(
      type: StatisticsV3GlobalInsightType.noData,
    );
  }

  final hasStrongConsistency =
      viewData.consistencyPct >= _minConsistencyForPositiveInsight &&
          viewData.completedHabits >= _minCompletionsForPositiveInsight;
  if (hasStrongConsistency) {
    return const StatisticsV3GlobalInsight(
      type: StatisticsV3GlobalInsightType.positiveConsistency,
    );
  }

  final topFamily = viewData.families.isEmpty ? null : viewData.families.first;
  if (topFamily != null &&
      topFamily.completedCount >= _minFamilyCompletionsForFeaturedInsight) {
    return StatisticsV3GlobalInsight(
      type: StatisticsV3GlobalInsightType.featuredFamily,
      familyName: topFamily.name,
    );
  }

  if (viewData.bestMoment.hasData &&
      viewData.bestMoment.count >= _minMomentCompletionsForInsight &&
      viewData.bestMoment.label.trim().isNotEmpty) {
    return StatisticsV3GlobalInsight(
      type: StatisticsV3GlobalInsightType.bestMoment,
      momentLabel: viewData.bestMoment.label.trim(),
      momentSlot: viewData.bestMoment.slot,
    );
  }

  if (viewData.consistencyPct <= _maxConsistencyForLowActivityInsight ||
      viewData.completedHabits <= _maxCompletionsForLowActivityInsight) {
    return const StatisticsV3GlobalInsight(
      type: StatisticsV3GlobalInsightType.lowActivity,
    );
  }

  return const StatisticsV3GlobalInsight(
    type: StatisticsV3GlobalInsightType.positiveConsistency,
  );
}
