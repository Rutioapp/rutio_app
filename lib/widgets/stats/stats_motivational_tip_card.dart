import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../l10n/l10n.dart';

/// Tarjeta de consejo/motivación (orgánica y sutil)
///
/// Diseño (según spec del usuario):
/// - Fondo verde muy suave (8% opacidad)
/// - Borde verde semitransparente
/// - Icono 🌱 a la izquierda en un cuadrado redondeado con fondo verde claro
/// - Texto 2–3 líneas en gris oscuro con keywords en verde bosque y fontWeight 700
/// - Border radius 20px
/// - Sin sombra
class StatsMotivationalTipCard extends StatelessWidget {
  final String habitTitle;
  final int streakDays;
  final int thisWeekDoneDays;
  final int lastWeekDoneDays;

  /// Opcional: mejor momento del día en español ("mañana", "tarde", "noche", "madrugada")
  final String? bestTimeLabel;

  const StatsMotivationalTipCard({
    super.key,
    required this.habitTitle,
    required this.streakDays,
    required this.thisWeekDoneDays,
    required this.lastWeekDoneDays,
    this.bestTimeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final cardH = screenH * 0.30; // 30% de la pantalla

    const forest = Color(0xFF1B5E20);
    const baseGreen = Color(0xFF2E7D32);
    final bg = baseGreen.withValues(alpha: 0.08);
    final border = baseGreen.withValues(alpha: 0.28);
    final iconBg = baseGreen.withValues(alpha: 0.14);
    final textColor = Colors.black.withValues(alpha: 0.74);

    final nextGoal = _nextGoal(streakDays);
    final diff = thisWeekDoneDays - lastWeekDoneDays;
    final hasWeekComparison = (thisWeekDoneDays + lastWeekDoneDays) > 0;

    final spans = _buildMessage(
      habitTitle: habitTitle,
      streakDays: streakDays,
      nextGoal: nextGoal,
      diff: diff,
      hasWeekComparison: hasWeekComparison,
      bestTimeLabel: bestTimeLabel,
      l10n: context.l10n,
      forest: forest,
      textColor: textColor,
    );

    return Container(
      width: double.infinity,
      height: cardH,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Text('🌱', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: RichText(
              text: TextSpan(children: spans),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static int _nextGoal(int streak) {
    const goals = [7, 14, 21, 30];
    for (final g in goals) {
      if (streak < g) return g;
    }
    return 30;
  }

  static List<TextSpan> _buildMessage({
    required String habitTitle,
    required int streakDays,
    required int nextGoal,
    required int diff,
    required bool hasWeekComparison,
    required String? bestTimeLabel,
    required AppLocalizations l10n,
    required Color forest,
    required Color textColor,
  }) {
    TextSpan n(String s) => TextSpan(
          text: s,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        );

    TextSpan k(String s) => TextSpan(
          text: s,
          style: TextStyle(
            color: forest,
            fontSize: 16,
            height: 1.55,
            fontWeight: FontWeight.w700,
          ),
        );

    final titleSafe = habitTitle.trim().isEmpty
        ? l10n.habitStatsThisHabitFallback
        : habitTitle.trim();

    // 1) Primera frase: streak + hábito
    final spans = <TextSpan>[
      n(l10n.habitStatsMotivationLead),
      k(l10n.habitStatsDaysLabel(streakDays)),
      n(l10n.habitStatsMotivationWith),
      k(titleSafe),
      n(' — '),
    ];

    // 2) Comparación semanal (si hay datos)
    if (hasWeekComparison) {
      if (diff > 0) {
        spans.addAll([
          n(l10n.habitStatsMotivationAboveLead),
          k(l10n.habitStatsMotivationAboveKeyword),
          n(l10n.habitStatsMotivationAboveTail),
        ]);
      } else if (diff < 0) {
        spans.addAll([
          n(l10n.habitStatsMotivationBelowLead),
          k(l10n.habitStatsMotivationBelowKeyword),
          n(l10n.habitStatsMotivationBelowTail),
        ]);
      } else {
        spans.addAll([
          n(l10n.habitStatsMotivationEqual),
        ]);
      }
    } else {
      spans.addAll([
        n(l10n.habitStatsMotivationStart),
      ]);
    }

    // 3) Meta próxima (7/14/21/30)
    if (streakDays < nextGoal) {
      spans.addAll([
        n(l10n.habitStatsMotivationGoalLead),
        k(l10n.habitStatsMotivationGoalKeyword(nextGoal)),
        n('.'),
      ]);
    } else {
      spans.addAll([
        n(l10n.habitStatsMotivationKeepLead),
        k(l10n.habitStatsMotivationKeepKeyword),
        n(l10n.habitStatsMotivationKeepTail),
      ]);
    }

    // 4) Sugerencia contextual (mejor momento del día)
    final bt = (bestTimeLabel ?? '').trim();
    if (bt.isNotEmpty) {
      spans.addAll([
        n(l10n.habitStatsMotivationBestTimeLead),
        k(l10n.habitStatsTimeSlot(bt)),
        n(l10n.habitStatsMotivationBestTimeTail),
      ]);
    }

    return spans;
  }
}
