import 'package:flutter/material.dart';

import 'habit_stats_hero_stage.dart';

class HabitStatsHeroBackground extends StatelessWidget {
  final HabitStatsHeroStage stage;

  const HabitStatsHeroBackground({
    super.key,
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    switch (stage) {
      case HabitStatsHeroStage.day1:
      case HabitStatsHeroStage.day3:
      case HabitStatsHeroStage.day7:
      case HabitStatsHeroStage.day14:
      case HabitStatsHeroStage.day30:
      case HabitStatsHeroStage.day100:
        return const _Day1HeroBackground();
    }
  }
}

class _Day1HeroBackground extends StatelessWidget {
  const _Day1HeroBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E6A9A),
            Color(0xFF2A879B),
            Color(0xFF67B17C),
          ],
          stops: [0.0, 0.58, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -26,
            top: -46,
            child: _GlowBlob(
              width: 158,
              height: 122,
              color: Color(0x6EE7F5D6),
            ),
          ),
          Positioned(
            right: -30,
            top: -24,
            child: _GlowBlob(
              width: 170,
              height: 112,
              color: Color(0x56B7DCF5),
            ),
          ),
          Positioned(
            right: 44,
            top: 22,
            child: _SunDisc(),
          ),
          Positioned(
            right: 14,
            top: 20,
            child: _CloudBlob(),
          ),
          Positioned(
            left: 58,
            right: -34,
            bottom: -2,
            child: _Hill(
              height: 58,
              color: Color(0xFF5EA67B),
              opacity: 0.78,
            ),
          ),
          Positioned(
            left: 36,
            right: -12,
            bottom: -8,
            child: _Hill(
              height: 50,
              color: Color(0xFF3F845C),
              opacity: 0.9,
            ),
          ),
          Positioned(
            right: 28,
            bottom: 14,
            child: _Sprout(),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _GlowBlob({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height),
        ),
      ),
    );
  }
}

class _SunDisc extends StatelessWidget {
  const _SunDisc();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFE9A8).withValues(alpha: 0.94),
              const Color(0xFFFFD17C).withValues(alpha: 0.9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFDC8D).withValues(alpha: 0.4),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudBlob extends StatelessWidget {
  const _CloudBlob();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 74,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(40),
        ),
      ),
    );
  }
}

class _Hill extends StatelessWidget {
  final double height;
  final Color color;
  final double opacity;

  const _Hill({
    required this.height,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      ),
    );
  }
}

class _Sprout extends StatelessWidget {
  const _Sprout();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 36,
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 17,
              top: 8,
              bottom: 2,
              child: Container(
                width: 2.6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6D7).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              left: 2,
              top: 0,
              child: Transform.rotate(
                angle: -0.48,
                child: Container(
                  width: 18,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFA5E0A8).withValues(alpha: 0.94),
                        const Color(0xFF5FB884).withValues(alpha: 0.94),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 4,
              child: Transform.rotate(
                angle: 0.52,
                child: Container(
                  width: 16,
                  height: 11,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFF84D38D).withValues(alpha: 0.94),
                        const Color(0xFF4DA573).withValues(alpha: 0.94),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
