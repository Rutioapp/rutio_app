import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/l10n.dart';

class StatisticsV3WeeklyActivityShell extends StatelessWidget {
  const StatisticsV3WeeklyActivityShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.days,
  });

  final String title;
  final String subtitle;
  final List<StatisticsV3WeeklyActivityDay> days;

  static const _border = Color(0xFFE9E3D9);
  static const _text = Color(0xFF2F251C);
  static const _green = Color(0xFF4E7D35);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 172;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WeeklyActivityHeader(
                title: title,
                compact: compact,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6A6155),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: days.isEmpty
                    ? _WeeklyActivityEmptyState(
                        message: l10n.statisticsV3ProgressMessageEmpty,
                      )
                    : _WeeklyActivityChart(
                        days: days,
                        weekdayLabels: _weekdayLabels(locale, l10n, days),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeeklyActivityHeader extends StatelessWidget {
  const _WeeklyActivityHeader({
    required this.title,
    required this.compact,
  });

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 22 : 23,
      child: Row(
        children: [
          Container(
            width: compact ? 21 : 23,
            height: compact ? 21 : 23,
            decoration: BoxDecoration(
              color:
                  StatisticsV3WeeklyActivityShell._green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.auto_graph_rounded,
              size: compact ? 15 : 16,
              color: StatisticsV3WeeklyActivityShell._green,
            ),
          ),
          const SizedBox(width: 7),
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
                  color: StatisticsV3WeeklyActivityShell._text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyActivityEmptyState extends StatelessWidget {
  const _WeeklyActivityEmptyState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 1,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E2D7).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.2,
                color: Color(0xFF8E8274),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyActivityChart extends StatelessWidget {
  const _WeeklyActivityChart({
    required this.days,
    required this.weekdayLabels,
  });

  final List<StatisticsV3WeeklyActivityDay> days;
  final List<String> weekdayLabels;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: constraints.biggest,
          painter: _WeeklyActivityChartPainter(
            days: days,
            weekdayLabels: weekdayLabels,
          ),
        );
      },
    );
  }
}

class _WeeklyActivityChartPainter extends CustomPainter {
  _WeeklyActivityChartPainter({
    required this.days,
    required this.weekdayLabels,
  });

  final List<StatisticsV3WeeklyActivityDay> days;
  final List<String> weekdayLabels;

  static const _labelColor = Color(0xFFB0A79A);
  static const _gridColor = Color(0x2DE4D9CA);
  static const _axisColor = Color(0x44D8CCBC);
  static const _lineColor = Color(0xFF6E8B62);
  static const _futureColor = Color(0xFFB9B1A6);
  static const _todayColor = Color(0xFF5F7855);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    const leftLabelWidth = 26.0;
    const rightPadding = 2.0;
    const topPadding = 4.0;
    const bottomLabelHeight = 14.0;
    const xLabelOffset = 2.0;

    final chartLeft = leftLabelWidth;
    final chartTop = topPadding;
    final chartWidth = math.max(0.0, size.width - chartLeft - rightPadding);
    final chartHeight = math.max(
      0.0,
      size.height - chartTop - bottomLabelHeight - xLabelOffset,
    );
    final chartRect = Rect.fromLTWH(
      chartLeft,
      chartTop,
      chartWidth,
      chartHeight,
    );

    _drawGrid(canvas, chartRect);
    _drawYAxisLabels(canvas, chartRect);

    if (days.isEmpty || chartRect.width <= 0 || chartRect.height <= 0) {
      return;
    }

    final points = _seriesPoints(chartRect);
    if (points.isEmpty) {
      return;
    }

    canvas.save();
    canvas.clipRect(chartRect);

    _drawArea(canvas, chartRect, points);
    _drawLine(canvas, points);
    _drawPoints(canvas, points);

    canvas.restore();

    _drawXAxisLabels(canvas, chartRect);
  }

  void _drawGrid(Canvas canvas, Rect chartRect) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _gridColor;

    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _axisColor;

    for (final value in const [100, 75, 50, 25, 0]) {
      final y = _valueToY(chartRect, value.toDouble());
      canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), gridPaint);
    }

    canvas.drawLine(
      Offset(chartRect.left, chartRect.bottom),
      Offset(chartRect.right, chartRect.bottom),
      axisPaint,
    );
  }

  void _drawYAxisLabels(Canvas canvas, Rect chartRect) {
    const values = [100, 75, 50, 25, 0];

    for (final value in values) {
      final painter = TextPainter(
        text: TextSpan(
          text: '$value',
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: _labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
        maxLines: 1,
      )..layout(maxWidth: 20);

      final y = _valueToY(chartRect, value.toDouble());
      painter.paint(
        canvas,
        Offset(chartRect.left - painter.width - 4, y - painter.height / 2),
      );
    }
  }

  void _drawXAxisLabels(Canvas canvas, Rect chartRect) {
    final count = math.min(days.length, weekdayLabels.length);
    if (count == 0) {
      return;
    }

    for (var index = 0; index < count; index++) {
      final label = weekdayLabels[index];
      final pointX = _xForIndex(chartRect, index, count);
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF908477),
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 1,
      )..layout(minWidth: 0, maxWidth: 20);

      painter.paint(
        canvas,
        Offset(pointX - painter.width / 2, chartRect.bottom + 6),
      );
    }
  }

  void _drawArea(Canvas canvas, Rect chartRect, List<Offset> points) {
    final areaPath = _buildSmoothPath(points)
      ..lineTo(points.last.dx, chartRect.bottom)
      ..lineTo(points.first.dx, chartRect.bottom)
      ..close();

    final areaPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0x558BA56B),
          const Color(0x0D8BA56B),
        ],
      ).createShader(chartRect);

    canvas.drawPath(areaPath, areaPaint);
  }

  void _drawLine(Canvas canvas, List<Offset> points) {
    if (points.length == 1) {
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = _lineColor;
      canvas.drawCircle(points.first, 3.2, dotPaint);
      return;
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _lineColor;

    canvas.drawPath(_buildSmoothPath(points), linePaint);

    final firstFutureIndex = days.indexWhere((day) => day.isFuture);
    if (firstFutureIndex >= 0 && firstFutureIndex < points.length) {
      final futurePoints = points.sublist(firstFutureIndex);
      if (futurePoints.length > 1) {
        final futurePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = _futureColor.withValues(alpha: 0.55);
        canvas.drawPath(_buildSmoothPath(futurePoints), futurePaint);
      }
    }
  }

  void _drawPoints(Canvas canvas, List<Offset> points) {
    final count = math.min(days.length, points.length);
    for (var index = 0; index < count; index++) {
      final day = days[index];
      final point = points[index];
      final radius = day.isToday ? 3.9 : 3.1;
      final fillColor = day.isFuture
          ? _futureColor.withValues(alpha: 0.55)
          : (day.isToday ? _todayColor : _lineColor);
      final borderColor = const Color(0xFFF7F3EC).withValues(alpha: 0.9);

      canvas.drawCircle(
        point,
        radius + 1.05,
        Paint()
          ..style = PaintingStyle.fill
          ..color = borderColor,
      );
      canvas.drawCircle(
        point,
        radius,
        Paint()
          ..style = PaintingStyle.fill
          ..color = fillColor,
      );
    }
  }

  List<Offset> _seriesPoints(Rect chartRect) {
    final count = math.min(days.length, weekdayLabels.length);
    if (count == 0) {
      return const [];
    }

    final points = <Offset>[];
    for (var index = 0; index < count; index++) {
      final day = days[index];
      final x = _xForIndex(chartRect, index, count);
      final y = _valueToY(
        chartRect,
        day.percentage.toDouble().clamp(0.0, 100.0).toDouble(),
      );
      points.add(Offset(x, y));
    }
    return points;
  }

  double _xForIndex(Rect chartRect, int index, int count) {
    if (count <= 1) {
      return chartRect.center.dx;
    }
    return chartRect.left + (chartRect.width * index / (count - 1));
  }

  double _valueToY(Rect chartRect, double value) {
    final clamped = value.clamp(0.0, 100.0).toDouble();
    return chartRect.bottom - (chartRect.height * clamped / 100.0);
  }

  Path _buildSmoothPath(List<Offset> points) {
    if (points.isEmpty) {
      return Path();
    }

    if (points.length == 1) {
      return Path()..addOval(Rect.fromCircle(center: points.first, radius: 0.5));
    }

    if (points.length == 2) {
      return Path()
        ..moveTo(points.first.dx, points.first.dy)
        ..lineTo(points.last.dx, points.last.dy);
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 0; index < points.length - 1; index++) {
      final p0 = index == 0 ? points[index] : points[index - 1];
      final p1 = points[index];
      final p2 = points[index + 1];
      final p3 = index + 2 < points.length ? points[index + 2] : p2;

      final c1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final c2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );

      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _WeeklyActivityChartPainter oldDelegate) {
    if (oldDelegate.days.length != days.length ||
        oldDelegate.weekdayLabels.length != weekdayLabels.length) {
      return true;
    }

    for (var index = 0; index < days.length; index++) {
      final oldDay = oldDelegate.days[index];
      final nextDay = days[index];
      if (oldDay.date != nextDay.date ||
          oldDay.completedCount != nextDay.completedCount ||
          oldDay.expectedCount != nextDay.expectedCount ||
          oldDay.percentage != nextDay.percentage ||
          oldDay.isToday != nextDay.isToday ||
          oldDay.isFuture != nextDay.isFuture) {
        return true;
      }
    }

    for (var index = 0; index < weekdayLabels.length; index++) {
      if (oldDelegate.weekdayLabels[index] != weekdayLabels[index]) {
        return true;
      }
    }

    return false;
  }
}

List<String> _weekdayLabels(
  Locale locale,
  AppLocalizations l10n,
  List<StatisticsV3WeeklyActivityDay> days,
) {
  final isSpanish = locale.languageCode.toLowerCase() == 'es';
  if (isSpanish) {
    return const ['L', 'M', 'X', 'J', 'V', 'S', 'D']
        .sublist(0, math.min(days.length, 7));
  }

  return [
    for (final day in days.take(7)) l10n.weekdayShort(day.date.weekday),
  ];
}
