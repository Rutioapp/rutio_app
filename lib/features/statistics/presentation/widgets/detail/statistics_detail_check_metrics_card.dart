import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/widgets/stats/helpers/stats_card_surface.dart';

class StatisticsDetailCheckMetricsCard extends StatelessWidget {
  const StatisticsDetailCheckMetricsCard({
    super.key,
    required this.completedDays,
    required this.scheduledDays,
    required this.completionPct,
    required this.bestStreak,
    required this.daysWithActivity,
  });

  final int completedDays;
  final int scheduledDays;
  final int completionPct;
  final int bestStreak;
  final int daysWithActivity;

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
            l10n.statisticsV2DetailCheckSectionTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'DMSerifDisplay',
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _MetricTile(
                      label: l10n.statisticsV2DetailCompletedDays,
                      value: l10n.statisticsV2HabitsCheckCompletedDays(
                        completedDays,
                        scheduledDays,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _MetricTile(
                      label: l10n.statisticsV2DetailCompletionLabel,
                      value: l10n.statisticsV2HabitsCompletedPct(completionPct),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _MetricTile(
                      label: l10n.statisticsV2DetailConsistencyLabel,
                      value: l10n.statisticsV2HabitsCompletedPct(completionPct),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _MetricTile(
                      label: l10n.statisticsV2DetailBestStreakLabel,
                      value: l10n.statisticsV2HabitsCurrentStreakDays(bestStreak),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _MetricTile(
                      label: l10n.statisticsV2DetailActivityDaysLabel,
                      value: daysWithActivity.toString(),
                    ),
                  ),
                ],
              );
            },
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
