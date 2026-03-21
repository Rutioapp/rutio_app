import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────
// SPLASH — dry cracked earth
// ─────────────────────────────────────────
class SplashScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Far hill
    _drawHill(canvas, w, h, 0.632, const Color(0xFFD0C6A2), 0.18);
    // Near hill
    _drawHill(canvas, w, h, 0.726, const Color(0xFFC4B882), 0.26);
    // Ground
    final groundY = h * 0.742;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, w, h - groundY),
      Paint()..color = const Color(0xFFBAA460),
    );
    // Ground edge line
    _drawPath(canvas, [Offset(0, groundY), Offset(w, groundY)],
        color: const Color(0xFF60480E).withValues(alpha: 0.16),
        strokeWidth: 0.8);

    // Cracks
    _drawCrack(canvas, w * 0.131, h * 0.79, w * 0.172, h * 0.838, w * 0.145,
        h * 0.886);
    _drawCrack(canvas, w * 0.262, h * 0.815, w * 0.303, h * 0.859);
    _drawCrack(canvas, w * 0.676, h * 0.801, w * 0.717, h * 0.851, w * 0.69,
        h * 0.898);
    _drawCrack(canvas, w * 0.821, h * 0.83, w * 0.862, h * 0.875);

    // Dead stumps
    _drawStump(canvas, w * 0.09, h * 0.72, h * 0.08);
    _drawStump(canvas, w * 0.886, h * 0.713, h * 0.08);

    // Path dashes
    _drawDashedPath(canvas, [
      Offset(w * 0.366, h),
      Offset(w * 0.441, h * 0.75),
      Offset(w * 0.476, groundY)
    ]);
    _drawDashedPath(canvas, [
      Offset(w * 0.628, h),
      Offset(w * 0.552, h * 0.75),
      Offset(w * 0.517, groundY)
    ]);

    // Walker
    _drawWalker(canvas, Offset(w * 0.48, h * 0.706), scale: 0.88);
  }

  void _drawHill(Canvas canvas, double w, double h, double yFrac, Color color,
      double strokeOpacity) {
    final path = Path()
      ..moveTo(-5, h * yFrac)
      ..quadraticBezierTo(
          w * 0.138, h * (yFrac - 0.14), w * 0.29, h * (yFrac - 0.07))
      ..quadraticBezierTo(
          w * 0.435, h * (yFrac - 0.165), w * 0.579, h * (yFrac - 0.09))
      ..quadraticBezierTo(
          w * 0.710, h * (yFrac - 0.133), w * 0.869, h * (yFrac - 0.072))
      ..quadraticBezierTo(
          w * 0.948, h * (yFrac - 0.106), w + 5, h * (yFrac - 0.065))
      ..lineTo(w + 5, h)
      ..lineTo(-5, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF60480E).withValues(alpha: strokeOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9);
  }

  void _drawCrack(Canvas canvas, double x1, double y1,
      [double? x2, double? y2, double? x3, double? y3]) {
    final pts = [Offset(x1, y1)];
    if (x2 != null) pts.add(Offset(x2, y2!));
    if (x3 != null) pts.add(Offset(x3, y3!));
    _drawPath(canvas, pts,
        color: const Color(0xFF906E2E).withValues(alpha: 0.2),
        strokeWidth: 0.7,
        lineCap: StrokeCap.round);
  }

  void _drawStump(Canvas canvas, double x, double y, double height) {
    final paint = Paint()
      ..color = const Color(0xFF684C24).withValues(alpha: 0.48)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x, y), Offset(x, y + height), paint);
    final branchPaint = Paint()
      ..color = const Color(0xFF684C24).withValues(alpha: 0.34)
      ..strokeWidth = 0.95
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x, y + height * 0.25),
        Offset(x - height * 0.55, y + height * 0.72), branchPaint);
    canvas.drawLine(Offset(x, y + height * 0.1),
        Offset(x + height * 0.55, y + height * 0.55), branchPaint);
  }

  void _drawPath(Canvas canvas, List<Offset> pts,
      {required Color color,
      required double strokeWidth,
      StrokeCap lineCap = StrokeCap.butt}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = lineCap
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final pt in pts.skip(1)) {
      path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawDashedPath(Canvas canvas, List<Offset> pts) {
    final paint = Paint()
      ..color = const Color(0xFF9A7638).withValues(alpha: 0.28)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Approximate dash by drawing short segments
    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final dx = b.dx - a.dx;
      final dy = b.dy - a.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      const dash = 5.0;
      const gap = 4.0;
      double pos = 0;
      bool drawing = true;
      while (pos < len) {
        final segLen = drawing ? dash : gap;
        final end = math.min(pos + segLen, len);
        if (drawing) {
          canvas.drawLine(
            Offset(a.dx + dx * pos / len, a.dy + dy * pos / len),
            Offset(a.dx + dx * end / len, a.dy + dy * end / len),
            paint,
          );
        }
        pos += segLen;
        drawing = !drawing;
      }
    }
  }

  void _drawWalker(Canvas canvas, Offset center, {double scale = 1.0}) {
    final s = scale;
    final x = center.dx;
    final y = center.dy;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Head
    canvas.drawCircle(
        Offset(x, y - 4 * s),
        4.2 * s,
        stroke
          ..color = const Color(0xFF18180F).withValues(alpha: 0.82)
          ..strokeWidth = 1.1 * s);
    // Body
    canvas.drawLine(
        Offset(x, y),
        Offset(x, y + 13 * s),
        stroke
          ..color = const Color(0xFF18180F).withValues(alpha: 0.75)
          ..strokeWidth = 1.2 * s);
    // Arms
    canvas.drawLine(
        Offset(x, y + 3 * s),
        Offset(x - 5 * s, y + 9 * s),
        stroke
          ..color = const Color(0xFF18180F).withValues(alpha: 0.64)
          ..strokeWidth = 1.0 * s);
    canvas.drawLine(
        Offset(x, y + 3 * s),
        Offset(x + 6 * s, y + 7 * s),
        stroke
          ..color = const Color(0xFF18180F).withValues(alpha: 0.64)
          ..strokeWidth = 1.0 * s);
    // Legs
    canvas.drawLine(
        Offset(x, y + 13 * s),
        Offset(x - 4 * s, y + 23 * s),
        stroke
          ..color = const Color(0xFF18180F).withValues(alpha: 0.72)
          ..strokeWidth = 1.1 * s);
    canvas.drawLine(
        Offset(x, y + 13 * s),
        Offset(x + 5 * s, y + 22 * s),
        stroke
          ..color = const Color(0xFF18180F).withValues(alpha: 0.72)
          ..strokeWidth = 1.1 * s);
    // Backpack
    final bp = Path()
      ..moveTo(x, y + 2 * s)
      ..lineTo(x + 5 * s, y + 2 * s)
      ..lineTo(x + 5 * s, y + 10 * s)
      ..lineTo(x, y + 10 * s);
    canvas.drawPath(
        bp,
        stroke
          ..color = const Color(0xFF604C24).withValues(alpha: 0.4)
          ..strokeWidth = 0.9 * s);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────
// WELCOME — first sprouts
// ─────────────────────────────────────────
class WelcomeScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Far hill
    _drawHill(canvas, w, h, 0.567, const Color(0xFFCACA9A));
    // Near hill
    _drawHill(canvas, w, h, 0.636, const Color(0xFFB8B882));
    // Ground
    final groundY = h * 0.645;
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY),
        Paint()..color = const Color(0xFFB2A260));
    // Path
    _drawDashes(canvas, w * 0.372, w * 0.483, h * 0.647, h);
    _drawDashes(canvas, w * 0.517, w * 0.628, h * 0.647, h);
    // Sparse grass L
    _drawGrassCluster(canvas, w * 0.065, groundY, 3, sparse: true);
    _drawGrassCluster(canvas, w * 0.186, groundY, 2, sparse: true);
    // Sparse grass R
    _drawGrassCluster(canvas, w * 0.910, groundY, 3, sparse: true);
    _drawGrassCluster(canvas, w * 0.817, groundY, 2, sparse: true);
    // Budding trees
    _drawBuddingTree(canvas, Offset(w * 0.079, groundY - 24), 24, layers: 2);
    _drawBuddingTree(canvas, Offset(w * 0.896, groundY - 26), 26, layers: 2);
    // Walker
    _drawWalker(canvas, Offset(w * 0.48, groundY - 14));
  }

  void _drawHill(Canvas canvas, double w, double h, double yFrac, Color color) {
    final path = Path()
      ..moveTo(-5, h * yFrac)
      ..quadraticBezierTo(
          w * 0.145, h * (yFrac - 0.11), w * 0.303, h * (yFrac - 0.05))
      ..quadraticBezierTo(
          w * 0.455, h * (yFrac - 0.134), w * 0.600, h * (yFrac - 0.063))
      ..quadraticBezierTo(
          w * 0.738, h * (yFrac - 0.117), w * 0.903, h * (yFrac - 0.052))
      ..quadraticBezierTo(
          w * 0.979, h * (yFrac - 0.082), w + 5, h * (yFrac - 0.026))
      ..lineTo(w + 5, h)
      ..lineTo(-5, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawGrassCluster(Canvas canvas, double cx, double y, int count,
      {bool sparse = false}) {
    final paint = Paint()
      ..color = const Color(0xFF687840).withValues(alpha: sparse ? 0.58 : 0.72)
      ..strokeWidth = sparse ? 0.85 : 0.95
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final spacing = 4.0;
    for (int i = 0; i < count; i++) {
      final x = cx + (i - count / 2) * spacing;
      final lean = (i % 2 == 0) ? -2.0 : 2.0;
      canvas.drawLine(Offset(x, y), Offset(x + lean, y - 8), paint);
    }
  }

  void _drawBuddingTree(Canvas canvas, Offset base, double height,
      {int layers = 2}) {
    final trunkPaint = Paint()
      ..color = const Color(0xFF563E20).withValues(alpha: 0.5)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(base, Offset(base.dx, base.dy - height), trunkPaint);
    final foliagePaint = Paint()
      ..color = const Color(0xFF548840).withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < layers; i++) {
      final tipY = base.dy - height + i * 7.0;
      final halfW = 9.0 + i * 1.0;
      final path = Path()
        ..moveTo(base.dx, tipY)
        ..lineTo(base.dx - halfW, tipY + 17)
        ..lineTo(base.dx + halfW, tipY + 17)
        ..close();
      canvas.drawPath(
          path,
          foliagePaint
            ..color = const Color(0xFF548840).withValues(alpha: 0.4 - i * 0.1));
    }
  }

  void _drawDashes(
      Canvas canvas, double x1, double x2, double yTop, double yBottom) {
    final paint = Paint()
      ..color = const Color(0xFF907438).withValues(alpha: 0.28)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final len = yBottom - yTop;
    const dash = 6.0;
    const gap = 5.0;
    double pos = 0;
    bool draw = true;
    while (pos < len) {
      final segLen = draw ? dash : gap;
      final end = math.min(pos + segLen, len);
      if (draw) {
        final t0 = pos / len;
        canvas.drawLine(
          Offset(
              x1 + (x2 - x1) * t0 * 0, yTop + pos), // vertical simplification
          Offset(x1, yTop + end),
          paint,
        );
        // simplified: just draw vertical dashes
        canvas.drawLine(Offset(x1, yTop + pos), Offset(x1, yTop + end), paint);
      }
      pos += segLen;
      draw = !draw;
    }
  }

  void _drawWalker(Canvas canvas, Offset base) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
        base.translate(0, -4),
        4.2,
        paint
          ..color = const Color(0xFF18180F).withValues(alpha: 0.82)
          ..strokeWidth = 1.1);
    canvas.drawLine(
        base,
        base.translate(0, 13),
        paint
          ..color = const Color(0xFF18180F).withValues(alpha: 0.75)
          ..strokeWidth = 1.2);
    canvas.drawLine(
        base.translate(0, 3),
        base.translate(-5, 9),
        paint
          ..color = const Color(0xFF18180F).withValues(alpha: 0.64)
          ..strokeWidth = 1.0);
    canvas.drawLine(
        base.translate(0, 3),
        base.translate(6, 7),
        paint
          ..color = const Color(0xFF18180F).withValues(alpha: 0.64)
          ..strokeWidth = 1.0);
    canvas.drawLine(
        base.translate(0, 13),
        base.translate(-4, 23),
        paint
          ..color = const Color(0xFF18180F).withValues(alpha: 0.72)
          ..strokeWidth = 1.1);
    canvas.drawLine(
        base.translate(0, 13),
        base.translate(5, 22),
        paint
          ..color = const Color(0xFF18180F).withValues(alpha: 0.72)
          ..strokeWidth = 1.1);
    // Staff
    canvas.drawLine(
        base.translate(-5, 9),
        base.translate(-7, 23),
        paint
          ..color = const Color(0xFF7C6030).withValues(alpha: 0.42)
          ..strokeWidth = 0.85);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────
// AUTH TOP SCENE — shared painter base
// takes a greenLevel 0.0 (login) → 1.0 (signup)
// ─────────────────────────────────────────
class AuthScenePainter extends CustomPainter {
  final double greenLevel; // 0 = login, 1 = signup

  const AuthScenePainter({required this.greenLevel});

  Color get _hillColor =>
      Color.lerp(const Color(0xFF7AAC56), const Color(0xFF3E7828), greenLevel)!;
  Color get _groundColor =>
      Color.lerp(const Color(0xFF569620), const Color(0xFF2E6820), greenLevel)!;
  Color get _gradBottom =>
      Color.lerp(const Color(0xFF8AB85A), const Color(0xFF3E8828), greenLevel)!;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFE4F0F8), _gradBottom],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // Hill
    final hillY = h * 0.652;
    final hillPath = Path()
      ..moveTo(-5, hillY)
      ..quadraticBezierTo(
          w * 0.131, hillY - h * 0.17, w * 0.283, hillY - h * 0.10)
      ..quadraticBezierTo(
          w * 0.421, hillY - h * 0.21, w * 0.562, hillY - h * 0.13)
      ..quadraticBezierTo(
          w * 0.693, hillY - h * 0.175, w * 0.855, hillY - h * 0.09)
      ..quadraticBezierTo(w * 0.931, hillY - h * 0.13, w + 5, hillY - h * 0.05)
      ..lineTo(w + 5, h)
      ..lineTo(-5, h)
      ..close();
    canvas.drawPath(hillPath, Paint()..color = _hillColor);

    // Ground
    final groundY = h * 0.67;
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY),
        Paint()..color = _groundColor);

    // Grass clusters
    final grassDensity = (3 + (greenLevel * 4)).round();
    _drawGrass(canvas, w * 0.024, groundY, grassDensity);
    _drawGrass(canvas, w * 0.083, groundY, grassDensity - 1);
    _drawGrass(canvas, w * 0.882, groundY, grassDensity);
    _drawGrass(canvas, w * 0.931, groundY, grassDensity - 1);
    if (greenLevel > 0.5) {
      _drawGrass(canvas, w * 0.21, groundY, 2);
      _drawGrass(canvas, w * 0.786, groundY, 2);
    }

    // Flowers (signup only)
    if (greenLevel > 0.4) {
      final opacity = ((greenLevel - 0.4) / 0.6).clamp(0.0, 1.0);
      _drawFlower(canvas, Offset(w * 0.145, groundY - 2),
          const Color(0xFFE8C44C), opacity);
      _drawFlower(canvas, Offset(w * 0.173, groundY - 3),
          const Color(0xFFD86074), opacity * 0.9);
      _drawFlower(canvas, Offset(w * 0.186, groundY - 2),
          const Color(0xFFE8C44C), opacity * 0.85);
      _drawFlower(canvas, Offset(w * 0.841, groundY - 2),
          const Color(0xFFE8C44C), opacity);
      _drawFlower(canvas, Offset(w * 0.868, groundY - 3),
          const Color(0xFFD86074), opacity * 0.9);
    }

    // Trees L
    _drawTree(canvas, Offset(w * 0.069, h * 0.614), h * 0.115,
        layers: 3 + (greenLevel * 2).round());
    _drawTree(canvas, Offset(w * 0.128, h * 0.627), h * 0.10,
        layers: 2 + (greenLevel).round(), opacity: 0.8);

    // Trees R
    _drawTree(canvas, Offset(w * 0.903, h * 0.607), h * 0.12,
        layers: 3 + (greenLevel * 2).round());
    _drawTree(canvas, Offset(w * 0.844, h * 0.62), h * 0.10,
        layers: 2 + (greenLevel).round(), opacity: 0.8);

    // Mist
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, groundY + 3), width: w * 1.16, height: 16),
      Paint()..color = Colors.white.withValues(alpha: 0.13),
    );

    // Walker mini
    _drawWalkerMini(canvas, Offset(w * 0.472, groundY - 11));
  }

  void _drawGrass(Canvas canvas, double cx, double y, int count) {
    final density = greenLevel;
    final paint = Paint()
      ..color =
          Color.lerp(const Color(0xFF187816), const Color(0xFF104A10), density)!
              .withValues(alpha: 0.65 + density * 0.1)
      ..strokeWidth = 0.95
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < count; i++) {
      final x = cx + (i - count / 2) * 4.0;
      final lean = (i % 3 == 0)
          ? -2.0
          : (i % 3 == 1)
              ? 2.0
              : 0.0;
      canvas.drawLine(
          Offset(x, y), Offset(x + lean, y - 9 - density * 1), paint);
    }
  }

  void _drawFlower(Canvas canvas, Offset pos, Color color, double opacity) {
    canvas.drawCircle(pos, 2.0 + greenLevel * 0.2,
        Paint()..color = color.withValues(alpha: opacity));
  }

  void _drawTree(Canvas canvas, Offset base, double height,
      {int layers = 3, double opacity = 1.0}) {
    final trunkColor = Color.lerp(
            const Color(0xFF36240F), const Color(0xFF2C1808), greenLevel)!
        .withValues(alpha: 0.58 * opacity);
    final foliageBase = Color.lerp(
        const Color(0xFF166A24), const Color(0xFF0E6018), greenLevel)!;

    canvas.drawLine(
        base,
        base.translate(0, -height),
        Paint()
          ..color = trunkColor
          ..strokeWidth = 1.2 * opacity
          ..style = PaintingStyle.stroke);

    for (int i = 0; i < layers; i++) {
      final tipY = base.dy - height + i * (height / (layers + 1));
      final halfW = 10.0 + i * 1.5;
      final fOpac = (0.58 - i * 0.1).clamp(0.1, 0.6) * opacity;
      final path = Path()
        ..moveTo(base.dx, tipY)
        ..lineTo(base.dx - halfW, tipY + 18)
        ..lineTo(base.dx + halfW, tipY + 18)
        ..close();
      canvas.drawPath(
          path,
          Paint()
            ..color = foliageBase.withValues(alpha: fOpac)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0 * opacity
            ..strokeJoin = StrokeJoin.round);
    }
  }

  void _drawWalkerMini(Canvas canvas, Offset base) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
        base.translate(0, -4),
        3.8,
        paint
          ..color = const Color(0xFF18180F).withValues(alpha: 0.84)
          ..strokeWidth = 1.0);
    canvas.drawLine(
        base,
        base.translate(0, 11),
        paint
          ..color = const Color(0xFF18180F).withValues(alpha: 0.76)
          ..strokeWidth = 1.0);
    canvas.drawLine(
        base.translate(0, 2),
        base.translate(-5, 8),
        paint
          ..color = const Color(0xFF18180F).withValues(alpha: 0.64)
          ..strokeWidth = 0.9);
    canvas.drawLine(
        base.translate(0, 2),
        base.translate(5, 6),
        paint
          ..color = const Color(0xFF18180F).withValues(alpha: 0.64)
          ..strokeWidth = 0.9);
    canvas.drawLine(
        base.translate(0, 11),
        base.translate(-4, 20),
        paint
          ..color = const Color(0xFF18180F).withValues(alpha: 0.73)
          ..strokeWidth = 1.0);
    canvas.drawLine(
        base.translate(0, 11),
        base.translate(4, 19),
        paint
          ..color = const Color(0xFF18180F).withValues(alpha: 0.73)
          ..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(AuthScenePainter old) => old.greenLevel != greenLevel;
}
