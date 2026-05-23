import 'package:flutter/material.dart';

class StatisticsV3GlobalInsightFooter extends StatelessWidget {
  const StatisticsV3GlobalInsightFooter({
    super.key,
    required this.label,
    required this.emoji,
    required this.message,
  });

  static const _cardBorder = Color(0xFFE9E3D9);
  static const _cardText = Color(0xFF2F251C);
  static const _cardMuted = Color(0xFF746A60);
  static const _badgeBase = Color(0xFFF5EEDF);
  static const _badgeBorder = Color(0xFFE6D7BE);

  final String label;
  final String emoji;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final messageStyle = textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          color: _cardMuted,
          height: 1.25,
        );
    final labelStyle = textTheme.titleMedium?.copyWith(
          fontSize: 12,
          color: _cardText,
          fontWeight: FontWeight.w600,
          height: 1.1,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxMessageWidth = constraints.maxWidth - (12 + 30 + 8 + 12);
        final estimatedLines = _estimateMessageLineCount(
          context,
          style: messageStyle,
          maxWidth: maxMessageWidth,
        );
        final verticalPadding = _verticalPaddingForLineCount(estimatedLines);

        return Container(
          key: const Key('statisticsV3GlobalInsightFooter'),
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(12, verticalPadding, 12, verticalPadding),
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
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _badgeBase,
                  border: Border.all(color: _badgeBorder),
                ),
                child: Text(
                  emoji,
                  key: const Key('statisticsV3GlobalInsightEmoji'),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: messageStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _estimateMessageLineCount(
    BuildContext context, {
    required TextStyle? style,
    required double maxWidth,
  }) {
    if (maxWidth <= 0) return 3;
    final painter = TextPainter(
      text: TextSpan(text: message, style: style),
      maxLines: 3,
      textDirection: Directionality.of(context),
      ellipsis: '...',
    )..layout(maxWidth: maxWidth);
    return painter.computeLineMetrics().length.clamp(1, 3);
  }

  double _verticalPaddingForLineCount(int lineCount) {
    if (lineCount <= 1) return 8;
    if (lineCount == 2) return 10;
    return 12;
  }
}
