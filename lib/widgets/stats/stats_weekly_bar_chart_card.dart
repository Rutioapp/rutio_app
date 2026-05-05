import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'helpers/stats_card_surface.dart';
import 'helpers/stats_number_formatter.dart';

class StatsBarPoint {
  final String label;
  final double value;
  final bool isActive;

  const StatsBarPoint({
    required this.label,
    required this.value,
    required this.isActive,
  });
}

class StatsWeeklyBarChartCard extends StatelessWidget {
  const StatsWeeklyBarChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.accent,
    this.valueFormatter,
  });

  final String title;
  final String subtitle;
  final List<StatsBarPoint> points;
  final Color accent;
  final String Function(double value)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.isEmpty
        ? 1.0
        : points
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1.0, double.infinity);

    final activePoint = points.where((p) => p.isActive).cast<StatsBarPoint?>().firstWhere(
          (p) => p != null,
          orElse: () => null,
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: StatsCardSurface.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B8B8B),
            ),
          ),
          if (activePoint != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${activePoint.label}: ${_format(activePoint.value)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: CustomPaint(
              painter: _LineChartPainter(
                points: points,
                maxValue: maxValue,
                accent: accent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: points
                .map(
                  (p) => Expanded(
                    child: Text(
                      p.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: p.isActive ? FontWeight.w800 : FontWeight.w600,
                        color: p.isActive
                            ? accent
                            : const Color(0xFF8B8B8B),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String _format(double value) {
    if (valueFormatter != null) {
      return valueFormatter!(value);
    }
    return StatsNumberFormatter.compact1(value);
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.maxValue,
    required this.accent,
  });

  final List<StatsBarPoint> points;
  final double maxValue;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const double topPadding = 8;
    const double bottomPadding = 12;
    final chartHeight = size.height - topPadding - bottomPadding;
    final stepX = points.length <= 1 ? 0.0 : size.width / (points.length - 1);

    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final normalized = (points[i].value / maxValue).clamp(0.0, 1.0);
      final y = topPadding + (chartHeight * (1.0 - normalized));
      offsets.add(Offset(i * stepX, y));
    }

    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = topPadding + (chartHeight * (i / 3));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final areaPath = _smoothPath(offsets)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final areaPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, topPadding),
        Offset(0, size.height),
        [
          accent.withValues(alpha: 0.20),
          accent.withValues(alpha: 0.02),
        ],
      );
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_smoothPath(offsets), linePaint);

    for (var i = 0; i < offsets.length; i++) {
      final isActive = points[i].isActive;
      final outer = Paint()..color = Colors.white;
      final inner = Paint()..color = isActive ? accent : accent.withValues(alpha: 0.80);
      if (isActive) {
        final glow = Paint()
          ..color = accent.withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(offsets[i], 7, glow);
      }
      canvas.drawCircle(offsets[i], 5.2, outer);
      canvas.drawCircle(offsets[i], isActive ? 3.4 : 3.0, inner);
    }
  }

  Path _smoothPath(List<Offset> points) {
    if (points.length <= 2) {
      return Path()..addPolygon(points, false);
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.accent != accent;
  }
}
