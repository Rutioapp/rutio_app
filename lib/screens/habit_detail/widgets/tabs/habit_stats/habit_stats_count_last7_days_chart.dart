import 'package:flutter/material.dart';

import 'habit_stats_models.dart';
import 'count_last7days_chart_painter.dart';

class HabitStatsCountLast7DaysChart extends StatelessWidget {
  final List<HabitStatsCountLast7DayItem> days;

  const HabitStatsCountLast7DaysChart({
    super.key,
    required this.days,
  });

  static const _lineColor = Color(0xFF709C7E);
  static const _markerFillColor = Color(0xFFF7F4EE);
  static const _markerStrokeColor = Color(0xFF6A9477);
  static const _labelColor = Color(0xFF6D6154);

  @override
  Widget build(BuildContext context) {
    final safeDays =
        days.isEmpty ? const <HabitStatsCountLast7DayItem>[] : days;

    return SizedBox(
      key: const Key('habit_stats_count_last7_chart'),
      height: 126,
      child: Column(
        children: [
          Expanded(
            child: _CountLast7DaysPlot(days: safeDays),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(
              left: CountLast7DaysChartScale.defaultLeftGutter,
              right: CountLast7DaysChartScale.defaultRightPadding,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < safeDays.length; index++)
                  Expanded(
                    child: Text(
                      safeDays[index].weekdayLabel,
                      key: Key('habit_stats_count_last7_weekday_$index'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _labelColor,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountLast7DaysPlot extends StatelessWidget {
  final List<HabitStatsCountLast7DayItem> days;

  const _CountLast7DaysPlot({
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final values = days.map((day) => day.value).toList(growable: false);
        final scale = CountLast7DaysChartScale.fromDays(values);
        final points = buildCountLast7DaysChartPoints(
          values: values,
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          scale: scale,
        );
        final axisTicks = buildCountLast7DaysAxisTicks(
          scale: scale,
          maxHeight: constraints.maxHeight,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                key: const Key('habit_stats_count_last7_plot'),
                painter: CountLast7DaysChartPainter(
                  points: points,
                  scale: scale,
                  lineColor: HabitStatsCountLast7DaysChart._lineColor,
                ),
              ),
            ),
            for (var index = axisTicks.length - 1; index >= 0; index--)
              Positioned(
                left: 0,
                top: axisTicks[index].y - 5,
                width: scale.leftGutter - 5,
                child: Text(
                  formatCountLast7DaysAxisLabel(
                    axisTicks[index].value,
                    fractionDigits: scale.fractionDigits,
                  ),
                  key: Key('habit_stats_count_last7_y_label_$index'),
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        height: 1,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8A7F72),
                      ),
                ),
              ),
            for (var index = 0; index < points.length; index++)
              Positioned(
                left: points[index].dx - 5,
                top: points[index].dy - 5,
                child: Container(
                  key: Key('habit_stats_count_last7_marker_$index'),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HabitStatsCountLast7DaysChart._markerFillColor,
                    border: Border.all(
                      color: HabitStatsCountLast7DaysChart._markerStrokeColor,
                      width: 1.7,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
