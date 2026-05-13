import 'package:flutter/material.dart';

import '../../../../../utils/app_theme.dart';
import 'habit_stats_models.dart';

class HabitStatsMetricGrid extends StatelessWidget {
  const HabitStatsMetricGrid({
    super.key,
    required this.cards,
  });

  final List<HabitStatsMetricCardData> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.length < 4) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _HabitStatsMetricCard(card: cards[0])),
            const SizedBox(width: 10),
            Expanded(child: _HabitStatsMetricCard(card: cards[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _HabitStatsMetricCard(card: cards[2])),
            const SizedBox(width: 10),
            Expanded(child: _HabitStatsMetricCard(card: cards[3])),
          ],
        ),
      ],
    );
  }
}

class _HabitStatsMetricCard extends StatelessWidget {
  const _HabitStatsMetricCard({required this.card});

  final HabitStatsMetricCardData card;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAE4DA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: card.badgeColor,
            ),
            alignment: Alignment.center,
            child: Icon(card.icon, color: card.iconColor, size: 28),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF23201C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  card.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.serifFamily,
                    fontSize: 50,
                    height: 0.93,
                    letterSpacing: -0.6,
                    color: Color(0xFF181614),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  card.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4F4A45),
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
