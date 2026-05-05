import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/app_theme.dart';

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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD7E7F2), Color(0xFFF6F0E5), Color(0xFFE8EFE5)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.check_circle_rounded,
                    label: l10n.statisticsV2OverviewCompletedHabits,
                    value: summary.completedHabits.toString(),
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.local_fire_department_rounded,
                    label: l10n.statisticsV2OverviewHabitsWithProgress,
                    value: summary.habitsWithProgress.toString(),
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.auto_graph_rounded,
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
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.earth),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.serifFamily,
            fontSize: 33,
            height: 0.98,
            color: Colors.black.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.64),
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
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.64),
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
