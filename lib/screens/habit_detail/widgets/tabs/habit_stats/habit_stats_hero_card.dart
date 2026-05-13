import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../utils/app_theme.dart';

class HabitStatsHeroCard extends StatelessWidget {
  const HabitStatsHeroCard({
    super.key,
    required this.streak,
    required this.streakLabel,
  });

  final int streak;
  final String streakLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final streakDays = l10n.habitStatsTabDayUnit(streak);

    return Container(
      width: double.infinity,
      height: 176,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFDAA768),
            Color(0xFFC68D4D),
            Color(0xFF7C4F24),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A3A1D).withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -32,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: 130,
            top: 24,
            child: Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD49A55).withValues(alpha: 0.95),
                  border: Border.all(color: const Color(0xFFFFE2BC), width: 2),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  CupertinoIcons.flame_fill,
                  color: Color(0xFFFFF8EF),
                  size: 42,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streakLabel,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.sansFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFDF5E8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$streak $streakDays',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.serifFamily,
                        fontSize: 70,
                        height: 0.92,
                        color: Color(0xFFFFF8EF),
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
