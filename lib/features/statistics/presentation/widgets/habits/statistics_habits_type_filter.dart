import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';

import '../../../domain/statistics_models.dart';

class StatisticsHabitsTypeFilter extends StatelessWidget {
  const StatisticsHabitsTypeFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final StatisticsHabitListTypeFilter value;
  final ValueChanged<StatisticsHabitListTypeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: l10n.statisticsV2HabitsFilterAll,
          selected: value == StatisticsHabitListTypeFilter.all,
          onTap: () => onChanged(StatisticsHabitListTypeFilter.all),
        ),
        _FilterChip(
          label: l10n.statisticsV2HabitsFilterCheck,
          selected: value == StatisticsHabitListTypeFilter.check,
          onTap: () => onChanged(StatisticsHabitListTypeFilter.check),
        ),
        _FilterChip(
          label: l10n.statisticsV2HabitsFilterCount,
          selected: value == StatisticsHabitListTypeFilter.count,
          onTap: () => onChanged(StatisticsHabitListTypeFilter.count),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF1D1B18) : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : Colors.black.withValues(alpha: 0.72),
            ),
          ),
        ),
      ),
    );
  }
}
