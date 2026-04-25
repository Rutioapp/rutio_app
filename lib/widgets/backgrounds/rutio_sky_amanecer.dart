import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../../utils/rutio_responsive.dart';

/// Sky background — Tema: Amanecer dorado
/// Incluye: gradiente de cielo, estrellas residuales, sol naciendo,
/// rayos de sol, nubes teñidas de amanecer y colinas oscuras.
/// Misma estructura que RutioSkyBackground (Splash/Welcome).
class RutioSkyAmanecer extends StatelessWidget {
  final bool showBottomFade;
  final double bottomFadeHeight;

  const RutioSkyAmanecer({
    super.key,
    this.showBottomFade = false,
    this.bottomFadeHeight = 420,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradiente del cielo (noche → amanecer → luz dorada)
        const _AmanecerGradient(),

        // Estrellas residuales (parte superior, desaparecen con la luz)
        const Positioned.fill(
          child: _StarsLayer(),
        ),

        // Sol naciendo (justo asomándose desde el horizonte)
        Positioned(
          bottom: R.h(context, 282), // alineado con la línea del horizonte
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: R.r(context, 200),
              height: R.r(context, 200),
              child: CustomPaint(painter: _SunPainter()),
            ),
          ),
        ),

        // Nubes teñidas de amanecer
        Positioned(
          bottom: R.h(context, 320),
          left: R.w(context, -10),
          child: const _DawnCloud(
            width: 200,
            height: 56,
            color: Color(0xFFe07060),
            opacity: 0.50,
            duration: 9,
          ),
        ),
        Positioned(
          bottom: R.h(context, 342),
          right: R.w(context, -20),
          child: const _DawnCloud(
            width: 220,
            height: 50,
            color: Color(0xFFd05050),
            opacity: 0.40,
            duration: 11,
            delay: 1,
          ),
        ),
        Positioned(
          bottom: R.h(context, 372),
          left: R.w(context, 30),
          right: R.w(context, 30),
          child: const _DawnCloud(
            width: 280,
            height: 60,
            color: Color(0xFFc04060),
            opacity: 0.30,
            duration: 13,
            delay: 2,
          ),
        ),

        // Colinas — capa trasera (marrón oscuro)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: Size(double.infinity, R.h(context, 320)),
            painter: const _HillsPainter(
              path: _HillsPath.back,
              color: Color(0xFF3d1505),
              opacity: 0.85,
            ),
          ),
        ),

        // Colinas — capa delantera (marrón muy oscuro)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: Size(double.infinity, R.h(context, 220)),
            painter: const _HillsPainter(
              path: _HillsPath.front,
              color: Color(0xFF2a0e03),
              opacity: 0.95,
            ),
          ),
        ),

        // Fade inferior opcional (para pantallas con contenido encima)
        if (showBottomFade)
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              child: Container(
                height: R.h(context, bottomFadeHeight),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.cream.withValues(alpha: 0.06),
                      AppColors.cream.withValues(alpha: 0.33),
                      AppColors.cream.withValues(alpha: 0.75),
                      AppColors.cream,
                    ],
                    stops: const [0.0, 0.22, 0.52, 0.78, 1.0],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// GRADIENTE DE CIELO
// #1a1040 → #7a2060 → #e86030 → #f5a050 → #f8d090
// ─────────────────────────────────────────────

class _AmanecerGradient extends StatelessWidget {
  const _AmanecerGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1040), // noche profunda
            Color(0xFF7a2060), // violeta rosa
            Color(0xFFe86030), // naranja intenso
            Color(0xFFf5a050), // naranja suave
            Color(0xFFf8d090), // dorado claro (horizonte)
          ],
          stops: [0.0, 0.25, 0.50, 0.75, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ESTRELLAS RESIDUALES
// ─────────────────────────────────────────────

class _StarsLayer extends StatelessWidget {
  const _StarsLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarsPainter(),
    );
  }
}

class _StarsPainter extends CustomPainter {
  static final List<_StarData> _stars = _generateStars();

  static List<_StarData> _generateStars() {
    final rng = math.Random(42); // seed fijo para consistencia
    return List.generate(18, (_) {
      return _StarData(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.25, // solo en el cuarto superior
        radius: 0.5 + rng.nextDouble() * 1.2,
        opacity: 0.15 + rng.nextDouble() * 0.35,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: s.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarData {
  final double x, y, radius, opacity;
  const _StarData({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
  });
}

// ─────────────────────────────────────────────
// SOL NACIENDO
// ─────────────────────────────────────────────

class _SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Halo exterior (muy suave)
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.50,
      Paint()..color = const Color(0xFFffdd88).withValues(alpha: 0.18),
    );

    // Halo medio
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.34,
      Paint()..color = const Color(0xFFffcc55).withValues(alpha: 0.32),
    );

    // Rayos (12 rayos simétricos)
    _drawRays(canvas, cx, cy, size.width * 0.19, size.width * 0.40);

    // Disco solar
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.20,
      Paint()..color = const Color(0xFFffee88),
    );
  }

  void _drawRays(Canvas canvas, double cx, double cy, double inner, double outer) {
    const count = 12;
    final paint = Paint()
      ..color = const Color(0xFFffdd88).withValues(alpha: 0.22)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final x1 = cx + inner * math.cos(angle);
      final y1 = cy + inner * math.sin(angle);
      final x2 = cx + outer * math.cos(angle);
      final y2 = cy + outer * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// NUBES DE AMANECER (con drift suave)
// ─────────────────────────────────────────────

class _DawnCloud extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final double opacity;
  final int duration;
  final int delay;

  const _DawnCloud({
    required this.width,
    required this.height,
    required this.color,
    required this.opacity,
    required this.duration,
    this.delay = 0,
  });

  @override
  State<_DawnCloud> createState() => _DawnCloudState();
}

class _DawnCloudState extends State<_DawnCloud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    )..repeat(reverse: true);

    if (widget.delay > 0) {
      Future.delayed(Duration(seconds: widget.delay), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final offset = (_controller.value - 0.5) * 12.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Opacity(
            opacity: widget.opacity,
            child: Container(
              width: R.w(context, widget.width),
              height: R.h(context, widget.height),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(R.h(context, widget.height)),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// COLINAS
// ─────────────────────────────────────────────

enum _HillsPath { back, front }

class _HillsPainter extends CustomPainter {
  final _HillsPath path;
  final Color color;
  final double opacity;

  const _HillsPainter({
    required this.path,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final p = Path();

    if (path == _HillsPath.back) {
      // Colina trasera: curva suave, más alta en el centro
      p.moveTo(0, h * 0.30);
      p.cubicTo(
        w * 0.21, h * 0.02, // colina izquierda
        w * 0.48, h * 0.14, // valle centro-izq
        w * 0.55, h * 0.18, // suave hacia centro
      );
      p.cubicTo(
        w * 0.69, h * 0.26, // valle centro-der
        w * 0.84, h * 0.02, // colina derecha
        w, h * 0.22,
      );
      p.lineTo(w, h);
      p.lineTo(0, h);
      p.close();
    } else {
      // Colina delantera: más baja y más suave
      p.moveTo(0, h * 0.45);
      p.cubicTo(
        w * 0.26, h * 0.18,
        w * 0.52, h * 0.30,
        w * 0.78, h * 0.15,
      );
      p.cubicTo(
        w * 0.88, h * 0.08,
        w * 0.94, h * 0.18,
        w, h * 0.20,
      );
      p.lineTo(w, h);
      p.lineTo(0, h);
      p.close();
    }

    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
