import 'package:flutter/material.dart';

import 'package:rutio/l10n/l10n.dart';

class MonthlyStreakRow extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;

  const MonthlyStreakRow({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: _StreakPill(
            emoji: '\u{1F525}',
            strongText: l10n.monthlyDaysLabel(
                currentStreak, currentStreak == 1 ? '' : 's'),
            softText: l10n.monthlyCurrentStreakSoft,
            highlighted: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StreakPill(
            emoji: '\u{1F3C6}',
            strongText:
                l10n.monthlyDaysLabel(bestStreak, bestStreak == 1 ? '' : 's'),
            softText: l10n.monthlyBestStreakSoft,
            highlighted: false,
          ),
        ),
      ],
    );
  }
}

class _StreakPill extends StatelessWidget {
  final String emoji;
  final String strongText;
  final String softText;
  final bool highlighted;

  const _StreakPill({
    required this.emoji,
    required this.strongText,
    required this.softText,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFFF1E5D8).withValues(alpha: 0.78)
            : Colors.white.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFD8C0A7).withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.58),
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 7),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: strongText,
                    style:
                        (textTheme.labelMedium ?? const TextStyle()).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.62),
                    ),
                  ),
                  TextSpan(
                    text: '  $softText',
                    style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.46),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
