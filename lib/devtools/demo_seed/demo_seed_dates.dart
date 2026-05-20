class DemoSeedDates {
  const DemoSeedDates._();

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static DateTime firstDayOfMonthMonthsBack({
    required DateTime now,
    required int monthsBack,
  }) {
    final safeMonthsBack = monthsBack < 0 ? 0 : monthsBack;
    final localNow = now.toLocal();
    return DateTime(localNow.year, localNow.month - safeMonthsBack, 1);
  }

  static Iterable<DateTime> eachDayInclusive({
    required DateTime start,
    required DateTime end,
  }) sync* {
    final startDay = dateOnly(start);
    final endDay = dateOnly(end);
    if (endDay.isBefore(startDay)) return;

    for (var day = startDay;
        !day.isAfter(endDay);
        day = day.add(const Duration(days: 1))) {
      yield day;
    }
  }

  static DateTime startOfWeek(DateTime day, {int weekStartsOn = 1}) {
    final safeWeekStartsOn = weekStartsOn >= 1 && weekStartsOn <= 7
        ? weekStartsOn
        : DateTime.monday;
    final normalized = dateOnly(day);
    final delta = (normalized.weekday - safeWeekStartsOn + 7) % 7;
    return normalized.subtract(Duration(days: delta));
  }
}
