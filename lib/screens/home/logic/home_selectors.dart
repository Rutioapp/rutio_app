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

  // =========================
  // 📅 VIAJE POR DÍAS: snapshot del día seleccionado
  // =========================
  final selectedKey = _dateKey(selectedDay);
  final todayKey = _dateKey(_onlyDate(DateTime.now()));

  final history = _map(userState['history']);
  final habitCompletions = _map(history['habitCompletions']);
  final habitCountValues = _map(history['habitCountValues']);

  final selectedDoneMap = _map(habitCompletions[selectedKey]);
  final selectedCountMap = _map(habitCountValues[selectedKey]);

  final List<Map<String, dynamic>> viewHabits = visibleHabits.map((h) {
    final id = (h['id'] ?? '').toString();
    final type = (h['type'] ?? 'check').toString();
    final out = Map<String, dynamic>.from(h);

    if (selectedKey != todayKey) {
      if (type == 'check') {
        out['doneToday'] = (selectedDoneMap[id] == true);
      } else {
        final target = _readNum(out['target'], fallback: 1);
        final val = _readNum(selectedCountMap[id], fallback: 0);
        out['progress'] = val;
        out['doneToday'] = (selectedDoneMap[id] == true) || (val >= target);
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
  final level = _readInt(
    rootMap,
    ['userState', 'progression', 'level'],
    fallback: 1 + (xpTotal ~/ 100),
  );
  final xpInLevel = xpTotal % 100;
  final xpToNext = 100 - xpInLevel;
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
    coins: coins,
  );
}
