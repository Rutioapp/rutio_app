import 'package:flutter/foundation.dart';

/// Canonical guard for showing a completed-day phrase.
@immutable
class CompletedDayEligibility {
  const CompletedDayEligibility({
    required this.isReady,
    required this.isLocalToday,
    required this.scheduledHabitCount,
    required this.completedHabitCount,
    required this.pendingHabitCount,
    required this.skippedHabitCount,
  });

  final bool isReady;
  final bool isLocalToday;
  final int scheduledHabitCount;
  final int completedHabitCount;
  final int pendingHabitCount;
  final int skippedHabitCount;

  bool get isCompletedDay =>
      isReady &&
      isLocalToday &&
      scheduledHabitCount > 0 &&
      completedHabitCount == scheduledHabitCount &&
      pendingHabitCount == 0 &&
      skippedHabitCount == 0;

  double get progress =>
      scheduledHabitCount <= 0 ? 0 : completedHabitCount / scheduledHabitCount;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CompletedDayEligibility &&
            other.isReady == isReady &&
            other.isLocalToday == isLocalToday &&
            other.scheduledHabitCount == scheduledHabitCount &&
            other.completedHabitCount == completedHabitCount &&
            other.pendingHabitCount == pendingHabitCount &&
            other.skippedHabitCount == skippedHabitCount;
  }

  @override
  int get hashCode => Object.hash(
        isReady,
        isLocalToday,
        scheduledHabitCount,
        completedHabitCount,
        pendingHabitCount,
        skippedHabitCount,
      );
}

String completedDayEligibilityReason(CompletedDayEligibility eligibility) {
  if (eligibility.isCompletedDay) return 'eligible';

  final reasons = <String>[];
  if (!eligibility.isReady) reasons.add('not_ready');
  if (!eligibility.isLocalToday) reasons.add('not_local_today');
  if (eligibility.scheduledHabitCount == 0) reasons.add('zero_scheduled');
  if (eligibility.completedHabitCount != eligibility.scheduledHabitCount) {
    reasons.add('completed_count_mismatch');
  }
  if (eligibility.pendingHabitCount != 0) reasons.add('pending_gt_zero');
  if (eligibility.skippedHabitCount != 0) reasons.add('skipped_gt_zero');
  return reasons.join(',');
}
