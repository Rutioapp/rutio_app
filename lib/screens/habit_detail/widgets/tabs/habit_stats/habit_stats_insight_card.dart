import 'package:flutter/material.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../../l10n/l10n.dart';
import 'habit_stats_helpers.dart';
import 'habit_stats_models.dart';

class HabitStatsInsightCard extends StatelessWidget {
  final HabitStatsShellData shellData;
  static const _cardBorder = Color(0xFFE9E3D9);
  static const _cardText = Color(0xFF2F251C);
  static const _cardMuted = Color(0xFF746A60);

  const HabitStatsInsightCard({
    super.key,
    required this.shellData,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = shellData.isCheckHabit
        ? _checkInsightMessage(l10n, shellData.weeklyConsistencyPct)
        : _countInsightMessage(l10n, buildCountMetricSummary(shellData).completionPct);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF5EEDF),
              border: Border.all(color: const Color(0xFFE6D7BE)),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFFB57A2C),
              size: 17,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.habitStatsInsightLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 13,
                        color: _cardText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  message,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 17,
                        fontFamily: 'Georgia',
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: _cardMuted,
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

String _checkInsightMessage(AppLocalizations l10n, int consistencyPct) {
  if (consistencyPct >= 80) {
    return l10n.habitStatsInsightSteadyRoutine;
  }
  if (consistencyPct >= 50) {
    return l10n.habitStatsInsightGoodRhythm;
  }
  return l10n.habitStatsInsightEveryRepetition;
}

String _countInsightMessage(AppLocalizations l10n, int completionPct) {
  if (completionPct >= 80) {
    return l10n.habitStatsCountInsightCloseToGoal;
  }
  if (completionPct >= 50) {
    return l10n.habitStatsCountInsightGoodProgress;
  }
  return l10n.habitStatsCountInsightAdjustPace;
}
