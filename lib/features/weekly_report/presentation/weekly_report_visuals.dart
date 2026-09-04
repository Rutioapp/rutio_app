import 'package:flutter/material.dart';

/// Presentation-only tokens for the weekly report. Keeping these together
/// makes the report's tinted surfaces and completion states consistent without
/// leaking visual decisions into the report/domain models.
abstract final class WeeklyReportVisuals {
  static const background = Color(0xFFF6F0E7);
  static const surface = Color(0xFFFDFBF7);
  static const text = Color(0xFF2F251C);
  static const mutedText = Color(0xFF746A60);
  static const border = Color(0xFFE9E3D9);
  static const divider = Color(0x33B8A98F);
  static const success = Color(0xFF5F8F45);
  static const successStrong = Color(0xFF477536);
  static const stable = Color(0xFF7D8E63);
  static const stableSoft = Color(0xFFE8EDDF);
  static const warning = Color(0xFFD4874E);
  static const warningStrong = Color(0xFFB96131);
  static const warningSoft = Color(0xFFFBE8D7);
  static const neutral = Color(0xFFE8E2D9);
  static const neutralStrong = Color(0xFF8C8175);
  static const reflection = Color(0xFFF4F0F8);
  static const reflectionBorder = Color(0xFFE1D9EC);

  static BoxDecoration cardDecoration({
    Color color = surface,
    Color borderColor = border,
    double radius = 16,
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: elevated
          ? const [
              BoxShadow(
                color: Color(0x120F281B),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  /// Maps the visible completion rate to a restrained Rutio tone.
  static Color completionColor(double? rate, {bool hasPlan = true}) {
    if (!hasPlan || rate == null) return neutralStrong;
    final value = rate.clamp(0.0, 1.0);
    if (value <= 0) return warning;
    if (value < .4) return warning;
    if (value < .6) return const Color(0xFFC59A3D);
    if (value < .8) return stable;
    return success;
  }

  static Color barColor(WeeklyReportVisualBarState state, double? rate) {
    if (state == WeeklyReportVisualBarState.noPlan || rate == null) {
      return neutral;
    }
    return completionColor(rate);
  }
}

enum WeeklyReportVisualBarState { noPlan, planned }

class WeeklyReportBotanicalDecoration extends StatelessWidget {
  const WeeklyReportBotanicalDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _WeeklyReportBotanicalPainter(),
        size: const Size(150, 150),
      ),
    );
  }
}

class _WeeklyReportBotanicalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 150;
    final stem = Paint()
      ..color = WeeklyReportVisuals.success.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale
      ..strokeCap = StrokeCap.round;
    final leaf = Paint()
      ..color = WeeklyReportVisuals.success.withValues(alpha: .18)
      ..style = PaintingStyle.fill;
    final dot = Paint()
      ..color = const Color(0xFFD98D50).withValues(alpha: .32)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(110 * scale, 150 * scale)
      ..quadraticBezierTo(106 * scale, 92 * scale, 129 * scale, 30 * scale);
    canvas.drawPath(path, stem);

    void drawLeaf(double x, double y, double angle, double width, double h) {
      canvas.save();
      canvas.translate(x * scale, y * scale);
      canvas.rotate(angle);
      final leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(width * scale, -h * scale, width * scale, 0)
        ..quadraticBezierTo(width * scale, h * scale, 0, 0)
        ..close();
      canvas.drawPath(leafPath, leaf);
      canvas.restore();
    }

    drawLeaf(116, 86, -.7, 30, 10);
    drawLeaf(116, 65, .5, 27, 9);
    drawLeaf(124, 47, -.75, 25, 9);
    canvas.drawCircle(Offset(83 * scale, 46 * scale), 5 * scale, dot);
    canvas.drawCircle(Offset(101 * scale, 72 * scale), 3 * scale, dot);
    canvas.drawCircle(Offset(69 * scale, 84 * scale), 2.5 * scale, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
