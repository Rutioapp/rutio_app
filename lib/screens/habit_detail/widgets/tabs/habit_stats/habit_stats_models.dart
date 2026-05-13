part of '../habit_stats_tab.dart';

class _ObjectiveMetric {
  const _ObjectiveMetric({
    required this.value,
    required this.subtitle,
  });

  final String value;
  final String subtitle;
}

class _DayRow {
  const _DayRow({
    required this.date,
    required this.skipped,
    required this.checkCompleted,
    required this.countValue,
  });

  const _DayRow.empty(this.date)
      : skipped = false,
        checkCompleted = false,
        countValue = 0;

  final DateTime date;
  final bool skipped;
  final bool checkCompleted;
  final num countValue;
}

class _DateRange {
  const _DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  int get dayCount => end.difference(start).inDays + 1;
}

class _CheckStats {
  const _CheckStats({
    required this.expected,
    required this.completed,
    required this.consistencyPct,
  });

  const _CheckStats.empty()
      : expected = 0,
        completed = 0,
        consistencyPct = 0;

  final int expected;
  final int completed;
  final int consistencyPct;
}

class _CountStats {
  const _CountStats({
    required this.total,
    required this.average,
    required this.completionPct,
  });

  const _CountStats.empty()
      : total = 0,
        average = 0,
        completionPct = 0;

  final num total;
  final num average;
  final int completionPct;
}
