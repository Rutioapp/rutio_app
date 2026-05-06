import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';

class StatisticsV3HighlightedHabitCard extends StatelessWidget {
  const StatisticsV3HighlightedHabitCard({
    super.key,
    required this.title,
    required this.emptyLabel,
    required this.items,
  });

  final String title;
  final String emptyLabel;
  final List<StatisticsV3HighlightedHabitItem> items;

  @override
  Widget build(BuildContext context) {
    final hasItems = items.isNotEmpty;

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
          if (!hasItems)
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
                for (var index = 0; index < items.take(3).length; index++) ...[
                  if (index > 0) const SizedBox(height: 8),
                  _HighlightedHabitRow(item: items[index]),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _HighlightedHabitRow extends StatelessWidget {
  const _HighlightedHabitRow({required this.item});

  final StatisticsV3HighlightedHabitItem item;

  @override
  Widget build(BuildContext context) {
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
            item.emoji,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E241B),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${item.completedCount}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5E554A),
          ),
        ),
      ],
    );
  }
}
