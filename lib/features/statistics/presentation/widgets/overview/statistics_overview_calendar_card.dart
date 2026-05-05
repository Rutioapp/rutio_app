import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/widgets/stats/stats_month_heatmap.dart';

import '../../../domain/statistics_models.dart';
import 'statistics_overview_section_card.dart';

class StatisticsOverviewCalendarCard extends StatelessWidget {
  const StatisticsOverviewCalendarCard({
    super.key,
    required this.summary,
  });

  final StatisticsOverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StatisticsOverviewSectionCard(
      title: l10n.statisticsV2OverviewCalendarTitle,
      subtitle: l10n.statisticsV2OverviewCalendarSubtitle,
      child: summary.totalHabits == 0
          ? Text(
              l10n.statisticsV2OverviewCalendarEmpty,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.56),
              ),
            )
          : StatsMonthHeatmap(
              month: summary.range.end,
              accent: const Color(0xFF507865),
              intensityByDay: summary.monthConsistencyByDay,
            ),
    );
  }
}
