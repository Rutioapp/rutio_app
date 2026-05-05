import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';

import '../../../domain/statistics_models.dart';
import '../../../domain/statistics_period.dart';
import 'statistics_overview_section_card.dart';

class StatisticsOverviewSummaryCard extends StatelessWidget {
  const StatisticsOverviewSummaryCard({
    super.key,
    required this.summary,
  });

  final StatisticsOverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StatisticsOverviewSectionCard(
      title: l10n.statisticsV2OverviewSummaryTitle,
      subtitle: summary.period.overviewSubtitle(context),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: l10n.statisticsV2OverviewCompletedHabits,
                  value: summary.completedHabits.toString(),
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: l10n.statisticsV2OverviewHabitsWithProgress,
                  value: summary.habitsWithProgress.toString(),
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: l10n.statisticsV2OverviewOverallConsistency,
                  value: '${summary.overallConsistencyPct}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InlineMetric(
                  label: l10n.statisticsV2OverviewTotalHabits,
                  value: summary.totalHabits.toString(),
                ),
              ),
              Expanded(
                child: _InlineMetric(
                  label: l10n.statisticsV2OverviewFamilies,
                  value: summary.totalFamilies.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.58),
          ),
        ),
      ],
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.58),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
