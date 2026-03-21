import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// WeeklyComparisonCard
/// UX/estilo (Rutio):
/// - Se comporta como una *card* consistente con el resto de widgets (radio, padding, sombra suave).
/// - Jerarquía clara: título/subtítulo + 2 filas (esta semana / semana pasada).
/// - Progreso minimal: texto "x/7" fuera de la barra (más legible).
/// - La barra usa siempre el mismo valor que el texto y clampa 0..1.
class WeeklyComparisonCard extends StatelessWidget {
  const WeeklyComparisonCard({
    super.key,
    required this.thisWeekDays,
    required this.lastWeekDays,
    required this.accentColor,
    this.title = '',
    this.subtitle = '',
    this.maxDays = 7,
    this.asCard = true,
  });

  final int thisWeekDays;
  final int lastWeekDays;
  final Color accentColor;
  final String title;
  final String subtitle;
  final int maxDays;
  final bool asCard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final titleText =
        title.isEmpty ? l10n.habitStatsWeeklyComparisonTitle : title;
    final subtitleText =
        subtitle.isEmpty ? l10n.habitStatsWeeklyComparisonSubtitle : subtitle;

    final int safeMax = maxDays <= 0 ? 7 : maxDays;

    Widget progressRow({
      required String label,
      required int value,
      required Color color,
      required bool muted,
    }) {
      final double factor = (value / safeMax.toDouble()).clamp(0.0, 1.0);
      final Color base =
          muted ? theme.colorScheme.onSurface.withValues(alpha: 0.35) : color;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: muted ? 0.55 : 0.75),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$value/$safeMax',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: base,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: factor,
              minHeight: 8,
              backgroundColor: base.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(base),
            ),
          ),
        ],
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleText,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          subtitleText,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 18),
        progressRow(
          label: l10n.habitStatsThisWeek,
          value: thisWeekDays,
          color: accentColor,
          muted: false,
        ),
        const SizedBox(height: 16),
        progressRow(
          label: l10n.habitStatsLastWeek,
          value: lastWeekDays,
          color: accentColor,
          muted: true,
        ),
      ],
    );

    if (!asCard) return content;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
      ),
      child: content,
    );
  }
}
