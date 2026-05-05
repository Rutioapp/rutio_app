import 'package:flutter/material.dart';

import '../../domain/statistics_models.dart';
import 'overview/statistics_overview_activity_card.dart';
import 'overview/statistics_overview_best_moment_card.dart';
import 'overview/statistics_overview_calendar_card.dart';
import 'overview/statistics_overview_consistency_card.dart';
import 'overview/statistics_overview_families_card.dart';
import 'overview/statistics_overview_summary_card.dart';
import 'overview/statistics_overview_top_habits_card.dart';

class StatisticsOverviewTab extends StatelessWidget {
  const StatisticsOverviewTab({
    super.key,
    required this.summary,
  });

  final StatisticsOverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        StatisticsOverviewSummaryCard(summary: summary),
        const SizedBox(height: 12),
        StatisticsOverviewConsistencyCard(summary: summary),
        const SizedBox(height: 12),
        StatisticsOverviewActivityCard(summary: summary),
        const SizedBox(height: 12),
        StatisticsOverviewFamiliesCard(summary: summary),
        const SizedBox(height: 12),
        StatisticsOverviewTopHabitsCard(summary: summary),
        const SizedBox(height: 12),
        StatisticsOverviewBestMomentCard(summary: summary),
        const SizedBox(height: 12),
        StatisticsOverviewCalendarCard(summary: summary),
      ],
    );
  }
}
