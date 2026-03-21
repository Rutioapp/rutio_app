import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'avatar_ring_palette.dart';

class XpRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final AvatarRingPalette palette;

  const XpRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.palette,
  });

  static const double startAngle = -math.pi / 2;
  static const double fullAngle = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = palette.trackColor;

    canvas.drawCircle(center, radius, trackPaint);

    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    if (clampedProgress <= 0) return;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 1.2
      ..strokeCap = StrokeCap.round
      ..color = palette.glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + fullAngle,
      colors: [
        palette.startColor,
        palette.midColor,
        palette.endColor,
      ],
      stops: const [0.0, 0.62, 1.0],
    );

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);

    final progressRect = Rect.fromCircle(center: center, radius: radius);
    final sweep = fullAngle * clampedProgress;

    canvas.drawArc(progressRect, startAngle, sweep, false, glowPaint);
    canvas.drawArc(progressRect, startAngle, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant XpRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.palette != palette;
  }
}

