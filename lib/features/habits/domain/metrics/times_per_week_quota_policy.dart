import 'dart:math' as math;

import 'habit_date_utils.dart';
import 'habit_snapshot.dart';
import 'weekly_report_week.dart';

enum TimesPerWeekQuotaPolicyKind {
  proratedCeil,
}

class TimesPerWeekQuotaPolicy {
  const TimesPerWeekQuotaPolicy._({
    required this.kind,
  });

  const TimesPerWeekQuotaPolicy.proratedCeil()
      : this._(kind: TimesPerWeekQuotaPolicyKind.proratedCeil);

  final TimesPerWeekQuotaPolicyKind kind;

  int effectiveScheduledQuota({
    required int configuredTimesPerWeek,
    required WeeklyReportWeek week,
    DateTime? activeFrom,
    DateTime? activeUntil,
  }) {
    final configured = configuredTimesPerWeek < 1 ? 1 : configuredTimesPerWeek;
    final eligibleDays = _eligibleDays(
      week: week,
      activeFrom: activeFrom,
      activeUntil: activeUntil,
    );
    if (eligibleDays <= 0) return 0;
    if (eligibleDays >= 7) return configured;

    switch (kind) {
      case TimesPerWeekQuotaPolicyKind.proratedCeil:
        final prorated =
            (configured * eligibleDays / week.eligibleDaysCount).ceil();
        return math.min(configured, math.max(0, prorated));
    }
  }

  int _eligibleDays({
    required WeeklyReportWeek week,
    DateTime? activeFrom,
    DateTime? activeUntil,
  }) {
    final start = activeFrom == null
        ? week.weekStartDate
        : dateOnly(activeFrom).isAfter(dateOnly(week.weekStartDate))
            ? dateOnly(activeFrom)
            : dateOnly(week.weekStartDate);
    final end = activeUntil == null
        ? week.weekEndDate
        : dateOnly(activeUntil).isBefore(dateOnly(week.weekEndDate))
            ? dateOnly(activeUntil)
            : dateOnly(week.weekEndDate);
    if (end.isBefore(start)) return 0;
    return daysBetweenInclusive(start, end);
  }
}

class TimesPerWeekQuotaResult {
  const TimesPerWeekQuotaResult({
    required this.configuredTimesPerWeek,
    required this.eligibleDays,
    required this.scheduledCount,
  });

  final int configuredTimesPerWeek;
  final int eligibleDays;
  final int scheduledCount;
}

TimesPerWeekQuotaResult calculateEffectiveScheduledQuota({
  required int configuredTimesPerWeek,
  required WeeklyReportWeek week,
  DateTime? activeFrom,
  DateTime? activeUntil,
  TimesPerWeekQuotaPolicy policy = const TimesPerWeekQuotaPolicy.proratedCeil(),
}) {
  final configured = configuredTimesPerWeek < 1 ? 1 : configuredTimesPerWeek;
  final eligibleDays = policy._eligibleDays(
    week: week,
    activeFrom: activeFrom,
    activeUntil: activeUntil,
  );
  return TimesPerWeekQuotaResult(
    configuredTimesPerWeek: configured,
    eligibleDays: eligibleDays,
    scheduledCount: policy.effectiveScheduledQuota(
      configuredTimesPerWeek: configured,
      week: week,
      activeFrom: activeFrom,
      activeUntil: activeUntil,
    ),
  );
}
