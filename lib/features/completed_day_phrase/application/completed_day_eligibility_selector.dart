import '../domain/completed_day_eligibility.dart';

/// Builds phrase eligibility from Home's real habit snapshot.
CompletedDayEligibility buildCompletedDayEligibility({
  required Iterable<Map<String, dynamic>> viewHabits,
  required DateTime selectedDay,
  required DateTime localToday,
  required bool isReady,
}) {
  var scheduled = 0;
  var completed = 0;
  var pending = 0;
  var skipped = 0;

  for (final habit in viewHabits) {
    scheduled += 1;
    final isSkipped = habit['skippedToday'] == true;
    final isCompleted = !isSkipped && habit['doneToday'] == true;
    if (isSkipped) {
      skipped += 1;
    } else if (isCompleted) {
      completed += 1;
    } else {
      pending += 1;
    }
  }

  return CompletedDayEligibility(
    isReady: isReady,
    isLocalToday: _dateKey(selectedDay) == _dateKey(localToday),
    scheduledHabitCount: scheduled,
    completedHabitCount: completed,
    pendingHabitCount: pending,
    skippedHabitCount: skipped,
  );
}

String _dateKey(DateTime value) {
  final local = DateTime(value.year, value.month, value.day);
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
