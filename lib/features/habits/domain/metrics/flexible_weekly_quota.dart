import 'habit_date_utils.dart';
import 'times_per_week_quota_policy.dart';
import 'weekly_report_week.dart';

/// Indicates how confidently a derived quota represents the requested period.
enum FlexibleWeeklyDataQuality {
  verified,
  currentConfigFallback,
  unverifiable,
}

/// An immutable configuration interval supplied by a caller that has history.
/// Dates are local calendar dates and both endpoints are inclusive.
class FlexibleWeeklyQuotaConfigSegment {
  const FlexibleWeeklyQuotaConfigSegment({
    required this.timesPerWeek,
    required this.effectiveFrom,
    this.effectiveUntil,
    this.weekStartsOn = DateTime.monday,
  });

  final int timesPerWeek;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;
  final int weekStartsOn;

  bool contains(DateTime date) {
    final day = dateOnly(date);
    final from = dateOnly(effectiveFrom);
    final until = effectiveUntil == null ? null : dateOnly(effectiveUntil!);
    return !day.isBefore(from) && (until == null || !day.isAfter(until));
  }

  DateTime get normalizedFrom => dateOnly(effectiveFrom);
  DateTime? get normalizedUntil =>
      effectiveUntil == null ? null : dateOnly(effectiveUntil!);
}

/// Current habit configuration plus optional historical configuration segments.
/// This is an input object only; it is never persisted.
class FlexibleWeeklyQuotaHabit {
  const FlexibleWeeklyQuotaHabit({
    required this.habitId,
    required this.timesPerWeek,
    this.createdAt,
    this.archivedAt,
    this.weekStartsOn = DateTime.monday,
    this.configurationSegments = const <FlexibleWeeklyQuotaConfigSegment>[],
  }) : assert(habitId != '');

  final String habitId;
  final int timesPerWeek;
  final DateTime? createdAt;
  final DateTime? archivedAt;
  final int weekStartsOn;
  final List<FlexibleWeeklyQuotaConfigSegment> configurationSegments;

  DateTime? get normalizedCreatedAt =>
      createdAt == null ? null : dateOnly(createdAt!);

  DateTime? get normalizedArchivedAt =>
      archivedAt == null ? null : dateOnly(archivedAt!);

  List<FlexibleWeeklyQuotaConfigSegment> segmentsForWeek(
    WeeklyReportWeek week,
  ) {
    if (configurationSegments.isEmpty) {
      return <FlexibleWeeklyQuotaConfigSegment>[
        FlexibleWeeklyQuotaConfigSegment(
          timesPerWeek: timesPerWeek,
          effectiveFrom: normalizedCreatedAt ?? week.weekStartDate,
          effectiveUntil: normalizedArchivedAt == null
              ? week.weekEndDate
              : normalizedArchivedAt!.subtract(const Duration(days: 1)),
          weekStartsOn: weekStartsOn,
        ),
      ];
    }
    return configurationSegments
        .where((segment) => segment.weekStartsOn == weekStartsOn)
        .toList(growable: false);
  }
}

class FlexibleWeeklyQuotaResult {
  const FlexibleWeeklyQuotaResult({
    required this.weekStart,
    required this.weekEnd,
    required this.completedDays,
    required this.scheduledQuota,
    required this.eligibleDays,
    required this.skippedDays,
    required this.dataQuality,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final int completedDays;
  final int scheduledQuota;
  final int eligibleDays;
  final int skippedDays;
  final FlexibleWeeklyDataQuality dataQuality;

  bool get quotaMet => completedDays >= scheduledQuota && scheduledQuota > 0;
  int get overTargetCount =>
      completedDays > scheduledQuota ? completedDays - scheduledQuota : 0;
  bool get isComparable => scheduledQuota > 0;
  bool get isUnverifiable =>
      dataQuality == FlexibleWeeklyDataQuality.unverifiable;
  double get rawRatio =>
      scheduledQuota <= 0 ? 0 : completedDays / scheduledQuota;
  double get cappedRatio => rawRatio.clamp(0.0, 1.0);
}

/// Evaluates one flexible CHECK quota bucket from canonical daily history.
class FlexibleWeeklyQuotaEvaluator {
  const FlexibleWeeklyQuotaEvaluator({
    this.quotaPolicy = const TimesPerWeekQuotaPolicy.proratedCeil(),
  });

  final TimesPerWeekQuotaPolicy quotaPolicy;

  FlexibleWeeklyQuotaResult evaluate({
    required FlexibleWeeklyQuotaHabit habit,
    required WeeklyReportWeek week,
    required Map<String, dynamic> history,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    bool currentWeek = false,
    FlexibleWeeklyDataQuality? dataQuality,
  }) {
    final requestedStart = dateOnly(rangeStart ?? week.weekStartDate);
    final requestedEnd = dateOnly(rangeEnd ?? week.weekEndDate);
    final intervalStart = _maxDate(week.weekStartDate, requestedStart);
    final intervalEnd = _minDate(week.weekEndDate, requestedEnd);

    if (habit.timesPerWeek < 1 ||
        habit.weekStartsOn < DateTime.monday ||
        habit.weekStartsOn > DateTime.sunday) {
      return FlexibleWeeklyQuotaResult(
        weekStart: week.weekStartDate,
        weekEnd: week.weekEndDate,
        completedDays: 0,
        scheduledQuota: 0,
        eligibleDays: 0,
        skippedDays: 0,
        dataQuality: FlexibleWeeklyDataQuality.unverifiable,
      );
    }

    if (intervalEnd.isBefore(intervalStart)) {
      return FlexibleWeeklyQuotaResult(
        weekStart: week.weekStartDate,
        weekEnd: week.weekEndDate,
        completedDays: 0,
        scheduledQuota: 0,
        eligibleDays: 0,
        skippedDays: 0,
        dataQuality: dataQuality ?? _defaultQuality(habit),
      );
    }

    final segments = habit.segmentsForWeek(week);
    var scheduledQuotaNumerator = 0;
    var eligibleDays = 0;
    final eligibleDates = <DateTime>{};
    var quality = dataQuality ?? _defaultQuality(habit);

    for (final segment in segments) {
      if (segment.timesPerWeek < 1 ||
          segment.weekStartsOn < DateTime.monday ||
          segment.weekStartsOn > DateTime.sunday) {
        quality = FlexibleWeeklyDataQuality.unverifiable;
        continue;
      }
      final start = _maxDate(intervalStart, segment.normalizedFrom);
      final segmentUntil = segment.normalizedUntil;
      final end = _minDate(
        intervalEnd,
        segmentUntil ?? intervalEnd,
      );
      if (end.isBefore(start)) continue;

      final quotaStart = _maxDate(week.weekStartDate, segment.normalizedFrom);
      final quotaEnd = _minDate(
        week.weekEndDate,
        segmentUntil ?? week.weekEndDate,
      );
      final eligibleStart = currentWeek ? quotaStart : start;
      final eligibleEnd = currentWeek ? quotaEnd : end;
      if (eligibleEnd.isBefore(eligibleStart)) continue;

      final quotaEligibleDays =
          daysBetweenInclusive(eligibleStart, eligibleEnd);
      eligibleDays += quotaEligibleDays;
      for (var index = 0; index < daysBetweenInclusive(start, end); index++) {
        eligibleDates.add(start.add(Duration(days: index)));
      }
      switch (quotaPolicy.kind) {
        case TimesPerWeekQuotaPolicyKind.proratedCeil:
          // Keep the rounding operation at the whole-week level. Rounding
          // each configuration segment independently would overcount a week
          // with several target changes compared with the backend contract.
          scheduledQuotaNumerator += segment.timesPerWeek * quotaEligibleDays;
      }
    }

    if (habit.configurationSegments.isNotEmpty &&
        !_segmentsCoverInterval(segments, intervalStart, intervalEnd)) {
      quality = FlexibleWeeklyDataQuality.unverifiable;
    }

    final completionDays = _historyDays(
      history: history,
      rootKey: 'habitCompletions',
      habitId: habit.habitId,
      from: intervalStart,
      to: intervalEnd,
      excluded: _historyDays(
        history: history,
        rootKey: 'habitSkips',
        habitId: habit.habitId,
        from: intervalStart,
        to: intervalEnd,
      ),
    ).where(eligibleDates.contains).toSet();
    final skippedDays = _historyDays(
      history: history,
      rootKey: 'habitSkips',
      habitId: habit.habitId,
      from: intervalStart,
      to: intervalEnd,
    ).where(eligibleDates.contains).length;

    final scheduledQuota =
        (scheduledQuotaNumerator / week.eligibleDaysCount).ceil();

    return FlexibleWeeklyQuotaResult(
      weekStart: week.weekStartDate,
      weekEnd: week.weekEndDate,
      completedDays: completionDays.length,
      scheduledQuota: scheduledQuota,
      eligibleDays: eligibleDays,
      skippedDays: skippedDays,
      dataQuality: quality,
    );
  }

  FlexibleWeeklyDataQuality _defaultQuality(FlexibleWeeklyQuotaHabit habit) {
    return habit.configurationSegments.isEmpty
        ? FlexibleWeeklyDataQuality.currentConfigFallback
        : FlexibleWeeklyDataQuality.verified;
  }
}

Set<DateTime> _historyDays({
  required Map<String, dynamic> history,
  required String rootKey,
  required String habitId,
  required DateTime from,
  required DateTime to,
  Set<DateTime> excluded = const <DateTime>{},
}) {
  final root = _map(history[rootKey]);
  final result = <DateTime>{};
  for (final entry in root.entries) {
    final date = _parseDate(entry.key);
    if (date == null || date.isBefore(from) || date.isAfter(to)) continue;
    final values = _map(entry.value);
    if (_truthy(values[habitId]) && !excluded.contains(date)) result.add(date);
  }
  return result;
}

bool _segmentsCoverInterval(
  List<FlexibleWeeklyQuotaConfigSegment> segments,
  DateTime from,
  DateTime to,
) {
  final days = <DateTime>{};
  for (final segment in segments) {
    final start = _maxDate(from, segment.normalizedFrom);
    final end = _minDate(to, segment.normalizedUntil ?? to);
    if (end.isBefore(start)) continue;
    final count = daysBetweenInclusive(start, end);
    for (var index = 0; index < count; index++) {
      days.add(start.add(Duration(days: index)));
    }
  }
  return days.length == daysBetweenInclusive(from, to);
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

DateTime? _parseDate(dynamic value) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  return parsed == null ? null : dateOnly(parsed.toLocal());
}

bool _truthy(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value > 0;
  return ['true', '1'].contains((value ?? '').toString().trim().toLowerCase());
}

DateTime _maxDate(DateTime left, DateTime right) {
  final a = dateOnly(left);
  final b = dateOnly(right);
  return a.isAfter(b) ? a : b;
}

DateTime _minDate(DateTime left, DateTime right) {
  final a = dateOnly(left);
  final b = dateOnly(right);
  return a.isBefore(b) ? a : b;
}
