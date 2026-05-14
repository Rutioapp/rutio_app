import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_models.dart';

class HabitStatsHeroCard extends StatelessWidget {
  final HabitStatsShellData shellData;
  final Color familyColor;

  const HabitStatsHeroCard({
    super.key,
    required this.shellData,
    required this.familyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 124,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFC1854E),
            Color(0xFFA06434),
            Color(0xFF6C3E1F),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.black.withValues(alpha: 0.28),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 12,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2D4A8).withValues(alpha: 0.78),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: _FlameBadge(familyColor: familyColor),
          ),
          Positioned(
            left: 72,
            top: 16,
            right: 10,
            child: _HeroCopy(
              currentStreak: shellData.currentStreak,
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 5,
            child: CustomPaint(
              size: const Size(double.infinity, 32),
              painter: _HeroLandscapePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlameBadge extends StatelessWidget {
  final Color familyColor;

  const _FlameBadge({required this.familyColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE4A25D), Color(0xFFB56F37)],
        ),
        border: Border.all(color: const Color(0xFFF4CCA0), width: 1.8),
      ),
      child: Center(
        child: Icon(
          Icons.local_fire_department_rounded,
          color: Colors.white.withValues(alpha: 0.94),
          size: 24,
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final int currentStreak;

  const _HeroCopy({required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.habitStatsTabCurrentStreakTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 1),
        Text(
          l10n.habitStatsTabDayUnit(currentStreak),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 34,
                color: Colors.white,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                height: 1,
              ),
        ),
      ],
    );
  }
}

class _HeroLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mountain = Paint()..color = const Color(0x883B2012);
    final front = Paint()..color = const Color(0xAA2B170D);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final backPath = Path()
      ..moveTo(0, size.height * 0.76)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.35, size.width * 0.42,
          size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.64, size.height * 0.2, size.width, size.height * 0.54)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(backPath, mountain);

    final frontPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.23, size.height * 0.58, size.width * 0.34,
          size.height * 0.78)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.48, size.width, size.height * 0.74)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(frontPath, front);

    final river = Path()
      ..moveTo(size.width * 0.38, size.height)
      ..quadraticBezierTo(size.width * 0.47, size.height * 0.74, size.width * 0.62, size.height)
      ..close();
    canvas.drawPath(river, line..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
