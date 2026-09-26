import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../../utils/rutio_responsive.dart';
import '../shared_widgets.dart';

/// Reusable sky background for Rutio (Splash + Welcome).
/// - Sky gradient (SkyBackground)
/// - Sun (SunPainter)
/// - Clouds (subtle animation)
/// - Birds
/// - Optional bottom fade (useful for Welcome content readability)
class RutioSkyBackground extends StatelessWidget {
  final bool showBottomFade;
  final double bottomFadeHeight;
  final double phase;
  final double? initialPhase;

  const RutioSkyBackground({
    super.key,
    this.showBottomFade = false,
    this.bottomFadeHeight = 420,
    this.phase = 0,
    this.initialPhase,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: initialPhase?.clamp(0.0, 1.0).toDouble(),
        end: phase.clamp(0.0, 1.0),
      ),
      duration: MediaQuery.maybeOf(context)?.disableAnimations == true
          ? Duration.zero
          : const Duration(milliseconds: 720),
      curve: Curves.easeInOut,
      builder: (context, animatedPhase, _) {
        final palette = _SkyPalette.forPhase(animatedPhase);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Sky
            SkyBackground(
              top: palette.top,
              mid1: palette.mid1,
              mid2: palette.mid2,
              bottom: palette.bottom,
            ),

            // Sun follows the same slow progression as the sky.
            Positioned(
              bottom: R.h(context, _lerp(260, 120, animatedPhase)),
              right: R.w(context, _lerp(54, 110, animatedPhase)),
              child: SizedBox(
                width: R.r(context, _lerp(110, 126, animatedPhase)),
                height: R.r(context, _lerp(110, 126, animatedPhase)),
                child: CustomPaint(
                  painter: SunPainter(
                    rayColor: palette.sunRay,
                    fillColor: palette.sunFill,
                  ),
                ),
              ),
            ),

            // Clouds
            Positioned(
              bottom: R.h(context, 205),
              left: R.w(context, 20),
              child: _AnimatedCloud(
                width: 220,
                height: 80,
                duration: 20,
                color: palette.cloud,
              ),
            ),
            Positioned(
              bottom: R.h(context, 165),
              right: R.w(context, 22),
              child: Opacity(
                opacity: 0.68,
                child: _AnimatedCloud(
                  width: 150,
                  height: 55,
                  duration: 26,
                  small: true,
                  color: palette.cloud,
                ),
              ),
            ),

            // Birds
            Positioned(
              bottom: R.h(context, 270),
              left: R.w(context, 70),
              child: CustomPaint(
                size: Size(R.w(context, 180), R.h(context, 40)),
                painter: const _BirdsPainter(),
              ),
            ),

            // Optional bottom fade (Welcome and onboarding content).
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
      },
    );
  }
}

double _lerp(double begin, double end, double value) =>
    begin + (end - begin) * value;

class _SkyPalette {
  final Color top;
  final Color mid1;
  final Color mid2;
  final Color bottom;
  final Color sunRay;
  final Color sunFill;
  final Color cloud;

  const _SkyPalette({
    required this.top,
    required this.mid1,
    required this.mid2,
    required this.bottom,
    required this.sunRay,
    required this.sunFill,
    required this.cloud,
  });

  static _SkyPalette forPhase(double phase) {
    final normalized = phase.clamp(0.0, 1.0);
    const morning = _SkyPalette(
      top: AppColors.skyTop,
      mid1: AppColors.skyMid1,
      mid2: AppColors.skyMid2,
      bottom: AppColors.skyBottom,
      sunRay: Color(0xACAC7C20),
      sunFill: Color(0x70F0C648),
      cloud: Colors.white,
    );
    const midday = _SkyPalette(
      top: Color(0xFFB9D8F2),
      mid1: Color(0xFF8FC3E8),
      mid2: Color(0xFF71A9D1),
      bottom: Color(0xFFD7C98F),
      sunRay: Color(0xB5B88324),
      sunFill: Color(0x8AF4D04D),
      cloud: Colors.white,
    );
    const sunset = _SkyPalette(
      top: Color(0xFF7795BE),
      mid1: Color(0xFFD39B79),
      mid2: Color(0xFFF0B46C),
      bottom: Color(0xFFE7C37D),
      sunRay: Color(0xC9D8752D),
      sunFill: Color(0xBFFFDF78),
      cloud: Color(0xFFFFE2C2),
    );

    if (normalized <= 0.55) {
      return _SkyPalette._lerp(morning, midday, normalized / 0.55);
    }
    return _SkyPalette._lerp(
      midday,
      sunset,
      (normalized - 0.55) / 0.45,
    );
  }

  static _SkyPalette _lerp(_SkyPalette a, _SkyPalette b, double value) {
    return _SkyPalette(
      top: Color.lerp(a.top, b.top, value)!,
      mid1: Color.lerp(a.mid1, b.mid1, value)!,
      mid2: Color.lerp(a.mid2, b.mid2, value)!,
      bottom: Color.lerp(a.bottom, b.bottom, value)!,
      sunRay: Color.lerp(a.sunRay, b.sunRay, value)!,
      sunFill: Color.lerp(a.sunFill, b.sunFill, value)!,
      cloud: Color.lerp(a.cloud, b.cloud, value)!,
    );
  }
}

/// Cloud widget with a subtle horizontal float animation.
class _AnimatedCloud extends StatefulWidget {
  final double width;
  final double height;
  final bool small;
  final int duration;
  final Color color;

  const _AnimatedCloud({
    required this.width,
    required this.height,
    this.small = false,
    this.duration = 20,
    this.color = Colors.white,
  });

  @override
  State<_AnimatedCloud> createState() => _AnimatedCloudState();
}

class _AnimatedCloudState extends State<_AnimatedCloud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    )..repeat(reverse: true);
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
        final offset = (_controller.value - 0.5) * (widget.small ? 8 : 10);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: CustomPaint(
            size: Size(
              R.w(context, widget.width),
              R.h(context, widget.height),
            ),
            painter: _CloudPainter(
              small: widget.small,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class _CloudPainter extends CustomPainter {
  final bool small;
  final Color color;

  const _CloudPainter({this.small = false, this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fill = Paint()..color = color.withValues(alpha: 0.62);
    final stroke = Paint()
      ..color = const Color(0xFF3C4660).withValues(alpha: 0.18)
      ..strokeWidth = small ? 0.9 : 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (small) {
      path
        ..moveTo(w * 0.17, h)
        ..cubicTo(w * 0.08, h, w * 0.08, h * 0.52, w * 0.17, h * 0.52)
        ..cubicTo(w * 0.18, h * 0.21, w * 0.42, h * 0.21, w * 0.40, h * 0.52)
        ..cubicTo(w * 0.56, h * 0.36, w * 0.59, h * 0.52, w * 0.57, h * 0.67)
        ..cubicTo(w * 0.62, h * 0.67, w * 0.60, h, w * 0.50, h)
        ..close();
    } else {
      path
        ..moveTo(w * 0.164, h)
        ..cubicTo(w * 0.073, h, w * 0.073, h * 0.5, w * 0.164, h * 0.5)
        ..cubicTo(w * 0.182, h * 0.2, w * 0.373, h * 0.2, w * 0.382, h * 0.5)
        ..cubicTo(w * 0.491, h * 0.37, w * 0.527, h * 0.52, w * 0.527, h * 0.66)
        ..cubicTo(w * 0.571, h * 0.66, w * 0.554, h, w * 0.464, h)
        ..close();
    }

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) =>
      oldDelegate.small != small || oldDelegate.color != color;
}

/// Birds painter (compatible; no Dart 3 records).
class _BirdsPainter extends CustomPainter {
  const _BirdsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Baseline original: 104×28
    final sx = size.width / 104.0;
    final sy = size.height / 28.0;
    final s = math.min(sx, sy);

    Offset o(double x, double y) => Offset(x * sx, y * sy);

    // x1,y1,cx,cy,x2,y2,opacity
    const birds = <List<double>>[
      [7.0, 15.0, 12.0, 8.0, 17.0, 15.0, 0.46],
      [25.0, 8.0, 31.0, 1.0, 37.0, 8.0, 0.40],
      [52.0, 18.0, 57.0, 12.0, 62.0, 18.0, 0.28],
      [74.0, 6.0, 77.0, 2.0, 80.0, 6.0, 0.20],
    ];

    for (final b in birds) {
      final opacity = b[6];
      final paint = Paint()
        ..color = const Color(0xFF18180F).withValues(alpha: opacity)
        ..strokeWidth = (opacity > 0.3 ? 1.2 : (opacity > 0.2 ? 1.0 : 0.85)) * s
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final p1 = o(b[0], b[1]);
      final c = o(b[2], b[3]);
      final p2 = o(b[4], b[5]);

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(c.dx, c.dy, p2.dx, p2.dy);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
