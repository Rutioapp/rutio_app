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
        for (final day in days)
          Expanded(
            child: Column(
              children: [
                Text(
                  day.weekdayLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF473C30),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 6),
                _DayCircle(state: day.state),
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
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = state == HabitStatsDayState.completed;
    final isSkipped = state == HabitStatsDayState.skipped;
    final color = isCompleted
        ? const Color(0xFF6DA466)
        : isSkipped
            ? const Color(0xFFD6CCC0)
            : const Color(0xFFC8BBB0);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? const Color(0xFF6DA466)
            : isSkipped
                ? const Color(0xFFF2ECE5)
                : Colors.transparent,
        border: Border.all(color: color, width: 1.6),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              )
            : isSkipped
                ? Container(
                    width: 10,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB9AC9E),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
