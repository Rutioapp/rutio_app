import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';

class StatisticsV3FamilyChipsCard extends StatelessWidget {
  const StatisticsV3FamilyChipsCard({
    super.key,
    required this.title,
    required this.emptyLabel,
    required this.items,
  });

  final String title;
  final String emptyLabel;
  final List<StatisticsV3FamilyItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2F251C),
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              emptyLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6A6155),
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: items
                  .take(4)
                  .map((item) => _FamilyChip(item: item))
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _FamilyChip extends StatelessWidget {
  const _FamilyChip({required this.item});

  final StatisticsV3FamilyItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: item.color.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          Text(
            item.emoji,
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4D4338),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${item.completedCount}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: item.color,
            ),
          ),
        ],
      ),
    );
  }
}
