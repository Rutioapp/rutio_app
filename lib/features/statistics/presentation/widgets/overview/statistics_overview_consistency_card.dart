import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';

import '../../../domain/statistics_models.dart';
import 'statistics_overview_section_card.dart';

class StatisticsOverviewConsistencyCard extends StatelessWidget {
  const StatisticsOverviewConsistencyCard({
    super.key,
    required this.summary,
  });

  final StatisticsOverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = summary.scheduledDays == 0
        ? 0.0
        : (summary.completedDays / summary.scheduledDays).clamp(0.0, 1.0);

    return StatisticsOverviewSectionCard(
      title: l10n.statisticsV2OverviewConsistencyTitle,
      subtitle: l10n.statisticsV2OverviewConsistencySubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statisticsV2OverviewConsistencyFraction(
              summary.completedDays,
              summary.scheduledDays,
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: Colors.black.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4F7D68),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.statisticsV2OverviewOverallConsistencyValue(
              summary.overallConsistencyPct,
            ),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.64),
            ),
          ),
        ],
      ),
    );
  }
}
