import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

class DiaryV2ExploreItem {
  const DiaryV2ExploreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class DiaryV2ExploreGrid extends StatelessWidget {
  const DiaryV2ExploreGrid({
    super.key,
    required this.items,
  });

  final List<DiaryV2ExploreItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) => _ExploreCard(item: items[index]),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.item});

  final DiaryV2ExploreItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DiaryV2Styles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: DiaryV2Styles.sageSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: DiaryV2Styles.sage, size: 22),
          ),
          const Spacer(),
          Text(
            item.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: DiaryV2Styles.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DiaryV2Styles.mutedText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
