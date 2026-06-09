import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

class DiaryV2StatItem {
  const DiaryV2StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String value;
  final String label;
  final String detail;
}

class DiaryV2StatsSummaryCard extends StatelessWidget {
  const DiaryV2StatsSummaryCard({
    super.key,
    required this.items,
  });

  final List<DiaryV2StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: DiaryV2Styles.cardDecoration(accented: true),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: _StatColumn(item: items[i])),
            if (i != items.length - 1)
              Container(
                width: 1,
                height: 54,
                color: DiaryV2Styles.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.item});

  final DiaryV2StatItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: DiaryV2Styles.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: DiaryV2Styles.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DiaryV2Styles.mutedText,
                  ),
                ),
                Text(
                  item.detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DiaryV2Styles.text,
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
