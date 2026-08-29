part of 'package:rutio/screens/home/home_screen.dart';

/// Construye todo lo que Home necesita para pintar, a partir del estado raw.
/// Mantener esta función pura (sin setState, sin navegar, sin toasts).
HomeViewData buildHomeViewData(dynamic root, DateTime selectedDay) {
  final rootMap = _map(root);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final userState = _map(rootMap['userState']);
  final activeHabits = _listMap(userState['activeHabits']);
  final summary = buildHabitDaySummary(
    activeHabits: activeHabits,
    history: _map(userState['history']),
    selectedDay: selectedDay,
    today: today,
  );

  final selectedKey = _dateKey(selectedDay);
  final todayKey = _dateKey(today);
  final bool isToday = selectedKey == todayKey;
  final String dayLabel =
      isToday ? 'Hoy' : '${selectedDay.day}/${selectedDay.month}';

  final xpTotal =
      _readInt(rootMap, ['userState', 'progression', 'xp'], fallback: 0);
  final levelProgress = LevelProgression.fromTotalXp(xpTotal);
  final level = levelProgress.level;
  final xpInLevel = levelProgress.currentLevelXp;
  final xpToNext = levelProgress.xpToNextLevel;
  final xpProgress = levelProgress.progress;

  return HomeViewData(
    visibleHabits: summary.visibleHabits,
    viewHabits: summary.viewHabits,
    pendingHabits: summary.pendingHabits,
    completedHabits: summary.completedHabits,
    skippedHabits: summary.skippedHabits,
    doneCount: summary.completedCount,
    totalCount: summary.totalCount,
    dayLabel: dayLabel,
    xpTotal: xpTotal,
    level: level,
    xpInLevel: xpInLevel,
    xpToNext: xpToNext,
    xpProgress: xpProgress,
  );
}

bool isHabitExpectedForDate(Map<String, dynamic> habit, DateTime date) {
  return isHabitExpectedForDateSummary(habit, date);
}
