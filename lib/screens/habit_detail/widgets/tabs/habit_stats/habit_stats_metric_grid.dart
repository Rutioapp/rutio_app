part of '../habit_stats_tab.dart';

class _CheckMetricsGrid extends StatelessWidget {
  const _CheckMetricsGrid({
    required this.l10n,
    required this.habit,
    required this.periodStats,
    required this.weekStats,
    required this.bestMoment,
  });

  final AppLocalizations l10n;
  final Map<String, dynamic> habit;
  final _CheckStats periodStats;
  final _CheckStats weekStats;
  final String bestMoment;

  @override
  Widget build(BuildContext context) {
    final objective = _objectiveMetricForCheck(l10n, habit);
    final completedText = '${weekStats.completed}/${weekStats.expected}';
    final consistencyText = '${periodStats.consistencyPct}%';

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MetricCard(
          widthFactor: 0.5,
          title: l10n.habitConfigGoalSection,
          value: objective.value,
          subtitle: objective.subtitle,
          icon: CupertinoIcons.scope,
        ),
        _MetricCard(
          widthFactor: 0.5,
          title: l10n.habitStatsMetricCompleted,
          value: completedText,
          subtitle: l10n.habitStatsThisWeek,
          icon: CupertinoIcons.checkmark_alt_circle,
        ),
        _MetricCard(
          widthFactor: 0.5,
          title: l10n.habitStatsMetricConsistency,
          value: consistencyText,
          subtitle: l10n.habitStatsIndividualCompletionSubtitle,
          icon: CupertinoIcons.chart_bar_alt_fill,
        ),
        _MetricCard(
          widthFactor: 0.5,
          title: l10n.statisticsV3BestMomentCardTitle,
          value: bestMoment,
          subtitle: l10n.habitStatsIndividualMostFrequentTime,
          icon: CupertinoIcons.sun_max_fill,
        ),
      ],
    );
  }
}

class _CountMetricsGrid extends StatelessWidget {
  const _CountMetricsGrid({
    required this.l10n,
    required this.target,
    required this.unit,
    required this.periodStats,
  });

  final AppLocalizations l10n;
  final num target;
  final String unit;
  final _CountStats periodStats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MetricCard(
          widthFactor: 0.5,
          title: l10n.habitConfigGoalSection,
          value: _valueWithUnit(target, unit),
          subtitle: l10n.habitStatsIndividualPerDay,
          icon: CupertinoIcons.scope,
        ),
        _MetricCard(
          widthFactor: 0.5,
          title: l10n.habitStatsIndividualVolume,
          value: _valueWithUnit(periodStats.total, unit),
          subtitle: l10n.habitStatsThisWeek,
          icon: CupertinoIcons.drop_fill,
        ),
        _MetricCard(
          widthFactor: 0.5,
          title: l10n.habitStatsIndividualDailyAverage,
          value: _valueWithUnit(periodStats.average, unit),
          subtitle: l10n.habitStatsIndividualAverage,
          icon: CupertinoIcons.waveform_path_ecg,
        ),
        _MetricCard(
          widthFactor: 0.5,
          title: l10n.habitStatsIndividualCompletion,
          value: '${periodStats.completionPct}%',
          subtitle: l10n.habitStatsIndividualOfGoal,
          icon: CupertinoIcons.percent,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.widthFactor,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final double widthFactor;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width - 42;
    final cardWidth = (maxWidth - 10) * widthFactor;
    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x1A2A2118)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F1E8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF5A3A22), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 24,
                    height: 0.95,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF22201B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.serifFamily,
                    fontSize: 48,
                    height: 0.9,
                    color: Color(0xFF18140F),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5D5952),
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
