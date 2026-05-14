import 'package:flutter/material.dart';

import 'habit_stats_models.dart';

class HabitStatsCountLast7DaysChart extends StatelessWidget {
  final List<HabitStatsCountLast7DayItem> days;

  const HabitStatsCountLast7DaysChart({
    super.key,
    required this.days,
  });

  static const _trackColor = Color(0xFFF1ECE3);
  static const _fillColor = Color(0xFF5A8F56);
  static const _labelColor = Color(0xFF4A3E31);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('habit_stats_count_last7_chart'),
      height: 126,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < days.length; index++)
            Expanded(
              child: _CountDayBar(
                key: Key('habit_stats_count_last7_bar_$index'),
                day: days[index],
              ),
            ),
        ],
      ),
    );
  }
}

class _CountDayBar extends StatelessWidget {
  final HabitStatsCountLast7DayItem day;

  const _CountDayBar({
    super.key,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    const trackHeight = 68.0;
    final fillHeight =
        (trackHeight * day.fillRatio).clamp(0.0, trackHeight).toDouble();
    final hasFill = fillHeight > 0;

    return Column(
      children: [
        Text(
          day.weekdayLabel,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: HabitStatsCountLast7DaysChart._labelColor,
              ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 17,
              height: trackHeight,
              decoration: BoxDecoration(
                color: HabitStatsCountLast7DaysChart._trackColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 17,
                  height: hasFill ? fillHeight : 0,
                  decoration: BoxDecoration(
                    color: HabitStatsCountLast7DaysChart._fillColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day.valueLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5D5044),
              ),
        ),
      ],
    );
  }
}
