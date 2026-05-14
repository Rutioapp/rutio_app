import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_models.dart';

class HabitStatsPeriodSelector extends StatelessWidget {
  final HabitStatsPeriod selectedPeriod;
  final ValueChanged<HabitStatsPeriod> onPeriodChanged;
  final Color familyColor;

  const HabitStatsPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.familyColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E9DB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DCCB)),
      ),
      child: CupertinoSlidingSegmentedControl<HabitStatsPeriod>(
        groupValue: selectedPeriod,
        thumbColor: Colors.white,
        children: {
          HabitStatsPeriod.week: _SegmentLabel(
            label: l10n.habitStatsPeriodWeek,
            active: selectedPeriod == HabitStatsPeriod.week,
          ),
          HabitStatsPeriod.month: _SegmentLabel(
            label: l10n.habitStatsPeriodMonth,
            active: selectedPeriod == HabitStatsPeriod.month,
          ),
          HabitStatsPeriod.year: _SegmentLabel(
            label: l10n.habitStatsPeriodYear,
            active: selectedPeriod == HabitStatsPeriod.year,
          ),
        },
        onValueChanged: (value) {
          if (value == null) return;
          onPeriodChanged(value);
        },
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  final String label;
  final bool active;

  const _SegmentLabel({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: active ? const Color(0xFF2F261D) : const Color(0xFF7A6853),
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
      ),
    );
  }
}
