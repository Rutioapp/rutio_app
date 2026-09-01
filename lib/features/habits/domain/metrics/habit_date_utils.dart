DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String dateKey(DateTime date) {
  final normalized = dateOnly(date);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

bool sameDate(DateTime left, DateTime right) {
  final normalizedLeft = dateOnly(left);
  final normalizedRight = dateOnly(right);
  return normalizedLeft.year == normalizedRight.year &&
      normalizedLeft.month == normalizedRight.month &&
      normalizedLeft.day == normalizedRight.day;
}

DateTime weekStartMonday(DateTime date) {
  final normalized = dateOnly(date);
  final delta = normalized.weekday - DateTime.monday;
  return normalized.subtract(Duration(days: delta));
}

DateTime weekEndSunday(DateTime date) {
  return weekStartMonday(date).add(const Duration(days: 6));
}

int daysBetweenInclusive(DateTime start, DateTime end) {
  final normalizedStart = dateOnly(start);
  final normalizedEnd = dateOnly(end);
  if (normalizedEnd.isBefore(normalizedStart)) {
    return 0;
  }
  return normalizedEnd.difference(normalizedStart).inDays + 1;
}
