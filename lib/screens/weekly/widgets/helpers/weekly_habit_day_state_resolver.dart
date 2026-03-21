import '../weekly_day_cell.dart';
import 'weekly_habit_data_helper.dart';

class WeeklyHabitDayStateResolver {
  const WeeklyHabitDayStateResolver({
    required this.habitCompletions,
    required this.habitSkips,
    required this.habitCountValues,
  });

  final Map<String, dynamic> habitCompletions;
  final Map<String, dynamic> habitSkips;
  final Map<String, dynamic> habitCountValues;

  WeeklyDayCellData buildDayState(
    Map<String, dynamic> habit,
    String habitId,
    String dateKey,
  ) {
    if (isSkippedFor(habitId: habitId, dateKey: dateKey)) {
      return const WeeklyDayCellData.skip();
    }

    final habitType = WeeklyHabitDataHelper.normalizeHabitType(habit);
    final isDone = isDoneFor(habitId: habitId, dateKey: dateKey);

    if (habitType == 'count') {
      final value = countValueFor(habitId: habitId, dateKey: dateKey);
      final target = WeeklyHabitDataHelper.positiveNum(
        habit['target'],
        fallback: 1,
      );
      final hasValue = value != null && value > 0;
      final achieved = isDone || ((value ?? 0) >= target);

      if (hasValue) {
        return WeeklyDayCellData.value(
          _formatCountValue(value),
          isAchieved: achieved,
        );
      }

      if (achieved) {
        return const WeeklyDayCellData.done();
      }

      return const WeeklyDayCellData.empty();
    }

    return isDone
        ? const WeeklyDayCellData.done()
        : const WeeklyDayCellData.empty();
  }

  bool isSkippedFor({
    required String habitId,
    required String dateKey,
  }) {
    final dayData = _dayMap(habitSkips, dateKey);
    return dayData[habitId] == true;
  }

  bool isDoneFor({
    required String habitId,
    required String dateKey,
  }) {
    final dayData = _dayMap(habitCompletions, dateKey);
    final value = dayData[habitId];
    if (value is bool) return value;
    if (value is num) return value > 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  num? countValueFor({
    required String habitId,
    required String dateKey,
  }) {
    final dayData = _dayMap(habitCountValues, dateKey);
    if (!dayData.containsKey(habitId)) return null;
    return WeeklyHabitDataHelper.numValue(dayData[habitId], fallback: 0);
  }

  Map<String, dynamic> _dayMap(Map<String, dynamic> source, String dateKey) {
    final raw = source[dateKey];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  String _formatCountValue(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  }
}
