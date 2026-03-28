import 'package:flutter/material.dart';

import 'package:rutio/screens/habit_monthly/utils/month_utils.dart';
import 'package:rutio/screens/habit_monthly/utils/monthly_state_utils.dart';

class MonthGrid extends StatelessWidget {
  final int totalCells;
  final int offset;
  final DateTime monthCursor;
  final Map<String, dynamic>? habit;
  final String habitId;
  final String habitType;
  final int target;
  final Map<String, dynamic> habitCompletions;
  final Map<String, dynamic> habitCountValues;
  final Color color;
  final bool dense;

  const MonthGrid({
    super.key,
    required this.totalCells,
    required this.offset,
    required this.monthCursor,
    required this.habit,
    required this.habitId,
    required this.habitType,
    required this.target,
    required this.habitCompletions,
    required this.habitCountValues,
    required this.color,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = MonthUtils.daysInMonth(monthCursor);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: dense ? 6 : 8,
        mainAxisSpacing: dense ? 6 : 8,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < offset) return const SizedBox.shrink();

        final day = index - offset + 1;
        if (day < 1 || day > daysInMonth) return const SizedBox.shrink();

        final date = DateTime(monthCursor.year, monthCursor.month, day);
        final dayKey = MonthUtils.dateKey(date);

        final dayDoneMap = MonthlyStateUtils.mapCast(habitCompletions[dayKey]);
        final dayValsMap = MonthlyStateUtils.mapCast(habitCountValues[dayKey]);

        final scheduled = (habit == null)
            ? true
            : MonthlyStateUtils.isScheduledForDate(
                habit!, date, MonthUtils.dateKey);

        bool done = false;
        if (scheduled) {
          if (habitType == 'count') {
            final v = ((dayValsMap[habitId] as num?) ?? 0).toInt();
            done = v >= target || (dayDoneMap[habitId] == true);
          } else {
            done = (dayDoneMap[habitId] == true);
          }
        }

        final bg = !scheduled
            ? Colors.grey.withValues(alpha: 0.12)
            : (done
                ? color.withValues(alpha: 0.85)
                : color.withValues(alpha: 0.12));

        final fg = !scheduled
            ? Colors.black.withValues(alpha: 0.25)
            : (done ? Colors.white : Colors.black.withValues(alpha: 0.65));

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(fontWeight: FontWeight.w800, color: fg),
            ),
          ),
        );
      },
    );
  }
}
