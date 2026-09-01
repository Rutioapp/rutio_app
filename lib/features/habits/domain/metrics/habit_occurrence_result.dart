import 'habit_date_utils.dart';
import 'habit_snapshot.dart';

enum HabitOccurrenceScope {
  dateBound,
  weeklyQuota,
}

class HabitOccurrenceResult {
  const HabitOccurrenceResult({
    required this.date,
    required this.scope,
    required this.scheduleType,
    required this.scheduled,
    required this.completed,
    required this.skipped,
    this.progress,
    this.target,
    this.weeklyScheduledCount,
    this.weeklyCompletedCount,
    this.weeklyQuotaMet = false,
  });

  final DateTime date;
  final HabitOccurrenceScope scope;
  final HabitScheduleType scheduleType;
  final bool scheduled;
  final bool completed;
  final bool skipped;
  final num? progress;
  final num? target;
  final int? weeklyScheduledCount;
  final int? weeklyCompletedCount;
  final bool weeklyQuotaMet;

  bool get isPartialProgress {
    final localProgress = progress;
    final localTarget = target;
    if (localProgress == null || localTarget == null) return false;
    return localProgress > 0 && localProgress < localTarget;
  }

  bool get hasCountProgress => progress != null || target != null;

  HabitOccurrenceResult copyWith({
    DateTime? date,
    HabitOccurrenceScope? scope,
    HabitScheduleType? scheduleType,
    bool? scheduled,
    bool? completed,
    bool? skipped,
    num? progress,
    bool clearProgress = false,
    num? target,
    bool clearTarget = false,
    int? weeklyScheduledCount,
    bool clearWeeklyScheduledCount = false,
    int? weeklyCompletedCount,
    bool clearWeeklyCompletedCount = false,
    bool? weeklyQuotaMet,
  }) {
    return HabitOccurrenceResult(
      date: date ?? this.date,
      scope: scope ?? this.scope,
      scheduleType: scheduleType ?? this.scheduleType,
      scheduled: scheduled ?? this.scheduled,
      completed: completed ?? this.completed,
      skipped: skipped ?? this.skipped,
      progress: clearProgress ? null : progress ?? this.progress,
      target: clearTarget ? null : target ?? this.target,
      weeklyScheduledCount: clearWeeklyScheduledCount
          ? null
          : weeklyScheduledCount ?? this.weeklyScheduledCount,
      weeklyCompletedCount: clearWeeklyCompletedCount
          ? null
          : weeklyCompletedCount ?? this.weeklyCompletedCount,
      weeklyQuotaMet: weeklyQuotaMet ?? this.weeklyQuotaMet,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitOccurrenceResult &&
        sameDate(other.date, date) &&
        other.scope == scope &&
        other.scheduleType == scheduleType &&
        other.scheduled == scheduled &&
        other.completed == completed &&
        other.skipped == skipped &&
        other.progress == progress &&
        other.target == target &&
        other.weeklyScheduledCount == weeklyScheduledCount &&
        other.weeklyCompletedCount == weeklyCompletedCount &&
        other.weeklyQuotaMet == weeklyQuotaMet;
  }

  @override
  int get hashCode => Object.hash(
        dateOnly(date),
        scope,
        scheduleType,
        scheduled,
        completed,
        skipped,
        progress,
        target,
        weeklyScheduledCount,
        weeklyCompletedCount,
        weeklyQuotaMet,
      );
}
