import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';

class StatisticsV3ConsistencyCard extends StatelessWidget {
  const StatisticsV3ConsistencyCard({
    super.key,
    required this.title,
    required this.completedHabits,
    required this.totalHabits,
    required this.consistencyPct,
    required this.streakDays,
    this.onTap,
  });

  static const _radius = 24.0;
  static const _padding = EdgeInsets.fromLTRB(12, 10, 12, 10);
  static const _cream = Color(0xFFFDFBF7);
  static const _border = Color(0xFFE9E3D9);
  static const _text = Color(0xFF2F2A24);
  static const _mutedText = Color(0xFF746A60);
  static const _track = Color(0xFFE8E7E0);
  static const _divider = Color(0xFFEDE4D9);
  static const _pending = Color(0xFFCB7B47);
  static const _streak = Color(0xFF8F73BC);

  final String title;
  final int completedHabits;
  final int totalHabits;
  final int consistencyPct;
  final int streakDays;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pct = consistencyPct.clamp(0, 100);
    final pendingCount = (totalHabits - completedHabits).clamp(0, totalHabits);
    final progressColor = _progressColorForPct(pct);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Container(
          padding: _padding,
          decoration: BoxDecoration(
            color: _cream.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _border),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 172;
              final headerHeight = compact ? 24.0 : 26.0;
              final footerHeight = compact ? 32.0 : 34.0;
              final headerGap = compact ? 6.0 : 7.0;
              final dividerGap = compact ? 5.0 : 6.0;
              final availableHeight = constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : 178.0;
              final bodyHeight = math.max(
                68.0,
                availableHeight -
                    headerHeight -
                    headerGap -
                    dividerGap -
                    1 -
                    dividerGap -
                    footerHeight,
              );
              final ringSize = math
                  .min(bodyHeight, constraints.maxWidth * 0.46)
                  .clamp(70.0, compact ? 78.0 : 84.0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ConsistencyHeader(
                    title: title,
                    color: progressColor,
                    height: headerHeight,
                    compact: compact,
                  ),
                  SizedBox(height: headerGap),
                  SizedBox(
                    height: bodyHeight,
                    child: _ConsistencyBody(
                      completedHabits: completedHabits,
                      totalHabits: totalHabits,
                      percentage: pct,
                      completedHabitsLabel:
                          l10n.statisticsV3SummaryCompletedLabel,
                      color: progressColor,
                      ringSize: ringSize,
                      compact: compact,
                    ),
                  ),
                  SizedBox(height: dividerGap),
                  const Divider(height: 1, thickness: 1, color: _divider),
                  SizedBox(height: dividerGap),
                  SizedBox(
                    height: footerHeight,
                    child: _ConsistencyFooter(
                      pendingCount: pendingCount,
                      streakDays: streakDays,
                      pendingLabel:
                          l10n.statisticsV3ConsistencyPendingLabel,
                      streakLabel:
                          l10n.statisticsV3ConsistencyStreakLabel,
                      compact: compact,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Color _progressColorForPct(int pct) {
    if (pct < 25) return const Color(0xFFD46C4E);
    if (pct < 50) return const Color(0xFFD1A24A);
    if (pct < 75) return const Color(0xFF86A66F);
    if (pct < 90) return const Color(0xFF6F9961);
    return const Color(0xFF4E7756);
  }
}

class _ConsistencyHeader extends StatelessWidget {
  const _ConsistencyHeader({
    required this.title,
    required this.color,
    required this.height,
    required this.compact,
  });

  final String title;
  final Color color;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          _CircleIcon(
            color: color,
            icon: Icons.track_changes_rounded,
            size: height,
            iconSize: compact ? 13 : 14,
            alpha: 0.12,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  fontSize: compact ? 13.4 : 14.2,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: StatisticsV3ConsistencyCard._text,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: height,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.74),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE8E0D4)),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: compact ? 15 : 16,
              color: const Color(0xFF857868),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsistencyBody extends StatelessWidget {
  const _ConsistencyBody({
    required this.completedHabits,
    required this.totalHabits,
    required this.percentage,
    required this.completedHabitsLabel,
    required this.color,
    required this.ringSize,
    required this.compact,
  });

  final int completedHabits;
  final int totalHabits;
  final int percentage;
  final String completedHabitsLabel;
  final Color color;
  final double ringSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ConsistencyProgressRing(
          percentage: percentage,
          color: color,
          size: ringSize,
          compact: compact,
        ),
        SizedBox(width: compact ? 8 : 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$completedHabits de $totalHabits',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: compact ? 18 : 20,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: StatisticsV3ConsistencyCard._text,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                completedHabitsLabel,
                maxLines: 3,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: compact ? 10.5 : 11,
                  height: 1.12,
                  fontWeight: FontWeight.w500,
                  color: StatisticsV3ConsistencyCard._mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsistencyProgressRing extends StatelessWidget {
  const _ConsistencyProgressRing({
    required this.percentage,
    required this.color,
    required this.size,
    required this.compact,
  });

  final int percentage;
  final Color color;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _ProgressRingPainter(
              progress: percentage / 100,
              color: color,
              strokeWidth: compact ? 6.2 : 6.8,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: (size * 0.36).clamp(24.0, 31.0),
                  height: 0.96,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConsistencyFooter extends StatelessWidget {
  const _ConsistencyFooter({
    required this.pendingCount,
    required this.streakDays,
    required this.pendingLabel,
    required this.streakLabel,
    required this.compact,
  });

  final int pendingCount;
  final int streakDays;
  final String pendingLabel;
  final String streakLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ConsistencyFooterMetric(
            value: pendingCount.toString(),
            label: pendingLabel,
            icon: Icons.schedule_rounded,
            color: StatisticsV3ConsistencyCard._pending,
            compact: compact,
          ),
        ),
        Container(
          width: 1,
          height: compact ? 26 : 30,
          margin: EdgeInsets.symmetric(horizontal: compact ? 7 : 9),
          color: const Color(0xFFE8E0D4).withValues(alpha: 0.75),
        ),
        Expanded(
          child: _ConsistencyFooterMetric(
            value: streakDays.toString(),
            label: streakLabel,
            icon: Icons.local_fire_department_outlined,
            color: StatisticsV3ConsistencyCard._streak,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

class _ConsistencyFooterMetric extends StatelessWidget {
  const _ConsistencyFooterMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.compact,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 20.0 : 22.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CircleIcon(
              color: color,
              icon: icon,
              size: iconSize,
              iconSize: compact ? 11.5 : 12.5,
              alpha: 0.13,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: compact ? 14.5 : 15.5,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: StatisticsV3ConsistencyCard._text,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontSize: compact ? 9.5 : 9.8,
            height: 1,
            fontWeight: FontWeight.w500,
            color: StatisticsV3ConsistencyCard._mutedText,
          ),
        ),
      ],
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.color,
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.alpha,
  });

  final Color color;
  final IconData icon;
  final double size;
  final double iconSize;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: color,
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = StatisticsV3ConsistencyCard._track;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
