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
        .map(
          (habit) => _buildHabitSummary(
            store: store,
            habit: habit,
            range: range,
          ),
        )
        .toList(growable: false);

    final totalHabits = summaries.length;

    final completedActivityDays = <String>{};
    final familiesMap = <String, _FamilyAccumulator>{};
    var completedHabits = 0;
    var habitsWithProgress = 0;
    var scheduledDays = 0;
    var completedDays = 0;
    var countGoalCompletedDays = 0;
    var countPartialProgressDays = 0;

    for (final habit in habits) {
      final habitId = _habitId(habit);
      final habitFamilyId = _habitFamilyId(habit);
      final habitType = _habitType(habit);
      final habitTarget = _habitTarget(habit);
      final familyAccumulator = familiesMap.putIfAbsent(
        habitFamilyId,
        () => _FamilyAccumulator(familyId: habitFamilyId),
      )..totalHabits += 1;

      var habitCompletedInRange = false;
      var habitHasProgress = false;

      for (final day in range.days) {
        if (!_isScheduledForDate(habit, day)) {
          continue;
        }

        scheduledDays += 1;
        familyAccumulator.scheduledDays += 1;

        final raw = _rawValueForDay(
          store: store,
          habitId: habitId,
          day: day,
        );
        final completed = _isCompletedForDay(
          store: store,
          habit: habit,
          habitId: habitId,
          day: day,
        );

        if (completed) {
          completedDays += 1;
          familyAccumulator.completedDays += 1;
          habitCompletedInRange = true;
          if (habitType == StatisticsHabitType.count) {
            countGoalCompletedDays += 1;
          }
        }

        if (habitType == StatisticsHabitType.check) {
          if (completed) {
            habitHasProgress = true;
            completedActivityDays.add(_dateKey(day));
          }
          continue;
        }

        if (raw > 0) {
          habitHasProgress = true;
          completedActivityDays.add(_dateKey(day));
        }
        if (raw > 0 && raw < habitTarget) {
          countPartialProgressDays += 1;
        }
      }

      if (habitCompletedInRange) {
        completedHabits += 1;
        familyAccumulator.completedHabits += 1;
      }
      if (habitHasProgress) {
        habitsWithProgress += 1;
        familyAccumulator.habitsWithProgress += 1;
      }
    }

    final overallConsistencyPct =
        scheduledDays == 0 ? 0 : ((completedDays / scheduledDays) * 100).round();

    final topHabits = [...summaries]
      ..sort((a, b) {
        final byDoneDays = b.doneDays.compareTo(a.doneDays);
        if (byDoneDays != 0) return byDoneDays;
        final byCompletion = b.completionPct.compareTo(a.completionPct);
        if (byCompletion != 0) return byCompletion;
        final byVolume = b.periodVolume.compareTo(a.periodVolume);
        if (byVolume != 0) return byVolume;
        return b.currentStreak.compareTo(a.currentStreak);
      });

    final families = [
      for (final familyId in FamilyTheme.order)
        if (familiesMap.containsKey(familyId)) familiesMap[familyId]!,
      for (final entry in familiesMap.entries)
        if (!FamilyTheme.order.contains(entry.key)) entry.value,
    ].map((item) => item.toSummary()).toList(growable: false);

    final bestMoment = _bestMomentPercents(
      store: store,
      range: range,
      habitIds: summaries.map((item) => item.id).toSet(),
    );

    final monthConsistencyByDay = _monthConsistencyByDay(
      store: store,
      habits: habits,
      month: _dateOnly(anchor ?? DateTime.now()),
    );

    final totalFamilies = families.length;

    return StatisticsOverviewSummary(
      period: period,
      range: range,
      totalHabits: totalHabits,
      totalFamilies: totalFamilies,
      completedHabits: completedHabits,
      habitsWithProgress: habitsWithProgress,
      scheduledDays: scheduledDays,
      completedDays: completedDays,
      daysWithActivity: completedActivityDays.length,
      countGoalCompletedDays: countGoalCompletedDays,
      countPartialProgressDays: countPartialProgressDays,
      overallConsistencyPct: overallConsistencyPct,
      topHabits: topHabits.take(3).toList(growable: false),
      families: families,
      bestMomentPercents: bestMoment.percents,
      bestMomentKey: bestMoment.bestKey,
      hasBestMomentData: bestMoment.hasData,
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
    return buildHabitList(
      store: store,
      period: period,
      query: query,
      familyId: familyId,
      anchor: anchor,
    ).map((item) => item.summary).toList(growable: false);
  }

  List<StatisticsHabitListItem> buildHabitList({
    required UserStateStore store,
    required StatisticsPeriod period,
    String? query,
    String? familyId,
    StatisticsHabitListTypeFilter typeFilter = StatisticsHabitListTypeFilter.all,
    DateTime? anchor,
  }) {
    final normalizedQuery = (query ?? '').trim().toLowerCase();
    final normalizedFamily = (familyId ?? '').trim().toLowerCase();
    final range = StatisticsRange.forPeriod(period, anchor: anchor);

    final output = <StatisticsHabitListItem>[];

    for (final habit in _activeHabits(store)) {
      final title = _habitTitle(habit);
      final itemFamily = _habitFamilyId(habit);
      final itemType = _habitType(habit);
      final matchesQuery = normalizedQuery.isEmpty ||
          title.toLowerCase().contains(normalizedQuery);
      final matchesFamily = normalizedFamily.isEmpty ||
          itemFamily.toLowerCase() == normalizedFamily;
      final matchesType = _matchesTypeFilter(itemType, typeFilter);
      if (!matchesQuery || !matchesFamily || !matchesType) {
        continue;
      }

      final summary = _buildHabitSummary(
        store: store,
        habit: habit,
        range: range,
      );
      final progress01 = summary.type == StatisticsHabitType.count &&
              summary.countProgress != null
          ? (summary.countProgress!.compliancePct / 100).clamp(0.0, 1.0)
          : (summary.completionPct / 100).clamp(0.0, 1.0);
      output.add(StatisticsHabitListItem(summary: summary, progress01: progress01));
    }

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
    final dailyValues = _dailyValuesInRange(
      store: store,
      habit: habit,
      range: range,
    );
    final daysWithActivity = _activityDaysInRange(
      store: store,
      habit: habit,
      range: range,
    );
    final bestMoment = _bestMomentPercents(
      store: store,
      range: range,
      habitIds: {summary.id},
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
      scheduledDays: summary.scheduledDays,
      completedDays: summary.doneDays,
      daysWithActivity: daysWithActivity,
      dailyValues: dailyValues,
      thisWeekDoneDays: thisWeekDone,
      lastWeekDoneDays: lastWeekDone,
      bestMomentPercents: bestMoment.percents,
      bestMomentKey: bestMoment.bestKey,
      hasBestMomentData: bestMoment.hasData,
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

  int _activityDaysInRange({
    required UserStateStore store,
    required Map<String, dynamic> habit,
    required StatisticsRange range,
  }) {
    final type = _habitType(habit);
    final habitId = _habitId(habit);
    var output = 0;

    for (final day in range.days) {
      if (!_isScheduledForDate(habit, day)) {
        continue;
      }

      if (type == StatisticsHabitType.check) {
        if (_isCompletedForDay(
          store: store,
          habit: habit,
          habitId: habitId,
          day: day,
        )) {
          output++;
        }
        continue;
      }

      final raw = _rawValueForDay(
        store: store,
        habitId: habitId,
        day: day,
      );
      if (raw > 0) {
        output++;
      }
    }

    return output;
  }

  List<int> _dailyValuesInRange({
    required UserStateStore store,
    required Map<String, dynamic> habit,
    required StatisticsRange range,
  }) {
    final type = _habitType(habit);
    final habitId = _habitId(habit);
    final output = <int>[];

    for (final day in range.days) {
      final isScheduled = _isScheduledForDate(habit, day);
      if (type == StatisticsHabitType.check) {
        final completed = isScheduled &&
            _isCompletedForDay(
              store: store,
              habit: habit,
              habitId: habitId,
              day: day,
            );
        output.add(completed ? 1 : 0);
        continue;
      }

      if (!isScheduled) {
        output.add(0);
        continue;
      }

      output.add(
        _rawValueForDay(
          store: store,
          habitId: habitId,
          day: day,
        ),
      );
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

  _BestMomentAggregate _bestMomentPercents({
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

    final percents = {
      'morning': pct(morning),
      'afternoon': pct(afternoon),
      'evening': pct(evening),
      'night': pct(night),
    };

    String? bestKey;
    var bestValue = 0;
    for (final entry in percents.entries) {
      if (entry.value > bestValue) {
        bestValue = entry.value;
        bestKey = entry.key;
      }
    }

    return _BestMomentAggregate(
      percents: percents,
      bestKey: bestValue > 0 ? bestKey : null,
      hasData: total > 0,
    );
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

  bool _matchesTypeFilter(
    StatisticsHabitType type,
    StatisticsHabitListTypeFilter filter,
  ) {
    switch (filter) {
      case StatisticsHabitListTypeFilter.all:
        return true;
      case StatisticsHabitListTypeFilter.check:
        return type == StatisticsHabitType.check;
      case StatisticsHabitListTypeFilter.count:
        return type == StatisticsHabitType.count;
    }
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

class _BestMomentAggregate {
  const _BestMomentAggregate({
    required this.percents,
    required this.bestKey,
    required this.hasData,
  });

  final Map<String, int> percents;
  final String? bestKey;
  final bool hasData;
}

class _FamilyAccumulator {
  _FamilyAccumulator({required this.familyId});

  final String familyId;
  int totalHabits = 0;
  int completedHabits = 0;
  int habitsWithProgress = 0;
  int scheduledDays = 0;
  int completedDays = 0;

  StatisticsOverviewFamilySummary toSummary() {
    return StatisticsOverviewFamilySummary(
      familyId: familyId,
      totalHabits: totalHabits,
      completedHabits: completedHabits,
      habitsWithProgress: habitsWithProgress,
      scheduledDays: scheduledDays,
      completedDays: completedDays,
    );
  }
}
