import 'package:flutter/material.dart';

class HomeBackground extends StatelessWidget {
  const HomeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEAF3FB),
                Color(0xFFD6EAF6),
                Color(0xFFC8DDED),
                Color(0xFFD8CEA8),
                Color(0xFFE6DCC0),
              ],
              stops: [0.0, 0.28, 0.52, 0.78, 1.0],
            ),
          ),
          child: _HomeBackgroundArt(),
        ),
      ),
    );
  }
}

class _HomeBackgroundArt extends StatelessWidget {
  const _HomeBackgroundArt();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final landscapeHeight = width * (180 / 290);

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SkyPainter(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: landscapeHeight,
              child: CustomPaint(
                painter: _LandscapePainter(),
                size: Size(width, landscapeHeight),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 290.0;
    final sy = size.height / 608.0;

    Offset p(double x, double y) => Offset(x * sx, y * sy);

    Color rgba(int r, int g, int b, double a) {
      return Color.fromRGBO(r, g, b, a);
    }

    const double skyOffsetY = 420.0;

    Offset ps(double x, double y) => p(x, y + skyOffsetY);

    final sunRayPaint = Paint()
      ..color = rgba(172, 124, 32, 0.28)
      ..strokeWidth = 0.9 * sx
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sunGlow1 = Paint()..color = rgba(240, 198, 72, 0.10);
    final sunGlow2 = Paint()
      ..color = rgba(240, 198, 72, 0.22)
      ..style = PaintingStyle.fill;
    final sunGlow2Stroke = Paint()
      ..color = rgba(172, 124, 32, 0.36)
      ..strokeWidth = 1.0 * sx
      ..style = PaintingStyle.stroke;
    final sunCore = Paint()..color = rgba(240, 198, 72, 0.40);

    final sunCenter = ps(244, 31);

    void ray(double x1, double y1, double x2, double y2) {
      canvas.drawLine(ps(x1, y1), ps(x2, y2), sunRayPaint);
    }

    ray(244, 18, 244, 24);
    ray(244, 44, 244, 50);
    ray(231, 31, 237, 31);
    ray(251, 31, 257, 31);
    ray(235, 21, 239, 26);
    ray(249, 36, 253, 41);
    ray(253, 21, 249, 26);
    ray(239, 36, 235, 41);

    canvas.drawCircle(sunCenter, 9 * sx, sunGlow1);
    canvas.drawCircle(sunCenter, 6.5 * sx, sunGlow2);
    canvas.drawCircle(sunCenter, 6.5 * sx, sunGlow2Stroke);
    canvas.drawCircle(sunCenter, 4.5 * sx, sunCore);

    final bird1 = Paint()
      ..color = rgba(24, 24, 15, 0.32)
      ..strokeWidth = 1.0 * sx
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final bird2 = Paint()
      ..color = rgba(24, 24, 15, 0.26)
      ..strokeWidth = 0.9 * sx
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final bird3 = Paint()
      ..color = rgba(24, 24, 15, 0.20)
      ..strokeWidth = 0.8 * sx
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Path birdPath(
      double x1,
      double y1,
      double cx,
      double cy,
      double x2,
      double y2,
    ) {
      return Path()
        ..moveTo(ps(x1, y1).dx, ps(x1, y1).dy)
        ..quadraticBezierTo(
          ps(cx, cy).dx,
          ps(cx, cy).dy,
          ps(x2, y2).dx,
          ps(x2, y2).dy,
        );
    }

    canvas.drawPath(birdPath(68, 22, 73, 16, 78, 22), bird1);
    canvas.drawPath(birdPath(88, 12, 94, 6, 100, 12), bird2);
    canvas.drawPath(birdPath(112, 26, 116, 21, 120, 26), bird3);

    final cloudFill = Paint()
      ..color = rgba(255, 255, 255, 0.62)
      ..style = PaintingStyle.fill;

    final cloudStroke = Paint()
      ..color = rgba(60, 70, 90, 0.17)
      ..strokeWidth = 0.85 * sx
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final cloud = Path()
      ..moveTo(ps(16, 40).dx, ps(16, 40).dy)
      ..quadraticBezierTo(
        ps(8, 40).dx,
        ps(8, 40).dy,
        ps(8, 33).dx,
        ps(8, 33).dy,
      )
      ..quadraticBezierTo(
        ps(8, 26).dx,
        ps(8, 26).dy,
        ps(16, 26).dx,
        ps(16, 26).dy,
      )
      ..quadraticBezierTo(
        ps(17, 18).dx,
        ps(17, 18).dy,
        ps(26, 18).dx,
        ps(26, 18).dy,
      )
      ..quadraticBezierTo(
        ps(35, 18).dx,
        ps(35, 18).dy,
        ps(36, 26).dx,
        ps(36, 26).dy,
      )
      ..quadraticBezierTo(
        ps(43, 24).dx,
        ps(43, 24).dy,
        ps(45, 30).dx,
        ps(45, 30).dy,
      )
      ..quadraticBezierTo(
        ps(49, 30).dx,
        ps(49, 30).dy,
        ps(49, 35).dx,
        ps(49, 35).dy,
      )
      ..quadraticBezierTo(
        ps(49, 40).dx,
        ps(49, 40).dy,
        ps(43, 40).dx,
        ps(43, 40).dy,
      )
      ..close();

    canvas.drawPath(cloud, cloudFill);
    canvas.drawPath(cloud, cloudStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    Path hill({
      required double yFrac,
      required double a1x,
      required double a1y,
      required double a2x,
      required double a2y,
      required double b1x,
      required double b1y,
      required double b2x,
      required double b2y,
      required double c1x,
      required double c1y,
      required double c2x,
      required double c2y,
      required double d1x,
      required double d1y,
      required double d2x,
      required double d2y,
    }) {
      return Path()
        ..moveTo(-5, h * yFrac)
        ..quadraticBezierTo(
            w * a1x, h * (yFrac - a1y), w * a2x, h * (yFrac - a2y))
        ..quadraticBezierTo(
            w * b1x, h * (yFrac - b1y), w * b2x, h * (yFrac - b2y))
        ..quadraticBezierTo(
            w * c1x, h * (yFrac - c1y), w * c2x, h * (yFrac - c2y))
        ..quadraticBezierTo(
            w * d1x, h * (yFrac - d1y), w + 5, h * (yFrac - d2y))
        ..lineTo(w + 5, h)
        ..lineTo(-5, h)
        ..close();
    }

    final farCream = hill(
      yFrac: 0.66,
      a1x: 0.12,
      a1y: 0.090,
      a2x: 0.27,
      a2y: 0.030,
      b1x: 0.44,
      b1y: 0.115,
      b2x: 0.60,
      b2y: 0.048,
      c1x: 0.75,
      c1y: 0.090,
      c2x: 0.90,
      c2y: 0.030,
      d1x: 0.97,
      d1y: 0.060,
      d2x: 0.02,
      d2y: 0.020,
    );

    final nearCream = hill(
      yFrac: 0.76,
      a1x: 0.11,
      a1y: 0.100,
      a2x: 0.26,
      a2y: 0.040,
      b1x: 0.43,
      b1y: 0.130,
      b2x: 0.60,
      b2y: 0.054,
      c1x: 0.74,
      c1y: 0.100,
      c2x: 0.89,
      c2y: 0.038,
      d1x: 0.96,
      d1y: 0.074,
      d2x: 0.02,
      d2y: 0.024,
    );

    final farGreen = hill(
      yFrac: 0.88,
      a1x: 0.12,
      a1y: 0.110,
      a2x: 0.28,
      a2y: 0.042,
      b1x: 0.45,
      b1y: 0.145,
      b2x: 0.60,
      b2y: 0.064,
      c1x: 0.74,
      c1y: 0.110,
      c2x: 0.89,
      c2y: 0.042,
      d1x: 0.97,
      d1y: 0.082,
      d2x: 0.05,
      d2y: 0.028,
    );

    final nearGreen = hill(
      yFrac: 0.96,
      a1x: 0.11,
      a1y: 0.100,
      a2x: 0.24,
      a2y: 0.036,
      b1x: 0.42,
      b1y: 0.132,
      b2x: 0.56,
      b2y: 0.052,
      c1x: 0.72,
      c1y: 0.102,
      c2x: 0.87,
      c2y: 0.034,
      d1x: 0.95,
      d1y: 0.072,
      d2x: 0.0,
      d2y: 0.0,
    );

    canvas.drawPath(farCream, Paint()..color = const Color(0xFFD8D8A6));
    canvas.drawPath(nearCream, Paint()..color = const Color(0xFFCAC98E));
    canvas.drawPath(farGreen, Paint()..color = const Color(0xFF74AC48));
    canvas.drawPath(nearGreen, Paint()..color = const Color(0xFF2E6F20));

    final groundY = h * 0.90;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, w, h - groundY),
      Paint()..color = const Color(0xFF2F6F1F),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.62),
        width: w * 1.06,
        height: h * 0.22,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );

    _drawGrass(canvas, w * 0.035, groundY, 5);
    _drawGrass(canvas, w * 0.085, groundY, 4);
    _drawGrass(canvas, w * 0.90, groundY, 5);
    _drawGrass(canvas, w * 0.95, groundY, 4);

    _drawFlower(canvas, Offset(w * 0.12, groundY - 4), const Color(0xFFE8C44C));
    _drawFlower(
      canvas,
      Offset(w * 0.145, groundY - 5),
      const Color(0xFFD86074),
    );
    _drawFlower(canvas, Offset(w * 0.88, groundY - 4), const Color(0xFFE8C44C));
    _drawFlower(
      canvas,
      Offset(w * 0.905, groundY - 5),
      const Color(0xFFD86074),
    );

    _drawWalker(canvas, Offset(w * 0.49, groundY - 10));
  }

  void _drawGrass(Canvas canvas, double cx, double y, int count) {
    final paint = Paint()
      ..color = const Color(0xFF1B4E14).withValues(alpha: 0.78)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < count; i++) {
      final x = cx + (i - count / 2) * 4.0;
      final lean = (i % 3 == 0)
          ? -2.0
          : (i % 3 == 1)
              ? 2.0
              : 0.0;
      canvas.drawLine(Offset(x, y), Offset(x + lean, y - 10), paint);
    }
  }

  void _drawFlower(Canvas canvas, Offset pos, Color color) {
    canvas.drawCircle(
      pos,
      2.2,
      Paint()..color = color.withValues(alpha: 0.95),
    );
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
        ..strokeWidth = 1.1,
    );
    canvas.drawLine(
      base,
      base.translate(0, 13),
      paint
        ..color = const Color(0xFF18180F).withValues(alpha: 0.75)
        ..strokeWidth = 1.2,
    );
    canvas.drawLine(
      base.translate(0, 3),
      base.translate(-5, 9),
      paint
        ..color = const Color(0xFF18180F).withValues(alpha: 0.64)
        ..strokeWidth = 1.0,
    );
    canvas.drawLine(
      base.translate(0, 3),
      base.translate(6, 7),
      paint
        ..color = const Color(0xFF18180F).withValues(alpha: 0.64)
        ..strokeWidth = 1.0,
    );
    canvas.drawLine(
      base.translate(0, 13),
      base.translate(-4, 23),
      paint
        ..color = const Color(0xFF18180F).withValues(alpha: 0.72)
        ..strokeWidth = 1.1,
    );
    canvas.drawLine(
      base.translate(0, 13),
      base.translate(5, 22),
      paint
        ..color = const Color(0xFF18180F).withValues(alpha: 0.72)
        ..strokeWidth = 1.1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
