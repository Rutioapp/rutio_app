import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../utils/app_theme.dart';
import 'habit_stats_models.dart';

class HabitStatsPeriodSelector extends StatelessWidget {
  const HabitStatsPeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final HabitStatsPeriod value;
  final ValueChanged<HabitStatsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      height: 58,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBE2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _HabitStatsPeriodChip(
            label: l10n.habitStatsPeriodWeek,
            selected: value == HabitStatsPeriod.week,
            onTap: () => onChanged(HabitStatsPeriod.week),
          ),
          _HabitStatsPeriodChip(
            label: l10n.habitStatsPeriodMonth,
            selected: value == HabitStatsPeriod.month,
            onTap: () => onChanged(HabitStatsPeriod.month),
          ),
          _HabitStatsPeriodChip(
            label: l10n.habitStatsPeriodYear,
            selected: value == HabitStatsPeriod.year,
            onTap: () => onChanged(HabitStatsPeriod.year),
          ),
        ],
      ),
    );
  }
}

class _HabitStatsPeriodChip extends StatelessWidget {
  const _HabitStatsPeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF6A3818),
                      Color(0xFF321607),
                    ],
                  )
                : null,
            color: selected ? null : Colors.transparent,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.sansFamily,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color:
                  selected ? const Color(0xFFFFFAF5) : const Color(0xFF2F231A),
            ),
          ),
        ),
      ),
    );
  }
}
