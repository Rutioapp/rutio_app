import 'package:flutter/material.dart';

class StatisticsV3HighlightedHabitCard extends StatelessWidget {
  const StatisticsV3HighlightedHabitCard({
    super.key,
    required this.title,
    required this.emptyLabel,
    required this.metricLabel,
    this.habitName,
    this.habitEmoji,
  });

  final String title;
  final String emptyLabel;
  final String metricLabel;
  final String? habitName;
  final String? habitEmoji;

  @override
  Widget build(BuildContext context) {
    final hasHabit = (habitName ?? '').trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E3D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2F251C),
            ),
          ),
          const SizedBox(height: 12),
          if (!hasHabit)
            Text(
              emptyLabel,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6A6155),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HighlightedHabitRow(
                  emoji: habitEmoji ?? '*',
                  name: habitName!,
                  metricLabel: metricLabel,
                ),
                const SizedBox(height: 8),
                _HighlightedHabitRow(
                  emoji: '*',
                  name: emptyLabel,
                  metricLabel: '',
                  isMuted: true,
                ),
                const SizedBox(height: 8),
                _HighlightedHabitRow(
                  emoji: '*',
                  name: emptyLabel,
                  metricLabel: '',
                  isMuted: true,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HighlightedHabitRow extends StatelessWidget {
  const _HighlightedHabitRow({
    required this.emoji,
    required this.name,
    required this.metricLabel,
    this.isMuted = false,
  });

  final String emoji;
  final String name;
  final String metricLabel;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isMuted ? const Color(0xFF8C8277) : const Color(0xFF2E241B);

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF4EEE4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isMuted ? FontWeight.w500 : FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        if (metricLabel.isNotEmpty) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              metricLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5E554A),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
