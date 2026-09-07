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

  /// Whether every relevant habit has a resolved state for today's phrase.
  ///
  /// A resolved state is either completed or skipped. This is intentionally
  /// separate from any future perfect-day concept, which may still require
  /// zero skips.
  bool get isDayResolvedForPhrase =>
      isReady &&
      isLocalToday &&
      scheduledHabitCount > 0 &&
      pendingHabitCount == 0 &&
      completedHabitCount + skippedHabitCount == scheduledHabitCount;

  /// Backwards-compatible name for existing Home presentation callers.
  bool get isCompletedDay => isDayResolvedForPhrase;

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
  if (eligibility.pendingHabitCount != 0) reasons.add('pending_gt_zero');
  if (eligibility.completedHabitCount + eligibility.skippedHabitCount !=
      eligibility.scheduledHabitCount) {
    reasons.add('resolved_count_mismatch');
  }
  return reasons.join(',');
}
