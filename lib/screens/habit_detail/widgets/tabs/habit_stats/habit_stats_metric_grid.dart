import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_models.dart';

class HabitStatsMetricGrid extends StatelessWidget {
  final HabitStatsShellData shellData;
  final HabitStatsPeriod selectedPeriod;
  final Color familyColor;

  const HabitStatsMetricGrid({
    super.key,
    required this.shellData,
    required this.selectedPeriod,
    required this.familyColor,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = <_MetricModel>[
      _MetricModel(
        icon: Icons.check_circle_outline_rounded,
        title: context.l10n.habitStatsMetricCompleted,
        value: '${shellData.completedDays}',
        caption: context.l10n.habitStatsMetricCompletionDescription(
          shellData.completedDays,
          _windowLength(selectedPeriod),
        ),
      ),
      _MetricModel(
        icon: Icons.local_fire_department_outlined,
        title: context.l10n.habitStatsMetricBestStreak,
        value: '${shellData.bestStreak}',
        caption: context.l10n.habitStatsMetricPersonalBest,
      ),
      _MetricModel(
        icon: Icons.repeat_rounded,
        title: context.l10n.habitStatsMetricTotalDone,
        value: '${shellData.totalCompletions}',
        caption: context.l10n.habitStatsMetricHistoricRecords,
      ),
      _MetricModel(
        icon: Icons.track_changes_outlined,
        title: context.l10n.habitConfigGoalSection,
        value: shellData.targetValue > 0 ? '${shellData.targetValue}' : '—',
        caption: context.l10n.habitConfigFrequencySection,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return _MetricCard(
          metric: metric,
          familyColor: familyColor,
        );
      },
    );
  }
}

class _MetricModel {
  final IconData icon;
  final String title;
  final String value;
  final String caption;

  const _MetricModel({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricModel metric;
  final Color familyColor;

  const _MetricCard({
    required this.metric,
    required this.familyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE1D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, size: 18, color: familyColor.withValues(alpha: 0.88)),
          const SizedBox(height: 8),
          Text(
            metric.value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2F261D),
                  height: 1.02,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF5F5142),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          Text(
            metric.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }
}

int _windowLength(HabitStatsPeriod period) {
  switch (period) {
    case HabitStatsPeriod.week:
      return 7;
    case HabitStatsPeriod.month:
      return 30;
    case HabitStatsPeriod.year:
      return 365;
  }
}
