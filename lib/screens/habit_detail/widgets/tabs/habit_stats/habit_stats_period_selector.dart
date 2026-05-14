import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_models.dart';

class HabitStatsPeriodSelector extends StatelessWidget {
  final HabitStatsPeriod selectedPeriod;
  final ValueChanged<HabitStatsPeriod> onPeriodChanged;

  const HabitStatsPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <(HabitStatsPeriod, String)>[
      (HabitStatsPeriod.week, l10n.habitStatsPeriodWeek),
      (HabitStatsPeriod.month, l10n.habitStatsPeriodMonth),
      (HabitStatsPeriod.year, l10n.habitStatsPeriodYear),
    ];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2ECE3),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: _PeriodChip(
                label: item.$2,
                selected: selectedPeriod == item.$1,
                onTap: () => onPeriodChanged(item.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: selected
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF4B2B1B),
                        Color(0xFF6A3D22),
                      ],
                    )
                  : null,
              color: selected ? null : Colors.transparent,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    color: selected ? Colors.white : const Color(0xFF3E2C20),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
