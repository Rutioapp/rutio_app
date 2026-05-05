import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'helpers/stats_card_surface.dart';
import 'helpers/stats_number_formatter.dart';

class StatsCountObjectiveCard extends StatelessWidget {
  const StatsCountObjectiveCard({
    super.key,
    required this.goalCompletedDays,
    required this.partialProgressDays,
    required this.compliancePct,
    required this.target,
    required this.accent,
  });

  final int goalCompletedDays;
  final int partialProgressDays;
  final double compliancePct;
  final int target;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: StatsCardSurface.decoration(context),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.habitStatsCountObjectiveTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.habitStatsCountObjectiveSubtitle(target),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            key: const Key('stats_objective_grid'),
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.8,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ObjectiveTile(
                icon: Icons.check_circle_rounded,
                label: l10n.habitStatsCountGoalCompleted,
                value: goalCompletedDays.toString(),
                accent: accent,
              ),
              _ObjectiveTile(
                icon: Icons.timelapse_rounded,
                label: l10n.habitStatsCountPartialProgress,
                value: partialProgressDays.toString(),
                accent: const Color(0xFF9A7A34),
              ),
              _ObjectiveTile(
                icon: Icons.track_changes_rounded,
                label: l10n.habitStatsCountAverageCompliance,
                value: '${StatsNumberFormatter.compact1(compliancePct)}%',
                accent: const Color(0xFF3E7A6A),
              ),
              _ObjectiveTile(
                icon: Icons.flag_rounded,
                label: l10n.habitStatsCountDailyTarget,
                value: target.toString(),
                accent: const Color(0xFF5E5AA7),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatsCountVolumeCard extends StatelessWidget {
  const StatsCountVolumeCard({
    super.key,
    required this.totalAccumulated,
    required this.dailyAverage,
    required this.activeDayAverage,
    required this.bestDay,
    required this.activeDays,
  });

  final int totalAccumulated;
  final double dailyAverage;
  final double activeDayAverage;
  final int bestDay;
  final int activeDays;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: StatsCardSurface.decoration(context),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.habitStatsCountVolumeTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _VolumeRow(
            badge: 'S',
            label: l10n.habitStatsCountTotalAccumulated,
            value: totalAccumulated.toString(),
          ),
          _VolumeRow(
            badge: 'AVG',
            label: l10n.habitStatsCountDailyAverage,
            value: StatsNumberFormatter.compact1(dailyAverage),
          ),
          _VolumeRow(
            badge: 'ON',
            label: l10n.habitStatsCountActiveDayAverage,
            value: StatsNumberFormatter.compact1(activeDayAverage),
          ),
          _VolumeRow(
            badge: 'MAX',
            label: l10n.habitStatsCountBestDay,
            value: bestDay.toString(),
          ),
          _VolumeRow(
            badge: 'D',
            label: l10n.habitStatsCountActiveDays,
            value: activeDays.toString(),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ObjectiveTile extends StatelessWidget {
  const _ObjectiveTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.badge,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String badge;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF4EFE7),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.72),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
