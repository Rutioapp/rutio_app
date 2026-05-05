import 'statistics_period.dart';

class StatisticsRange {
  const StatisticsRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  factory StatisticsRange.forPeriod(
    StatisticsPeriod period, {
    DateTime? anchor,
  }) {
    final today = _dateOnly(anchor ?? DateTime.now());
    switch (period) {
      case StatisticsPeriod.day:
        return StatisticsRange(start: today, end: today);
      case StatisticsPeriod.week:
        return StatisticsRange.lastDays(7, anchor: today);
      case StatisticsPeriod.month:
        return StatisticsRange.lastDays(30, anchor: today);
      case StatisticsPeriod.year:
        return StatisticsRange.lastDays(365, anchor: today);
    }
  }

  factory StatisticsRange.lastDays(int days, {DateTime? anchor}) {
    final end = _dateOnly(anchor ?? DateTime.now());
    final start = end.subtract(Duration(days: days - 1));
    return StatisticsRange(start: start, end: end);
  }

  int get lengthInDays => end.difference(start).inDays + 1;

  StatisticsRange get previousPeriod {
    final previousEnd = start.subtract(const Duration(days: 1));
    final previousStart =
        previousEnd.subtract(Duration(days: lengthInDays - 1));
    return StatisticsRange(start: previousStart, end: previousEnd);
  }

  List<DateTime> get days {
    final output = <DateTime>[];
    for (var i = 0; i < lengthInDays; i++) {
      output.add(start.add(Duration(days: i)));
    }
    return output;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
