import '../../../../stores/user_state_store.dart';
import '../../statistics/domain/statistics_models.dart';
import '../../statistics/domain/statistics_range.dart';
import '../domain/count_habit_progress.dart';
import 'count_habit_stats_aggregator.dart';

class CountHabitStatsAdapter {
  const CountHabitStatsAdapter({
    CountHabitStatsAggregator? aggregator,
  }) : _aggregator = aggregator ?? const CountHabitStatsAggregator();

  final CountHabitStatsAggregator _aggregator;

  CountHabitProgressSnapshot buildSnapshot({
    required UserStateStore store,
    required Map<String, dynamic> habit,
    required StatisticsRange range,
  }) {
    final target = _habitTarget(habit);
    final rawValues = _rawValuesByDay(
      store: store,
      habitId: _habitId(habit),
      range: range,
    );

    return _aggregator.aggregate(
      target: target,
      range: range,
      rawValuesByDay: rawValues,
    );
  }

  List<CountHabitProgress> buildSeries({
    required UserStateStore store,
    required Map<String, dynamic> habit,
    required StatisticsRange range,
  }) {
    final target = _habitTarget(habit);
    final rawValues = _rawValuesByDay(
      store: store,
      habitId: _habitId(habit),
      range: range,
    );

    return range.days.map((day) {
      final key = _dateOnly(day);
      final raw = rawValues[key] ?? 0;
      return CountHabitProgress(
        date: key,
        rawValue: raw,
        normalizedProgress: (raw / target).clamp(0.0, 1.0),
        goalCompleted: raw >= target,
      );
    }).toList(growable: false);
  }

  Map<DateTime, int> _rawValuesByDay({
    required UserStateStore store,
    required String habitId,
    required StatisticsRange range,
  }) {
    final root = _history(store);
    final countValues = _readMap(root['habitCountValues']);
    final output = <DateTime, int>{};

    for (final day in range.days) {
      final dayKey = _dateKey(day);
      final dayMap = _readMap(countValues[dayKey]);
      output[_dateOnly(day)] = (dayMap[habitId] as num?)?.toInt() ?? 0;
    }

    return output;
  }

  String _habitId(Map<String, dynamic> habit) {
    return (habit['id'] ?? habit['habitId'] ?? '').toString();
  }

  int _habitTarget(Map<String, dynamic> habit) {
    final value = (habit['target'] as num?)?.toInt() ?? 1;
    return value <= 0 ? 1 : value;
  }

  Map<String, dynamic> _history(UserStateStore store) {
    final root = _readMap(store.state);
    final userState = _readMap(root['userState']);
    return _readMap(userState['history']);
  }

  Map<String, dynamic> _readMap(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
