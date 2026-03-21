import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/radar_datum.dart';

class RadarPainter extends CustomPainter {
  final List<RadarDatum> data;
  final Color gridColor;
  final Color borderColor;

  RadarPainter({
    required this.data,
    required this.gridColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;

    final n = data.length;
    final angleStep = (2 * math.pi) / n;
    final startAngle = -math.pi / 2;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gridColor;

    // Grid rings
    const rings = 4;
    for (int r = 1; r <= rings; r++) {
      final t = r / rings;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final a = startAngle + angleStep * i;
        final p = center + Offset(math.cos(a), math.sin(a)) * (radius * t);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Spokes
    for (int i = 0; i < n; i++) {
      final a = startAngle + angleStep * i;
      final p = center + Offset(math.cos(a), math.sin(a)) * radius;
      canvas.drawLine(center, p, gridPaint);
    }

    // Data polygon
    final poly = Path();
    for (int i = 0; i < n; i++) {
      final a = startAngle + angleStep * i;
      final v = data[i].value.clamp(0.0, 1.0);
      final p = center + Offset(math.cos(a), math.sin(a)) * (radius * v);
      if (i == 0) {
        poly.moveTo(p.dx, p.dy);
      } else {
        poly.lineTo(p.dx, p.dy);
      }
    }
    poly.close();

    // Fill
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = borderColor.withValues(alpha: 0.12);
    canvas.drawPath(poly, fillPaint);

    // Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = borderColor;
    canvas.drawPath(poly, borderPaint);

    // Points
    for (int i = 0; i < n; i++) {
      final a = startAngle + angleStep * i;
      final v = data[i].value.clamp(0.0, 1.0);
      final p = center + Offset(math.cos(a), math.sin(a)) * (radius * v);
      final pointPaint = Paint()..color = data[i].color;
      canvas.drawCircle(p, 3.2, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.borderColor != borderColor;
  }
}
