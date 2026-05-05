import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'helpers/stats_motivation_engine.dart';

class StatsMotivationalTipCard extends StatelessWidget {
  const StatsMotivationalTipCard({
    super.key,
    required this.habitTitle,
    required this.streakDays,
    required this.thisWeekDoneDays,
    required this.lastWeekDoneDays,
    this.bestTimeLabel,
    this.compliancePct,
  });

  final String habitTitle;
  final int streakDays;
  final int thisWeekDoneDays;
  final int lastWeekDoneDays;
  final String? bestTimeLabel;
  final int? compliancePct;

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF1B5E20);
    const baseGreen = Color(0xFF2E7D32);
    final bg = baseGreen.withValues(alpha: 0.08);
    final border = baseGreen.withValues(alpha: 0.28);
    final iconBg = baseGreen.withValues(alpha: 0.14);
    final textColor = Colors.black.withValues(alpha: 0.74);

    final pick = StatsMotivationEngine.pick(
      StatsMotivationInput(
        streakDays: streakDays,
        thisWeekDoneDays: thisWeekDoneDays,
        lastWeekDoneDays: lastWeekDoneDays,
        hasBestTime: (bestTimeLabel ?? '').trim().isNotEmpty,
        compliancePct: compliancePct ?? 0,
      ),
    );

    final message = _buildPhrase(context, pick);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Text('??', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(text: message.prefix),
                  TextSpan(
                    text: message.highlight,
                    style: const TextStyle(
                      color: forest,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: message.suffix),
                ],
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  _PhraseParts _buildPhrase(BuildContext context, StatsMotivationPick pick) {
    final l10n = context.l10n;
    final titleSafe = habitTitle.trim().isEmpty
        ? l10n.habitStatsThisHabitFallback
        : habitTitle.trim();
    final weeklyDelta = thisWeekDoneDays - lastWeekDoneDays;
    final bestTime = (bestTimeLabel ?? '').trim();

    switch (pick.tone) {
      case StatsMotivationTone.strongStreak:
        if (pick.variant == 0) {
          return _PhraseParts(
            prefix:
                '${l10n.habitStatsMotivationLead}${l10n.habitStatsDaysLabel(streakDays)} ${l10n.habitStatsMotivationWith}',
            highlight: titleSafe,
            suffix:
                '. ${l10n.habitStatsMotivationKeepLead.toLowerCase()}${l10n.habitStatsMotivationKeepKeyword}${l10n.habitStatsMotivationKeepTail}',
          );
        }
        if (pick.variant == 1) {
          return _PhraseParts(
            prefix: l10n.habitStatsMotivationKeepLead,
            highlight: l10n.habitStatsMotivationKeepKeyword,
            suffix: ' ${l10n.habitStatsMotivationWith}$titleSafe.',
          );
        }
        return _PhraseParts(
          prefix: l10n.habitStatsMotivationLead,
          highlight: l10n.habitStatsDaysLabel(streakDays),
          suffix:
              '. ${l10n.habitStatsMotivationGoalLead.toLowerCase()}${l10n.habitStatsMotivationGoalKeyword(_nextGoal(streakDays))}.',
        );

      case StatsMotivationTone.weeklyImprovement:
        return _PhraseParts(
          prefix:
              '${l10n.habitStatsMotivationLead}${l10n.habitStatsDaysLabel(streakDays)} ${l10n.habitStatsMotivationWith}$titleSafe: ',
          highlight: l10n.habitStatsMotivationAboveKeyword,
          suffix:
              '${l10n.habitStatsMotivationAboveTail}${weeklyDelta > 0 ? '+' : ''}$weeklyDelta.',
        );

      case StatsMotivationTone.steadyProgress:
        return _PhraseParts(
          prefix: '${l10n.habitStatsMotivationWith}$titleSafe, ',
          highlight: l10n.habitStatsMotivationEqual.trim(),
          suffix: '',
        );

      case StatsMotivationTone.bestTime:
        return _PhraseParts(
          prefix:
              '${l10n.habitStatsMotivationLead}${l10n.habitStatsDaysLabel(streakDays)} ${l10n.habitStatsMotivationWith}$titleSafe. ${l10n.habitStatsMotivationBestTimeLead}',
          highlight: l10n.habitStatsTimeSlot(bestTime),
          suffix: l10n.habitStatsMotivationBestTimeTail,
        );

      case StatsMotivationTone.goodCompliance:
        return _PhraseParts(
          prefix: l10n.habitStatsMotivationLead,
          highlight: '${compliancePct ?? 0}%',
          suffix:
              ' ${l10n.habitStatsCountAverageCompliance.toLowerCase()} ${l10n.habitStatsMotivationWith}$titleSafe.',
        );

      case StatsMotivationTone.neutral:
        return _PhraseParts(
          prefix: '${l10n.habitStatsMotivationWith}$titleSafe, ',
          highlight: l10n.habitStatsMotivationStart.trim(),
          suffix:
              '${l10n.habitStatsMotivationGoalLead.toLowerCase()}${l10n.habitStatsMotivationGoalKeyword(_nextGoal(streakDays))}.',
        );
    }
  }

  static int _nextGoal(int streak) {
    const goals = [7, 14, 21, 30];
    for (final g in goals) {
      if (streak < g) return g;
    }
    return 30;
  }
}

class _PhraseParts {
  const _PhraseParts({
    required this.prefix,
    required this.highlight,
    required this.suffix,
  });

  final String prefix;
  final String highlight;
  final String suffix;
}
