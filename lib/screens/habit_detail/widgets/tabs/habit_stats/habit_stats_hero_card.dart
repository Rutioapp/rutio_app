import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_hero_backgrounds.dart';
import 'habit_stats_hero_stage.dart';
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
    final stage = heroStageForStreak(shellData.currentStreak);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: double.infinity,
        height: 124,
        child: Stack(
          children: [
            Positioned.fill(
              child: HabitStatsHeroBackground(stage: stage),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.06),
                      Colors.black.withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 0.75],
                  ),
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
          ],
        ),
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
        border: Border.all(
          color: Color.lerp(const Color(0xFFF4CCA0), familyColor, 0.22) ?? const Color(0xFFF4CCA0),
          width: 1.8,
        ),
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
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
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
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
        ),
      ],
    );
  }
}
