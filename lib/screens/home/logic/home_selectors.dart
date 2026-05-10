part of 'package:rutio/screens/home/home_screen.dart';

/// Construye todo lo que Home necesita para pintar, a partir del estado raw.
/// Mantener esta función pura (sin setState, sin navegar, sin toasts).
HomeViewData buildHomeViewData(dynamic root, DateTime selectedDay) {
  final rootMap = _map(root);

  final userState = _map(rootMap['userState']);
  final activeHabits = _listMap(userState['activeHabits']);

  // Filtramos hábitos archivados para no mostrarlos en Home
  final visibleHabits = activeHabits.where((h) {
    final a = h['archived'] == true || h['isArchived'] == true;
    return !a;
  }).toList(growable: false);

  // Solo los hábitos esperados en la fecha seleccionada cuentan para Home.
  final expectedHabits = visibleHabits
      .where((habit) => isHabitExpectedForDate(habit, selectedDay))
      .toList(growable: false);

  // =========================
  // 📅 VIAJE POR DÍAS: snapshot del día seleccionado
  // =========================
  final selectedKey = _dateKey(selectedDay);
  final todayKey = _dateKey(_onlyDate(DateTime.now()));

  final history = _map(userState['history']);
  final habitCompletions = _map(history['habitCompletions']);
  final habitCountValues = _map(history['habitCountValues']);
  final habitSkips = _map(history['habitSkips']);

  final selectedDoneMap = _map(habitCompletions[selectedKey]);
  final selectedCountMap = _map(habitCountValues[selectedKey]);
  final selectedSkipsMap = _map(habitSkips[selectedKey]);

  final List<Map<String, dynamic>> viewHabits = expectedHabits.map((h) {
    final id = (h['id'] ?? '').toString();
    final type = (h['type'] ?? 'check').toString();
    final out = Map<String, dynamic>.from(h);

    if (selectedKey != todayKey) {
      final skipped = selectedSkipsMap[id] == true;
      out['skippedToday'] = skipped;
      if (type == 'check') {
        out['doneToday'] = !skipped && (selectedDoneMap[id] == true);
      } else {
        final target = _readNum(out['target'], fallback: 1);
        final val = skipped ? 0 : _readNum(selectedCountMap[id], fallback: 0);
        out['progress'] = val;
        out['doneToday'] =
            !skipped && ((selectedDoneMap[id] == true) || (val >= target));
      }
    }
    return out;
  }).toList(growable: false);

  final pendingHabits = viewHabits.where((h) {
    final done = h['doneToday'] == true;
    final skipped = h['skippedToday'] == true;
    return !done && !skipped;
  }).toList();

  final completedHabits = viewHabits.where((h) {
    return h['doneToday'] == true;
  }).toList();

  final skippedHabits = viewHabits.where((h) {
    return h['skippedToday'] == true;
  }).toList();

  final int doneCount = completedHabits.length;
  final int totalCount = viewHabits.length;

  final bool isToday = selectedKey == todayKey;
  final String dayLabel =
      isToday ? 'Hoy' : '${selectedDay.day}/${selectedDay.month}';

  // =========================
  // Progresión / wallet
  // =========================
  final xpTotal =
      _readInt(rootMap, ['userState', 'progression', 'xp'], fallback: 0);
  final levelProgress = LevelProgression.fromTotalXp(xpTotal);
  final level = levelProgress.level;
  final xpInLevel = levelProgress.currentLevelXp;
  final xpToNext = levelProgress.xpToNextLevel;
  final xpProgress = levelProgress.progress;
  final coins =
      _readInt(rootMap, ['userState', 'wallet', 'coins'], fallback: 0);

  return HomeViewData(
    visibleHabits: visibleHabits,
    viewHabits: viewHabits,
    pendingHabits: pendingHabits,
    completedHabits: completedHabits,
    skippedHabits: skippedHabits,
    doneCount: doneCount,
    totalCount: totalCount,
    dayLabel: dayLabel,
    xpTotal: xpTotal,
    level: level,
    xpInLevel: xpInLevel,
    xpToNext: xpToNext,
    xpProgress: xpProgress,
    coins: coins,
  );
}

bool isHabitExpectedForDate(Map<String, dynamic> habit, DateTime date) {
  if (_isArchivedHabit(habit)) return false;
  if (!_wasHabitCreatedByDay(habit, date)) return false;
  return _isHabitScheduledForDate(habit, date);
}

bool _isArchivedHabit(Map<String, dynamic> habit) =>
    habit['archived'] == true || habit['isArchived'] == true;

bool _wasHabitCreatedByDay(Map<String, dynamic> habit, DateTime day) {
  final createdAt = _parseHabitDate(
    habit['createdAt'] ??
        habit['created_at'] ??
        habit['createdDate'] ??
        habit['dateCreated'],
  );
  if (createdAt == null) return true;
  final createdDateOnly = _onlyDate(createdAt.toLocal());
  final dayOnly = _onlyDate(day);
  return !createdDateOnly.isAfter(dayOnly);
}

DateTime? _parseHabitDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt()).toLocal();
  }

  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return null;

  final parsed = DateTime.tryParse(raw);
  if (parsed != null) return parsed.toLocal();

  final dateKeyMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
  if (dateKeyMatch == null) return null;

  return DateTime(
    int.parse(dateKeyMatch.group(1)!),
    int.parse(dateKeyMatch.group(2)!),
    int.parse(dateKeyMatch.group(3)!),
  );
}

bool _isHabitScheduledForDate(Map<String, dynamic> habit, DateTime date) {
  final schedule = _map(habit['schedule']);
  final type = (schedule['type'] ?? 'daily').toString().trim().toLowerCase();

  if (type == 'once') {
    return (schedule['date'] ?? '').toString().trim() == _dateKey(date);
  }

  if (type == 'weekly') {
    final weekdays = schedule['weekdays'];
    if (weekdays is! List) return false;
    return weekdays
        .whereType<num>()
        .map((day) => day.toInt())
        .contains(date.weekday);
  }

  return true;
}
