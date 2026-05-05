import '../../../../stores/user_state_store.dart';
import '../../../../utils/family_theme.dart';
import '../../../habits/application/count_habit_stats_adapter.dart';
import '../../domain/statistics_models.dart';
import '../../domain/statistics_period.dart';
import '../../domain/statistics_range.dart';

class StatisticsDataAdapter {
  const StatisticsDataAdapter({
    CountHabitStatsAdapter? countAdapter,
  }) : _countAdapter = countAdapter ?? const CountHabitStatsAdapter();

  final CountHabitStatsAdapter _countAdapter;

  StatisticsOverviewSummary buildOverview({
    required UserStateStore store,
    required StatisticsPeriod period,
    DateTime? anchor,
  }) {
    final range = StatisticsRange.forPeriod(period, anchor: anchor);
    final habits = _activeHabits(store);
    final summaries = habits
        .map((habit) => _buildHabitSummary(
              store: store,
              habit: habit,
              range: range,
            ))
        .toList(growable: false);

    final totalHabits = summaries.length;
    final totalFamilies = summaries
        .map((item) => item.familyId)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .length;

    final overallConsistencyPct = totalHabits == 0
        ? 0
        : (summaries
                    .map((item) => item.completionPct)
                    .reduce((a, b) => a + b) /
                totalHabits)
            .round();

    final topHabits = [...summaries]
      ..sort((a, b) {
        final byCompletion = b.completionPct.compareTo(a.completionPct);
        if (byCompletion != 0) return byCompletion;
        return b.currentStreak.compareTo(a.currentStreak);
      });

    final familyConsistencyPct = <String, int>{};
    for (final familyId in FamilyTheme.order) {
      final familyItems = summaries.where((item) => item.familyId == familyId);
      if (familyItems.isEmpty) {
        continue;
      }
      final average = familyItems
              .map((item) => item.completionPct)
              .reduce((a, b) => a + b) /
          familyItems.length;
      familyConsistencyPct[familyId] = average.round();
    }

    final bestMomentPercents = _bestMomentPercents(
      store: store,
      range: range,
      habitIds: summaries.map((item) => item.id).toSet(),
    );

    final bestMomentLabel = _bestMomentLabel(bestMomentPercents);

    final monthConsistencyByDay = _monthConsistencyByDay(
      store: store,
      habits: habits,
      month: _dateOnly(anchor ?? DateTime.now()),
    );

    return StatisticsOverviewSummary(
      period: period,
      range: range,
      totalHabits: totalHabits,
      totalFamilies: totalFamilies,
      overallConsistencyPct: overallConsistencyPct,
      topHabits: topHabits.take(3).toList(growable: false),
      familyConsistencyPct: familyConsistencyPct,
      bestMomentPercents: bestMomentPercents,
      bestMomentLabel: bestMomentLabel,
      monthConsistencyByDay: monthConsistencyByDay,
    );
  }

  List<StatisticsHabitSummary> buildHabits({
    required UserStateStore store,
    required StatisticsPeriod period,
    String? query,
    String? familyId,
    DateTime? anchor,
  }) {
    final normalizedQuery = (query ?? '').trim().toLowerCase();
    final normalizedFamily = (familyId ?? '').trim().toLowerCase();
    final range = StatisticsRange.forPeriod(period, anchor: anchor);

    final output = <StatisticsHabitSummary>[];

    for (final habit in _activeHabits(store)) {
      final title = _habitTitle(habit);
      final itemFamily = _habitFamilyId(habit);
      final matchesQuery = normalizedQuery.isEmpty ||
          title.toLowerCase().contains(normalizedQuery);
      final matchesFamily = normalizedFamily.isEmpty ||
          itemFamily.toLowerCase() == normalizedFamily;
      if (!matchesQuery || !matchesFamily) {
        continue;
      }

      output.add(
        _buildHabitSummary(store: store, habit: habit, range: range),
      );
    }

    output.sort((a, b) {
      final byCompletion = b.completionPct.compareTo(a.completionPct);
      if (byCompletion != 0) return byCompletion;
      final byVolume = b.periodVolume.compareTo(a.periodVolume);
      if (byVolume != 0) return byVolume;
      return a.title.compareTo(b.title);
    });

    return output;
  }

  StatisticsHabitDetailSummary? buildHabitDetail({
    required UserStateStore store,
    required String habitId,
    required StatisticsPeriod period,
    DateTime? anchor,
  }) {
    final habits = _activeHabits(store);
    final selected = habits.where((habit) => _habitId(habit) == habitId);
    if (selected.isEmpty) {
      return null;
    }

    final range = StatisticsRange.forPeriod(period, anchor: anchor);
    final habit = selected.first;

    final summary = _buildHabitSummary(
      store: store,
      habit: habit,
      range: range,
    );

    final today = _dateOnly(anchor ?? DateTime.now());
    final thisWeekRange = StatisticsRange.lastDays(7, anchor: today);
    final lastWeekRange = thisWeekRange.previousPeriod;

    final thisWeekDone = _doneDaysInRange(
      store: store,
      habit: habit,
      range: thisWeekRange,
    );
    final lastWeekDone = _doneDaysInRange(
      store: store,
      habit: habit,
      range: lastWeekRange,
    );

    final weeklyDelta = thisWeekDone - lastWeekDone;
    final insight = _buildInsight(summary: summary, weeklyDelta: weeklyDelta);

    return StatisticsHabitDetailSummary(
      period: period,
      range: range,
      habit: summary,
      thisWeekDoneDays: thisWeekDone,
      lastWeekDoneDays: lastWeekDone,
      insight: insight,
    );
  }

  StatisticsHabitSummary _buildHabitSummary({
    required UserStateStore store,
    required Map<String, dynamic> habit,
    required StatisticsRange range,
  }) {
    final habitId = _habitId(habit);
    final type = _habitType(habit);
    final target = _habitTarget(habit);

    var scheduledDays = 0;
    var doneDays = 0;
    var periodVolume = 0;

    final last7Range = StatisticsRange.lastDays(7, anchor: range.end);
    final last7Values = <int>[];

    for (final day in range.days) {
      if (!_isScheduledForDate(habit, day)) {
        continue;
      }

      scheduledDays++;
      final rawValue = _rawValueForDay(
        store: store,
        habitId: habitId,
        day: day,
      );
      final done = _isCompletedForDay(
        store: store,
        habit: habit,
        habitId: habitId,
        day: day,
      );

      if (done) {
        doneDays++;
      }

      if (type == StatisticsHabitType.count) {
        periodVolume += rawValue;
      } else {
        periodVolume += done ? 1 : 0;
      }
    }

    for (final day in last7Range.days) {
      final raw = _rawValueForDay(store: store, habitId: habitId, day: day);
      if (type == StatisticsHabitType.count) {
        last7Values.add(raw);
      } else {
        final done = _isCompletedForDay(
          store: store,
          habit: habit,
          habitId: habitId,
          day: day,
        );
        last7Values.add(done ? 1 : 0);
      }
    }

    final snapshot = store.habitStreakSnapshotForHabitId(habitId);

    CountHabitProgressSnapshot? countProgress;
    if (type == StatisticsHabitType.count) {
      countProgress = _countAdapter.buildSnapshot(
        store: store,
        habit: habit,
        range: range,
      );
    }

    return StatisticsHabitSummary(
      id: habitId,
      title: _habitTitle(habit),
      familyId: _habitFamilyId(habit),
      type: type,
      target: target,
      scheduledDays: scheduledDays,
      doneDays: doneDays,
      currentStreak: snapshot.currentStreak,
      bestStreak: snapshot.bestStreak,
      last7Values: last7Values,
      periodVolume: periodVolume,
      countProgress: countProgress,
    );
  }

  int _doneDaysInRange({
    required UserStateStore store,
    required Map<String, dynamic> habit,
    required StatisticsRange range,
  }) {
    var output = 0;
    final habitId = _habitId(habit);
    for (final day in range.days) {
      if (!_isScheduledForDate(habit, day)) {
        continue;
      }
      if (_isCompletedForDay(
        store: store,
        habit: habit,
        habitId: habitId,
        day: day,
      )) {
        output++;
      }
    }
    return output;
  }

  bool _isCompletedForDay({
    required UserStateStore store,
    required Map<String, dynamic> habit,
    required String habitId,
    required DateTime day,
  }) {
    final type = _habitType(habit);
    final history = _history(store);

    final key = _dateKey(day);
    final completions = _readMap(history['habitCompletions']);
    final dayDone = _readMap(completions[key]);

    if (type == StatisticsHabitType.check) {
      return dayDone[habitId] == true;
    }

    final raw = _rawValueForDay(store: store, habitId: habitId, day: day);
    return raw >= _habitTarget(habit);
  }

  int _rawValueForDay({
    required UserStateStore store,
    required String habitId,
    required DateTime day,
  }) {
    final history = _history(store);
    final countValues = _readMap(history['habitCountValues']);
    final dayMap = _readMap(countValues[_dateKey(day)]);
    return (dayMap[habitId] as num?)?.toInt() ?? 0;
  }

  Map<String, int> _bestMomentPercents({
    required UserStateStore store,
    required StatisticsRange range,
    required Set<String> habitIds,
  }) {
    final history = _history(store);
    final completionTimes = _readMap(history['habitCompletionTimes']);

    var morning = 0;
    var afternoon = 0;
    var evening = 0;
    var night = 0;
    var total = 0;

    for (final day in range.days) {
      final dayMap = _readMap(completionTimes[_dateKey(day)]);
      for (final entry in dayMap.entries) {
        if (!habitIds.contains(entry.key)) {
          continue;
        }

        final value = (entry.value as num?)?.toInt() ?? 0;
        if (value <= 0) {
          continue;
        }

        final dateTime = DateTime.fromMillisecondsSinceEpoch(value);
        final hour = dateTime.hour;
        if (hour >= 6 && hour <= 11) {
          morning++;
        } else if (hour >= 12 && hour <= 17) {
          afternoon++;
        } else if (hour >= 18 && hour <= 23) {
          evening++;
        } else {
          night++;
        }

        total++;
      }
    }

    int pct(int bucket) {
      if (total <= 0) return 0;
      return ((bucket * 100) / total).round();
    }

    return {
      'morning': pct(morning),
      'afternoon': pct(afternoon),
      'evening': pct(evening),
      'night': pct(night),
    };
  }

  String _bestMomentLabel(Map<String, int> percents) {
    final entries = percents.entries.toList(growable: false);
    if (entries.isEmpty) return '';

    final best = entries.reduce((a, b) {
      if (b.value > a.value) return b;
      return a;
    });

    if (best.value <= 0) return '';
    switch (best.key) {
      case 'morning':
        return 'Manana';
      case 'afternoon':
        return 'Tarde';
      case 'evening':
        return 'Noche';
      case 'night':
        return 'Madrugada';
      default:
        return '';
    }
  }

  Map<int, double> _monthConsistencyByDay({
    required UserStateStore store,
    required List<Map<String, dynamic>> habits,
    required DateTime month,
  }) {
    final year = month.year;
    final monthIndex = month.month;
    final daysInMonth = DateTime(year, monthIndex + 1, 0).day;
    final output = <int, double>{};

    for (var dayNumber = 1; dayNumber <= daysInMonth; dayNumber++) {
      final day = DateTime(year, monthIndex, dayNumber);
      var scheduled = 0;
      var done = 0;

      for (final habit in habits) {
        if (!_isScheduledForDate(habit, day)) {
          continue;
        }
        scheduled++;
        if (_isCompletedForDay(
          store: store,
          habit: habit,
          habitId: _habitId(habit),
          day: day,
        )) {
          done++;
        }
      }

      output[dayNumber] = scheduled == 0 ? 0.0 : (done / scheduled);
    }

    return output;
  }

  String _buildInsight({
    required StatisticsHabitSummary summary,
    required int weeklyDelta,
  }) {
    if (summary.type == StatisticsHabitType.count && summary.countProgress != null) {
      final compliance = summary.countProgress!.compliancePct.round();
      if (weeklyDelta > 0) {
        return 'Subiste $weeklyDelta dias frente a la semana pasada y mantienes $compliance% de cumplimiento.';
      }
      if (weeklyDelta < 0) {
        return 'Bajaste ${weeklyDelta.abs()} dias frente a la semana pasada. Prioriza bloques cortos para recuperar ritmo.';
      }
      return 'Semana estable: $compliance% de cumplimiento medio en este habito count.';
    }

    if (weeklyDelta > 0) {
      return 'Vas en subida: +$weeklyDelta dias completados frente a la semana anterior.';
    }
    if (weeklyDelta < 0) {
      return 'Hay una caida de ${weeklyDelta.abs()} dias. Un ajuste pequeno puede devolver la racha.';
    }
    return 'Ritmo estable respecto a la semana pasada. Buena base para construir consistencia.';
  }

  List<Map<String, dynamic>> _activeHabits(UserStateStore store) {
    return store.activeHabits
        .map((habit) => Map<String, dynamic>.from(habit))
        .toList(growable: false);
  }

  String _habitId(Map<String, dynamic> habit) {
    return (habit['id'] ?? habit['habitId'] ?? '').toString();
  }

  String _habitTitle(Map<String, dynamic> habit) {
    final value = habit['title'] ?? habit['name'] ?? habit['habitName'] ?? '';
    final title = value.toString().trim();
    if (title.isEmpty) {
      return 'Habito sin titulo';
    }
    return title;
  }

  String _habitFamilyId(Map<String, dynamic> habit) {
    final family = (habit['familyId'] ?? FamilyTheme.fallbackId).toString();
    return family.trim().isEmpty ? FamilyTheme.fallbackId : family.trim();
  }

  int _habitTarget(Map<String, dynamic> habit) {
    final target = (habit['target'] as num?)?.toInt() ?? 1;
    return target <= 0 ? 1 : target;
  }

  StatisticsHabitType _habitType(Map<String, dynamic> habit) {
    final raw = (habit['type'] ?? 'check').toString().toLowerCase();
    return raw == 'count' ? StatisticsHabitType.count : StatisticsHabitType.check;
  }

  bool _isScheduledForDate(Map<String, dynamic> habit, DateTime date) {
    final schedule = _readMap(habit['schedule']);
    final type = (schedule['type'] ?? 'daily').toString();

    if (type == 'daily') {
      return true;
    }

    if (type == 'once') {
      return (schedule['date'] ?? '').toString() == _dateKey(date);
    }

    if (type == 'weekly') {
      final weekdaysRaw = schedule['weekdays'];
      if (weekdaysRaw is List) {
        final weekdays = weekdaysRaw
            .map((item) => (item as num?)?.toInt())
            .whereType<int>()
            .toSet();
        if (weekdays.isEmpty) {
          return true;
        }
        return weekdays.contains(date.weekday);
      }
      return true;
    }

    return true;
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
