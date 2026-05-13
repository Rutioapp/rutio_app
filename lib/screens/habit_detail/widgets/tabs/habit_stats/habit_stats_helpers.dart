import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../stores/user_state_store.dart';
import 'habit_stats_models.dart';

HabitStatsData buildHabitStatsData({
  required BuildContext context,
  required dynamic habit,
  required HabitStatsPeriod period,
  required Color familyColor,
  required DateTime today,
}) {
  final l10n = context.l10n;
  final habitMap = habitToMap(habit);
  final habitId = habitIdOf(habitMap);
  final title = habitTitleOf(habitMap, fallback: l10n.habitStatsHabitFallbackTitle);
  final familyId = habitFamilyIdOf(habitMap);
  final familyName = l10n.familyName(familyId);
  final isCountHabit = isCountHabitOf(habitMap);

  final completionByDay = extractCheckCountsByDayWithStoreFallback(
    context: context,
    habit: habitMap,
    habitId: habitId,
    today: today,
  );
  final countValuesByDay = extractCountValuesByDayWithStoreFallback(
    context: context,
    habit: habitMap,
    habitId: habitId,
    today: today,
  );
  final skipByDay = extractSkipsByDayWithStoreFallback(
    context: context,
    habit: habitMap,
    habitId: habitId,
    today: today,
  );

  final progressByDay = <DateTime, double>{};
  if (isCountHabit) {
    for (final entry in countValuesByDay.entries) {
      progressByDay[entry.key] = entry.value;
    }
  } else {
    for (final entry in completionByDay.entries) {
      progressByDay[entry.key] = entry.value.toDouble();
    }
  }

  final countTarget = countTargetOf(habitMap);
  final countUnit = countUnitOf(habitMap, l10n);

  final last7Days = List<DateTime>.generate(
    7,
    (index) => today.subtract(Duration(days: 6 - index)),
    growable: false,
  );

  final last7Values = last7Days
      .map((day) => (progressByDay[dateOnly(day)] ?? 0).toDouble())
      .toList(growable: false);

  final last7DoneStates =
      last7Values.map((value) => value > 0).toList(growable: false);
  final last7SkippedStates = last7Days
      .map((day) => skipByDay[dateOnly(day)] ?? false)
      .toList(growable: false);

  final days = periodDays(period);
  final periodRange = List<DateTime>.generate(
    days,
    (index) => today.subtract(Duration(days: days - 1 - index)),
    growable: false,
  );

  final doneInPeriod = periodRange
      .where((day) => (progressByDay[dateOnly(day)] ?? 0) > 0)
      .length;

  final consistencyPct = periodRange.isEmpty
      ? 0
      : ((doneInPeriod / periodRange.length) * 100).round().clamp(0, 100);

  final currentStreak = currentStreakOf(progressByDay, today);
  final bestStreak = bestStreakOf(progressByDay);

  final totalDone = isCountHabit
      ? progressByDay.values.fold<double>(0, (sum, value) => sum + value)
      : progressByDay.values.where((value) => value > 0).length.toDouble();

  final prev7Days = List<DateTime>.generate(
    7,
    (index) => today.subtract(Duration(days: 13 - index)),
    growable: false,
  );

  final doneThisWeek = last7Values.where((value) => value > 0).length;
  final donePrevWeek = prev7Days
      .map((day) => (progressByDay[dateOnly(day)] ?? 0) > 0)
      .where((isDone) => isDone)
      .length;

  final volumeThisWeek = last7Values.fold<double>(0, (sum, value) => sum + value);
  final volumePrevWeek = prev7Days
      .map((day) => (progressByDay[dateOnly(day)] ?? 0).toDouble())
      .fold<double>(0, (sum, value) => sum + value);

  final deltaPctForCheck =
      percentDelta(doneThisWeek.toDouble(), donePrevWeek.toDouble());
  final deltaPctForCount = percentDelta(volumeThisWeek, volumePrevWeek);

  final weeklyGoal = checkWeeklyGoalOf(habitMap);
  final bestMoment = bestMomentLabel(context, habitId, periodRange);

  final countCompletionPct =
      isCountHabit ? countCompletionPctOf(last7Values, countTarget) : 0;

  final bestCountDay = bestCountDayOf(last7Days, last7Values);

  final metricCards = isCountHabit
      ? countMetricCards(
          l10n: l10n,
          target: countTarget,
          unit: countUnit,
          volume7: volumeThisWeek,
          dailyAvg7: volumeThisWeek / 7,
          completionPct: countCompletionPct,
          familyColor: familyColor,
        )
      : checkMetricCards(
          l10n: l10n,
          weeklyGoal: weeklyGoal,
          completedWeek: doneThisWeek,
          consistencyPct: consistencyPct,
          bestMoment: bestMoment,
          familyColor: familyColor,
        );

  final familyAndGoalLabel =
      '$familyName · ${goalLabelOf(habitMap, l10n, countTarget, countUnit)}';

  final comparisonTitle = isCountHabit
      ? (l10n.localeName.toLowerCase().startsWith('es') ? 'Mejor día' : 'Best day')
      : l10n.habitStatsWeeklyComparisonTitle;
  final comparisonMain = isCountHabit
      ? bestCountDay.main
      : '${deltaPctForCheck > 0 ? '+' : ''}$deltaPctForCheck%';
  final comparisonSubtitle = isCountHabit
      ? (l10n.localeName.toLowerCase().startsWith('es')
          ? 'Últimos 7 días'
          : 'Last 7 days')
      : l10n.habitStatsWeeklyComparisonSubtitle;

  final comparisonTrendText = isCountHabit
      ? '${deltaPctForCount > 0 ? '+' : ''}$deltaPctForCount%'
      : l10n.habitStatsTabWeeklyDelta(doneThisWeek - donePrevWeek);

  final comparisonTrendPositive =
      isCountHabit ? deltaPctForCount >= 0 : (doneThisWeek - donePrevWeek) >= 0;

  final insightText = insightTextFor(
    l10n: l10n,
    isCountHabit: isCountHabit,
    currentStreak: currentStreak,
    consistencyPct: consistencyPct,
    countCompletionPct: countCompletionPct,
    bestMoment: bestMoment,
  );

  return HabitStatsData(
    title: title,
    familyAndGoalLabel: familyAndGoalLabel,
    isCountHabit: isCountHabit,
    countTarget: countTarget,
    countUnit: countUnit,
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    totalDone: totalDone,
    last7Days: last7Days,
    last7Values: last7Values,
    last7DoneStates: last7DoneStates,
    last7SkippedStates: last7SkippedStates,
    metricCards: metricCards,
    comparisonTitle: comparisonTitle,
    comparisonMain: comparisonMain,
    comparisonSubtitle: comparisonSubtitle,
    comparisonTrendText: comparisonTrendText,
    comparisonTrendPositive: comparisonTrendPositive,
    insightText: insightText,
  );
}

List<HabitStatsMetricCardData> checkMetricCards({
  required dynamic l10n,
  required int weeklyGoal,
  required int completedWeek,
  required int consistencyPct,
  required String bestMoment,
  required Color familyColor,
}) {
  final isEs = l10n.localeName.toLowerCase().startsWith('es');
  return [
    HabitStatsMetricCardData(
      title: isEs ? 'Objetivo' : 'Goal',
      value: '$weeklyGoal ${isEs ? 'días' : 'days'}',
      subtitle: isEs ? 'Por semana' : 'Per week',
      icon: Icons.gps_fixed_rounded,
      iconColor: const Color(0xFF5A351C),
      badgeColor: const Color(0xFFF4EEE5),
    ),
    HabitStatsMetricCardData(
      title: isEs ? 'Completados' : 'Completed',
      value: '$completedWeek/7',
      subtitle: isEs ? 'Esta semana' : 'This week',
      icon: Icons.check_circle_outline_rounded,
      iconColor: const Color(0xFF5A351C),
      badgeColor: const Color(0xFFF4EEE5),
    ),
    HabitStatsMetricCardData(
      title: isEs ? 'Consistencia' : 'Consistency',
      value: '$consistencyPct%',
      subtitle: isEs ? 'Cumplimiento' : 'Completion',
      icon: Icons.show_chart_rounded,
      iconColor: familyColor.withValues(alpha: 0.90),
      badgeColor: const Color(0xFFF1F6EF),
    ),
    HabitStatsMetricCardData(
      title: isEs ? 'Mejor momento' : 'Best moment',
      value: bestMoment,
      subtitle: isEs ? 'Hora más frecuente' : 'Most frequent hour',
      icon: Icons.wb_sunny_outlined,
      iconColor: const Color(0xFFCF8D1D),
      badgeColor: const Color(0xFFFFF6E8),
    ),
  ];
}

List<HabitStatsMetricCardData> countMetricCards({
  required dynamic l10n,
  required double target,
  required String unit,
  required double volume7,
  required double dailyAvg7,
  required int completionPct,
  required Color familyColor,
}) {
  final isEs = l10n.localeName.toLowerCase().startsWith('es');
  return [
    HabitStatsMetricCardData(
      title: isEs ? 'Objetivo' : 'Goal',
      value: '${formatValue(target, keepOneDecimal: true)} $unit',
      subtitle: isEs ? 'Por día' : 'Per day',
      icon: Icons.gps_fixed_rounded,
      iconColor: const Color(0xFF5A351C),
      badgeColor: const Color(0xFFF4EEE5),
    ),
    HabitStatsMetricCardData(
      title: isEs ? 'Volumen' : 'Volume',
      value: '${formatValue(volume7, keepOneDecimal: true)} $unit',
      subtitle: isEs ? 'Esta semana' : 'This week',
      icon: Icons.water_drop_outlined,
      iconColor: const Color(0xFF5A351C),
      badgeColor: const Color(0xFFF4EEE5),
    ),
    HabitStatsMetricCardData(
      title: isEs ? 'Media diaria' : 'Daily average',
      value: '${formatValue(dailyAvg7, keepOneDecimal: true)} $unit',
      subtitle: isEs ? 'Promedio' : 'Average',
      icon: Icons.multiline_chart_rounded,
      iconColor: const Color(0xFF5A351C),
      badgeColor: const Color(0xFFF4EEE5),
    ),
    HabitStatsMetricCardData(
      title: isEs ? 'Cumplimiento' : 'Completion',
      value: '$completionPct%',
      subtitle: isEs ? 'Del objetivo' : 'Of target',
      icon: Icons.percent_rounded,
      iconColor: familyColor.withValues(alpha: 0.90),
      badgeColor: const Color(0xFFF1F6EF),
    ),
  ];
}

String insightTextFor({
  required dynamic l10n,
  required bool isCountHabit,
  required int currentStreak,
  required int consistencyPct,
  required int countCompletionPct,
  required String bestMoment,
}) {
  final isEs = l10n.localeName.toLowerCase().startsWith('es');

  if (isCountHabit) {
    if (countCompletionPct >= 90) {
      return isEs
          ? 'Tu ritmo se mantiene muy cerca del objetivo.'
          : 'Your rhythm is staying very close to the target.';
    }
    if (countCompletionPct >= 70) {
      return isEs
          ? 'Vas bien. Un pequeño ajuste te pondrá en rango óptimo.'
          : 'You are doing well. A small push gets you to target range.';
    }
    return isEs
        ? 'Aumentar un poco los días bajos elevará tu promedio semanal.'
        : 'Lifting the lower days will raise your weekly average.';
  }

  if (currentStreak >= 7) {
    return isEs
        ? 'Vas construyendo una rutina estable.'
        : 'You are building a stable routine.';
  }
  if (bestMoment.trim().isNotEmpty) {
    return isEs
        ? 'Tu mejor momento es $bestMoment. Repetir esa ventana ayuda a consolidar.'
        : 'Your best moment is $bestMoment. Repeating that window helps build consistency.';
  }
  if (consistencyPct >= 70) {
    return isEs
        ? 'Mantienes un ritmo sólido esta semana.'
        : 'You are keeping a solid pace this week.';
  }
  return isEs
      ? 'Pequeños pasos diarios te acercan a una racha más fuerte.'
      : 'Small daily steps move you toward a stronger streak.';
}

int periodDays(HabitStatsPeriod period) {
  switch (period) {
    case HabitStatsPeriod.week:
      return 7;
    case HabitStatsPeriod.month:
      return 30;
    case HabitStatsPeriod.year:
      return 365;
  }
}

String goalLabelOf(
  Map<String, dynamic> habit,
  dynamic l10n,
  double countTarget,
  String countUnit,
) {
  final isEs = l10n.localeName.toLowerCase().startsWith('es');
  if (isCountHabitOf(habit)) {
    return '${isEs ? 'Objetivo' : 'Goal'}: ${formatValue(countTarget, keepOneDecimal: true)} $countUnit ${isEs ? 'al día' : 'per day'}';
  }

  final schedule = toMap(habit['schedule']);
  final scheduleType = (schedule['type'] ?? '').toString().trim().toLowerCase();
  if (scheduleType == 'timesperweek') {
    final timesPerWeek = safeInt(
      schedule['timesPerWeek'] ??
          schedule['timesPerWeekTarget'] ??
          schedule['times'] ??
          habit['timesPerWeekTarget'] ??
          habit['goal'],
      fallback: 1,
    ).clamp(1, 14);
    return '${isEs ? 'Objetivo' : 'Goal'}: $timesPerWeek ${isEs ? 'veces por semana' : 'times per week'}';
  }

  return isEs ? 'Objetivo: 1 vez al día' : 'Goal: once per day';
}

int checkWeeklyGoalOf(Map<String, dynamic> habit) {
  final schedule = toMap(habit['schedule']);
  final scheduleType = (schedule['type'] ?? '').toString().trim().toLowerCase();
  if (scheduleType == 'timesperweek') {
    return safeInt(
      schedule['timesPerWeek'] ??
          schedule['timesPerWeekTarget'] ??
          schedule['times'] ??
          habit['timesPerWeekTarget'] ??
          habit['goal'],
      fallback: 7,
    ).clamp(1, 14);
  }
  return 7;
}

int countCompletionPctOf(List<double> values, double target) {
  if (target <= 0) return 0;
  if (values.isEmpty) return 0;
  var ratioSum = 0.0;
  for (final value in values) {
    ratioSum += (value / target).clamp(0.0, 1.0);
  }
  return ((ratioSum / values.length) * 100).round().clamp(0, 100);
}

HabitStatsBestCountDay bestCountDayOf(List<DateTime> days, List<double> values) {
  if (days.isEmpty || values.isEmpty) {
    return const HabitStatsBestCountDay(main: '-');
  }

  var bestIndex = 0;
  var bestValue = values.first;
  for (var i = 1; i < values.length; i++) {
    if (values[i] > bestValue) {
      bestValue = values[i];
      bestIndex = i;
    }
  }

  return HabitStatsBestCountDay(
    main:
        '${dowShortLabel(days[bestIndex])} · ${formatValue(bestValue, keepOneDecimal: true)}',
  );
}

int percentDelta(double current, double previous) {
  if (previous <= 0) {
    if (current <= 0) return 0;
    return 100;
  }
  return (((current - previous) / previous) * 100).round();
}

String bestMomentLabel(
    BuildContext context, String habitId, List<DateTime> range) {
  final l10n = context.l10n;
  if (habitId.isEmpty) return '-';

  Map<String, dynamic> root;
  try {
    root = toMap(context.read<UserStateStore>().state);
  } catch (_) {
    root = <String, dynamic>{};
  }

  final userState = toMap(root['userState']);
  final history = toMap(userState['history']);
  final timesRoot = toMap(history['habitCompletionTimes']);

  final buckets = <String, int>{
    'morning': 0,
    'afternoon': 0,
    'evening': 0,
    'night': 0,
  };

  for (final day in range) {
    final dayKey = dateKey(day);
    final dayMap = toMap(timesRoot[dayKey]);
    final epochMs = safeInt(dayMap[habitId], fallback: 0);
    if (epochMs <= 0) continue;

    final hour = DateTime.fromMillisecondsSinceEpoch(epochMs).toLocal().hour;
    if (hour >= 6 && hour <= 11) {
      buckets['morning'] = (buckets['morning'] ?? 0) + 1;
    } else if (hour >= 12 && hour <= 17) {
      buckets['afternoon'] = (buckets['afternoon'] ?? 0) + 1;
    } else if (hour >= 18 && hour <= 23) {
      buckets['evening'] = (buckets['evening'] ?? 0) + 1;
    } else {
      buckets['night'] = (buckets['night'] ?? 0) + 1;
    }
  }

  final best = buckets.entries.reduce((a, b) => b.value > a.value ? b : a);
  if (best.value <= 0) return '-';

  switch (best.key) {
    case 'morning':
      return l10n.habitStatsTimeSlotMorning;
    case 'afternoon':
      return l10n.habitStatsTimeSlotAfternoon;
    case 'evening':
      return l10n.habitStatsTimeSlotEvening;
    case 'night':
      return l10n.habitStatsTimeSlotNight;
    default:
      return '-';
  }
}

Map<DateTime, int> extractCheckCountsByDayWithStoreFallback({
  required BuildContext context,
  required Map<String, dynamic> habit,
  required String habitId,
  required DateTime today,
}) {
  final out = <DateTime, int>{};

  final fromHabit = extractCountsByDay(habit);
  for (final entry in fromHabit.entries) {
    out[entry.key] = entry.value;
  }

  if (habitId.isEmpty) return out;

  try {
    final root = toMap(context.read<UserStateStore>().state);
    final userState = toMap(root['userState']);
    final history = toMap(userState['history']);
    final completionsRoot = toMap(history['habitCompletions']);

    for (final entry in completionsRoot.entries) {
      final day = tryParseDate(entry.key);
      if (day == null) continue;

      final dayMap = toMap(entry.value);
      final done = isDone(dayMap[habitId]);
      out[dateOnly(day)] = done ? 1 : (out[dateOnly(day)] ?? 0);
    }

    final activeViewDateKey = (userState['meta'] is Map)
        ? (toMap(userState['meta'])['activeViewDateKey'] ?? '').toString()
        : '';
    final todayKey = dateKey(today);
    if (activeViewDateKey == todayKey) {
      if (isDone(habit['doneToday']) && !isDone(habit['skippedToday'])) {
        out[dateOnly(today)] = 1;
      } else if (isDone(habit['skippedToday'])) {
        out[dateOnly(today)] = 0;
      }
    }
  } catch (_) {}

  return out;
}

Map<DateTime, double> extractCountValuesByDayWithStoreFallback({
  required BuildContext context,
  required Map<String, dynamic> habit,
  required String habitId,
  required DateTime today,
}) {
  final out = <DateTime, double>{};

  if (habitId.isEmpty) return out;

  try {
    final root = toMap(context.read<UserStateStore>().state);
    final userState = toMap(root['userState']);
    final history = toMap(userState['history']);
    final countValuesRoot = toMap(history['habitCountValues']);

    for (final entry in countValuesRoot.entries) {
      final day = tryParseDate(entry.key);
      if (day == null) continue;

      final dayMap = toMap(entry.value);
      out[dateOnly(day)] = safeNum(dayMap[habitId], fallback: 0);
    }

    final activeViewDateKey = (userState['meta'] is Map)
        ? (toMap(userState['meta'])['activeViewDateKey'] ?? '').toString()
        : '';

    final todayKey = dateKey(today);
    if (activeViewDateKey == todayKey) {
      if (isDone(habit['skippedToday'])) {
        out[dateOnly(today)] = 0;
      } else {
        final current = safeNum(
          habit['progress'] ?? habit['current'] ?? habit['value'],
          fallback: out[dateOnly(today)] ?? 0,
        );
        out[dateOnly(today)] = current;
      }
    }
  } catch (_) {}

  return out;
}

Map<DateTime, bool> extractSkipsByDayWithStoreFallback({
  required BuildContext context,
  required Map<String, dynamic> habit,
  required String habitId,
  required DateTime today,
}) {
  final out = <DateTime, bool>{};
  if (habitId.isEmpty) return out;

  try {
    final root = toMap(context.read<UserStateStore>().state);
    final userState = toMap(root['userState']);
    final history = toMap(userState['history']);
    final skipsRoot = toMap(history['habitSkips']);

    for (final entry in skipsRoot.entries) {
      final day = tryParseDate(entry.key);
      if (day == null) continue;

      final dayMap = toMap(entry.value);
      out[dateOnly(day)] = isDone(dayMap[habitId]);
    }

    final activeViewDateKey = (userState['meta'] is Map)
        ? (toMap(userState['meta'])['activeViewDateKey'] ?? '').toString()
        : '';

    final todayKey = dateKey(today);
    if (activeViewDateKey == todayKey && isDone(habit['skippedToday'])) {
      out[dateOnly(today)] = true;
    }
  } catch (_) {}

  return out;
}

int currentStreakOf(Map<DateTime, double> valuesByDay, DateTime today) {
  var streak = 0;
  var day = dateOnly(today);
  while ((valuesByDay[day] ?? 0) > 0) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

int bestStreakOf(Map<DateTime, double> valuesByDay) {
  final doneDays = valuesByDay.entries
      .where((entry) => entry.value > 0)
      .map((entry) => dateOnly(entry.key))
      .toList()
    ..sort();

  var best = 0;
  var current = 0;
  DateTime? prev;

  for (final day in doneDays) {
    if (prev == null) {
      current = 1;
    } else {
      final diff = day.difference(prev).inDays;
      current = diff == 1 ? current + 1 : 1;
    }

    if (current > best) best = current;
    prev = day;
  }

  return best;
}

Map<String, dynamic> habitToMap(dynamic habit) {
  if (habit is Map<String, dynamic>) return habit;
  if (habit is Map) return habit.cast<String, dynamic>();

  try {
    final dynamic dyn = habit;
    final json = dyn.toJson?.call();
    if (json is Map) {
      return json.cast<String, dynamic>();
    }
  } catch (_) {}

  return <String, dynamic>{};
}

String habitIdOf(Map<String, dynamic> habit) {
  final raw = habit['id'] ?? habit['habitId'] ?? habit['uuid'] ?? habit['key'];
  return raw?.toString().trim() ?? '';
}

String habitTitleOf(Map<String, dynamic> habit, {required String fallback}) {
  final raw =
      habit['title'] ?? habit['name'] ?? habit['habitTitle'] ?? habit['label'];
  final text = raw?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String habitFamilyIdOf(Map<String, dynamic> habit) {
  final raw = (habit['familyId'] ?? '').toString().trim().toLowerCase();
  return raw.isEmpty ? 'mind' : raw;
}

bool isCountHabitOf(Map<String, dynamic> habit) {
  final type = (habit['type'] ?? habit['habitType'] ?? habit['trackingType'] ?? '')
      .toString()
      .trim()
      .toLowerCase();
  return type == 'count' || type == 'counter' || type == 'numeric';
}

double countTargetOf(Map<String, dynamic> habit) {
  final raw = safeNum(habit['target'] ?? habit['goal'] ?? habit['times'], fallback: 1);
  if (raw <= 0) return 1;
  return raw;
}

String countUnitOf(Map<String, dynamic> habit, dynamic l10n) {
  final raw = (habit['unit'] ?? habit['unitLabel'] ?? habit['units'] ?? '')
      .toString()
      .trim();
  if (raw.isEmpty) return l10n.unitTimesShort;
  return l10n.habitUnitLabel(raw);
}

String formatValue(num value, {bool keepOneDecimal = false}) {
  if (!value.isFinite) return '0';
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.0001) {
    if (keepOneDecimal) return rounded.toStringAsFixed(1);
    return rounded.toInt().toString();
  }
  final fixed = value.toStringAsFixed(1);
  if (keepOneDecimal) return fixed;
  return fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

Map<DateTime, int> extractCountsByDay(dynamic habit) {
  final out = <DateTime, int>{};

  void addDate(DateTime day, [int inc = 1]) {
    final key = dateOnly(day);
    out[key] = (out[key] ?? 0) + inc;
  }

  final candidates = <dynamic>[];

  if (habit is Map) {
    const keys = [
      'history',
      'log',
      'doneDates',
      'completedDates',
      'completionDates',
      'checkins',
      'checkIns',
      'completions',
      'records',
      'calendar',
    ];
    for (final key in keys) {
      final value = habit[key];
      if (value != null) candidates.add(value);
    }
  }

  for (final candidate in candidates) {
    consumeAnyHistoryValue(candidate, addDate);
  }

  final lastDone = tryParseDate(
    (habit is Map) ? (habit['lastDoneAt'] ?? habit['lastCompletedAt']) : null,
  );
  if (lastDone != null) addDate(lastDone);

  return out;
}

void consumeAnyHistoryValue(
  dynamic value,
  void Function(DateTime day, [int inc]) addDate,
) {
  if (value == null) return;

  if (value is List) {
    for (final entry in value) {
      if (entry is DateTime) {
        addDate(entry);
      } else if (entry is String || entry is int || entry is num) {
        final parsed = tryParseDate(entry);
        if (parsed != null) addDate(parsed);
      } else if (entry is Map) {
        final done = (entry['done'] ?? entry['completed'] ?? entry['isDone']);
        if (done == false) continue;

        final count = (entry['count'] is int) ? entry['count'] as int : 1;
        final parsed = tryParseDate(
          entry['date'] ??
              entry['day'] ??
              entry['ts'] ??
              entry['time'] ??
              entry['completedAt'],
        );
        if (parsed != null) addDate(parsed, count);
      }
    }
    return;
  }

  if (value is Map) {
    value.forEach((key, entryValue) {
      final parsed = tryParseDate(key);
      if (parsed == null) return;

      if (entryValue == true) addDate(parsed, 1);
      if (entryValue is int && entryValue > 0) addDate(parsed, entryValue);
      if (entryValue is num && entryValue > 0) {
        addDate(parsed, entryValue.round());
      }
    });
    return;
  }

  if (value is DateTime) {
    addDate(value);
    return;
  }

  final parsed = tryParseDate(value);
  if (parsed != null) addDate(parsed);
}

DateTime? tryParseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  if (value is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } catch (_) {}
    try {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    } catch (_) {}
    return null;
  }

  if (value is num) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    } catch (_) {}
    try {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000);
    } catch (_) {}
    return null;
  }

  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {}
  }

  return null;
}

DateTime dateOnly(DateTime day) => DateTime(day.year, day.month, day.day);

String dateKey(DateTime day) {
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

Map<String, dynamic> toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

int safeInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  final parsed = int.tryParse((value ?? '').toString().trim());
  return parsed ?? fallback;
}

double safeNum(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  final parsed = double.tryParse((value ?? '').toString().trim());
  return parsed ?? fallback;
}

bool isDone(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value > 0;
  final normalized = (value ?? '').toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

String dowShort(BuildContext context, DateTime date) =>
    context.l10n.weekdayShort(date.weekday);

String dowShortLabel(DateTime date) {
  const labels = {
    DateTime.monday: 'Lun',
    DateTime.tuesday: 'Mar',
    DateTime.wednesday: 'Mié',
    DateTime.thursday: 'Jue',
    DateTime.friday: 'Vie',
    DateTime.saturday: 'Sáb',
    DateTime.sunday: 'Dom',
  };
  return labels[date.weekday] ?? '-';
}

class HabitStatsSurfaceCard extends StatelessWidget {
  const HabitStatsSurfaceCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFECE6DC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class HabitStatsBackgroundOrb extends StatelessWidget {
  const HabitStatsBackgroundOrb({
    super.key,
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
