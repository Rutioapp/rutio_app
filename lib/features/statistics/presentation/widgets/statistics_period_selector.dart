import 'package:flutter/material.dart';

import '../../domain/statistics_period.dart';

class StatisticsPeriodSelector extends StatelessWidget {
  const StatisticsPeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.periods = StatisticsPeriod.values,
  });

  final StatisticsPeriod value;
  final ValueChanged<StatisticsPeriod> onChanged;
  final List<StatisticsPeriod> periods;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: periods.map((period) {
        final selected = period == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 38,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF1D1B18) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  period.label(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : Colors.black.withValues(alpha: 0.64),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}
