part of 'user_state_store.dart';

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

List<dynamic> _list(dynamic value) => value is List ? value : <dynamic>[];

num _safeNum(dynamic value, {num fallback = 0}) {
  if (value is num) {
    if (value is double && !value.isFinite) return fallback;
    return value;
  }

  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return fallback;

  final parsed = num.tryParse(raw.replaceAll(',', '.'));
  if (parsed == null) return fallback;
  if (parsed is double && !parsed.isFinite) return fallback;
  return parsed;
}

int _safeInt(dynamic value, {int fallback = 0}) =>
    _safeNum(value, fallback: fallback).toInt();

double _safeDouble(dynamic value, {double fallback = 0}) =>
    _safeNum(value, fallback: fallback).toDouble();

num _safePositiveNum(dynamic value, {num fallback = 1}) {
  final parsed = _safeNum(value, fallback: fallback);
  return parsed > 0 ? parsed : fallback;
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _today() => _dateKey(DateTime.now());

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _normalizeFamilyId(String id) => id.trim().toLowerCase();

bool _onboardingDone(UserStateStore store) {
  if (store._state == null) return false;
  final userState = _ensureUserStateRoot(store._state!);
  final meta = _map(userState['meta']);
  return meta['onboardingDone'] == true;
}

Future<void> _setOnboardingDone(
  UserStateStore store,
  bool done, {
  String? email,
}) async {
  if (store._state == null) return;

  final root = Map<String, dynamic>.from(store._state!);
  final userState = _ensureUserStateRoot(root);
  final meta = _map(userState['meta']);
  meta['onboardingDone'] = done;

  if (email != null && email.trim().isNotEmpty) {
    meta['authEmail'] = email.trim().toLowerCase();
  }

  userState['meta'] = meta;
  root['userState'] = userState;
  store._state = root;

  await store._repo.save(root);
  store._emitChanged();
}

String _activeViewDateKey(Map<String, dynamic> userState) {
  final meta = _map(userState['meta']);
  final key = (meta['activeViewDateKey'] ?? '').toString();
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) return key;
  return _today();
}

DateTime _dateFromKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return DateTime.now();

  final now = DateTime.now();
  final year = int.tryParse(parts[0]) ?? now.year;
  final month = int.tryParse(parts[1]) ?? now.month;
  final day = int.tryParse(parts[2]) ?? now.day;
  return DateTime(year, month, day);
}

Future<void> _setActiveViewDate(UserStateStore store, DateTime date) async {
  if (store._state == null) return;

  final root = Map<String, dynamic>.from(store._state!);
  final userState = _ensureUserStateRoot(root);
  final meta = _map(userState['meta']);

  meta['activeViewDateKey'] = _dateKey(date);
  userState['meta'] = meta;

  _hydrateActiveHabitsForDate(userState, date);
  _touchLastSavedAt(userState);

  root['userState'] = userState;
  store._state = root;

  await store._repo.save(root);
  store._emitChanged();
}

void _hydrateActiveHabitsForDate(
  Map<String, dynamic> userState,
  DateTime date,
) {
  final history = _ensureHistoryRoot(userState);
  final habitCompletions = _map(history['habitCompletions']);
  final habitCountValues = _map(history['habitCountValues']);
  final habitSkips = _map(history['habitSkips']);

  final dayKey = _dateKey(date);
  final dayDone = _map(habitCompletions[dayKey]);
  final dayValues = _map(habitCountValues[dayKey]);
  final daySkips = _map(habitSkips[dayKey]);

  final activeHabits = _list(userState['activeHabits'])
      .whereType<Map>()
      .map((entry) => entry.cast<String, dynamic>())
      .toList();

  for (final habit in activeHabits) {
    final habitId = (habit['id'] ?? '').toString();
    final type = (habit['type'] ?? 'check').toString();

    if (!_isScheduledForDate(habit, date)) {
      habit['doneToday'] = false;
      habit['skippedToday'] = false;
      habit['progress'] = 0;
      continue;
    }

    final skipped = daySkips[habitId] == true;
    habit['skippedToday'] = skipped;

    if (type == 'count') {
      final value = skipped ? 0 : _safeNum(dayValues[habitId], fallback: 0);
      final target = _safePositiveNum(habit['target'], fallback: 1);

      habit['progress'] = value;
      habit['doneToday'] =
          !skipped && (value >= target || dayDone[habitId] == true);
      continue;
    }

    habit['doneToday'] = !skipped && dayDone[habitId] == true;
    habit['progress'] = habit['doneToday'] == true ? 1 : 0;
  }

  userState['activeHabits'] = activeHabits;
}

Map<String, dynamic> _normalizeSchedule(Map<String, dynamic>? schedule) {
  final normalized = _map(schedule);
  final type = (normalized['type'] ?? 'daily').toString();

  if (type == 'once') {
    return {
      'type': 'once',
      'date': (normalized['date'] ?? '').toString(),
    };
  }

  if (type == 'weekly') {
    final rawWeekdays = normalized['weekdays'];
    final weekdays = rawWeekdays is List
        ? rawWeekdays
            .whereType<num>()
            .map((day) => day.toInt())
            .where((day) => day >= 1 && day <= 7)
            .toList()
        : <int>[];

    return {
      'type': 'weekly',
      'weekdays': weekdays,
    };
  }

  return {'type': 'daily'};
}

bool _isScheduledForDate(Map<String, dynamic> habit, DateTime date) {
  final schedule = _normalizeSchedule(_map(habit['schedule']));
  final type = (schedule['type'] ?? 'daily').toString();

  if (type == 'daily') return true;

  if (type == 'once') {
    final scheduledDate = (schedule['date'] ?? '').toString();
    return scheduledDate.isNotEmpty && scheduledDate == _dateKey(date);
  }

  if (type == 'weekly') {
    final weekdays = schedule['weekdays'] is List
        ? (schedule['weekdays'] as List)
            .whereType<num>()
            .map((day) => day.toInt())
            .toList()
        : <int>[];
    return weekdays.contains(date.weekday);
  }

  return true;
}

void _touchLastSavedAt(Map<String, dynamic> userState) {
  final meta = _map(userState['meta']);
  meta['lastSavedAt'] = DateTime.now().toUtc().toIso8601String();
  userState['meta'] = meta;
}

Map<String, dynamic> _ensureUserStateRoot(Map<String, dynamic> root) {
  final userState = _map(root['userState']);
  root['userState'] = userState;
  return userState;
}

Map<String, dynamic> _ensureHistoryRoot(Map<String, dynamic> userState) {
  final history = _map(userState['history']);
  history['habitCompletions'] = _map(history['habitCompletions']);
  history['habitCountValues'] = _map(history['habitCountValues']);
  history['habitSkips'] = _map(history['habitSkips']);
  userState['history'] = history;
  return history;
}

List<Map<String, dynamic>> _ensureDiaryEntriesRoot(
  Map<String, dynamic> userState,
) {
  final entries = _list(userState['diaryEntries'])
      .whereType<Map>()
      .map((entry) => entry.cast<String, dynamic>())
      .toList();

  userState['diaryEntries'] = entries;
  return entries;
}

bool _ensureActiveHabitIds(Map<String, dynamic> userState) {
  final activeHabits = _list(userState['activeHabits'])
      .whereType<Map>()
      .map((entry) => entry.cast<String, dynamic>())
      .toList();

  var changed = false;

  for (var index = 0; index < activeHabits.length; index += 1) {
    final habit = activeHabits[index];
    var id = (habit['id'] ?? '').toString().trim();

    if (id.isEmpty) {
      id = (habit['habitId'] ?? habit['uuid'] ?? habit['key'] ?? '')
          .toString()
          .trim();
    }

    if (id.isEmpty) {
      final createdAt = (habit['createdAt'] ?? _today()).toString();
      final name = (habit['name'] ?? habit['title'] ?? 'habit').toString();
      id = 'auto_${createdAt}_${index}_${name.hashCode.abs()}';
    }

    if ((habit['id'] ?? '').toString().trim() != id) {
      habit['id'] = id;
      changed = true;
    }

    if ((habit['habitId'] ?? '').toString().trim().isEmpty) {
      habit['habitId'] = id;
    }

    activeHabits[index] = habit;
  }

  if (changed) {
    userState['activeHabits'] = activeHabits;
  }

  return changed;
}

void _ensureDailyReset(Map<String, dynamic> userState) {
  final daily = _map(userState['daily']);
  final lastResetDate = (daily['lastResetDate'] ?? '').toString();
  final today = _today();

  if (lastResetDate == today) {
    userState['daily'] = daily;
    return;
  }

  final previousDayKey = lastResetDate;
  if (previousDayKey.isNotEmpty) {
    final history = _ensureHistoryRoot(userState);
    final habitCompletions = _map(history['habitCompletions']);
    final habitCountValues = _map(history['habitCountValues']);
    final habitSkips = _map(history['habitSkips']);

    final previousDone = _map(habitCompletions[previousDayKey]);
    final previousCounts = _map(habitCountValues[previousDayKey]);
    final previousSkips = _map(habitSkips[previousDayKey]);

    final activeHabits = _list(userState['activeHabits'])
        .whereType<Map>()
        .map((entry) => entry.cast<String, dynamic>())
        .toList();

    for (final habit in activeHabits) {
      final habitId = (habit['id'] ?? '').toString();
      final type = (habit['type'] ?? 'check').toString();
      final skipped = habit['skippedToday'] == true;

      previousSkips[habitId] = skipped;

      if (type == 'count') {
        final value = skipped ? 0 : _safeNum(habit['progress'], fallback: 0);
        final target = _safePositiveNum(habit['target'], fallback: 1);

        previousCounts[habitId] = value;
        previousDone[habitId] = !skipped && value >= target;
        continue;
      }

      previousDone[habitId] = !skipped && habit['doneToday'] == true;
    }

    habitCompletions[previousDayKey] = previousDone;
    habitCountValues[previousDayKey] = previousCounts;
    habitSkips[previousDayKey] = previousSkips;
    history['habitCompletions'] = habitCompletions;
    history['habitCountValues'] = habitCountValues;
    history['habitSkips'] = habitSkips;
    userState['history'] = history;
  }

  daily['lastResetDate'] = today;
  daily['xpEarnedToday'] = 0;
  daily['coinsEarnedToday'] = 0;
  daily['habitsCompletedToday'] = <String, dynamic>{};
  userState['daily'] = daily;

  final activeHabits = _list(userState['activeHabits'])
      .whereType<Map>()
      .map((entry) => entry.cast<String, dynamic>())
      .toList();

  for (final habit in activeHabits) {
    habit['doneToday'] = false;
    habit['skippedToday'] = false;
    if ((habit['type'] ?? 'check').toString() != 'check') {
      habit['progress'] = 0;
    }
  }

  userState['activeHabits'] = activeHabits;
}

Future<void> _loadStore(UserStateStore store) async {
  if (store._loading) return;

  store._loading = true;
  store._error = null;
  store._emitChanged();

  try {
    store._state = await store._repo.loadOrCreate();

    if (store._state != null) {
      final userState = _ensureUserStateRoot(store._state!);
      _ensureDailyReset(userState);
      _ensureActiveHabitIds(userState);
      _ensureDiaryEntriesRoot(userState);
      _ensureTodosRoot(userState);
      _ensureAchievementsRoot(userState);
      _syncAchievementsFromCurrentHabits(store, userState);

      final viewKey = _activeViewDateKey(userState);
      if (viewKey != _today()) {
        _hydrateActiveHabitsForDate(userState, _dateFromKey(viewKey));
      }

      _touchLastSavedAt(userState);
      await store._repo.save(store._state!);
    }
  } catch (error) {
    store._error = error;
  } finally {
    store._loading = false;
    store._emitChanged();
  }
}

Future<void> _saveStore(
  UserStateStore store,
  Map<String, dynamic> newState,
) async {
  store._state = newState;

  final userState = _ensureUserStateRoot(store._state!);
  _ensureDailyReset(userState);
  _ensureActiveHabitIds(userState);
  _ensureTodosRoot(userState);
  _ensureAchievementsRoot(userState);
  _sanitizeFeaturedAchievements(userState);

  final viewKey = _activeViewDateKey(userState);
  if (viewKey != _today()) {
    _hydrateActiveHabitsForDate(userState, _dateFromKey(viewKey));
  }

  _touchLastSavedAt(userState);

  store._emitChanged();
  await store._repo.save(store._state!);
}

Map<String, dynamic> _ensureHabitCompletionTimesRoot(
  Map<String, dynamic> history,
) {
  final completionTimes = _map(history['habitCompletionTimes']);
  history['habitCompletionTimes'] = completionTimes;
  return completionTimes;
}

void _setCompletionTime({
  required Map<String, dynamic> userState,
  required String dateKey,
  required String habitId,
  required int epochMillis,
}) {
  final history = _ensureHistoryRoot(userState);
  final timesRoot = _ensureHabitCompletionTimesRoot(history);
  final dayMap = _map(timesRoot[dateKey]);

  dayMap[habitId] = epochMillis;
  timesRoot[dateKey] = dayMap;
  history['habitCompletionTimes'] = timesRoot;
  userState['history'] = history;
}

void _removeCompletionTime({
  required Map<String, dynamic> userState,
  required String dateKey,
  required String habitId,
}) {
  final history = _ensureHistoryRoot(userState);
  final timesRoot = _ensureHabitCompletionTimesRoot(history);
  final dayMap = _map(timesRoot[dateKey]);

  if (!dayMap.containsKey(habitId)) return;

  dayMap.remove(habitId);
  timesRoot[dateKey] = dayMap;
  history['habitCompletionTimes'] = timesRoot;
  userState['history'] = history;
}
