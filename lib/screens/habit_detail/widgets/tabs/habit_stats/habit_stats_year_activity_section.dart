import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_helpers.dart';
import 'habit_stats_models.dart';
import 'habit_stats_section_card.dart';

class HabitStatsYearActivitySection extends StatelessWidget {
  final List<HabitStatsYearMonthSummary> monthSummaries;
  final HabitStatsYearActivitySummary? activitySummary;

  const HabitStatsYearActivitySection({
    super.key,
    required this.monthSummaries,
    this.activitySummary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = activitySummary ??
        resolveHabitStatsYearActivitySummary(
          monthSummaries: monthSummaries,
        );

    return HabitStatsSectionCard(
      key: const Key('habit_stats_year_activity_card'),
      title: l10n.yearlyActivityTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.yearlyActivitySubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  height: 1.35,
                  color: const Color(0xFF746A60),
                ),
          ),
          const SizedBox(height: 10),
          _YearActivityRow(
            label: l10n.yearlyActivityBestMonth,
            value: _monthPerformanceLabel(context, summary.bestMonth),
          ),
          const SizedBox(height: 7),
          _YearActivityRow(
            label: l10n.yearlyActivityWeakestMonth,
            value: _monthPerformanceLabel(context, summary.weakestMonth),
          ),
          const SizedBox(height: 7),
          _YearActivityRow(
            label: l10n.yearlyActivityActiveMonths,
            value: l10n.yearlyActivityActiveMonthsValue(summary.activeMonths),
          ),
          const SizedBox(height: 7),
          _YearActivityRow(
            label: l10n.yearlyActivityTrend,
            value: _trendLabel(l10n, summary.trend),
          ),
        ],
      ),
    );
  }

  String _monthPerformanceLabel(
    BuildContext context,
    HabitStatsYearMonthSummary? month,
  ) {
    if (month == null || month.performancePct == null) {
      return '\u2014';
    }
    final l10n = context.l10n;
    final monthLabel = _capitalizeFirst(l10n.monthShort(month.month));
    return '$monthLabel ${String.fromCharCode(0x00B7)} ${month.performancePct}%';
  }

  String _trendLabel(dynamic l10n, HabitStatsYearTrend trend) {
    switch (trend) {
      case HabitStatsYearTrend.improving:
        return l10n.yearlyActivityTrendImproving;
      case HabitStatsYearTrend.stable:
        return l10n.yearlyActivityTrendStable;
      case HabitStatsYearTrend.declining:
        return l10n.yearlyActivityTrendDeclining;
      case HabitStatsYearTrend.starting:
        return l10n.yearlyActivityTrendStarting;
      case HabitStatsYearTrend.noData:
        return l10n.yearlyActivityTrendNoData;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
}

class _YearActivityRow extends StatelessWidget {
  final String label;
  final String value;

  const _YearActivityRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13.2,
                  height: 1.2,
                  color: const Color(0xFF746A60),
                ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13.6,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2F251C),
                ),
          ),
        ),
      ],
    );
  }
}
