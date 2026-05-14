import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_helpers.dart';
import 'habit_stats_models.dart';

class HabitStatsCountBestDayCard extends StatelessWidget {
  final HabitStatsShellData shellData;

  const HabitStatsCountBestDayCard({
    super.key,
    required this.shellData,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = buildCountBestDaySummary(context, shellData);
    final valueText = summary.hasData
        ? '${summary.weekdayLabel} ${String.fromCharCode(0x00B7)} ${summary.valueLabel}'
        : l10n.habitStatsCountBestDayNoDataYet;

    return Container(
      key: const Key('habit_stats_count_best_day_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE4D8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFF5EFE6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFB07A2A),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.habitStatsCountBestDayTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF221A14),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  valueText,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 20,
                        color: const Color(0xFF2E251C),
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  l10n.habitStatsCountBestDaySubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF5A4E42),
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.emoji_events_rounded,
            color: const Color(0xFFC58A2D).withValues(alpha: 0.45),
            size: 20,
          ),
        ],
      ),
    );
  }
}
