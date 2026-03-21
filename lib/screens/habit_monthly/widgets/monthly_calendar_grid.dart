import 'package:flutter/material.dart';

import 'package:rutio/screens/habit_monthly/utils/month_utils.dart';
import 'package:rutio/screens/habit_monthly/utils/monthly_state_utils.dart';
import 'package:rutio/screens/habit_monthly/widgets/monthly_day_cell.dart';

enum MonthlyDayStatus {
  done,
  skip,
  missed,
  future,
  today,
  unscheduled,
}

class MonthlyCalendarGrid extends StatelessWidget {
  final DateTime monthCursor;
  final Map<String, dynamic> habit;
  final Color accentColor;
  final Map<String, dynamic> habitCompletions;
  final Map<String, dynamic> habitCountValues;
  final Map<String, dynamic> habitSkips;
  final DateTime? selectedDate;
  final void Function(DateTime date, MonthlyDayStatus status)? onDayTap;

  const MonthlyCalendarGrid({
    super.key,
    required this.monthCursor,
    required this.habit,
    required this.accentColor,
    required this.habitCompletions,
    required this.habitCountValues,
    required this.habitSkips,
    this.selectedDate,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = MonthUtils.daysInMonth(monthCursor);
    final offset = MonthUtils.mondayBasedOffset(monthCursor);
    final totalCells = ((offset + daysInMonth + 6) ~/ 7) * 7;

    final habitId = (habit['id'] ?? '').toString();
    final habitType = (habit['type'] ?? 'check').toString();
    final target = ((habit['target'] as num?) ?? 1).toInt();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return GridView.builder(
      itemCount: totalCells,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - offset + 1;
        if (index < offset || dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(monthCursor.year, monthCursor.month, dayNumber);
        final key = MonthUtils.dateKey(date);

        final doneMap = _map(habitCompletions[key]);
        final valuesMap = _map(habitCountValues[key]);
        final skipsMap = _map(habitSkips[key]);

        final scheduled = MonthlyStateUtils.isScheduledForDate(
          habit,
          date,
          MonthUtils.dateKey,
        );

        final skipped = skipsMap[habitId] == true;

        bool done;
        if (habitType == 'count') {
          final v = ((valuesMap[habitId] as num?) ?? 0).toInt();
          done = !skipped && (v >= target || doneMap[habitId] == true);
        } else {
          done = !skipped && (doneMap[habitId] == true);
        }

        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isFuture = date.isAfter(today);

        MonthlyDayStatus status;
        if (!scheduled) {
          status = MonthlyDayStatus.unscheduled;
        } else if (isToday) {
          status = MonthlyDayStatus.today;
        } else if (isFuture) {
          status = MonthlyDayStatus.future;
        } else if (done) {
          status = MonthlyDayStatus.done;
        } else if (skipped) {
          status = MonthlyDayStatus.skip;
        } else {
          status = MonthlyDayStatus.missed;
        }

        final sel = selectedDate;
        final isSelected = sel != null &&
            sel.year == date.year &&
            sel.month == date.month &&
            sel.day == date.day;

        return MonthlyDayCell(
          day: dayNumber,
          status: status,
          accentColor: accentColor,
          isSelected: isSelected,
          onTap: () => onDayTap?.call(date, status),
        );
      },
    );
  }
}

Map<String, dynamic> _map(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}
