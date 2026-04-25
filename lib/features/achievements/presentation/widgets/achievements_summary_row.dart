import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';

class AchievementsSummaryRow extends StatelessWidget {
  const AchievementsSummaryRow({
    super.key,
    required this.unlockedCount,
    required this.totalCount,
    required this.progress,
  });

  final int unlockedCount;
  final int totalCount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        Container(
          width: 122,
          padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE9DECD),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$unlockedCount',
                style: const TextStyle(
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF402B1F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.achievementsSummaryUnlockedOf(totalCount),
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.15,
                  color: Color(0xFF8A7A69),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE9DECD),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.achievementsSummaryProgressTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8D7E6E),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFD7CCBD),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFAA7740),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
