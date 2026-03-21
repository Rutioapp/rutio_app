import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────
// Sky gradient background
// ─────────────────────────────────────────
class SkyBackground extends StatelessWidget {
  const SkyBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.36, 0.64, 1.0],
          colors: [
            AppColors.skyTop,
            AppColors.skyMid1,
            AppColors.skyMid2,
            AppColors.skyBottom,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Primary filled button
// ─────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.ink,
          foregroundColor: AppColors.cream,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.btnLabel,
        ).copyWith(
          overlayColor:
              WidgetStateProperty.all(Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(label),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Outline / ghost button
// ─────────────────────────────────────────
class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const OutlineButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: BorderSide(
              color: AppColors.ink.withValues(alpha: 0.18), width: 1.5),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.btnOutlineLabel,
        ),
        child: Text(label),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Labeled text field
// ─────────────────────────────────────────
class LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;
  final TextEditingController? controller;

  const LabeledField({
    super.key,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.fieldLabel,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 46,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: AppTextStyles.fieldInput,
            decoration: InputDecoration(hintText: hint),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Back button (circle)
// ─────────────────────────────────────────
class CircleBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? iconColor;

  const CircleBackButton({super.key, this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.maybePop(context),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.56),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 14,
          color: iconColor ?? AppColors.ink.withValues(alpha: 0.68),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Progress dots (login = first, signup = second)
// ─────────────────────────────────────────
class ProgressDots extends StatelessWidget {
  final int active; // 0 or 1

  const ProgressDots({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(left: 5),
          width: isActive ? 14 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: isActive ? 0.55 : 0.18),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────
// Auth brand stamp (bottom-left of top scene)
// ─────────────────────────────────────────
class AuthBrand extends StatelessWidget {
  final String subtitle;

  const AuthBrand({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('rutio', style: AppTextStyles.brandName),
        const SizedBox(height: 3),
        Text(
          subtitle.toUpperCase(),
          style: AppTextStyles.brandSub,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Auth switch row ("already have account?")
// ─────────────────────────────────────────
class AuthSwitchRow extends StatelessWidget {
  final String prefix;
  final String linkText;
  final VoidCallback onTap;

  const AuthSwitchRow({
    super.key,
    required this.prefix,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.authSwitch,
          children: [
            TextSpan(text: prefix),
            WidgetSpan(
              child: GestureDetector(
                onTap: onTap,
                child: Text(linkText, style: AppTextStyles.authSwitchLink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Sun painter (contour rays + circle)
// ─────────────────────────────────────────
class SunPainter extends CustomPainter {
  final Color rayColor;
  final Color fillColor;

  const SunPainter({
    this.rayColor = const Color(0xACAC7C20),
    this.fillColor = const Color(0x70F0C648),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.21;

    final rayPaint = Paint()
      ..color = rayColor
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 8 rays
    for (int i = 0; i < 8; i++) {
      final angle = i * 3.14159 / 4;
      final inner = r + 4;
      final outer = r + 10;
      canvas.drawLine(
        Offset(cx + inner * _cos(angle), cy + inner * _sin(angle)),
        Offset(cx + outer * _cos(angle), cy + outer * _sin(angle)),
        rayPaint,
      );
    }

    // Glow ring
    canvas.drawCircle(
      Offset(cx, cy),
      r * 1.35,
      Paint()..color = fillColor.withValues(alpha: 0.1),
    );

    // Main circle
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = fillColor.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = rayColor
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    // Inner warm fill
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.7,
      Paint()..color = fillColor.withValues(alpha: 0.42),
    );
  }

  double _cos(double a) => (a == 0)
      ? 1
      : (a == 1.5708)
          ? 0
          : (a == 3.14159)
              ? -1
              : (a == 4.71239)
                  ? 0
                  : _dartCos(a);
  double _sin(double a) => (a == 0)
      ? 0
      : (a == 1.5708)
          ? 1
          : (a == 3.14159)
              ? 0
              : (a == 4.71239)
                  ? -1
                  : _dartSin(a);

  // fallback to dart:math for diagonal rays
  double _dartCos(double a) {
    // Taylor-free: use known values for 45° multiples
    const values = [1.0, 0.7071, 0.0, -0.7071, -1.0, -0.7071, 0.0, 0.7071];
    final idx = ((a / (3.14159 / 4)) % 8).round() % 8;
    return values[idx];
  }

  double _dartSin(double a) {
    const values = [0.0, 0.7071, 1.0, 0.7071, 0.0, -0.7071, -1.0, -0.7071];
    final idx = ((a / (3.14159 / 4)) % 8).round() % 8;
    return values[idx];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
