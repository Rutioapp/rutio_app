import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_consistency_legend.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_consistency_palette.dart';
import 'package:rutio/l10n/l10n.dart';

class StatisticsV3MonthlyCalendarShell extends StatelessWidget {
  const StatisticsV3MonthlyCalendarShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.days,
  });

  final String title;
  final String subtitle;
  final List<StatisticsV3MonthlyCalendarDay> days;

  static const _border = Color(0xFFE9E3D9);
  static const _cream = Color(0xFFFDFBF7);
  static const _todayBorder = Color(0xFF9AA789);

  @override
  Widget build(BuildContext context) {
    final calendarDays = days.isEmpty ? _fallbackDays() : days;
    final firstDay = calendarDays.first.date;
    final daysInMonth = calendarDays.length;
    const daysPerWeek = DateTime.daysPerWeek;
    final leadingDays =
        (firstDay.weekday - DateTime.monday + daysPerWeek) % daysPerWeek;
    final totalCells = leadingDays + daysInMonth;
    final rows = math.max(5, (totalCells / daysPerWeek).ceil());
    final cellCount = rows * daysPerWeek;

    return Container(
      key: const Key('statisticsV3MonthlyCalendarShell'),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: _cream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(title: title, subtitle: subtitle),
          _WeekdayHeader(),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 6.0;
              final rawCellWidth = (constraints.maxWidth - (spacing * 6)) / 7;
              final markerSize = rawCellWidth.clamp(30.0, 34.0).toDouble();
              final cellHeight = markerSize + 4;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: cellCount,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: rawCellWidth / cellHeight,
                ),
                itemBuilder: (context, index) {
                  if (index < leadingDays || index >= leadingDays + daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final day = calendarDays[index - leadingDays];
                  final intensity = StatisticsV3ConsistencyPalette.intensityFor(
                    percentage: day.percentage,
                    expectedCount: day.expectedCount,
                    isFuture: day.isFuture,
                  );
                  final tone =
                      StatisticsV3ConsistencyPalette.toneFor(intensity);

                  return _MonthDayCell(
                    day: day,
                    markerSize: markerSize,
                    tone: tone,
                    todayBorderColor: _todayBorder,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 10),
          const StatisticsV3ConsistencyLegend(),
        ],
      ),
    );
  }

  List<StatisticsV3MonthlyCalendarDay> _fallbackDays() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    return List<StatisticsV3MonthlyCalendarDay>.generate(daysInMonth, (index) {
      final date = firstDay.add(Duration(days: index));
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));

      return StatisticsV3MonthlyCalendarDay(
        date: date,
        completedCount: 0,
        expectedCount: 0,
        percentage: 0,
        isToday: isToday,
        isFuture: isFuture,
        isCurrentMonth: true,
      );
    }, growable: false);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  static const _todayBorder = Color(0xFF9AA789);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 172;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: compact ? 23 : 24,
              child: Row(
                children: [
                  Container(
                    width: compact ? 22 : 24,
                    height: compact ? 22 : 24,
                    decoration: BoxDecoration(
                      color: _todayBorder.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      size: compact ? 15 : 16,
                      color: _todayBorder,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: compact ? 13.4 : 14.2,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: StatisticsV3ConsistencyPalette.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w500,
                color: StatisticsV3ConsistencyPalette.mutedText,
              ),
            ),
            const SizedBox(height: 9),
          ],
        );
      },
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      context.l10n.weekdayLetter(DateTime.monday),
      context.l10n.weekdayLetter(DateTime.tuesday),
      context.l10n.weekdayLetter(DateTime.wednesday),
      context.l10n.weekdayLetter(DateTime.thursday),
      context.l10n.weekdayLetter(DateTime.friday),
      context.l10n.weekdayLetter(DateTime.saturday),
      context.l10n.weekdayLetter(DateTime.sunday),
    ];
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10.5,
                      height: 1,
                      color: const Color(0xFF8B7D6E),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.day,
    required this.markerSize,
    required this.tone,
    required this.todayBorderColor,
  });

  final StatisticsV3MonthlyCalendarDay day;
  final double markerSize;
  final StatisticsV3ConsistencyTone tone;
  final Color todayBorderColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        key: Key('statisticsV3MonthDay_${_dateKey(day.date)}'),
        width: markerSize,
        height: markerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tone.fillColor,
          border: Border.all(
            color: day.isToday ? todayBorderColor : tone.borderColor,
            width: day.isToday ? 1.25 : 1.05,
          ),
        ),
        child: Center(
          child: Text(
            '${day.date.day}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: markerSize >= 32 ? 12.0 : 11.3,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: tone.textColor.withValues(
                    alpha: day.isFuture ? 0.58 : 0.95,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
