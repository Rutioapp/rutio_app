import 'habit_date_utils.dart';

/// Derived weekly quota progress for a flexible CHECK schedule.
///
/// The source of truth is the canonical daily completion history. Nothing in
/// this model is persisted as mutable weekly state.
class WeeklyCheckProgress {
  const WeeklyCheckProgress({
    required this.completedDays,
    required this.targetDays,
    required this.weekStart,
    required this.weekEnd,
  });

  final int completedDays;
  final int targetDays;
  final DateTime weekStart;
  final DateTime weekEnd;

  bool get quotaMet => completedDays >= targetDays;

  double get rawProgressRatio =>
      targetDays <= 0 ? 0 : completedDays / targetDays;

  double get cappedProgressRatio => rawProgressRatio.clamp(0.0, 1.0);
}

class HabitWeeklyCheckProgressCalculator {
  const HabitWeeklyCheckProgressCalculator();

  WeeklyCheckProgress calculate({
    required Map<String, dynamic> habit,
    required Map<String, dynamic> history,
    required DateTime referenceDate,
  }) {
    final habitId = (habit['id'] ?? habit['habitId'] ?? '').toString().trim();
    final schedule = _map(habit['schedule']);
    final targetRaw =
        schedule['timesPerWeek'] ?? schedule['timesPerWeekTarget'];
    final target = _positiveInt(targetRaw);
    final weekStart = weekStartMonday(referenceDate);
    final weekEnd = weekEndSunday(referenceDate);
    final completions = _map(_map(history['habitCompletions']));
    final skips = _map(_map(history['habitSkips']));

    var completedDays = 0;
    for (var offset = 0; offset < 7; offset += 1) {
      final day = weekStart.add(Duration(days: offset));
      final dayCompletions = _map(completions[dateKey(day)]);
      final daySkips = _map(skips[dateKey(day)]);
      if (_isTruthy(dayCompletions[habitId]) && !_isTruthy(daySkips[habitId])) {
        completedDays += 1;
      }
    }

    return WeeklyCheckProgress(
      completedDays: completedDays,
      targetDays: target,
      weekStart: weekStart,
      weekEnd: weekEnd,
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

int _positiveInt(dynamic value) {
  final parsed = value is num ? value.toInt() : int.tryParse('$value');
  return parsed == null || parsed < 1 ? 1 : parsed;
}

bool _isTruthy(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value > 0;
  final normalized = (value ?? '').toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}
