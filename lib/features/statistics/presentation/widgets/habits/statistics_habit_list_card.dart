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
    final familyColor = FamilyTheme.colorOf(item.familyId);
    final l10n = context.l10n;
    final tertiaryMetric = _tertiaryMetric(context);
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: familyColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  FamilyTheme.emojiOf(item.familyId),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _primaryMetric(context),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: familyColor,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              FamilyTheme.nameOf(item.familyId),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
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
                        const SizedBox(height: 5),
                        Text(
                          _secondaryMetric(context),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withValues(alpha: 0.62),
                          ),
                        ),
                        if (tertiaryMetric != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            tertiaryMetric,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: item.progress01.clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: familyColor.withValues(alpha: 0.14),
                        valueColor: AlwaysStoppedAnimation<Color>(familyColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                size: 23,
                color: Colors.black.withValues(alpha: 0.42),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _primaryMetric(BuildContext context) {
    final l10n = context.l10n;
    if (item.isCount) {
      final progress = item.countProgress;
      if (progress == null) {
        return StatsNumberFormatter.compact1(item.periodVolume);
      }
      return l10n.statisticsV2HabitsCompletedPct(progress.compliancePct.round());
    }
    return l10n.statisticsV2HabitsCompletedPct(item.completionPct);
  }

  String _secondaryMetric(BuildContext context) {
    final l10n = context.l10n;
    final progress = item.countProgress;
    if (item.isCheck) {
      return l10n.statisticsV2HabitsCheckCompletedDays(
        item.doneDays,
        item.scheduledDays,
      );
    }
    if (progress == null) {
      return StatsNumberFormatter.compact1(item.periodVolume);
    }
    return l10n.statisticsV2HabitsGoalCompletedDays(progress.goalCompletedDays);
  }

  String? _tertiaryMetric(BuildContext context) {
    final l10n = context.l10n;
    final progress = item.countProgress;
    if (item.isCheck) {
      return '${l10n.statisticsV2HabitsMetricStreak}: ${l10n.statisticsV2HabitsCurrentStreakDays(item.currentStreak)}';
    }
    if (progress == null) {
      return null;
    }
    return l10n.statisticsV2HabitsPartialDays(progress.partialProgressDays);
  }
}

