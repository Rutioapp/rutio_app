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
    this.onItemTap,
  });

  final List<DiaryV2ExploreItem> items;
  final ValueChanged<DiaryV2ExploreItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: compact ? 150 : 144,
          ),
          itemBuilder: (context, index) => _ExploreCard(
            item: items[index],
            onTap: onItemTap == null ? null : () => onItemTap!(items[index]),
          ),
        );
      },
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.item,
    this.onTap,
  });

  final DiaryV2ExploreItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DiaryV2Styles.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DiaryV2Styles.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: DiaryV2Styles.sageSoft.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: DiaryV2Styles.sage, size: 18),
                ),
                const SizedBox(height: 11),
                Flexible(
                  flex: 2,
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: DiaryV2Styles.textStrong,
                          fontWeight: FontWeight.w600,
                          height: 1.12,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  flex: 3,
                  child: Text(
                    item.subtitle,
                    maxLines: compactTitleLines(item.title) ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DiaryV2Styles.mutedText,
                          height: 1.28,
                        ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool compactTitleLines(String title) {
    return title.length > 16;
  }
}
