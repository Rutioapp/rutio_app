import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../../utils/app_theme.dart';
import 'habit_stats_hero_milestone.dart';
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
    final l10n = context.l10n;
    final streak = shellData.currentStreak < 0 ? 0 : shellData.currentStreak;
    final milestone = habitStatsHeroMilestoneProgressForStreak(streak);
    final daysUnit = _daysUnit(l10n, streak);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: double.infinity,
        height: 124,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8F2E7),
                Color(0xFFF4EBDD),
              ],
            ),
            border: Border.all(color: const Color(0xFFE7DAC7)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -6,
                top: -12,
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 72,
                  color: familyColor.withValues(alpha: 0.10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.habitStatsCurrentStreakUpper,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.sansFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFF7C6649),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$streak',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.serifFamily,
                            fontSize: 40,
                            height: 0.94,
                            color: Color(0xFF1F1A15),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            daysUnit,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.sansFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6F5F4C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _motivationHeadline(l10n, streak),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.sansFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D241B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.habitStatsMilestoneProgress(
                                  l10n.habitStatsNextMilestone,
                                  milestone.to,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.sansFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF78634A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 6,
                        color: const Color(0x29B29167),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: milestone.progress,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCB9155),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _daysLabel(l10n, milestone.from),
                          style: const TextStyle(
                            fontFamily: AppTextStyles.sansFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A755C),
                          ),
                        ),
                        Text(
                          _daysLabel(l10n, milestone.to),
                          style: const TextStyle(
                            fontFamily: AppTextStyles.sansFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A755C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _motivationHeadline(AppLocalizations l10n, int streak) {
  final isSpanish = l10n.localeName.toLowerCase().startsWith('es');
  if (isSpanish) {
    if (streak <= 0) return 'Empezamos hoy';
    if (streak == 1) return 'Primer día completado';
    if (streak == 2) return 'Ya estás en marcha';
    if (streak < 7) return 'Primer hito conseguido';
    if (streak < 14) return 'Una semana sólida';
    if (streak < 30) return 'Constancia real';
    if (streak < 60) return 'Hábito consolidado';
    if (streak < 100) return 'Ritmo imparable';
    return 'Parte de tu vida';
  }
  if (streak <= 0) return 'Starting today';
  if (streak == 1) return 'First day completed';
  if (streak == 2) return 'You are moving';
  if (streak < 7) return 'First milestone reached';
  if (streak < 14) return 'A solid week';
  if (streak < 30) return 'Real consistency';
  if (streak < 60) return 'Habit consolidated';
  if (streak < 100) return 'Unstoppable rhythm';
  return 'Part of your life';
}

String _daysUnit(AppLocalizations l10n, int value) {
  final isSpanish = l10n.localeName.toLowerCase().startsWith('es');
  if (isSpanish) return value == 1 ? 'día' : 'días';
  return value == 1 ? 'day' : 'days';
}

String _daysLabel(AppLocalizations l10n, int value) => '$value ${_daysUnit(l10n, value)}';
