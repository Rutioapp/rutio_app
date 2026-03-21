import 'package:flutter/material.dart';

import 'package:rutio/l10n/l10n.dart';

class MonthlyStatsRow extends StatelessWidget {
  final int monthPercent;
  final int currentStreak;
  final int habitsCount;

  const MonthlyStatsRow({
    super.key,
    required this.monthPercent,
    required this.currentStreak,
    required this.habitsCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: _MonthlyStatCard(
            value: '$monthPercent%',
            label: l10n.monthlyStatMonthLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MonthlyStatCard(
            value: '$currentStreak',
            label: l10n.monthlyStatStreakLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MonthlyStatCard(
            value: '$habitsCount',
            label: l10n.monthlyStatHabitsLabel,
          ),
        ),
      ],
    );
  }
}

class _MonthlyStatCard extends StatelessWidget {
  final String value;
  final String label;

  const _MonthlyStatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (textTheme.headlineSmall ?? const TextStyle()).copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.74),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
