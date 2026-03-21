import 'package:flutter/widgets.dart';

import 'package:rutio/l10n/l10n.dart';

class MonthUtils {
  static String monthLabel(BuildContext context, DateTime month) {
    final raw = context.l10n.monthFull(month.month);
    final capitalized =
        raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}';
    return '$capitalized ${month.year}';
  }

  static int daysInMonth(DateTime monthCursor) =>
      DateTime(monthCursor.year, monthCursor.month + 1, 0).day;

  static int mondayBasedOffset(DateTime monthCursor) {
    final firstWeekday = monthCursor.weekday;
    return (firstWeekday + 6) % 7;
  }

  static String dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
