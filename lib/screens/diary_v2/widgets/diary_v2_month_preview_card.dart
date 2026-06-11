import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

enum DiaryV2MonthDotTone {
  red,
  orange,
  camel,
  greenSoft,
  greenStrong,
  neutral,
}

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
    required this.dominantMood,
    required this.dots,
  });

  final String title;
  final String summary;
  final String moodLabel;
  final int? dominantMood;
  final List<DiaryV2MonthDot> dots;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: DiaryV2Styles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: DiaryV2Styles.title(context).copyWith(
                    fontSize: 17,
                    color: DiaryV2Styles.textStrong,
                  ),
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: DiaryV2Styles.mutedTextStrong,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _WeekLabels(),
          const SizedBox(height: 12),
          _MonthDotGrid(dots: dots),
          const SizedBox(height: 15),
          Text(
            summary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DiaryV2Styles.textStrong,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  moodLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DiaryV2Styles.mutedTextStrong,
                        height: 1.25,
                      ),
                ),
              ),
              if (dominantMood != null) ...[
                const SizedBox(width: 8),
                _MonthMoodBadge(moodValue: dominantMood!),
              ],
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
                    color: DiaryV2Styles.mutedTextStrong.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
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
        final cellWidth = (constraints.maxWidth - (columns - 1) * 7) / columns;
        final dotSize = cellWidth.clamp(12.0, 15.0);
        return Wrap(
          spacing: 7,
          runSpacing: 9,
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
    final tone = _toneStyle(dot.tone);
    final showsMood = dot.active && dot.moodValue != null;
    final baseSize = dot.highlighted ? size + 2 : size - 0.5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: baseSize,
      height: baseSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: showsMood
            ? tone.fill
            : dot.highlighted
                ? Colors.white
                : dot.active
                    ? const Color(0xFFE8DDD0)
                    : const Color(0xFFF1EAE0),
        shape: BoxShape.circle,
        border: Border.all(
          color: dot.highlighted
              ? (showsMood ? tone.border : DiaryV2Styles.accent.withValues(alpha: 0.62))
              : showsMood
                  ? tone.border.withValues(alpha: 0.96)
                  : dot.active
                      ? DiaryV2Styles.border.withValues(alpha: 0.92)
                      : Colors.transparent,
          width: dot.highlighted ? 1.8 : showsMood ? 1.2 : dot.active ? 0.9 : 0,
        ),
      ),
      child: showsMood
          ? Icon(
              _iconForMood(dot.moodValue!),
              size: (baseSize - 5).clamp(8.5, 11.0),
              color: tone.border,
            )
          : dot.active
              ? Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DiaryV2Styles.mutedTextStrong.withValues(alpha: 0.52),
                    shape: BoxShape.circle,
                  ),
                )
              : null,
    );
  }

  _MonthToneStyle _toneStyle(DiaryV2MonthDotTone tone) {
    switch (tone) {
      case DiaryV2MonthDotTone.red:
        return const _MonthToneStyle(
          fill: Color(0xFFF8E4DE),
          border: Color(0xFF8F5146),
        );
      case DiaryV2MonthDotTone.orange:
        return const _MonthToneStyle(
          fill: Color(0xFFF8E8D7),
          border: Color(0xFF976739),
        );
      case DiaryV2MonthDotTone.camel:
        return const _MonthToneStyle(
          fill: Color(0xFFF5E7D2),
          border: Color(0xFF8C6339),
        );
      case DiaryV2MonthDotTone.greenSoft:
        return const _MonthToneStyle(
          fill: Color(0xFFEAF2E3),
          border: Color(0xFF667B4D),
        );
      case DiaryV2MonthDotTone.greenStrong:
        return const _MonthToneStyle(
          fill: Color(0xFFE2EED9),
          border: Color(0xFF4F6B38),
        );
      case DiaryV2MonthDotTone.neutral:
        return const _MonthToneStyle(
          fill: Color(0xFFF1EAE0),
          border: Color(0xFF9B8778),
        );
    }
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

class _MonthMoodBadge extends StatelessWidget {
  const _MonthMoodBadge({
    required this.moodValue,
  });

  final int moodValue;

  @override
  Widget build(BuildContext context) {
    final tone = _toneForMood(moodValue);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: tone.fill,
        shape: BoxShape.circle,
        border: Border.all(
          color: tone.border,
          width: 1.1,
        ),
      ),
      child: Icon(
        _iconForMood(moodValue),
        color: tone.border,
        size: 12.5,
      ),
    );
  }

  _MonthToneStyle _toneForMood(int moodValue) {
    switch (moodValue) {
      case -2:
        return const _MonthToneStyle(
          fill: Color(0xFFF8E4DE),
          border: Color(0xFF8F5146),
        );
      case -1:
        return const _MonthToneStyle(
          fill: Color(0xFFF8E8D7),
          border: Color(0xFF976739),
        );
      case 1:
        return const _MonthToneStyle(
          fill: Color(0xFFEAF2E3),
          border: Color(0xFF667B4D),
        );
      case 2:
        return const _MonthToneStyle(
          fill: Color(0xFFE2EED9),
          border: Color(0xFF4F6B38),
        );
      default:
        return const _MonthToneStyle(
          fill: Color(0xFFF5E7D2),
          border: Color(0xFF8C6339),
        );
    }
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

class _MonthToneStyle {
  const _MonthToneStyle({
    required this.fill,
    required this.border,
  });

  final Color fill;
  final Color border;
}
