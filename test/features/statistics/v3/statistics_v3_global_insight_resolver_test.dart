import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/statistics/presentation/v3/application/statistics_v3_global_insight_resolver.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_global_insight.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';

void main() {
  group('resolveStatisticsV3GlobalInsight', () {
    test('returns empty-state insight when there is not enough data', () {
      final result = resolveStatisticsV3GlobalInsight(
        _viewData(totalDays: 0, completedHabits: 0, consistencyPct: 0),
      );

      expect(result.type, StatisticsV3GlobalInsightType.noData);
    });

    test('returns positive consistency insight when consistency is strong', () {
      final result = resolveStatisticsV3GlobalInsight(
        _viewData(totalDays: 10, completedHabits: 8, consistencyPct: 80),
      );

      expect(result.type, StatisticsV3GlobalInsightType.positiveConsistency);
    });

    test('returns featured family insight when one family stands out', () {
      final result = resolveStatisticsV3GlobalInsight(
        _viewData(
          totalDays: 10,
          completedHabits: 4,
          consistencyPct: 55,
          families: const [
            StatisticsV3FamilyItem(
              name: 'Mind',
              emoji: '*',
              color: Color(0xFF72A481),
              completedCount: 3,
            ),
          ],
        ),
      );

      expect(result.type, StatisticsV3GlobalInsightType.featuredFamily);
      expect(result.familyName, 'Mind');
    });

    test('returns best moment insight when family is not yet featured', () {
      final result = resolveStatisticsV3GlobalInsight(
        _viewData(
          totalDays: 10,
          completedHabits: 3,
          consistencyPct: 45,
          families: const [
            StatisticsV3FamilyItem(
              name: 'Mind',
              emoji: '*',
              color: Color(0xFF72A481),
              completedCount: 1,
            ),
          ],
          bestMoment: const StatisticsV3BestMomentInsight(
            hasData: true,
            slot: StatisticsV3BestMomentSlot.morning,
            label: 'Morning',
            count: 2,
          ),
        ),
      );

      expect(result.type, StatisticsV3GlobalInsightType.bestMoment);
      expect(result.momentLabel, 'Morning');
      expect(result.momentSlot, StatisticsV3BestMomentSlot.morning);
    });
  });
}

StatisticsV3ViewData _viewData({
  required int totalDays,
  required int completedHabits,
  required int consistencyPct,
  List<StatisticsV3FamilyItem> families = const [],
  StatisticsV3BestMomentInsight bestMoment =
      const StatisticsV3BestMomentInsight(
    hasData: false,
    slot: StatisticsV3BestMomentSlot.morning,
    label: '',
    count: 0,
  ),
}) {
  return StatisticsV3ViewData(
    totalDays: totalDays,
    completedHabits: completedHabits,
    xpGained: 0,
    amberGained: 0,
    activeDays: 0,
    consistencyPct: consistencyPct,
    families: families,
    bestMoment: bestMoment,
    highlightedHabits: const [],
    weeklyActivity: const [],
    monthlyCalendarDays: const [],
    yearlyConsistencyMonths: const [],
    weeklyImprovement: const StatisticsV3WeeklyImprovementData(
      hasComparison: false,
      currentWeekPercentage: 0,
      previousWeekPercentage: 0,
      deltaPercentage: 0,
    ),
    rewardBreakdown: const StatisticsV3RewardBreakdown(rows: []),
  );
}
