import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/shared/statistics_best_moment_illustrations.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_helpers.dart';
import 'habit_stats_models.dart';

class HabitStatsMetricGrid extends StatelessWidget {
  final HabitStatsShellData? shellData;
  final List<HabitStatsMetricGridItem>? metrics;
  final Key? gridKey;

  const HabitStatsMetricGrid({
    super.key,
    required this.shellData,
  })  : assert(shellData != null),
        metrics = null,
        gridKey = null;

  const HabitStatsMetricGrid.custom({
    super.key,
    required this.metrics,
    this.gridKey,
  }) : shellData = null;

  @override
  Widget build(BuildContext context) {
    final resolvedShellData = shellData;
    final resolvedMetrics = metrics ??
        (resolvedShellData!.isCheckHabit
            ? _checkMetricItems(context, resolvedShellData)
            : _countMetricItems(context, resolvedShellData));
    final resolvedKey = gridKey ??
        (resolvedShellData == null
            ? const Key('habit_stats_custom_metric_grid')
            : Key(
                resolvedShellData.isCheckHabit
                    ? 'habit_stats_check_metric_grid'
                    : 'habit_stats_count_metric_grid',
              ));

    return GridView.builder(
      key: resolvedKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: resolvedMetrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.94,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) =>
          _MetricCard(metric: resolvedMetrics[index]),
    );
  }
}

List<HabitStatsMetricGridItem> _checkMetricItems(
  BuildContext context,
  HabitStatsShellData shellData,
) {
  final l10n = context.l10n;
  final goalValue = _goalValueLabel(context, shellData.weeklyTarget);
  return <HabitStatsMetricGridItem>[
    HabitStatsMetricGridItem(
      icon: Icons.gps_fixed_rounded,
      title: l10n.habitConfigGoalSection,
      value: goalValue,
      subtitle: l10n.habitStatsPerWeek,
      iconColor: const Color(0xFF5A3B23),
    ),
    HabitStatsMetricGridItem(
      icon: Icons.check_circle_outline_rounded,
      title: l10n.habitStatsMetricCompleted,
      value: '${shellData.weeklyCompleted}/${shellData.weeklyTarget}',
      subtitle: l10n.habitStatsThisWeek,
      iconColor: const Color(0xFF5A3B23),
    ),
    HabitStatsMetricGridItem(
      icon: Icons.trending_up_rounded,
      title: l10n.habitStatsMetricConsistency,
      value: '${shellData.weeklyConsistencyPct}%',
      subtitle: l10n.habitStatsMetricCompletion,
      iconColor: const Color(0xFF5B975A),
      valueColor: const Color(0xFF4E7D35),
    ),
    HabitStatsMetricGridItem(
      icon: Icons.schedule_rounded,
      title: l10n.statisticsV3BestMomentCardTitle,
      value: shellData.bestMomentLabel,
      subtitle: l10n.statisticsV3BestMomentSubtitle,
      iconColor: const Color(0xFF4E7D35),
      bestMomentSlot: shellData.bestMomentSlot,
      useBestMomentVisual: shellData.hasBestMomentData,
    ),
  ];
}

List<HabitStatsMetricGridItem> _countMetricItems(
  BuildContext context,
  HabitStatsShellData shellData,
) {
  final l10n = context.l10n;
  final summary = buildCountMetricSummary(shellData);
  return <HabitStatsMetricGridItem>[
    HabitStatsMetricGridItem(
      icon: Icons.flag_rounded,
      title: l10n.habitStatsCountObjectiveTitle,
      value: formatCountMetricValue(summary.dailyTarget,
          unitLabel: summary.unitLabel),
      subtitle: _countPerDayLabel(context),
      iconColor: const Color(0xFF5A3B23),
    ),
    HabitStatsMetricGridItem(
      icon: Icons.water_drop_rounded,
      title: l10n.habitStatsCountVolumeTitle,
      value: formatCountMetricValue(summary.weeklyTotal,
          unitLabel: summary.unitLabel),
      subtitle: l10n.habitStatsThisWeek,
      iconColor: const Color(0xFF3E7B7A),
    ),
    HabitStatsMetricGridItem(
      icon: Icons.bar_chart_rounded,
      title: l10n.habitStatsCountDailyAverage,
      value: formatCountMetricValue(summary.dailyAverage,
          unitLabel: summary.unitLabel),
      subtitle: _countAverageLabel(context),
      iconColor: const Color(0xFF5B975A),
    ),
    HabitStatsMetricGridItem(
      icon: Icons.check_circle_outline_rounded,
      title: l10n.habitStatsMetricCompletion,
      value: '${summary.completionPct}%',
      subtitle: _countOfGoalLabel(context),
      iconColor: const Color(0xFF8A5B2C),
    ),
  ];
}

class HabitStatsMetricGridItem {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color iconColor;
  final Color? valueColor;
  final HabitStatsBestMomentSlot? bestMomentSlot;
  final bool useBestMomentVisual;

  const HabitStatsMetricGridItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconColor,
    this.valueColor,
    this.bestMomentSlot,
    this.useBestMomentVisual = false,
  });
}

class _MetricCard extends StatelessWidget {
  final HabitStatsMetricGridItem metric;

  const _MetricCard({
    required this.metric,
  });

  static const _cream = Color(0xFFFDFBF7);
  static const _border = Color(0xFFE9E3D9);
  static const _text = Color(0xFF2F251C);
  static const _muted = Color(0xFF746A60);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricHeader(metric: metric),
          const SizedBox(height: 8),
          Expanded(
            child: metric.useBestMomentVisual
                ? _BestMomentMetricBody(metric: metric)
                : _StandardMetricBody(metric: metric),
          ),
        ],
      ),
    );
  }
}

class _MetricHeader extends StatelessWidget {
  const _MetricHeader({
    required this.metric,
  });

  final HabitStatsMetricGridItem metric;

  @override
  Widget build(BuildContext context) {
    final chevronSize = 24.0;
    return SizedBox(
      height: chevronSize,
      child: Row(
        children: [
          Container(
            width: 23,
            height: 23,
            decoration: BoxDecoration(
              color: metric.iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(metric.icon, color: metric.iconColor, size: 15),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              metric.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.2,
                height: 1,
                fontWeight: FontWeight.w700,
                color: _MetricCard._text,
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }
}

class _StandardMetricBody extends StatelessWidget {
  const _StandardMetricBody({
    required this.metric,
  });

  final HabitStatsMetricGridItem metric;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              metric.value,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                height: 0.95,
                fontWeight: FontWeight.w800,
                color: metric.valueColor ?? _MetricCard._text,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            metric.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.2,
              height: 1,
              fontWeight: FontWeight.w500,
              color: _MetricCard._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BestMomentMetricBody extends StatelessWidget {
  const _BestMomentMetricBody({
    required this.metric,
  });

  final HabitStatsMetricGridItem metric;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxHeight < 58;
        if (isTight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BestMomentPill(
                    slot: metric.bestMomentSlot ??
                        HabitStatsBestMomentSlot.unknown,
                    compact: true,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      metric.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: _MetricCard._text,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                metric.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9.6,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  color: _MetricCard._muted,
                ),
              ),
            ],
          );
        }

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BestMomentPill(
                slot: metric.bestMomentSlot ?? HabitStatsBestMomentSlot.unknown,
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  metric.value,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 0.95,
                    fontWeight: FontWeight.w800,
                    color: _MetricCard._text,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                metric.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.2,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  color: _MetricCard._muted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BestMomentPill extends StatelessWidget {
  const _BestMomentPill({
    required this.slot,
    this.compact = false,
  });

  final HabitStatsBestMomentSlot slot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pillWidth = compact ? 46.0 : 106.0;
    final pillHeight = compact ? 24.0 : 55.0;
    final iconSize = compact ? 13.0 : 16.0;

    if (slot == HabitStatsBestMomentSlot.unknown) {
      return Container(
        width: pillWidth,
        height: pillHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFFF2F2F2),
        ),
        child: Icon(
          Icons.schedule_rounded,
          size: iconSize,
          color: const Color(0xFF8E8B86),
        ),
      );
    }

    final asset = _assetFor(slot);
    return Container(
      width: pillWidth,
      height: pillHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        asset,
        key: Key('habitStatsBestMomentIllustration-${slot.name}'),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );
  }

  String _assetFor(HabitStatsBestMomentSlot slot) {
    switch (slot) {
      case HabitStatsBestMomentSlot.morning:
        return statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.morning,
        );
      case HabitStatsBestMomentSlot.noon:
        return statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.midday,
        );
      case HabitStatsBestMomentSlot.afternoon:
        return statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.afternoon,
        );
      case HabitStatsBestMomentSlot.night:
        return statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.night,
        );
      case HabitStatsBestMomentSlot.unknown:
        return statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.morning,
        );
    }
  }
}

String _goalValueLabel(BuildContext context, int weeklyTarget) {
  if (weeklyTarget <= 0) return '0';
  final isSpanish = _isSpanish(context);
  if (weeklyTarget == 1) return isSpanish ? '1 vez' : '1 time';
  return isSpanish ? '$weeklyTarget veces' : '$weeklyTarget times';
}

String _countPerDayLabel(BuildContext context) {
  return _isSpanish(context) ? 'Por día' : 'Per day';
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
