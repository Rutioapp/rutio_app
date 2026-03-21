import 'package:flutter/material.dart';

import 'package:rutio/utils/app_theme.dart';
import 'package:rutio/screens/habit_monthly/widgets/monthly_calendar_grid.dart';

class MonthlyDayCell extends StatelessWidget {
  final int day;
  final MonthlyDayStatus status;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const MonthlyDayCell({
    super.key,
    required this.day,
    required this.status,
    required this.accentColor,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final isToday = status == MonthlyDayStatus.today;
    final isDone = status == MonthlyDayStatus.done;
    final isSkip = status == MonthlyDayStatus.skip;
    final isFuture = status == MonthlyDayStatus.future;
    final isMissed = status == MonthlyDayStatus.missed;
    final isUnscheduled = status == MonthlyDayStatus.unscheduled;
    final isSelectedToday = isSelected && isToday;

    final bgColor = isSelectedToday
        ? AppColors.earth
        : isSelected
            ? accentColor.withValues(alpha: 0.18)
            : isToday
                ? AppColors.earth
                : isDone
                    ? accentColor.withValues(alpha: 0.20)
                    : Colors.transparent;

    final borderColor = isSelected
        ? accentColor.withValues(alpha: 0.46)
        : isToday
            ? AppColors.earth.withValues(alpha: 0.9)
            : isDone
                ? accentColor.withValues(alpha: 0.30)
                : Colors.transparent;

    final numberColor = isSelectedToday
        ? Colors.white
        : isSelected
            ? accentColor.withValues(alpha: 0.9)
            : isToday
                ? Colors.white
                : isDone
                    ? accentColor.withValues(alpha: 0.86)
                    : isFuture
                        ? Colors.black.withValues(alpha: 0.35)
                        : isUnscheduled
                            ? Colors.black.withValues(alpha: 0.22)
                            : Colors.black
                                .withValues(alpha: isMissed ? 0.56 : 0.62);

    final markerColor = isSelected
        ? accentColor.withValues(alpha: 0.98)
        : accentColor.withValues(alpha: 0.95);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: borderColor,
                width: isSelected || isToday || isDone ? 1.2 : 0.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$day',
                    style: (textTheme.labelLarge ?? const TextStyle()).copyWith(
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
                      color: numberColor,
                    ),
                  ),
                  if (isDone) ...[
                    const SizedBox(height: 1),
                    Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: markerColor,
                    ),
                  ] else if (isSkip) ...[
                    const SizedBox(height: 1),
                    Icon(
                      Icons.fast_forward_rounded,
                      size: 13,
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
