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
    final cardWidth = MediaQuery.sizeOf(context).width - 30;
    final isCompact = cardWidth < 380;
    final streakFontSize = isCompact ? 70.0 : 78.0;
    final streakLabelFontSize = isCompact ? 17.0 : 19.0;
    final headlineFontSize = isCompact ? 19.0 : 23.0;
    final headlineLineHeight = isCompact ? 1.03 : 1.08;
    final milestoneFontSize = isCompact ? 15.0 : 16.0;
    final streakColumnMaxWidth = isCompact ? 104.0 : 112.0;
    final streakToMessageSpacing = isCompact ? 10.0 : 14.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4ECDE), Color(0xFFEDE2D1)],
          ),
          border: Border.all(color: const Color(0xFFE1D3BF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2213120F),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 38,
              bottom: 20,
              child: Transform.rotate(
                angle: -0.12,
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: isCompact ? 112 : 126,
                  color: const Color(0xFFE9A24A).withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              right: 56,
              bottom: 35,
              child: Transform.rotate(
                angle: -0.10,
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: isCompact ? 72 : 84,
                  color: const Color(0xFFF3BE72).withValues(alpha: 0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.habitStatsCurrentStreakUpper,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.sansFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.0,
                      color: Color(0xFF6B6156),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 92,
                          maxWidth: streakColumnMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$streak',
                              style: TextStyle(
                                fontFamily: AppTextStyles.serifFamily,
                                fontSize: streakFontSize,
                                height: 0.92,
                                color: Color(0xFF1F1A15),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              daysUnit,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTextStyles.sansFamily,
                                fontSize: streakLabelFontSize,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6A5F52),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: streakToMessageSpacing),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _motivationHeadline(l10n, streak),
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.sansFamily,
                                  fontSize: headlineFontSize,
                                  fontWeight: FontWeight.w800,
                                  height: headlineLineHeight,
                                  color: Color(0xFF2D241B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.habitStatsMilestoneProgress(
                                  l10n.habitStatsNextMilestone,
                                  milestone.to,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.sansFamily,
                                  fontSize: milestoneFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6F6458),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MilestoneProgressBar(progress: milestone.progress),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _daysLabel(l10n, milestone.from),
                        style: const TextStyle(
                          fontFamily: AppTextStyles.sansFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF776B5F),
                        ),
                      ),
                      Text(
                        _daysLabel(l10n, milestone.to),
                        style: const TextStyle(
                          fontFamily: AppTextStyles.sansFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF776B5F),
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
    );
  }
}

class _MilestoneProgressBar extends StatelessWidget {
  const _MilestoneProgressBar({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFFD7CCBD),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              var widthFactor = clamped;
              if (widthFactor > 0 && constraints.maxWidth > 0) {
                final minVisibleWidthFactor =
                    (4 / constraints.maxWidth).clamp(0.0, 1.0);
                widthFactor = widthFactor < minVisibleWidthFactor
                    ? minVisibleWidthFactor
                    : widthFactor;
              }

              return Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: widthFactor,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE5B678), Color(0xFFD39A55)],
                      ),
                    ),
                    child: SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

String _motivationHeadline(AppLocalizations l10n, int streak) {
  final isSpanish = l10n.localeName.toLowerCase().startsWith('es');
  if (isSpanish) {
    if (streak <= 0) return 'Empezamos hoy!';
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
