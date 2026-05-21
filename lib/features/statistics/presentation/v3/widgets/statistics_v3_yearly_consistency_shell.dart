import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_consistency_legend.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_consistency_palette.dart';

class StatisticsV3YearlyConsistencyShell extends StatelessWidget {
  const StatisticsV3YearlyConsistencyShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.months,
  });

  final String title;
  final String subtitle;
  final List<StatisticsV3YearlyConsistencyMonth> months;

  static const _border = Color(0xFFE9E3D9);
  static const _cream = Color(0xFFFDFBF7);
  static const _todayBorder = Color(0xFF9AA789);

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final data = months.isEmpty ? _fallbackMonths() : months;

    return Container(
      key: const Key('statisticsV3YearlyConsistencyShell'),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: _cream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const columnSpacing = 10.0;
          const rowSpacing = 10.0;
          final columns = constraints.maxWidth < 295 ? 2 : 3;
          final monthWidth =
              (constraints.maxWidth - (columnSpacing * (columns - 1))) / columns;
          final dayGap = monthWidth < 96 ? 1.5 : 2.0;
          final daySize =
              ((monthWidth - (dayGap * 6)) / 7).clamp(4.0, 9.0).toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(title: title, subtitle: subtitle),
              const SizedBox(height: 11),
              GridView.builder(
                key: const Key('statisticsV3YearCalendarGrid'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: data.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: columnSpacing,
                  mainAxisSpacing: rowSpacing,
                  childAspectRatio: columns == 3 ? 0.92 : 1.14,
                ),
                itemBuilder: (context, index) {
                  final month = data[index];
                  return _MonthMiniCalendar(
                    month: month,
                    monthLabel: _monthLabel(
                      localeName: localeName,
                      year: month.year,
                      month: month.month,
                    ),
                    daySize: daySize,
                    dayGap: dayGap,
                    todayBorderColor: _todayBorder,
                  );
                },
              ),
              const SizedBox(height: 10),
              const StatisticsV3ConsistencyLegend(),
            ],
          );
        },
      ),
    );
  }

  List<StatisticsV3YearlyConsistencyMonth> _fallbackMonths() {
    final now = DateTime.now();
    return List<StatisticsV3YearlyConsistencyMonth>.generate(12, (index) {
      final month = index + 1;
      final monthStart = DateTime(now.year, month, 1);
      final daysInMonth = DateUtils.getDaysInMonth(now.year, month);
      final days = List<StatisticsV3YearlyConsistencyDay>.generate(
        daysInMonth,
        (dayIndex) {
          final date = monthStart.add(Duration(days: dayIndex));
          final isFuture = date.isAfter(now);
          final isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
          return StatisticsV3YearlyConsistencyDay(
            date: date,
            completedCount: 0,
            expectedCount: 0,
            percentage: 0,
            isToday: isToday,
            isFuture: isFuture,
          );
        },
        growable: false,
      );
      return StatisticsV3YearlyConsistencyMonth(
        month: month,
        year: now.year,
        completedCount: 0,
        expectedCount: 0,
        percentage: 0,
        isCurrentMonth: month == now.month,
        isFuture: month > now.month,
        days: days,
      );
    }, growable: false);
  }

  String _monthLabel({
    required String localeName,
    required int year,
    required int month,
  }) {
    final label = DateFormat.MMM(localeName).format(DateTime(year, month, 1));
    if (label.isEmpty) return '';
    final first = label.substring(0, 1).toUpperCase();
    final rest = label.length > 1 ? label.substring(1) : '';
    return '$first$rest';
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
    return SizedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _todayBorder.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_view_month_rounded,
              size: 16,
              color: _todayBorder,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.2,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: StatisticsV3ConsistencyPalette.text,
                  ),
                ),
                const SizedBox(height: 5),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthMiniCalendar extends StatelessWidget {
  const _MonthMiniCalendar({
    required this.month,
    required this.monthLabel,
    required this.daySize,
    required this.dayGap,
    required this.todayBorderColor,
  });

  final StatisticsV3YearlyConsistencyMonth month;
  final String monthLabel;
  final double daySize;
  final double dayGap;
  final Color todayBorderColor;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(month.days);
    return Column(
      key: Key('statisticsV3YearMonth_${month.month}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          monthLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1,
                fontWeight: FontWeight.w700,
                color: StatisticsV3ConsistencyPalette.text.withValues(alpha: 0.9),
              ),
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < rows.length; row++) ...[
          if (row > 0) SizedBox(height: dayGap),
          Row(
            children: [
              for (var column = 0; column < rows[row].length; column++) ...[
                if (column > 0) SizedBox(width: dayGap),
                _YearDayDot(
                  day: rows[row][column],
                  size: daySize,
                  todayBorderColor: todayBorderColor,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _YearDayDot extends StatelessWidget {
  const _YearDayDot({
    required this.day,
    required this.size,
    required this.todayBorderColor,
  });

  final StatisticsV3YearlyConsistencyDay? day;
  final double size;
  final Color todayBorderColor;

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      return SizedBox.square(dimension: size);
    }

    final intensity = StatisticsV3ConsistencyPalette.intensityFor(
      percentage: day!.percentage,
      expectedCount: day!.expectedCount,
      isFuture: day!.isFuture,
    );
    final tone = StatisticsV3ConsistencyPalette.toneFor(intensity);

    return Container(
      key: Key('statisticsV3YearDay_${_dateKey(day!.date)}'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.fillColor,
        borderRadius: BorderRadius.circular(size * 0.36),
        border: Border.all(
          color: day!.isToday ? todayBorderColor : tone.borderColor,
          width: day!.isToday ? 0.95 : 0.6,
        ),
      ),
    );
  }
}

List<List<StatisticsV3YearlyConsistencyDay?>> _buildRows(
  List<StatisticsV3YearlyConsistencyDay> days,
) {
  if (days.isEmpty) return const <List<StatisticsV3YearlyConsistencyDay?>>[];
  final leading =
      (days.first.date.weekday - DateTime.monday + DateTime.daysPerWeek) %
          DateTime.daysPerWeek;
  final slots = <StatisticsV3YearlyConsistencyDay?>[
    for (var i = 0; i < leading; i++) null,
    ...days,
  ];
  final remainder = slots.length % DateTime.daysPerWeek;
  if (remainder != 0) {
    final trailing = DateTime.daysPerWeek - remainder;
    for (var i = 0; i < trailing; i++) {
      slots.add(null);
    }
  }

  final rows = <List<StatisticsV3YearlyConsistencyDay?>>[];
  for (var index = 0; index < slots.length; index += DateTime.daysPerWeek) {
    rows.add(slots.sublist(index, index + DateTime.daysPerWeek));
  }
  return rows;
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
