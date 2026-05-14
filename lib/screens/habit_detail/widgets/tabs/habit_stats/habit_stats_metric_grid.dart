import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_helpers.dart';
import 'habit_stats_models.dart';

class HabitStatsMetricGrid extends StatelessWidget {
  final HabitStatsShellData shellData;

  const HabitStatsMetricGrid({
    super.key,
    required this.shellData,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = shellData.isCheckHabit
        ? _checkMetricItems(context, shellData)
        : _countMetricItems(context, shellData);

    return GridView.builder(
      key: Key(
        shellData.isCheckHabit
            ? 'habit_stats_check_metric_grid'
            : 'habit_stats_count_metric_grid',
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.05,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
    );
  }
}

List<_MetricItem> _checkMetricItems(BuildContext context, HabitStatsShellData shellData) {
  final l10n = context.l10n;
  final goalValue = _goalValueLabel(l10n, shellData.weeklyTarget);
  return <_MetricItem>[
    _MetricItem(
      icon: Icons.gps_fixed_rounded,
      title: l10n.habitConfigGoalSection,
      value: goalValue,
      subtitle: l10n.habitStatsPerWeek,
      iconColor: const Color(0xFF5A3B23),
    ),
    _MetricItem(
      icon: Icons.check_circle_outline_rounded,
      title: l10n.habitStatsMetricCompleted,
      value: '${shellData.weeklyCompleted}/${shellData.weeklyTarget}',
      subtitle: l10n.habitStatsThisWeek,
      iconColor: const Color(0xFF5A3B23),
    ),
    _MetricItem(
      icon: Icons.trending_up_rounded,
      title: l10n.habitStatsMetricConsistency,
      value: '${shellData.weeklyConsistencyPct}%',
      subtitle: l10n.habitStatsMetricCompletion,
      iconColor: const Color(0xFF5B975A),
    ),
    _MetricItem(
      icon: Icons.wb_sunny_rounded,
      title: l10n.statisticsV3BestMomentCardTitle,
      value: shellData.bestMomentLabel,
      subtitle: l10n.habitStatsMostFrequentTime,
      iconColor: const Color(0xFFDE8B21),
    ),
  ];
}

List<_MetricItem> _countMetricItems(BuildContext context, HabitStatsShellData shellData) {
  final l10n = context.l10n;
  final summary = buildCountMetricSummary(shellData);
  return <_MetricItem>[
    _MetricItem(
      icon: Icons.flag_rounded,
      title: l10n.habitStatsCountObjectiveTitle,
      value: formatCountMetricValue(summary.dailyTarget, unitLabel: summary.unitLabel),
      subtitle: _countPerDayLabel(context),
      iconColor: const Color(0xFF5A3B23),
    ),
    _MetricItem(
      icon: Icons.water_drop_rounded,
      title: l10n.habitStatsCountVolumeTitle,
      value: formatCountMetricValue(summary.weeklyTotal, unitLabel: summary.unitLabel),
      subtitle: l10n.habitStatsThisWeek,
      iconColor: const Color(0xFF3E7B7A),
    ),
    _MetricItem(
      icon: Icons.bar_chart_rounded,
      title: l10n.habitStatsCountDailyAverage,
      value: formatCountMetricValue(summary.dailyAverage, unitLabel: summary.unitLabel),
      subtitle: _countAverageLabel(context),
      iconColor: const Color(0xFF5B975A),
    ),
    _MetricItem(
      icon: Icons.check_circle_outline_rounded,
      title: l10n.habitStatsMetricCompletion,
      value: '${summary.completionPct}%',
      subtitle: _countOfGoalLabel(context),
      iconColor: const Color(0xFF8A5B2C),
    ),
  ];
}

class _MetricItem {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color iconColor;

  const _MetricItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconColor,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricItem metric;

  const _MetricCard({
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEE5D9)),
      ),
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF5EFE6),
              shape: BoxShape.circle,
            ),
            child: Icon(metric.icon, color: metric.iconColor, size: 15),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF241C15),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 24,
                        color: const Color(0xFF1F1913),
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),
                Text(
                  metric.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF5C5247),
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

String _goalValueLabel(dynamic l10n, int weeklyTarget) {
  if (weeklyTarget <= 0) return '0';
  return l10n.habitStatsTimesLabel(weeklyTarget);
}

String _countPerDayLabel(BuildContext context) {
  return _isSpanish(context) ? 'Por dia' : 'Per day';
}

String _countAverageLabel(BuildContext context) {
  return _isSpanish(context) ? 'Promedio' : 'Average';
}

String _countOfGoalLabel(BuildContext context) {
  return _isSpanish(context) ? 'Del objetivo' : 'Of goal';
}

bool _isSpanish(BuildContext context) {
  return Localizations.localeOf(context).languageCode.toLowerCase() == 'es';
}
