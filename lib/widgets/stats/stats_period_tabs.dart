import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

enum StatsPeriod { week, month, threeMonths, all }

extension StatsPeriodX on StatsPeriod {
  String label(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case StatsPeriod.week:
        return l10n.habitStatsPeriodWeek;
      case StatsPeriod.month:
        return l10n.habitStatsPeriodMonth;
      case StatsPeriod.threeMonths:
        return l10n.habitStatsPeriodThreeMonths;
      case StatsPeriod.all:
        return l10n.habitStatsPeriodAll;
    }
  }
}

class StatsPeriodTabs extends StatelessWidget {
  const StatsPeriodTabs({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final StatsPeriod value;
  final ValueChanged<StatsPeriod> onChanged;

  static const Color _activeBg = Color(0xFF1C1A17);
  static const Color _inactiveBg = Colors.white;
  static const Color _inactiveBorder = Color(0xFFE6E6E6);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: StatsPeriod.values.map((p) {
        final isActive = p == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive ? _activeBg : _inactiveBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive ? Colors.transparent : _inactiveBorder,
                    width: 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          )
                        ]
                      : const [],
                ),
                alignment: Alignment.center,
                child: Text(
                  p.label(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF8B8B8B),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
