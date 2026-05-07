import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';

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
  static const _text = Color(0xFF2F251C);
  static const _mutedText = Color(0xFF6A6155);
  static const _cellBase = Color(0xFFD8D1C5);
  static const _cellBorder = Color(0xFFE5DED3);
  static const _todayBorder = Color(0xFF9AA789);
  static const _futureFill = Color(0xFFF0EBE3);
  static final _legendEntries = <_CalendarLegendEntry>[
    _CalendarLegendEntry(
      label: '0–24%',
      color: _CalendarIntensityBucket.zero.color,
    ),
    _CalendarLegendEntry(
      label: '25–49%',
      color: _CalendarIntensityBucket.low.color,
    ),
    _CalendarLegendEntry(
      label: '50–74%',
      color: _CalendarIntensityBucket.medium.color,
    ),
    _CalendarLegendEntry(
      label: '75–89%',
      color: _CalendarIntensityBucket.high.color,
    ),
    _CalendarLegendEntry(
      label: '90–100%',
      color: _CalendarIntensityBucket.full.color,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final calendarDays = days.isEmpty ? _fallbackDays() : days;
    final firstDay = calendarDays.first.date;
    final daysInMonth = calendarDays.length;
    const daysPerWeek = 7;
    final leadingDays =
        (firstDay.weekday - DateTime.monday + daysPerWeek) % daysPerWeek;
    final totalCells = leadingDays + daysInMonth;
    final rows = math.max(4, (totalCells / daysPerWeek).ceil());
    final cellCount = rows * daysPerWeek;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: _cream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
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
                                color: _text,
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
                      color: _mutedText,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              if (index < leadingDays || index >= leadingDays + daysInMonth) {
                return const _CalendarPlaceholderCell();
              }

              final day = calendarDays[index - leadingDays];
              final tone = _calendarToneFor(day);

              return _CalendarCell(
                dayNumber: day.date.day,
                fillColor: tone.fillColor,
                borderColor: day.isToday ? _todayBorder.withValues(alpha: 0.82) : tone.borderColor,
                dayColor: tone.textColor,
                dotColor: tone.dotColor,
                isToday: day.isToday,
                isFuture: day.isFuture,
              );
            },
          ),
          const SizedBox(height: 10),
          _CalendarLegend(entries: _legendEntries),
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

  _CalendarTone _calendarToneFor(StatisticsV3MonthlyCalendarDay day) {
    if (day.isFuture) {
      return _CalendarTone.future;
    }

    final bucket = _calendarBucketForPercentage(day.percentage);
    return _CalendarTone.fromBucket(bucket);
  }

  _CalendarIntensityBucket _calendarBucketForPercentage(int percentage) {
    final value = percentage.clamp(0, 100);
    if (value <= 24) {
      return _CalendarIntensityBucket.zero;
    }
    if (value <= 49) {
      return _CalendarIntensityBucket.low;
    }
    if (value <= 74) {
      return _CalendarIntensityBucket.medium;
    }
    if (value <= 89) {
      return _CalendarIntensityBucket.high;
    }
    return _CalendarIntensityBucket.full;
  }
}

class _CalendarPlaceholderCell extends StatelessWidget {
  const _CalendarPlaceholderCell();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: StatisticsV3MonthlyCalendarShell._cellBorder.withValues(alpha: 0.25)),
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.dayNumber,
    required this.fillColor,
    required this.borderColor,
    required this.dayColor,
    required this.dotColor,
    required this.isToday,
    required this.isFuture,
  });

  final int dayNumber;
  final Color fillColor;
  final Color borderColor;
  final Color dayColor;
  final Color dotColor;
  final bool isToday;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 4,
            child: Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 10.5,
                height: 1,
                fontWeight: FontWeight.w700,
                color: dayColor.withValues(
                  alpha: isFuture ? 0.50 : (isToday ? 0.95 : 0.88),
                ),
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarTone {
  const _CalendarTone({
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.dotColor,
  });

  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final Color dotColor;

  factory _CalendarTone.fromBucket(_CalendarIntensityBucket bucket) {
    return _CalendarTone(
      fillColor: bucket.color,
      borderColor: StatisticsV3MonthlyCalendarShell._cellBorder,
      textColor: StatisticsV3MonthlyCalendarShell._text,
      dotColor: bucket.color.withValues(alpha: 0.64),
    );
  }

  static const future = _CalendarTone(
    fillColor: StatisticsV3MonthlyCalendarShell._futureFill,
    borderColor: StatisticsV3MonthlyCalendarShell._cellBorder,
    textColor: StatisticsV3MonthlyCalendarShell._mutedText,
    dotColor: StatisticsV3MonthlyCalendarShell._cellBase,
  );
}

class _CalendarIntensityBucket {
  const _CalendarIntensityBucket._(this.color);

  final Color color;

  static const zero = _CalendarIntensityBucket._(Color(0xFFF4EAD7));
  static const low = _CalendarIntensityBucket._(Color(0xFFEEDDAF));
  static const medium = _CalendarIntensityBucket._(Color(0xFFD9A947));
  static const high = _CalendarIntensityBucket._(Color(0xFF8FA36C));
  static const full = _CalendarIntensityBucket._(Color(0xFF4F743B));
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.entries});

  final List<_CalendarLegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: entries
          .map(
            (entry) => _CalendarLegendItem(
              label: entry.label,
              color: entry.color,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _CalendarLegendEntry {
  const _CalendarLegendEntry({required this.label, required this.color});

  final String label;
  final Color color;
}

class _CalendarLegendItem extends StatelessWidget {
  const _CalendarLegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            height: 1,
            fontWeight: FontWeight.w500,
            color: StatisticsV3MonthlyCalendarShell._mutedText,
          ),
        ),
      ],
    );
  }
}
