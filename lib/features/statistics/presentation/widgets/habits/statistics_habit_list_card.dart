import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/family_theme.dart';
import 'package:rutio/widgets/stats/helpers/stats_card_surface.dart';
import 'package:rutio/widgets/stats/helpers/stats_number_formatter.dart';

import '../../../domain/statistics_models.dart';

class StatisticsHabitListCard extends StatelessWidget {
  const StatisticsHabitListCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final StatisticsHabitListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final familyColor = FamilyTheme.colorOf(item.familyId);
    final typeLabel = item.isCount
        ? l10n.statisticsV2HabitsTypeCount
        : l10n.statisticsV2HabitsTypeCheck;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: StatsCardSurface.decoration(context),
          padding: StatsCardSurface.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: familyColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      FamilyTheme.emojiOf(item.familyId),
                      style: const TextStyle(fontSize: 19),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          FamilyTheme.nameOf(item.familyId),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: familyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (item.isCheck) ..._buildCheckMetrics(context),
              if (item.isCount) ..._buildCountMetrics(context),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: item.progress01.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: familyColor.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(familyColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCheckMetrics(BuildContext context) {
    final l10n = context.l10n;
    return [
      Row(
        children: [
          Expanded(
            child: _Metric(
              label: l10n.statisticsV2HabitsMetricCompleted,
              value: l10n.statisticsV2HabitsCheckCompletedDays(
                item.doneDays,
                item.scheduledDays,
              ),
            ),
          ),
          Expanded(
            child: _Metric(
              label: l10n.statisticsV2HabitsMetricCompletion,
              value: l10n.statisticsV2HabitsCompletedPct(item.completionPct),
            ),
          ),
          Expanded(
            child: _Metric(
              label: l10n.statisticsV2HabitsMetricStreak,
              value: l10n.statisticsV2HabitsCurrentStreakDays(item.currentStreak),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildCountMetrics(BuildContext context) {
    final l10n = context.l10n;
    final progress = item.countProgress;
    if (progress == null) {
      return _buildCheckMetrics(context);
    }

    return [
      Row(
        children: [
          Expanded(
            child: _Metric(
              label: l10n.statisticsV2HabitsTotalAccumulated,
              value: StatsNumberFormatter.compact1(progress.totalAccumulated),
            ),
          ),
          Expanded(
            child: _Metric(
              label: l10n.statisticsV2HabitsMetricCompletion,
              value: l10n.statisticsV2HabitsCompletedPct(
                progress.compliancePct.round(),
              ),
            ),
          ),
          Expanded(
            child: _Metric(
              label: l10n.statisticsV2HabitsMetricStreak,
              value: l10n.statisticsV2HabitsCurrentStreakDays(item.currentStreak),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _Metric(
              label: l10n.statisticsV2HabitsGoalCompleted,
              value: l10n.statisticsV2HabitsGoalCompletedDays(
                progress.goalCompletedDays,
              ),
            ),
          ),
          Expanded(
            child: _Metric(
              label: l10n.statisticsV2HabitsPartialProgress,
              value: l10n.statisticsV2HabitsPartialDays(
                progress.partialProgressDays,
              ),
            ),
          ),
          Expanded(
            child: _Metric(
              label: l10n.statisticsV2HabitsMetricCompleted,
              value: l10n.statisticsV2HabitsCheckCompletedDays(
                item.doneDays,
                item.scheduledDays,
              ),
            ),
          ),
        ],
      ),
    ];
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.56),
          ),
        ),
      ],
    );
  }
}
