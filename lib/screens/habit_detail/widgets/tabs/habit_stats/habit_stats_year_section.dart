import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_helpers.dart';
import 'habit_stats_insight_card.dart';
import 'habit_stats_models.dart';
import 'habit_stats_year_comparison_card.dart';
import 'habit_stats_year_activity_section.dart';
import 'habit_stats_year_insight_resolver.dart';
import 'habit_stats_year_month_grid.dart';
import 'habit_stats_section_card.dart';

class HabitStatsYearSection extends StatelessWidget {
  final HabitStatsShellData shellData;
  final int year;
  final List<HabitStatsYearMonthSummary> monthSummaries;
  final List<HabitStatsYearCalendarMonth> calendarMonths;
  final Color accentColor;

  const HabitStatsYearSection({
    super.key,
    required this.shellData,
    required this.year,
    required this.monthSummaries,
    required this.calendarMonths,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activitySummary = resolveHabitStatsYearActivitySummary(
      monthSummaries: monthSummaries,
    );
    final comparison = resolveHabitStatsYearComparison(
      monthSummaries: monthSummaries,
      activitySummary: activitySummary,
    );
    final comparisonCopy =
        resolveHabitStatsYearComparisonCopy(l10n, comparison);
    final yearlyInsight = resolveHabitStatsYearInsight(
      l10n,
      monthSummaries: monthSummaries,
      comparison: comparison,
    );

    return Column(
      children: [
        HabitStatsSectionCard(
          key: const Key('habit_stats_year_months_card'),
          title: l10n.habitStatsYearCalendarTitle,
          child: HabitStatsYearMonthGrid(
            year: year,
            months: calendarMonths,
            accentColor: accentColor,
          ),
        ),
        const SizedBox(height: 8),
        HabitStatsYearActivitySection(
          monthSummaries: monthSummaries,
          activitySummary: activitySummary,
        ),
        const SizedBox(height: 8),
        HabitStatsYearComparisonCard(
          comparison: comparison,
          copy: comparisonCopy,
        ),
        const SizedBox(height: 8),
        HabitStatsInsightCard(
          shellData: shellData,
          insight: yearlyInsight.insight,
          insightLabel: l10n.habitStatsYearlyInsightTitle,
          adaptiveLayout: true,
        ),
      ],
    );
  }
}
