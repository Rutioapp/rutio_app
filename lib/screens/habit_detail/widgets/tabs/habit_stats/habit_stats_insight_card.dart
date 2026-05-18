import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_insight_resolver.dart';
import 'habit_stats_models.dart';

class HabitStatsInsightCard extends StatelessWidget {
  final HabitStatsShellData shellData;
  final HabitStatsInsight? insight;
  final String? insightLabel;
  final bool adaptiveLayout;
  static const _cardBorder = Color(0xFFE9E3D9);
  static const _cardText = Color(0xFF2F251C);
  static const _cardMuted = Color(0xFF746A60);
  static const _badgeBase = Color(0xFFF5EEDF);
  static const _badgeBorder = Color(0xFFE6D7BE);
  static const _shortTextThreshold = 120;
  static const _mediumTextThreshold = 200;
  static const _narrowWidthBreakpoint = 340.0;

  const HabitStatsInsightCard({
    super.key,
    required this.shellData,
    this.insight,
    this.insightLabel,
    this.adaptiveLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resolvedInsight =
        insight ?? resolveHabitStatsInsight(l10n, shellData);
    final badgeToneColor = _badgeColorForTone(resolvedInsight.tone);
    if (!adaptiveLayout) {
      return _buildCompactCard(
        context,
        insightLabel ?? l10n.habitStatsInsightLabel,
        resolvedInsight,
        badgeToneColor,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final density = _resolveInsightTextDensity(
          resolvedInsight: resolvedInsight,
          maxWidth: constraints.maxWidth,
        );
        final layout = _layoutForDensity(density);
        return _buildAdaptiveCard(
          context,
          insightLabel ?? l10n.habitStatsInsightLabel,
          resolvedInsight,
          badgeToneColor,
          layout,
        );
      },
    );
  }

  Widget _buildCompactCard(
    BuildContext context,
    String insightLabel,
    HabitStatsInsight resolvedInsight,
    Color badgeToneColor,
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _badgeBase,
              border: Border.all(color: _badgeBorder),
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: badgeToneColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insightLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 12,
                        color: _cardText,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  resolvedInsight.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w500,
                        color: _cardText,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  resolvedInsight.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: _cardMuted,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveCard(
    BuildContext context,
    String insightLabel,
    HabitStatsInsight resolvedInsight,
    Color badgeToneColor,
    _HabitStatsInsightLayout layout,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final icon = _buildIcon(badgeToneColor);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: layout.minHeight),
      padding: layout.padding,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: layout.vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(width: 8),
                    Text(
                      insightLabel,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 12,
                        color: _cardText,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: layout.headerSpacing),
                Text(
                  resolvedInsight.title,
                  maxLines: layout.titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w500,
                    color: _cardText,
                    height: 1.12,
                  ),
                ),
                SizedBox(height: layout.bodySpacing),
                Text(
                  resolvedInsight.body,
                  maxLines: layout.bodyMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: _cardMuted,
                    height: layout.bodyLineHeight,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insightLabel,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 12,
                          color: _cardText,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: layout.headerSpacing),
                      Text(
                        resolvedInsight.title,
                        maxLines: layout.titleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.w500,
                          color: _cardText,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: layout.bodySpacing),
                      Text(
                        resolvedInsight.body,
                        maxLines: layout.bodyMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: _cardMuted,
                          height: layout.bodyLineHeight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildIcon(Color badgeToneColor) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _badgeBase,
        border: Border.all(color: _badgeBorder),
      ),
      child: Icon(
        Icons.lightbulb_rounded,
        color: badgeToneColor,
        size: 16,
      ),
    );
  }

  _InsightTextDensity _resolveInsightTextDensity({
    required HabitStatsInsight resolvedInsight,
    required double maxWidth,
  }) {
    final textLength =
        '${resolvedInsight.title} ${resolvedInsight.body}'.trim().length;
    var density = textLength <= _shortTextThreshold
        ? _InsightTextDensity.short
        : textLength <= _mediumTextThreshold
            ? _InsightTextDensity.medium
            : _InsightTextDensity.long;

    if (maxWidth <= _narrowWidthBreakpoint &&
        density != _InsightTextDensity.long) {
      density = density == _InsightTextDensity.short
          ? _InsightTextDensity.medium
          : _InsightTextDensity.long;
    }
    return density;
  }

  _HabitStatsInsightLayout _layoutForDensity(_InsightTextDensity density) {
    switch (density) {
      case _InsightTextDensity.short:
        return const _HabitStatsInsightLayout(
          vertical: false,
          titleMaxLines: 1,
          bodyMaxLines: 2,
          minHeight: 96,
          padding: EdgeInsets.fromLTRB(12, 10, 12, 11),
          headerSpacing: 6,
          bodySpacing: 4,
          bodyLineHeight: 1.25,
        );
      case _InsightTextDensity.medium:
        return const _HabitStatsInsightLayout(
          vertical: false,
          titleMaxLines: 2,
          bodyMaxLines: 3,
          minHeight: 110,
          padding: EdgeInsets.fromLTRB(12, 11, 12, 12),
          headerSpacing: 6,
          bodySpacing: 5,
          bodyLineHeight: 1.28,
        );
      case _InsightTextDensity.long:
        return const _HabitStatsInsightLayout(
          vertical: true,
          titleMaxLines: 2,
          bodyMaxLines: 4,
          minHeight: 126,
          padding: EdgeInsets.fromLTRB(13, 12, 13, 13),
          headerSpacing: 8,
          bodySpacing: 6,
          bodyLineHeight: 1.3,
        );
    }
  }
}

Color _badgeColorForTone(HabitStatsInsightTone tone) {
  switch (tone) {
    case HabitStatsInsightTone.positive:
      return const Color(0xFF4E8A4A);
    case HabitStatsInsightTone.recovery:
      return const Color(0xFF9B6A2A);
    case HabitStatsInsightTone.paused:
      return const Color(0xFF7A6A56);
    case HabitStatsInsightTone.amber:
      return const Color(0xFFB57A2C);
    case HabitStatsInsightTone.neutral:
      return const Color(0xFF806744);
  }
}

enum _InsightTextDensity {
  short,
  medium,
  long,
}

class _HabitStatsInsightLayout {
  final bool vertical;
  final int titleMaxLines;
  final int bodyMaxLines;
  final double minHeight;
  final EdgeInsets padding;
  final double headerSpacing;
  final double bodySpacing;
  final double bodyLineHeight;

  const _HabitStatsInsightLayout({
    required this.vertical,
    required this.titleMaxLines,
    required this.bodyMaxLines,
    required this.minHeight,
    required this.padding,
    required this.headerSpacing,
    required this.bodySpacing,
    required this.bodyLineHeight,
  });
}
