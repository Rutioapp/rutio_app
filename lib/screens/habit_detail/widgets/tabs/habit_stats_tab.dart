import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import 'habit_stats/habit_stats_header.dart';
import 'habit_stats/habit_stats_helpers.dart';
import 'habit_stats/habit_stats_hero_card.dart';
import 'habit_stats/habit_stats_insight_card.dart';
import 'habit_stats/habit_stats_count_best_day_card.dart';
import 'habit_stats/habit_stats_count_last7_days_chart.dart';
import 'habit_stats/habit_stats_last7_days_card.dart';
import 'habit_stats/habit_stats_metric_grid.dart';
import 'habit_stats/habit_stats_models.dart';
import 'habit_stats/habit_stats_period_selector.dart';
import 'habit_stats/habit_stats_section_card.dart';
import 'habit_stats/habit_stats_weekly_comparison_card.dart';

class HabitStatsTab extends StatefulWidget {
  final dynamic habit;
  final Color familyColor;
  final bool scrollable;
  final bool showHeaderControls;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMorePressed;

  const HabitStatsTab({
    super.key,
    required this.habit,
    required this.familyColor,
    this.scrollable = true,
    this.showHeaderControls = false,
    this.onBackPressed,
    this.onMorePressed,
  });

  @override
  State<HabitStatsTab> createState() => _HabitStatsTabState();
}

class _HabitStatsTabState extends State<HabitStatsTab> {
  HabitStatsPeriod _selectedPeriod = HabitStatsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final shellData = buildHabitStatsShellData(
      context,
      widget.habit,
      period: _selectedPeriod,
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HabitStatsHeader(
          title: shellData.title,
          familyAndObjective: shellData.familyAndObjective,
          familyColor: widget.familyColor,
          showControls: widget.showHeaderControls,
          onBackPressed: widget.onBackPressed,
          onMorePressed: widget.onMorePressed,
        ),
        const SizedBox(height: 8),
        HabitStatsPeriodSelector(
          selectedPeriod: _selectedPeriod,
          onPeriodChanged: (period) => setState(() => _selectedPeriod = period),
        ),
        const SizedBox(height: 8),
        HabitStatsHeroCard(
          shellData: shellData,
          familyColor: widget.familyColor,
        ),
        const SizedBox(height: 8),
        HabitStatsSectionCard(
          title: context.l10n.habitStatsTabLastDaysTitle(7),
          child: shellData.isCheckHabit
              ? HabitStatsLast7DaysCard(days: shellData.last7Days)
              : HabitStatsCountLast7DaysChart(days: shellData.countLast7Days),
        ),
        const SizedBox(height: 8),
        HabitStatsMetricGrid(shellData: shellData),
        const SizedBox(height: 8),
        if (shellData.isCheckHabit)
          HabitStatsWeeklyComparisonCard(deltaPct: shellData.weeklyComparisonDeltaPct),
        if (!shellData.isCheckHabit) HabitStatsCountBestDayCard(shellData: shellData),
        const SizedBox(height: 8),
        HabitStatsInsightCard(shellData: shellData),
      ],
    );

    const horizontalPadding = 15.0;
    final topPadding = widget.showHeaderControls ? 4.0 : 10.0;
    final child = widget.scrollable
        ? SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontalPadding, topPadding, horizontalPadding, 16),
            child: content,
          )
        : Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, topPadding, horizontalPadding, 16),
            child: content,
          );
    return ColoredBox(
      color: const Color(0xFFFAF6EF),
      child: SafeArea(
        top: widget.showHeaderControls,
        bottom: false,
        child: child,
      ),
    );
  }
}
