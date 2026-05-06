import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_period.dart';
import 'package:rutio/l10n/l10n.dart';

class StatisticsV3PeriodSelector extends StatelessWidget {
  const StatisticsV3PeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final StatisticsV3Period value;
  final ValueChanged<StatisticsV3Period> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFE9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE9E1D5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: SizedBox(
          height: 32,
          width: double.infinity,
          child: CupertinoSlidingSegmentedControl<StatisticsV3Period>(
            backgroundColor: Colors.transparent,
            thumbColor: const Color(0xFF6A3C23),
            groupValue: value,
            children: {
              for (final period in StatisticsV3Period.values)
                period: Center(
                  child: Text(
                    period.label(l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          period == value ? FontWeight.w700 : FontWeight.w500,
                      color: period == value
                          ? Colors.white
                          : const Color(0xFF5B5146),
                    ),
                  ),
                ),
            },
            onValueChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ),
    );
  }
}
