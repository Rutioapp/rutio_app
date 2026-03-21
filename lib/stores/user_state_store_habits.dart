part of 'user_state_store.dart';

Map<String, dynamic> _dailyRewardGrants(Map<String, dynamic> userState) {
  final daily = _map(userState['daily']);
  final grants = _map(daily['habitsCompletedToday']);
  daily['habitsCompletedToday'] = grants;
  userState['daily'] = daily;
  return grants;
}

bool _hasDailyRewardGrant(
  Map<String, dynamic> userState, {
  required String habitId,
}) {
  return _dailyRewardGrants(userState)[habitId] == true;
}

void _setDailyRewardGrant(
  Map<String, dynamic> userState, {
  required String habitId,
  required bool granted,
}) {
  _dailyRewardGrants(userState)[habitId] = granted;
}

String _formatHabitName({
  required Map<String, dynamic> habitDef,
  required num target,
}) {
  final rawName =
      (habitDef['nameTemplate'] ?? habitDef['name'] ?? habitDef['id'] ?? '')
          .toString();
  final targetText =
      target % 1 == 0 ? target.toInt().toString() : target.toString();

  var output = rawName.replaceAll('{target}', targetText);
  output = output.replaceAllMapped(RegExp(r'\bX\b'), (_) => targetText);
  return output;
}

List<Map<String, dynamic>> _mutableActiveHabits(
  Map<String, dynamic> userState,
) {
  final activeHabits = _list(userState['activeHabits'])
      .whereType<Map>()
      .map((entry) => entry.cast<String, dynamic>())
      .toList();
  userState['activeHabits'] = activeHabits;
  return activeHabits;
}

String? _habitIdValue(dynamic habit) {
  if (habit == null) return null;

  if (habit is Map) {
    final mapHabit = _map(habit);
    final id = (mapHabit['id'] ??
            mapHabit['habitId'] ??
            mapHabit['uuid'] ??
            mapHabit['key'])
        ?.toString()
        .trim();
    return id == null || id.isEmpty ? null : id;
  }

  try {
    final dynamic id = (habit as dynamic).id;
    final normalized = id?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
  } catch (_) {}

  try {
    final dynamic id = (habit as dynamic).habitId;
    final normalized = id?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
  } catch (_) {}

  try {
    final dynamic id = (habit as dynamic).uuid;
    final normalized = id?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
  } catch (_) {}

  return null;
}

int _activeHabitIndex(
  List<Map<String, dynamic>> activeHabits,
  String habitId,
) {
  final normalizedId = habitId.trim();
  return activeHabits.indexWhere(
    (habit) => _habitIdValue(habit) == normalizedId,
  );
}

String _normalizedHabitType(dynamic rawType) {
  final value = (rawType ?? 'check').toString().trim().toLowerCase();
  return value == 'count' || value == 'counter' || value == 'number'
      ? 'count'
      : 'check';
}

bool _isCountHabit(Map<String, dynamic> habit) =>
    _normalizedHabitType(habit['type']) == 'count';

List<int> _normalizedWeekdays(dynamic rawWeekdays) {
  if (rawWeekdays is! List) return const <int>[];
  return rawWeekdays
      .whereType<num>()
      .map((day) => day.toInt())
      .where((day) => day >= 1 && day <= 7)
      .toList(growable: false);
}

Map<String, dynamic> _habitSchedule({
  String scheduleType = 'daily',
  String? scheduledDate,
  List<int>? weekdays,
}) {
  if (scheduleType == 'once') {
    return _normalizeSchedule({
      'type': 'once',
      'date': (scheduledDate ?? '').toString(),
    });
  }

  if (scheduleType == 'weekly') {
    return _normalizeSchedule({
      'type': 'weekly',
      'weekdays': weekdays ?? const <int>[],
    });
  }

  return _normalizeSchedule({'type': 'daily'});
}

void _removeHabitFromHistory(
  Map<String, dynamic> userState, {
  required String habitId,
}) {
  final history = _ensureHistoryRoot(userState);

  for (final key in [
    'habitCompletions',
    'habitCountValues',
    'habitSkips',
    'habitCompletionTimes',
  ]) {
    final bucket = _map(history[key]);
    for (final dayKey in bucket.keys.toList()) {
      final dayMap = _map(bucket[dayKey]);
      if (!dayMap.containsKey(habitId)) continue;
      dayMap.remove(habitId);
      bucket[dayKey] = dayMap;
    }
    history[key] = bucket;
  }

  userState['history'] = history;
}

Future<void> _deleteHabitById(
  UserStateStore store,
  String id, {
  bool purgeHistory = true,
}) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);
  _ensureActiveHabitIds(userState);

  final activeHabits = _mutableActiveHabits(userState);
  final normalizedId = id.trim();

  final before = activeHabits.length;
  activeHabits.removeWhere((habit) => _habitIdValue(habit) == normalizedId);

  if (activeHabits.length == before) return;

  userState['activeHabits'] = activeHabits;

  if (purgeHistory) {
    _removeHabitFromHistory(userState, habitId: normalizedId);
  }

  await store.save(root);
}

Future<void> _addHabitFromCatalog(
  UserStateStore store, {
  required Map<String, dynamic> habitDef,
  required String familyId,
  num? target,
  String scheduleType = 'daily',
  String? scheduledDate,
  List<int>? weekdays,
  String? routine,
}) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);

  final activeHabits = _mutableActiveHabits(userState);

  final id = (habitDef['id'] ?? '').toString();
  if (id.isEmpty) return;
  if (_activeHabitIndex(activeHabits, id) != -1) return;

  final type = _normalizedHabitType(habitDef['type']);
  final metric = _map(habitDef['metric']);
  final resolvedTarget = target ?? (type == 'check' ? 1 : 10);

  final normalizedRoutine =
      routine == null || routine.trim().isEmpty ? null : routine.trim();

  activeHabits.add(<String, dynamic>{
    'id': id,
    'createdAt': _today(),
    'name': _formatHabitName(habitDef: habitDef, target: resolvedTarget),
    'emoji': (habitDef['emoji'] ?? '?').toString(),
    'familyId': familyId,
    'type': type,
    'unit': metric['unit'],
    'target': resolvedTarget,
    'progress': 0,
    'doneToday': false,
    'skippedToday': false,
    'schedule': _habitSchedule(
      scheduleType: scheduleType,
      scheduledDate: scheduledDate,
      weekdays: weekdays,
    ),
    'routine': normalizedRoutine,
  });

  userState['activeHabits'] = activeHabits;
  await store.save(root);
}

Future<void> _addCustomHabit(
  UserStateStore store,
  Map<String, dynamic> habit,
) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);

  final activeHabits = _mutableActiveHabits(userState);

  final providedId = (habit['id'] ?? '').toString().trim();
  final id = providedId.isNotEmpty
      ? providedId
      : 'custom_${DateTime.now().millisecondsSinceEpoch}';

  if (_activeHabitIndex(activeHabits, id) != -1) {
    return;
  }

  final type = _normalizedHabitType(habit['type']);
  final routineDays = _normalizedWeekdays(habit['routineDays']);
  final schedule = routineDays.isEmpty || routineDays.length == 7
      ? _habitSchedule()
      : _habitSchedule(scheduleType: 'weekly', weekdays: routineDays);

  final familyId = habit['familyId'];
  final allFamilies = habit['allFamilies'] == true;
  final resolvedFamilyId = allFamilies
      ? null
      : (familyId is String ? familyId : familyId?.toString());
  final rawEmoji =
      (habit['emoji'] ?? habit['habitEmoji'] ?? '').toString().trim();
  final resolvedEmoji =
      rawEmoji.isNotEmpty ? rawEmoji : FamilyTheme.emojiOf(resolvedFamilyId);

  activeHabits.add(<String, dynamic>{
    'id': id,
    'name': (habit['name'] ?? habit['title'] ?? 'Habito').toString(),
    'emoji': resolvedEmoji,
    'description': (habit['description'] ?? '').toString(),
    'familyId': resolvedFamilyId,
    'allFamilies': allFamilies,
    'type': type,
    'unit': type == 'count' ? habit['unit'] : null,
    'target':
        type == 'count' ? _safePositiveNum(habit['target'], fallback: 1) : 1,
    'progress': 0,
    'doneToday': false,
    'skippedToday': false,
    'schedule': schedule,
    'isCustom': true,
    'reminderEnabled':
        habit['reminderEnabled'] == true || habit['remindersEnabled'] == true,
    'reminderTime': habit['reminderTime'],
  });

  userState['activeHabits'] = activeHabits;
  await store.save(root);
}

Future<void> _reorderVisibleHabits(
  UserStateStore store, {
  required List<String> orderedVisibleIds,
}) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);

  final activeHabits = _mutableActiveHabits(userState);

  final visibleById = <String, Map<String, dynamic>>{};
  final visibleInCurrentOrder = <Map<String, dynamic>>[];

  for (final habit in activeHabits) {
    final isArchived = habit['archived'] == true || habit['isArchived'] == true;
    if (isArchived) continue;

    final id = (habit['id'] ?? '').toString();
    if (id.isEmpty || visibleById.containsKey(id)) continue;

    visibleById[id] = habit;
    visibleInCurrentOrder.add(habit);
  }

  if (visibleById.isEmpty) return;

  final reorderedVisible = <Map<String, dynamic>>[];
  final seenIds = <String>{};

  for (final id in orderedVisibleIds) {
    final habit = visibleById[id];
    if (habit == null || !seenIds.add(id)) continue;
    reorderedVisible.add(habit);
  }

  for (final habit in visibleInCurrentOrder) {
    final id = (habit['id'] ?? '').toString();
    if (!seenIds.add(id)) continue;
    reorderedVisible.add(habit);
  }

  var visibleIndex = 0;
  final reorderedActive = activeHabits.map((habit) {
    final isArchived = habit['archived'] == true || habit['isArchived'] == true;
    if (isArchived) return habit;

    final nextHabit = reorderedVisible[visibleIndex];
    visibleIndex += 1;
    return nextHabit;
  }).toList(growable: false);

  userState['activeHabits'] = reorderedActive;
  await store.save(root);
}

Future<void> _updateHabitPlan(
  UserStateStore store, {
  required String habitId,
  String? scheduleType,
  String? scheduledDate,
  List<int>? weekdays,
  String? routine,
}) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);

  final activeHabits = _mutableActiveHabits(userState);

  final index = _activeHabitIndex(activeHabits, habitId);
  if (index == -1) return;

  final habit = Map<String, dynamic>.from(activeHabits[index]);

  if (scheduleType != null) {
    habit['schedule'] = _habitSchedule(
      scheduleType: scheduleType,
      scheduledDate: scheduledDate,
      weekdays: weekdays,
    );
  }

  if (routine != null) {
    habit['routine'] = routine.trim().isEmpty ? null : routine.trim();
  }

  activeHabits[index] = habit;
  userState['activeHabits'] = activeHabits;
  await store.save(root);
}

Future<void> _updateHabitDetailsFromEdit(
  UserStateStore store,
  dynamic updatedHabit,
) async {
  final root = store._state;
  if (root == null) return;

  String? id;
  var patch = <String, dynamic>{};

  if (updatedHabit is Map) {
    final mapValue = _map(updatedHabit);
    id = _habitIdValue(mapValue);
    patch = Map<String, dynamic>.from(mapValue);
  } else {
    try {
      final value = (updatedHabit as dynamic).id;
      if (value != null) id = value.toString();
    } catch (_) {}

    for (final key in [
      'name',
      'title',
      'description',
      'notes',
      'reminderEnabled',
      'remindersEnabled',
      'reminderTime',
      'archived',
      'isArchived',
      'target',
      'targetCount',
      'frequency',
    ]) {
      try {
        final value = (updatedHabit as dynamic).__get(key);
        if (value != null) patch[key] = value;
      } catch (_) {}

      try {
        final value = (updatedHabit as dynamic).toJson?.call();
        if (value is Map) patch.addAll(_map(value));
      } catch (_) {}
    }
  }

  if (id == null || id.isEmpty) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);

  final activeHabits = _mutableActiveHabits(userState);
  final index = _activeHabitIndex(activeHabits, id);
  if (index == -1) return;

  final current = Map<String, dynamic>.from(activeHabits[index]);

  final newName = (patch['name'] ?? patch['title'])?.toString();
  if (newName != null && newName.trim().isNotEmpty) {
    current['name'] = newName.trim();
    current['title'] = newName.trim();
    current['habitTitle'] = newName.trim();
  }

  final newDescription =
      (patch['description'] ?? patch['desc'] ?? patch['subtitle'])?.toString();
  if (newDescription != null) current['description'] = newDescription;

  final newEmoji = (patch['emoji'] ?? patch['habitEmoji'])?.toString();
  if (newEmoji != null && newEmoji.trim().isNotEmpty) {
    current['emoji'] = newEmoji.trim();
  }

  if (patch.containsKey('notes')) current['notes'] = patch['notes'];
  if (patch.containsKey('note')) current['notes'] = patch['note'];

  if (patch.containsKey('reminderEnabled')) {
    current['reminderEnabled'] = patch['reminderEnabled'] == true;
  }
  if (patch.containsKey('remindersEnabled')) {
    current['reminderEnabled'] = patch['remindersEnabled'] == true;
  }
  if (patch.containsKey('reminderTime')) {
    current['reminderTime'] = patch['reminderTime'];
  }

  if (patch.containsKey('archived')) {
    current['archived'] = patch['archived'] == true;
  }
  if (patch.containsKey('isArchived')) {
    current['archived'] = patch['isArchived'] == true;
  }

  final incomingTypeRaw = (patch['type'] ??
          patch['trackingType'] ??
          patch['habitType'] ??
          patch['tracking'] ??
          patch['mode'])
      ?.toString()
      .toLowerCase();

  if (incomingTypeRaw != null && incomingTypeRaw.isNotEmpty) {
    final normalized = incomingTypeRaw == 'count' ||
            incomingTypeRaw == 'counter' ||
            incomingTypeRaw == 'number'
        ? 'count'
        : 'check';

    current['type'] = normalized;
    if (normalized == 'check') {
      current['target'] = 1;
      if (current['doneToday'] != true) {
        current['progress'] = 0;
      }
    }
  }

  final incomingUnit = (patch['unit'] ??
          patch['unitLabel'] ??
          patch['counterUnit'] ??
          patch['units'])
      ?.toString();
  if (incomingUnit != null) {
    final trimmedUnit = incomingUnit.trim();
    if (trimmedUnit.isEmpty) {
      current.remove('unit');
      current.remove('unitLabel');
    } else {
      current['unit'] = trimmedUnit;
      current['unitLabel'] = trimmedUnit;
    }
  }

  final incomingStep = patch['counterStep'] ?? patch['step'];
  if (incomingStep != null) {
    final step = _safeInt(incomingStep, fallback: 0);
    if (step > 0) current['counterStep'] = step;
  }

  final type = _normalizedHabitType(current['type']);
  if (type == 'count') {
    final target = patch['target'] ??
        patch['targetCount'] ??
        patch['goal'] ??
        patch['times'];
    if (target is num) current['target'] = target;
    if (target is String) {
      final parsed = num.tryParse(target);
      if (parsed != null) current['target'] = parsed;
    }
  }

  if (patch.containsKey('frequency')) {
    current['frequency'] = patch['frequency'];
  }
  if (patch.containsKey('cadence')) {
    current['frequency'] = patch['cadence'];
  }

  if (patch.containsKey('schedule') && patch['schedule'] is Map) {
    current['schedule'] = _normalizeSchedule(_map(patch['schedule']));
  }

  activeHabits[index] = current;
  userState['activeHabits'] = activeHabits;

  await store.save(root);
}

Future<void> _setCountHabitValue(
  UserStateStore store, {
  required String habitId,
  required num value,
}) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);

  final activeHabits = _mutableActiveHabits(userState);

  final index = _activeHabitIndex(activeHabits, habitId);
  if (index == -1) return;

  final habit = Map<String, dynamic>.from(activeHabits[index]);
  if (!_isScheduledForDate(habit, DateTime.now())) return;
  if (!_isCountHabit(habit)) return;

  final rewardAlreadyGranted =
      _hasDailyRewardGrant(userState, habitId: habitId);
  final progressResult = _setCountHabitProgress(
    habit,
    value: value,
    rewardAlreadyGranted: rewardAlreadyGranted,
  );
  final dayKey = _today();

  _setHabitCompletionTimeState(
    userState,
    dateKey: dayKey,
    habitId: habitId,
    done: habit['doneToday'] == true,
    epochMillis: DateTime.now().millisecondsSinceEpoch,
  );

  if (progressResult.grantDailyReward) {
    _applyHabitRewards(
      userState,
      familyId: _habitFamilyId(habit),
      xpGain: progressResult.xpGain,
      coinsGain: progressResult.coinsGain,
    );
    _setDailyRewardGrant(userState, habitId: habitId, granted: true);
  }

  activeHabits[index] = habit;
  userState['activeHabits'] = activeHabits;
  userState['profile'] = _map(userState['profile']);
  _syncHabitHistoryFromState(
    userState,
    dateKey: dayKey,
    habitId: habitId,
    habit: habit,
  );

  await store.save(root);
}

Future<void> _completeHabit(
  UserStateStore store, {
  required String habitId,
  num delta = 1,
}) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);

  final activeHabits = _mutableActiveHabits(userState);

  final index = _activeHabitIndex(activeHabits, habitId);
  if (index == -1) return;

  final habit = Map<String, dynamic>.from(activeHabits[index]);
  if (!_isScheduledForDate(habit, DateTime.now())) return;

  final type = _normalizedHabitType(habit['type']);
  final rewardAlreadyGranted =
      _hasDailyRewardGrant(userState, habitId: habitId);
  final dayKey = _today();

  if (type == 'check') {
    if (habit['doneToday'] == true) return;
  }

  final progressResult = _applyHabitProgressDelta(
    habit,
    delta: delta,
    rewardAlreadyGranted: rewardAlreadyGranted,
  );
  _setHabitCompletionTimeState(
    userState,
    dateKey: dayKey,
    habitId: habitId,
    done: habit['doneToday'] == true,
    epochMillis: DateTime.now().millisecondsSinceEpoch,
  );
  _applyHabitRewards(
    userState,
    familyId: _habitFamilyId(habit),
    xpGain: progressResult.xpGain,
    coinsGain: progressResult.coinsGain,
  );

  if (habit['doneToday'] == true && progressResult.grantDailyReward) {
    _setDailyRewardGrant(userState, habitId: habitId, granted: true);
  }

  activeHabits[index] = habit;
  userState['activeHabits'] = activeHabits;
  _syncHabitHistoryFromState(
    userState,
    dateKey: dayKey,
    habitId: habitId,
    habit: habit,
  );

  await store.save(root);
}

Future<void> _toggleHabitDoneForDate(
  UserStateStore store, {
  required String habitId,
  required DateTime date,
}) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);

  if (_isSameDay(date, DateTime.now())) {
    await store.completeHabit(habitId: habitId);
    return;
  }

  _ensureDailyReset(userState);

  final activeHabits = _mutableActiveHabits(userState);

  final index = _activeHabitIndex(activeHabits, habitId);
  if (index == -1) return;

  final habit = Map<String, dynamic>.from(activeHabits[index]);
  if (!_isScheduledForDate(habit, date)) return;

  final dayKey = _dateKey(date);
  final history = _ensureHistoryRoot(userState);
  final dayMap = _map(_map(history['habitCompletions'])[dayKey]);
  final currentlyDone = dayMap[habitId] == true;

  _setHabitCompletionTimeState(
    userState,
    dateKey: dayKey,
    habitId: habitId,
    done: !currentlyDone,
    epochMillis: 0,
  );
  _setHabitCompletionForDay(
    userState,
    dateKey: dayKey,
    habitId: habitId,
    done: !currentlyDone,
  );

  await store.save(root);
}

Future<void> _setHabitCompletionForKey(
  UserStateStore store, {
  required String habitId,
  required String dateKey,
  required bool done,
}) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);

  final date = _dateFromKey(dateKey);

  if (_isSameDay(date, DateTime.now())) {
    if (done) {
      await store.completeHabit(habitId: habitId);
      return;
    }

    final activeHabits = _mutableActiveHabits(userState);

    final index = _activeHabitIndex(activeHabits, habitId);
    if (index != -1) {
      final habit = Map<String, dynamic>.from(activeHabits[index]);
      final type = _normalizedHabitType(habit['type']);

      habit['doneToday'] = false;
      habit['skippedToday'] = false;
      habit['progress'] =
          type == 'count' ? _safeNum(habit['progress'], fallback: 0) : 0;

      activeHabits[index] = habit;
      userState['activeHabits'] = activeHabits;
    }
  }

  _setHabitCompletionTimeState(
    userState,
    dateKey: dateKey,
    habitId: habitId,
    done: done,
    epochMillis: 0,
  );
  _setHabitCompletionForDay(
    userState,
    dateKey: dateKey,
    habitId: habitId,
    done: done,
  );
  _setHabitSkipForDay(
    userState,
    dateKey: dateKey,
    habitId: habitId,
    skipped: false,
  );

  await store.save(root);
}

Future<void> _setHabitSkipForKey(
  UserStateStore store, {
  required String habitId,
  required String dateKey,
  required bool skipped,
}) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);

  final date = _dateFromKey(dateKey);

  if (_isSameDay(date, DateTime.now())) {
    final activeHabits = _mutableActiveHabits(userState);

    final index = _activeHabitIndex(activeHabits, habitId);
    if (index != -1) {
      final habit = Map<String, dynamic>.from(activeHabits[index]);

      habit['skippedToday'] = skipped;
      if (skipped) {
        habit['doneToday'] = false;
        if (_isCountHabit(habit)) {
          habit['progress'] = 0;
        }

        _setHabitCompletionTimeState(
          userState,
          dateKey: dateKey,
          habitId: habitId,
          done: false,
          epochMillis: 0,
        );
      }

      activeHabits[index] = habit;
      userState['activeHabits'] = activeHabits;
    }
  }

  _setHabitSkipForDay(
    userState,
    dateKey: dateKey,
    habitId: habitId,
    skipped: skipped,
  );

  if (skipped) {
    _setHabitCompletionForDay(
      userState,
      dateKey: dateKey,
      habitId: habitId,
      done: false,
    );
    _setHabitCountValueForDay(
      userState,
      dateKey: dateKey,
      habitId: habitId,
      value: 0,
    );

    _setHabitCompletionTimeState(
      userState,
      dateKey: dateKey,
      habitId: habitId,
      done: false,
      epochMillis: 0,
    );
  }

  await store.save(root);
}

Future<void> _setCountHabitValueForDate(
  UserStateStore store, {
  required String habitId,
  required DateTime date,
  required num value,
}) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);

  if (_isSameDay(date, DateTime.now())) {
    await store.setCountHabitValue(habitId: habitId, value: value);
    return;
  }

  _ensureDailyReset(userState);

  final activeHabits = _mutableActiveHabits(userState);

  final index = _activeHabitIndex(activeHabits, habitId);
  if (index == -1) return;

  final habit = Map<String, dynamic>.from(activeHabits[index]);
  if (!_isCountHabit(habit)) return;
  if (!_isScheduledForDate(habit, date)) return;

  final target = _habitTarget(habit);
  final safeValue = _safeDouble(value, fallback: 0).clamp(0, double.infinity);

  final dayKey = _dateKey(date);
  _setHabitCountValueForDay(
    userState,
    dateKey: dayKey,
    habitId: habitId,
    value: safeValue,
  );
  _setHabitCompletionForDay(
    userState,
    dateKey: dayKey,
    habitId: habitId,
    done: safeValue >= target,
  );
  _setHabitSkipForDay(
    userState,
    dateKey: dayKey,
    habitId: habitId,
    skipped: false,
  );

  await store.save(root);
}

dynamic _getActiveHabitById(UserStateStore store, String id) {
  final root = store._state;
  if (root == null) return null;

  final userState = _ensureUserStateRoot(root);
  final activeHabits = _list(userState['activeHabits']);

  for (final habit in activeHabits) {
    if (_habitIdValue(habit) == id) return habit;
  }

  return null;
}

List<Map<String, dynamic>> _activeHabits(UserStateStore store) {
  final root = store._state;
  if (root == null) return const [];

  final userState = _ensureUserStateRoot(root);
  return _list(userState['activeHabits'])
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(_map(entry)))
      .toList(growable: false);
}
