import 'package:flutter/cupertino.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        if (compact) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: DiaryV2Styles.cardDecoration(accented: true),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _StatColumn(item: items[i], centered: false),
                  if (i != items.length - 1) ...[
                    const SizedBox(height: 12),
                    const Divider(color: DiaryV2Styles.border, height: 1),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: DiaryV2Styles.cardDecoration(accented: true),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                Expanded(
                  child: _StatColumn(
                    item: items[i],
                    centered: true,
                  ),
                ),
                if (i != items.length - 1)
                  Container(
                    width: 1,
                    height: 56,
                    color: DiaryV2Styles.border,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.item,
    required this.centered,
  });

  final DiaryV2StatItem item;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final alignment =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;
    final labelSpec = _labelSpecFor(
      item: item,
      isSpanish: Localizations.localeOf(context).languageCode == 'es',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DiaryV2Styles.cream.withValues(alpha: 0.82),
              shape: BoxShape.circle,
            ),
            child: Transform.translate(
              offset: _iconOffset(item.icon),
              child: Icon(
                item.icon,
                color: DiaryV2Styles.accentDeep,
                size: 17,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: DiaryV2Styles.textStrong,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            labelSpec.lineOne,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: labelSpec.emphasizeFirstLine
                      ? DiaryV2Styles.text
                      : DiaryV2Styles.mutedText,
                  fontWeight: labelSpec.emphasizeFirstLine
                      ? FontWeight.w600
                      : FontWeight.w400,
                  height: 1.15,
                ),
          ),
          Text(
            labelSpec.lineTwo,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: labelSpec.emphasizeSecondLine
                      ? DiaryV2Styles.text
                      : DiaryV2Styles.mutedText,
                  fontWeight: labelSpec.emphasizeSecondLine
                      ? FontWeight.w600
                      : FontWeight.w400,
                  height: 1.15,
                ),
          ),
        ],
      ),
    );
  }

  Offset _iconOffset(IconData icon) {
    if (icon == CupertinoIcons.bookmark) {
      return const Offset(0, 1);
    }
    return Offset.zero;
  }

  _StatLabelSpec _labelSpecFor({
    required DiaryV2StatItem item,
    required bool isSpanish,
  }) {
    if (item.icon == CupertinoIcons.bookmark) {
      return isSpanish
          ? const _StatLabelSpec(
              lineOne: 'Mejores',
              lineTwo: 'momentos',
              emphasizeFirstLine: false,
              emphasizeSecondLine: true,
            )
          : const _StatLabelSpec(
              lineOne: 'Saved',
              lineTwo: 'moments',
              emphasizeFirstLine: false,
              emphasizeSecondLine: true,
            );
    }

    return _StatLabelSpec(
      lineOne: item.label,
      lineTwo: item.detail,
      emphasizeFirstLine: false,
      emphasizeSecondLine: true,
    );
  }
}

class _StatLabelSpec {
  const _StatLabelSpec({
    required this.lineOne,
    required this.lineTwo,
    required this.emphasizeFirstLine,
    required this.emphasizeSecondLine,
  });

  final String lineOne;
  final String lineTwo;
  final bool emphasizeFirstLine;
  final bool emphasizeSecondLine;
}
