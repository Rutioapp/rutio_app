import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_insight_resolver.dart';
import 'habit_stats_models.dart';

class HabitStatsInsightCard extends StatelessWidget {
  final HabitStatsShellData shellData;
  static const _cardBorder = Color(0xFFE9E3D9);
  static const _cardText = Color(0xFF2F251C);
  static const _cardMuted = Color(0xFF746A60);
  static const _badgeBase = Color(0xFFF5EEDF);
  static const _badgeBorder = Color(0xFFE6D7BE);

  const HabitStatsInsightCard({
    super.key,
    required this.shellData,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final insight = resolveHabitStatsInsight(l10n, shellData);
    final badgeToneColor = _badgeColorForTone(insight.tone);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _badgeBase,
              border: Border.all(color: _badgeBorder),
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: badgeToneColor,
              size: 16,
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
                        fontSize: 12,
                        color: _cardText,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w500,
                        color: _cardText,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: _cardMuted,
                        height: 1.25,
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

Color _badgeColorForTone(HabitStatsInsightTone tone) {
  switch (tone) {
    case HabitStatsInsightTone.positive:
      return const Color(0xFF4E8A4A);
    case HabitStatsInsightTone.recovery:
      return const Color(0xFF9B6A2A);
    case HabitStatsInsightTone.paused:
      return const Color(0xFF7A6A56);
    case HabitStatsInsightTone.amber:
      return const Color(0xFFB57A2C);
    case HabitStatsInsightTone.neutral:
      return const Color(0xFF806744);
  }
}
