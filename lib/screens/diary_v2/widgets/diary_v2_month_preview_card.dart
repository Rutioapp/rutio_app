import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

enum DiaryV2MonthDotTone { calm, warm, soft, neutral }

class DiaryV2MonthDot {
  const DiaryV2MonthDot({
    required this.active,
    required this.tone,
    this.moodValue,
    this.highlighted = false,
  });

  final bool active;
  final bool highlighted;
  final DiaryV2MonthDotTone tone;
  final int? moodValue;
}

class DiaryV2MonthPreviewCard extends StatelessWidget {
  const DiaryV2MonthPreviewCard({
    super.key,
    required this.title,
    required this.summary,
    required this.moodLabel,
    required this.dots,
  });

  final String title;
  final String summary;
  final String moodLabel;
  final List<DiaryV2MonthDot> dots;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: DiaryV2Styles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: DiaryV2Styles.title(context).copyWith(fontSize: 17),
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: DiaryV2Styles.text,
                size: 15,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _WeekLabels(),
          const SizedBox(height: 10),
          _MonthDotGrid(dots: dots),
          const SizedBox(height: 14),
          Text(
            summary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DiaryV2Styles.textStrong,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  moodLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DiaryV2Styles.mutedText,
                        height: 1.3,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.smiley,
                color: DiaryV2Styles.sage,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekLabels extends StatelessWidget {
  const _WeekLabels();

  @override
  Widget build(BuildContext context) {
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels
          .map(
            (label) => Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: DiaryV2Styles.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          )
          .toList(),
    );
  }
}

class _MonthDotGrid extends StatelessWidget {
  const _MonthDotGrid({required this.dots});

  final List<DiaryV2MonthDot> dots;

  @override
  Widget build(BuildContext context) {
    final visibleDots = dots.take(21).toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 7;
        final cellWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;
        final dotSize = cellWidth.clamp(12.0, 16.0);
        return Wrap(
          spacing: 8,
          runSpacing: 10,
          children: visibleDots
              .map(
                (dot) => SizedBox(
                  width: cellWidth,
                  child: Center(
                    child: _MonthDot(
                      dot: dot,
                      size: dotSize,
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MonthDot extends StatelessWidget {
  const _MonthDot({
    required this.dot,
    required this.size,
  });

  final DiaryV2MonthDot dot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = !dot.active
        ? const Color(0xFFE0DACE)
        : switch (dot.tone) {
            DiaryV2MonthDotTone.warm => DiaryV2Styles.accent,
            DiaryV2MonthDotTone.soft => DiaryV2Styles.sageMuted,
            DiaryV2MonthDotTone.neutral => DiaryV2Styles.mutedText,
            DiaryV2MonthDotTone.calm => DiaryV2Styles.sage,
          };
    final showsMood = dot.active && dot.moodValue != null;
    final baseSize = dot.highlighted ? size + 2 : size;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: baseSize,
      height: baseSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: showsMood
            ? Colors.white.withValues(alpha: dot.highlighted ? 0.98 : 0.9)
            : dot.highlighted
                ? Colors.white
                : color,
        shape: BoxShape.circle,
        border: Border.all(
          color: dot.highlighted ? color : Colors.transparent,
          width: dot.highlighted ? 2.6 : 0,
        ),
      ),
      child: showsMood
          ? Icon(
              _iconForMood(dot.moodValue!),
              size: (baseSize - 4).clamp(9.0, 12.0),
              color: color,
            )
          : null,
    );
  }

  IconData _iconForMood(int moodValue) {
    switch (moodValue) {
      case -2:
        return CupertinoIcons.cloud_rain;
      case -1:
        return CupertinoIcons.moon_zzz;
      case 1:
        return CupertinoIcons.sun_max;
      case 2:
        return CupertinoIcons.heart_circle;
      default:
        return CupertinoIcons.smiley;
    }
  }
}
