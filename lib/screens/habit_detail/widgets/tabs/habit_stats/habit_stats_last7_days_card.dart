import 'package:flutter/material.dart';

import 'habit_stats_models.dart';

class HabitStatsLast7DaysCard extends StatelessWidget {
  final List<HabitStatsLast7DayItem> days;

  const HabitStatsLast7DaysCard({
    super.key,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('habit_stats_check_last7_days'),
      children: [
        for (var index = 0; index < days.length; index++)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  days[index].weekdayLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10.6,
                        height: 1,
                        color: const Color(0xFF7A6E62),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 7),
                _DayCircle(
                  key: Key('habit_stats_day_circle_${index}_${days[index].state.name}'),
                  state: days[index].state,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCircle extends StatelessWidget {
  final HabitStatsDayState state;

  const _DayCircle({
    super.key,
    required this.state,
  });

  static const _completedFill = Color(0xFF6D9660);
  static const _completedBorder = Color(0xFF628957);
  static const _completedIcon = Color(0xFFFFFAF1);
  static const _skippedFill = Color(0xFFF5EDE2);
  static const _skippedBorder = Color(0xFFDCCCB7);
  static const _skippedDash = Color(0xFFB59C7F);
  static const _pendingFill = Color(0xFFFEFBF6);
  static const _pendingBorder = Color(0xFFD6C9BB);
  static const _futureFill = Color(0xFFFCF8F2);
  static const _futureBorder = Color(0xFFE7DFD3);

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(state);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: style.fillColor,
        border: Border.all(color: style.borderColor, width: 1.35),
      ),
      child: Center(
        child: style.child,
      ),
    );
  }

  _DayCircleStyle _styleFor(HabitStatsDayState state) {
    switch (state) {
      case HabitStatsDayState.completed:
        return const _DayCircleStyle(
          fillColor: _completedFill,
          borderColor: _completedBorder,
          child: Icon(
            Icons.check_rounded,
            color: _completedIcon,
            size: 13.2,
          ),
        );
      case HabitStatsDayState.skipped:
        return _DayCircleStyle(
          fillColor: _skippedFill,
          borderColor: _skippedBorder,
          child: Container(
            width: 9,
            height: 1.8,
            decoration: BoxDecoration(
              color: _skippedDash,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      case HabitStatsDayState.future:
        return _DayCircleStyle(
          fillColor: _futureFill.withValues(alpha: 0.6),
          borderColor: _futureBorder.withValues(alpha: 0.7),
          child: const SizedBox.shrink(),
        );
      case HabitStatsDayState.pending:
        return const _DayCircleStyle(
          fillColor: _pendingFill,
          borderColor: _pendingBorder,
          child: SizedBox.shrink(),
        );
    }
  }
}

class _DayCircleStyle {
  final Color fillColor;
  final Color borderColor;
  final Widget child;

  const _DayCircleStyle({
    required this.fillColor,
    required this.borderColor,
    required this.child,
  });
}
