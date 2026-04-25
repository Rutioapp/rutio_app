import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/l10n.dart';
import '../../../../utils/app_theme.dart';
import '../../application/achievement_catalog.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/achievement_progress.dart';
import '../widgets/achievement_asset_image.dart';

Future<void> showAchievementDetailSheet(
  BuildContext context, {
  required AchievementProgress progress,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (sheetContext) => _AchievementDetailSheet(progress: progress),
  );
}

class _AchievementDetailSheet extends StatelessWidget {
  const _AchievementDetailSheet({required this.progress});

  final AchievementProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSpecial = progress.achievement.type == AchievementType.special;
    final familyName = isSpecial
        ? l10n.achievementsSpecialLabel
        : l10n.familyName(progress.achievement.familyId);
    final title = progress.isHiddenLocked
        ? l10n.achievementsMysteryTitle
        : progress.achievement.title;
    final description = progress.isHiddenLocked
        ? l10n.achievementsMysterySubtitle
        : progress.achievement.description;
    final dateLabel = progress.unlockedAt == null
        ? null
        : l10n.achievementsUnlockedOnDate(_formatDate(progress.unlockedAt!));
    final metricValue = _metricValue();
    final metricLabel = _metricLabel();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8EFDE),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetBadge(progress: progress),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEDFC9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isSpecial
                      ? 'LOGRO ESPECIAL'
                      : '${AchievementCatalog.tierLabel(progress.achievement.tier).toUpperCase()} · ${familyName.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: Color(0xFFB57E47),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTextStyles.serifFamily,
                  fontSize: 23,
                  height: 1.05,
                  color: Color(0xFF3F2B1F),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.48,
                  color: Color(0xFF6F6152),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                height: 1,
                color: const Color(0xFFDCCDBA),
              ),
              const SizedBox(height: 20),
              Text(
                metricValue,
                style: const TextStyle(
                  fontFamily: AppTextStyles.serifFamily,
                  fontSize: 38,
                  height: 1,
                  color: Color(0xFF3E2B1E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metricLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8A7B6C),
                ),
              ),
              if (dateLabel != null) ...[
                const SizedBox(height: 16),
                Text(
                  dateLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFFA39485),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF1E5D4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE8D9C4)),
                    ),
                  ),
                  child: Text(
                    l10n.achievementsCloseButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFDF9F2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = DateFormat.MMMM('es').format(date).toLowerCase();
    return '${date.day} $month ${date.year}';
  }

  String _metricValue() {
    if (progress.isHiddenLocked) return '?';

    switch (progress.status) {
      case AchievementStatus.unlocked:
        return '${progress.targetValue}';
      case AchievementStatus.inProgress:
        return '${progress.currentValue}';
      case AchievementStatus.locked:
        return '${progress.targetValue}';
    }
  }

  String _metricLabel() {
    if (progress.isHiddenLocked) {
      return 'Desc\u00fabr\u00edalo para revelar su progreso';
    }

    if (progress.achievement.type == AchievementType.special) {
      switch (progress.achievement.id) {
        case 'special:madrugador':
          return _metricLabelForCount(
            unlocked: 'habitos tempranos completados',
            pending: 'completados antes de las 09:00',
          );
        case 'special:buho_nocturno':
          return _metricLabelForCount(
            unlocked: 'habitos nocturnos completados',
            pending: 'completados despues de las 22:00',
          );
        case 'special:flash':
          return _metricLabelForCount(
            unlocked: 'habitos en tu mejor dia',
            pending: 'como pico de completados en un dia',
          );
        case 'special:guerrero_del_finde':
          return _metricLabelForCount(
            unlocked: 'dias de finde completados',
            pending: 'dias de fin de semana con progreso',
          );
        case 'special:el_arquitecto':
          return _metricLabelForCount(
            unlocked: 'acciones totales realizadas',
            pending: 'acciones totales realizadas',
          );
        case 'special:turista':
          return _metricLabelForCount(
            unlocked: 'familias exploradas',
            pending: 'familias distintas con progreso',
          );
        case 'special:polimota':
          return _metricLabelForCount(
            unlocked: 'familias activas cubiertas',
            pending: 'familias con al menos un habito activo',
          );
        case 'special:hay_alguien_ahi':
          return _metricLabelForCount(
            unlocked: 'dias sociales completados',
            pending: 'dias distintos con progreso social',
          );
        case 'special:ave_fenix':
          return _metricLabelForCount(
            unlocked: 'recuperacion conseguida',
            pending: 'rachas recuperadas tras una caida',
          );
        case 'special:perfeccionista':
          return _metricLabelForCount(
            unlocked: 'dias perfectos conseguidos',
            pending: 'dias completando todo lo programado',
          );
        case 'special:el_centurion':
          return _metricLabelForCount(
            unlocked: 'completados acumulados',
            pending: 'completados totales necesarios',
          );
        case 'special:imparable':
          return _metricLabelForCount(
            unlocked: 'dias de racha global alcanzados',
            pending: 'dias seguidos con al menos un habito',
          );
        case 'special:leyenda_viva':
          return _metricLabelForCount(
            unlocked: 'acciones historicas completadas',
            pending: 'acciones totales en historico',
          );
        case 'special:coleccionista':
          return _metricLabelForCount(
            unlocked: 'logros desbloqueados',
            pending: 'logros distintos desbloqueados',
          );
      }
    }

    switch (progress.status) {
      case AchievementStatus.unlocked:
        return 'dias de constancia conseguidos';
      case AchievementStatus.inProgress:
        return 'de ${progress.targetValue} dias necesarios';
      case AchievementStatus.locked:
        return 'dias necesarios para desbloquear';
    }
  }

  String _metricLabelForCount({
    required String unlocked,
    required String pending,
  }) {
    switch (progress.status) {
      case AchievementStatus.unlocked:
        return unlocked;
      case AchievementStatus.inProgress:
        return 'de ${progress.targetValue} $pending';
      case AchievementStatus.locked:
        return '${progress.targetValue} $pending';
    }
  }
}

class _SheetBadge extends StatelessWidget {
  const _SheetBadge({required this.progress});

  final AchievementProgress progress;
  static const Color _silhouetteColor = Color(0xFF9C958A);

  @override
  Widget build(BuildContext context) {
    final isHidden = progress.isHiddenLocked;
    final icon = AchievementAssetImage(
      assetPath: progress.achievement.assetPath,
      fit: BoxFit.contain,
      tintColor:
          progress.status == AchievementStatus.unlocked ? null : _silhouetteColor,
    );

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F1E7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDBF9B)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: progress.status == AchievementStatus.unlocked
              ? icon
              : Opacity(
                  opacity: progress.status == AchievementStatus.inProgress
                      ? 0.55
                      : isHidden
                          ? 0.18
                          : 0.34,
                  child: icon,
                ),
        ),
      ),
    );
  }
}
