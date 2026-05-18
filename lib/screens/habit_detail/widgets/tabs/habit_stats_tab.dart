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
import 'habit_stats/habit_stats_monthly_activity_grid.dart';
import 'habit_stats/habit_stats_monthly_comparison_card.dart';
import 'habit_stats/habit_stats_monthly_comparison_resolver.dart';
import 'habit_stats/habit_stats_monthly_insight_resolver.dart';
import 'habit_stats/habit_stats_period_selector.dart';
import 'habit_stats/habit_stats_section_card.dart';
import 'habit_stats/habit_stats_weekly_comparison_card.dart';
import 'habit_stats/habit_stats_year_section.dart';

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
  static const _sectionSpacing = 8.0;
  static const _lowerSectionSpacing = 8.0;

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
        const SizedBox(height: _sectionSpacing),
        HabitStatsPeriodSelector(
          selectedPeriod: _selectedPeriod,
          onPeriodChanged: (period) => setState(() => _selectedPeriod = period),
        ),
        ..._buildPeriodContent(shellData),
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

  List<Widget> _buildPeriodContent(HabitStatsShellData shellData) {
    switch (_selectedPeriod) {
      case HabitStatsPeriod.month:
        return _buildMonthlyContent(shellData);
      case HabitStatsPeriod.week:
        return _buildWeeklyContent(shellData);
      case HabitStatsPeriod.year:
        return _buildYearlyContent(shellData);
    }
  }

  List<Widget> _buildWeeklyContent(HabitStatsShellData shellData) {
    return [
      const SizedBox(height: _sectionSpacing),
      HabitStatsHeroCard(
        shellData: shellData,
        familyColor: widget.familyColor,
      ),
      const SizedBox(height: _sectionSpacing),
      HabitStatsSectionCard(
        title: context.l10n.habitStatsTabLastDaysTitle(7),
        child: shellData.isCheckHabit
            ? HabitStatsLast7DaysCard(days: shellData.last7Days)
            : HabitStatsCountLast7DaysChart(days: shellData.countLast7Days),
      ),
      const SizedBox(height: _sectionSpacing),
      _buildWeeklyMetricGrid(shellData),
      const SizedBox(height: _lowerSectionSpacing),
      if (shellData.isCheckHabit)
        HabitStatsWeeklyComparisonCard(deltaPct: shellData.weeklyComparisonDeltaPct),
      if (!shellData.isCheckHabit) HabitStatsCountBestDayCard(shellData: shellData),
      const SizedBox(height: _lowerSectionSpacing),
      HabitStatsInsightCard(shellData: shellData),
    ];
  }

  List<Widget> _buildMonthlyContent(HabitStatsShellData shellData) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month, 1);
    final monthlyData = shellData.isCheckHabit
        ? buildHabitStatsMonthlyDataForCheck(
            habit: widget.habit,
            month: month,
            now: now,
            countsByDay: shellData.countsByDay,
            skipsByDay: shellData.skipsByDay,
            completionTimesByDay: shellData.completionTimesByDay,
          )
        : null;
    final monthlyComparisonData = shellData.isCheckHabit
        ? buildHabitStatsMonthlyComparisonDataForCheck(
            habit: widget.habit,
            month: month,
            now: now,
            countsByDay: shellData.countsByDay,
            skipsByDay: shellData.skipsByDay,
          )
        : null;
    final monthlyComparisonCopy = monthlyComparisonData == null
        ? null
        : resolveHabitStatsMonthlyComparisonCopy(
            context.l10n,
            monthlyComparisonData,
          );
    final monthlyInsight = shellData.isCheckHabit && monthlyData != null
        ? resolveHabitStatsMonthlyInsight(
            context.l10n,
            monthlyData: monthlyData,
            monthlyComparisonData: monthlyComparisonData,
          )
        : null;

    return [
      const SizedBox(height: _sectionSpacing),
      HabitStatsHeroCard(
        shellData: shellData,
        familyColor: widget.familyColor,
      ),
      const SizedBox(height: _sectionSpacing),
      _buildMonthlyMetricGrid(shellData, monthlyData: monthlyData),
      const SizedBox(height: _sectionSpacing),
      if (shellData.isCheckHabit && monthlyData != null)
        HabitStatsMonthlyActivityGrid(
          monthlyData: monthlyData,
          month: month,
        ),
      const SizedBox(height: _lowerSectionSpacing),
      if (shellData.isCheckHabit &&
          monthlyComparisonData != null &&
          monthlyComparisonCopy != null)
        HabitStatsMonthlyComparisonCard(
          comparison: monthlyComparisonData,
          copy: monthlyComparisonCopy,
        ),
      const SizedBox(height: _lowerSectionSpacing),
      if (monthlyInsight != null)
        HabitStatsInsightCard(
          shellData: shellData,
          insight: monthlyInsight,
          adaptiveLayout: true,
        ),
    ];
  }

  List<Widget> _buildYearlyContent(HabitStatsShellData shellData) {
    return [
      const SizedBox(height: _sectionSpacing),
      HabitStatsHeroCard(
        shellData: shellData,
        familyColor: widget.familyColor,
      ),
      const SizedBox(height: _sectionSpacing),
      const HabitStatsYearSection(),
    ];
  }

  Widget _buildWeeklyMetricGrid(HabitStatsShellData shellData) {
    return HabitStatsMetricGrid(shellData: shellData);
  }

  Widget _buildMonthlyMetricGrid(
    HabitStatsShellData shellData, {
    HabitStatsMonthlyData? monthlyData,
  }) {
    if (!shellData.isCheckHabit) {
      return HabitStatsMetricGrid(shellData: shellData);
    }

    final resolvedMonthlyData = monthlyData ??
        buildHabitStatsMonthlyDataForCheck(
          habit: widget.habit,
          month: DateTime(DateTime.now().year, DateTime.now().month, 1),
          now: DateTime.now(),
          countsByDay: shellData.countsByDay,
          skipsByDay: shellData.skipsByDay,
          completionTimesByDay: shellData.completionTimesByDay,
        );
    final objective = buildHabitStatsMonthlyObjectiveForCheck(
      monthlyData: resolvedMonthlyData,
    );
    // Metric card consistency is based on full monthly objective to match the
    // Objective and Completed cards shown in this same monthly grid.
    final consistencyPct = buildHabitStatsMonthlyMetricCardConsistencyPct(
      monthlyData: resolvedMonthlyData,
    );
    final l10n = context.l10n;
    final objectiveUnit = resolvedMonthlyData.objectiveUnit == HabitStatsMonthlyObjectiveUnit.times
        ? l10n.habitStatsTimesUnitLabel(objective)
        : l10n.habitStatsDaysUnitLabel(objective);
    final bestMoment = resolvedMonthlyData.bestMoment;
    final bestMomentValue = bestMoment == null
        // TODO(phase-6): Replace this fallback once we add a dedicated monthly
        // insight resolver and product copy for sparse best-moment data.
        ? '—'
        : habitStatsBestMomentLabelForSlot(
            l10n: l10n,
            slot: bestMoment.slot,
          );

    return HabitStatsMetricGrid.custom(
      gridKey: const Key('habit_stats_monthly_check_metric_grid'),
      metrics: <HabitStatsMetricGridItem>[
        HabitStatsMetricGridItem(
          icon: Icons.gps_fixed_rounded,
          title: l10n.habitConfigGoalSection,
          value: '$objective $objectiveUnit',
          subtitle: l10n.habitStatsThisMonth,
          iconColor: const Color(0xFF5A3B23),
        ),
        HabitStatsMetricGridItem(
          icon: Icons.check_circle_outline_rounded,
          title: l10n.habitStatsMetricCompleted,
          value: '${resolvedMonthlyData.completedDays}/$objective',
          subtitle: l10n.habitStatsThisMonth,
          iconColor: const Color(0xFF5A3B23),
        ),
        HabitStatsMetricGridItem(
          icon: Icons.trending_up_rounded,
          title: l10n.habitStatsMetricConsistency,
          value: '$consistencyPct%',
          subtitle: l10n.habitStatsMonthlyConsistency,
          iconColor: const Color(0xFF5B975A),
          valueColor: const Color(0xFF4E7D35),
        ),
        HabitStatsMetricGridItem(
          icon: Icons.schedule_rounded,
          title: l10n.statisticsV3BestMomentCardTitle,
          value: bestMomentValue,
          subtitle: l10n.statisticsV3BestMomentSubtitle,
          iconColor: const Color(0xFF4E7D35),
          bestMomentSlot: bestMoment?.slot,
          useBestMomentVisual: bestMoment != null,
        ),
      ],
    );
  }
}
