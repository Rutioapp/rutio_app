import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/family_theme.dart';
import 'package:rutio/widgets/stats/helpers/stats_number_formatter.dart';

import '../../../domain/statistics_models.dart';
import 'statistics_overview_section_card.dart';

class StatisticsOverviewTopHabitsCard extends StatelessWidget {
  const StatisticsOverviewTopHabitsCard({
    super.key,
    required this.summary,
  });

  final StatisticsOverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return StatisticsOverviewSectionCard(
      title: l10n.statisticsV2OverviewTopHabitsTitle,
      subtitle: l10n.statisticsV2OverviewTopHabitsSubtitle,
      child: summary.topHabits.isEmpty
          ? Text(
              l10n.statisticsV2OverviewTopHabitsEmpty,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.56),
              ),
            )
          : Column(
              children: List<Widget>.generate(
                summary.topHabits.length,
                (index) => _HabitRow(
                  rank: index + 1,
                  habit: summary.topHabits[index],
                ),
              ),
            ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.rank,
    required this.habit,
  });

  final int rank;
  final StatisticsHabitSummary habit;

  @override
  Widget build(BuildContext context) {
    final color = FamilyTheme.colorOf(habit.familyId);
    final l10n = context.l10n;
    final rightLabel = habit.type == StatisticsHabitType.count
        ? l10n.statisticsV2OverviewVolumeLabel
        : l10n.statisticsV2OverviewConsistencyShortLabel;
    final rightValue = habit.type == StatisticsHabitType.count
        ? StatsNumberFormatter.compact1(habit.periodVolume)
        : '${habit.completionPct}%';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            alignment: Alignment.centerLeft,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.black.withValues(alpha: 0.62),
              ),
            ),
          ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              habit.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rightValue,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              Text(
                rightLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.56),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
