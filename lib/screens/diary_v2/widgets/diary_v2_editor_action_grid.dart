import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

class DiaryV2EditorActionItem {
  const DiaryV2EditorActionItem({
    required this.icon,
    required this.label,
    this.enabled = true,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool selected;
  final VoidCallback? onTap;
}

class DiaryV2EditorActionGrid extends StatelessWidget {
  const DiaryV2EditorActionGrid({
    super.key,
    required this.items,
  });

  final List<DiaryV2EditorActionItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ActionTile(item: item);
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.item});

  final DiaryV2EditorActionItem item;

  @override
  Widget build(BuildContext context) {
    final enabled = item.enabled || item.onTap != null;
    final foreground = item.selected
        ? DiaryV2Styles.accentDeep
        : (enabled ? DiaryV2Styles.textStrong : DiaryV2Styles.mutedText);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? item.onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: item.selected
                ? DiaryV2Styles.accentSoftMuted
                : Colors.white.withValues(alpha: enabled ? 0.58 : 0.4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.selected
                  ? DiaryV2Styles.accent.withValues(alpha: 0.36)
                  : DiaryV2Styles.border.withValues(alpha: 0.9),
            ),
            boxShadow: const [
              BoxShadow(
                color: DiaryV2Styles.shadow,
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: foreground, size: 23),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
