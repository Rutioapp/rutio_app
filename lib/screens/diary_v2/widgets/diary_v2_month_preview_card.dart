import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../diary_v2_mood_visuals.dart';
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
    final labels = _weekLabelsForLocale(Localizations.localeOf(context));
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
          _WeekLabels(labels: labels),
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
  const _WeekLabels({
    required this.labels,
  });

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _MonthPreviewGridMetrics.fromWidth(constraints.maxWidth);
        return Row(
          children: labels
              .map(
                (label) => SizedBox(
                  width: metrics.cellExtent,
                  child: Center(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: DiaryV2Styles.mutedTextStrong.withValues(alpha: 0.78),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
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

class _MonthDotGrid extends StatelessWidget {
  const _MonthDotGrid({required this.dots});

  final List<DiaryV2MonthDot> dots;

  @override
  Widget build(BuildContext context) {
    final visibleDots = dots.take(21).toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _MonthPreviewGridMetrics.fromWidth(constraints.maxWidth);
        return Wrap(
          spacing: metrics.spacing,
          runSpacing: metrics.runSpacing,
          children: visibleDots
              .map(
                (dot) => SizedBox(
                  width: metrics.cellExtent,
                  height: metrics.cellExtent,
                  child: _MonthDayCell(
                    dot: dot,
                    metrics: metrics,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.dot,
    required this.metrics,
  });

  final DiaryV2MonthDot dot;
  final _MonthPreviewGridMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final tone = _toneStyle(dot.tone);
    final showsMood = dot.active && dot.moodValue != null;
    final circleSize =
        dot.highlighted ? metrics.dotSize + 2 : metrics.dotSize;

    return SizedBox.square(
      dimension: metrics.cellExtent,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: circleSize,
          height: circleSize,
          child: _MonthMoodCircle(
            size: circleSize,
            tone: tone,
            moodValue: dot.moodValue,
            isActive: dot.active,
            isHighlighted: dot.highlighted,
            inactiveDotSize: metrics.inactiveDotSize,
            showMood: showsMood,
            moodScale: 0.72,
          ),
        ),
      ),
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
}

class _MonthMoodCircle extends StatelessWidget {
  const _MonthMoodCircle({
    required this.size,
    required this.tone,
    required this.moodValue,
    required this.isActive,
    required this.isHighlighted,
    required this.inactiveDotSize,
    required this.showMood,
    required this.moodScale,
  });

  final double size;
  final _MonthToneStyle tone;
  final int? moodValue;
  final bool isActive;
  final bool isHighlighted;
  final double inactiveDotSize;
  final bool showMood;
  final double moodScale;

  @override
  Widget build(BuildContext context) {
    final fillColor = showMood
        ? tone.fill
        : isHighlighted
            ? Colors.white
            : isActive
                ? const Color(0xFFE8DDD0)
                : const Color(0xFFF1EAE0);
    final borderColor = isHighlighted
        ? (showMood
            ? tone.border
            : DiaryV2Styles.accent.withValues(alpha: 0.62))
        : showMood
            ? tone.border.withValues(alpha: 0.96)
            : isActive
                ? DiaryV2Styles.border.withValues(alpha: 0.92)
                : Colors.transparent;
    final borderWidth =
        isHighlighted ? 1.8 : showMood ? 1.2 : isActive ? 0.9 : 0.0;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fillColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
              ),
            ),
          ),
          if (showMood && moodValue != null)
            _CenteredMoodEmoji(
              moodValue: moodValue!,
              boxSize: size * moodScale,
              color: tone.border,
              fontSize: moodValue == 0 ? size * 0.68 : size * 0.64,
            )
          else if (isActive)
            SizedBox.square(
              dimension: inactiveDotSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: DiaryV2Styles.mutedTextStrong.withValues(alpha: 0.52),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CenteredMoodEmoji extends StatelessWidget {
  const _CenteredMoodEmoji({
    required this.moodValue,
    required this.boxSize,
    required this.color,
    required this.fontSize,
  });

  final int moodValue;
  final double boxSize;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final iconOffset = _moodIconOffset(moodValue, boxSize);

    return Center(
      child: Transform.translate(
        offset: iconOffset,
        child: SizedBox.square(
          dimension: boxSize,
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                DiaryMoodVisuals.emojiFor(moodValue),
                textAlign: TextAlign.center,
                textScaler: TextScaler.noScaling,
                strutStyle: const StrutStyle(
                  height: 1,
                  forceStrutHeight: true,
                  leading: 0,
                ),
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1,
                  leadingDistribution: TextLeadingDistribution.even,
                  color: color,
                  fontWeight:
                      moodValue == 0 ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Offset _moodIconOffset(int moodValue, double boxSize) {
  switch (moodValue) {
    case -2:
      return Offset(0, boxSize <= 14 ? 0.8 : 1.1);
    case -1:
      return Offset(0, boxSize <= 14 ? 0.8 : 1.0);
    case 1:
      return Offset(0, boxSize <= 14 ? 1.1 : 1.4);
    case 2:
      return Offset(0, boxSize <= 14 ? 1.8 : 2.2);
    default:
      return Offset(0, boxSize <= 14 ? 0.3 : 0.5);
  }
}

class _MonthPreviewGridMetrics {
  const _MonthPreviewGridMetrics({
    required this.cellExtent,
    required this.dotSize,
    required this.inactiveDotSize,
    required this.spacing,
    required this.runSpacing,
  });

  final double cellExtent;
  final double dotSize;
  final double inactiveDotSize;
  final double spacing;
  final double runSpacing;

  static _MonthPreviewGridMetrics fromWidth(double width) {
    const columns = 7;
    final spacing = width < 300 ? 4.0 : width < 340 ? 5.0 : 6.0;
    final cellExtent = (width - (columns - 1) * spacing) / columns;
    final dotSize = cellExtent.clamp(25.0, 31.0);

    return _MonthPreviewGridMetrics(
      cellExtent: cellExtent,
      dotSize: dotSize,
      inactiveDotSize: dotSize >= 28 ? 6.0 : 5.0,
      spacing: spacing,
      runSpacing: width < 300 ? 8.0 : 10.0,
    );
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
    return SizedBox(
      width: 20,
      height: 20,
      child: _MonthMoodCircle(
        size: 20,
        tone: tone,
        moodValue: moodValue,
        isActive: true,
        isHighlighted: false,
        inactiveDotSize: 0,
        showMood: true,
        moodScale: 0.7,
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
}

class _MonthToneStyle {
  const _MonthToneStyle({
    required this.fill,
    required this.border,
  });

  final Color fill;
  final Color border;
}

List<String> _weekLabelsForLocale(Locale locale) {
  if (locale.languageCode == 'es') {
    return const ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  }
  return const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
}
