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
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F1E6),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                ),
                alignment: Alignment.center,
                child: Text(
                  _habitEmoji(),
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 30,
                              height: 0.98,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _primaryMetric(context),
                          key: const Key('statistics_habit_primary_metric'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetaChip(
                          backgroundColor: familyColor.withValues(alpha: 0.13),
                          textColor: Colors.black.withValues(alpha: 0.72),
                          label:
                              '${FamilyTheme.emojiOf(item.familyId)} ${FamilyTheme.nameOf(item.familyId)}',
                        ),
                        _MetaChip(
                          backgroundColor: Colors.black.withValues(alpha: 0.06),
                          textColor: Colors.black.withValues(alpha: 0.7),
                          label: typeLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _secondaryMetric(context),
                      key: const Key('statistics_habit_secondary_metric'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha: 0.64),
                      ),
                    ),
                    if (tertiaryMetric != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        tertiaryMetric,
                        key: const Key('statistics_habit_tertiary_metric'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: item.isCount
                              ? const Color(0xFF8B5A1F)
                              : const Color(0xFF94613C),
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
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
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 25,
                color: Colors.black.withValues(alpha: 0.38),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _habitEmoji() {
    final normalized = item.habitEmoji.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
    final fallbackFamily = FamilyTheme.emojiOf(item.familyId).trim();
    if (fallbackFamily.isNotEmpty) {
      return fallbackFamily;
    }
    return '•';
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.backgroundColor,
    required this.textColor,
    required this.label,
  });

  final Color backgroundColor;
  final Color textColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}
