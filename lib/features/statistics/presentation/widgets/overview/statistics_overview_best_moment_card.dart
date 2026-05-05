import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/widgets/stats/stats_best_time_of_day_card.dart';

import '../../../domain/statistics_models.dart';
import 'statistics_overview_section_card.dart';

class StatisticsOverviewBestMomentCard extends StatelessWidget {
  const StatisticsOverviewBestMomentCard({
    super.key,
    required this.summary,
  });

  final StatisticsOverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bestLabel = _bestMomentLabel(context);
    final title = bestLabel == null
        ? l10n.statisticsV2OverviewBestMomentTitle
        : l10n.statisticsV2OverviewBestMomentTitleWith(bestLabel);

    return StatisticsOverviewSectionCard(
      title: title,
      subtitle: l10n.statisticsV2OverviewBestMomentSubtitle,
      child: summary.hasBestMomentData
          ? StatsBestTimeOfDayCard(
              accent: const Color(0xFF4A7A64),
              morningPct: summary.bestMomentPercents['morning'] ?? 0,
              afternoonPct: summary.bestMomentPercents['afternoon'] ?? 0,
              eveningPct: summary.bestMomentPercents['evening'] ?? 0,
              nightPct: summary.bestMomentPercents['night'] ?? 0,
            )
          : Text(
              l10n.statisticsV2OverviewBestMomentEmpty,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.56),
              ),
            ),
    );
  }

  String? _bestMomentLabel(BuildContext context) {
    final key = summary.bestMomentKey;
    if (key == null || key.isEmpty) return null;
    return context.l10n.habitStatsTimeSlot(key);
  }
}
