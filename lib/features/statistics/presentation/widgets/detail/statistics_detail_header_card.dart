import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/family_theme.dart';
import 'package:rutio/widgets/stats/helpers/stats_card_surface.dart';

import '../../../domain/statistics_models.dart';

class StatisticsDetailHeaderCard extends StatelessWidget {
  const StatisticsDetailHeaderCard({
    super.key,
    required this.habit,
  });

  final StatisticsHabitSummary habit;

  @override
  Widget build(BuildContext context) {
    final familyColor = FamilyTheme.colorOf(habit.familyId);
    final l10n = context.l10n;
    final typeLabel = habit.type == StatisticsHabitType.count
        ? l10n.statisticsV2HabitsTypeCount
        : l10n.statisticsV2HabitsTypeCheck;
    final goalText = habit.type == StatisticsHabitType.count
        ? '${habit.target}'
        : l10n.statisticsV2HabitsMetricCompleted;

    return Container(
      decoration: StatsCardSurface.decoration(context),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: familyColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  FamilyTheme.emojiOf(habit.familyId),
                  style: const TextStyle(fontSize: 27),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 33,
                        height: 0.95,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${FamilyTheme.nameOf(habit.familyId)} · $goalText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MiniChip(
                color: Colors.black.withValues(alpha: 0.06),
                textColor: Colors.black.withValues(alpha: 0.72),
                label: typeLabel,
              ),
              _MiniChip(
                color: const Color(0xFFEAF6EE),
                textColor: const Color(0xFF2F6B4F),
                label: '${l10n.statisticsV2HabitsMetricStreak}: ${habit.currentStreak}',
              ),
              _MiniChip(
                color: const Color(0xFFF5EFE4),
                textColor: const Color(0xFF6B4D2E),
                label:
                    '${l10n.statisticsV2HabitsMetricCompletion}: ${habit.completionPct}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.color,
    required this.textColor,
    required this.label,
  });

  final Color color;
  final Color textColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

