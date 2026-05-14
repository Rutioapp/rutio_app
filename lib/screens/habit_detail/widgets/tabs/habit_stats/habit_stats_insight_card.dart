import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_models.dart';

class HabitStatsInsightCard extends StatelessWidget {
  final HabitStatsShellData shellData;

  const HabitStatsInsightCard({
    super.key,
    required this.shellData,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = _insightMessage(l10n, shellData.weeklyConsistencyPct);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1E2CC)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF4E4C5),
              border: Border.all(color: const Color(0xFFECD7B4)),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFFC58A2D),
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
                        color: const Color(0xFF251D16),
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
                        color: const Color(0xFF2E251C),
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

String _insightMessage(dynamic l10n, int consistencyPct) {
  if (consistencyPct >= 80) {
    return l10n.habitStatsInsightSteadyRoutine;
  }
  if (consistencyPct >= 50) {
    return l10n.habitStatsInsightGoodRhythm;
  }
  return l10n.habitStatsInsightEveryRepetition;
}
