import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../utils/app_theme.dart';

class StatsBestTimeOfDayCard extends StatelessWidget {
  final Color accent;
  final int morningPct;
  final int afternoonPct;
  final int eveningPct;
  final int nightPct;

  const StatsBestTimeOfDayCard({
    super.key,
    required this.accent,
    required this.morningPct,
    required this.afternoonPct,
    required this.eveningPct,
    required this.nightPct,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final values = <int>[morningPct, afternoonPct, eveningPct, nightPct];
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    // Si todo es 0, no destacamos ninguna.
    final highlightIndex = (maxVal <= 0) ? -1 : values.indexOf(maxVal);

    return Row(
      children: [
        Expanded(
          child: _SlotTile(
            emoji: '🌅',
            labelUpper: l10n.habitStatsTimeSlot('morning').toUpperCase(),
            pct: morningPct,
            accent: accent,
            highlighted: highlightIndex == 0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SlotTile(
            emoji: '☀️',
            labelUpper: l10n.habitStatsTimeSlot('afternoon').toUpperCase(),
            pct: afternoonPct,
            accent: accent,
            highlighted: highlightIndex == 1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SlotTile(
            emoji: '🌆',
            labelUpper: l10n.habitStatsTimeSlot('evening').toUpperCase(),
            pct: eveningPct,
            accent: accent,
            highlighted: highlightIndex == 2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SlotTile(
            emoji: '🌙',
            labelUpper: l10n.habitStatsTimeSlot('night').toUpperCase(),
            pct: nightPct,
            accent: accent,
            highlighted: highlightIndex == 3,
          ),
        ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  final String emoji;
  final String labelUpper;
  final int pct;
  final Color accent;
  final bool highlighted;

  const _SlotTile({
    required this.emoji,
    required this.labelUpper,
    required this.pct,
    required this.accent,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlighted
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.10), const Color(0xFFFFFFFF))
        : const Color(0xFFF3F4F6);

    final border =
        highlighted ? accent.withValues(alpha: 0.95) : Colors.transparent;

    final pctColor =
        highlighted ? accent : Colors.black.withValues(alpha: 0.72);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            labelUpper,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.black.withValues(alpha: 0.65),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${pct.clamp(0, 100)}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: pctColor,
              fontFamily: AppTextStyles.serifFamily,
            ),
          ),
          const SizedBox(height: 10),
          _ThinProgressBar(
            value01: (pct.clamp(0, 100)) / 100.0,
            color: highlighted ? accent : Colors.black.withValues(alpha: 0.18),
            trackColor: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }
}

class _ThinProgressBar extends StatelessWidget {
  final double value01;
  final Color color;
  final Color trackColor;

  const _ThinProgressBar({
    required this.value01,
    required this.color,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final v = value01.isNaN ? 0.0 : value01.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 5,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: trackColor)),
            FractionallySizedBox(
              widthFactor: v,
              alignment: Alignment.centerLeft,
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
