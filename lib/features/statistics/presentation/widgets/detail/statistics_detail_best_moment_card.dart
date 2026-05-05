import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/widgets/stats/helpers/stats_card_surface.dart';
import 'package:rutio/widgets/stats/stats_best_time_of_day_card.dart';

class StatisticsDetailBestMomentCard extends StatelessWidget {
  const StatisticsDetailBestMomentCard({
    super.key,
    required this.accent,
    required this.hasData,
    required this.percents,
  });

  final Color accent;
  final bool hasData;
  final Map<String, int> percents;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: StatsCardSurface.decoration(context),
      padding: StatsCardSurface.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statisticsV2DetailBestMomentTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'DMSerifDisplay',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.statisticsV2DetailBestMomentSubtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.56),
            ),
          ),
          const SizedBox(height: 12),
          if (!hasData)
            Text(
              l10n.statisticsV2DetailBestMomentEmpty,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: Colors.black.withValues(alpha: 0.62),
              ),
            )
          else
            StatsBestTimeOfDayCard(
              accent: accent,
              morningPct: percents['morning'] ?? 0,
              afternoonPct: percents['afternoon'] ?? 0,
              eveningPct: percents['evening'] ?? 0,
              nightPct: percents['night'] ?? 0,
            ),
        ],
      ),
    );
  }
}
