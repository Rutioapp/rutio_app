import 'package:flutter/material.dart';

import '../../domain/statistics_period.dart';
import 'statistics_v2_tokens.dart';

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
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StatisticsV2Tokens.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: periods.map((period) {
          final selected = period == value;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onChanged(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected ? StatisticsV2Tokens.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    period.label(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : StatisticsV2Tokens.ink.withValues(alpha: 0.74),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
