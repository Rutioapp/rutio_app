part of 'user_state_store.dart';

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

Map<String, dynamic> _cloneMap(Map<String, dynamic> value) {
  return (jsonDecode(jsonEncode(value)) as Map).cast<String, dynamic>();
}

List<dynamic> _list(dynamic value) => value is List ? value : <dynamic>[];

bool _clearTransientGamificationStateInternal(UserStateStore store) {
  final hasPendingEvents = store._pendingAchievementUnlocks.isNotEmpty ||
      store._pendingLevelCelebrations.isNotEmpty;
  if (!hasPendingEvents) return false;
  store._pendingAchievementUnlocks.clear();
  store._pendingLevelCelebrations.clear();
  return true;
}

void _clearHydrationBaselinesInternal(UserStateStore store) {
  if (store._hydratedXpBaselineByUserId.isEmpty &&
      store._hydratedLevelBaselineByUserId.isEmpty) {
    return;
  }

  store._hydratedXpBaselineByUserId.clear();
  store._hydratedLevelBaselineByUserId.clear();
}

void _primeHydrationBaselineFromUserState(
  UserStateStore store,
  Map<String, dynamic> userState,
  XpMutationOrigin origin,
) {
  final userId = (store.userId ?? '').trim();
  if (userId.isEmpty) return;

  final progression = _map(userState['progression']);
  final xp = _safeInt(progression['xp'], fallback: 0).clamp(0, 1 << 30);
  final level = LevelProgression.fromTotalXp(xp).level;

  store._hydratedXpBaselineByUserId[userId] = xp;
  store._hydratedLevelBaselineByUserId[userId] = level;

  if (kDebugMode) {
    final originLabel = origin.name;
    final existingXp = store._hydratedXpBaselineByUserId[userId];
    final existingLevel = store._hydratedLevelBaselineByUserId[userId];
    debugPrint(
      '[user_state_store] primed xp baseline '
      '(user=${_debugUserIdLabel(userId)}, origin=$originLabel, '
      'xp=$existingXp, level=$existingLevel)',
    );
  }
}

String _debugUserIdLabel(String userId) {
  final normalized = userId.trim();
  if (normalized.isEmpty) return 'guest';
  if (normalized.length <= 8) return normalized;
  return '${normalized.substring(0, 4)}…${normalized.substring(normalized.length - 4)}';
}

void _clearTransientGamificationState(UserStateStore store) {
  final changed = _clearTransientGamificationStateInternal(store);
  if (changed) {
    store._emitChanged();
  }
}

void _suppressGamificationOverlaysDuringLogout(UserStateStore store) {
  final hadStateChange = !store._isLoggingOut ||
      !store._isResettingUserState ||
      !store._suppressGamificationOverlays;
  store._isLoggingOut = true;
  store._isResettingUserState = true;
  store._suppressGamificationOverlays = true;
  final hadQueueChange = _clearTransientGamificationStateInternal(store);
  if (hadStateChange || hadQueueChange) {
    store._emitChanged();
  }
}

void _restoreGamificationOverlaysAfterLogout(UserStateStore store) {
  final hadStateChange = store._isLoggingOut ||
      store._isResettingUserState ||
      store._suppressGamificationOverlays;
  store._isLoggingOut = false;
  store._isResettingUserState = false;
  store._suppressGamificationOverlays = false;
  if (hadStateChange) {
    store._emitChanged();
  }
}

bool _canQueueGamificationOverlays(
  UserStateStore store, {
  Map<String, dynamic>? userState,
}) {
  if (store._isLoggingOut ||
      store._isResettingUserState ||
      store._suppressGamificationOverlays) {
    return false;
  }

  final currentUserId = (store.userId ?? '').trim();
  if (currentUserId.isNotEmpty) return true;

  final rawUserId =
      (userState?['userId'] ?? userState?['id'] ?? '').toString().trim();
  return rawUserId.isNotEmpty;
}

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

String _today([DateTime Function()? nowProvider]) =>
    _dateKey((nowProvider ?? DateTime.now)().toLocal());

String _todayFrom(DateTime Function() calendarNowProvider) =>
    _dateKey(calendarNowProvider().toLocal());

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _normalizeFamilyId(String id) => id.trim().toLowerCase();

const String _templateUserIdPlaceholder = 'user_123';

bool _onboardingDone(UserStateStore store) {
  if (store._state == null) return false;
  final userState = _ensureUserStateRoot(store._state!);
  final meta = _map(userState['meta']);
  return meta['onboardingDone'] == true;
}

Future<void> _switchLocalScope(
  UserStateStore store, {
  String? userId,
  bool forceReload = false,
}) async {
  final normalizedUserId = _normalizedScopeUserId(userId);
  final currentUserId = _normalizedScopeUserId(store._activeLocalScopeUserId);

  final scopeChanged = normalizedUserId != currentUserId;
  if (!scopeChanged && !forceReload && store._state != null) {
    return;
  }

  store._scopeEpoch += 1;
  final switchEpoch = store._scopeEpoch;
  store._activeLocalScopeUserId = normalizedUserId;
  store._repo.setActiveUserScope(normalizedUserId);
  if (kDebugMode) {
    debugPrint(
      '[user_state_store] switching local scope: '
      'userId=${normalizedUserId ?? 'guest'} '
      '(epoch=$switchEpoch)',
    );
  }

  // Prevent stale in-memory data from a different authenticated account.
  if (scopeChanged) {
    store._state = null;
    store._error = null;
    _clearTransientGamificationStateInternal(store);
    _clearHydrationBaselinesInternal(store);
    store._emitChanged();
  }

  await _loadStore(
    store,
    expectedScopeEpoch: switchEpoch,
    force: true,
  );
}

String? _normalizedScopeUserId(String? userId) {
  final normalized = (userId ?? '').trim();
  return normalized.isEmpty ? null : normalized;
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

void _normalizeUserIdForActiveScope(
  UserStateStore store,
  Map<String, dynamic> userState,
) {
  final activeScopeUserId = _normalizedScopeUserId(
    store._activeLocalScopeUserId ?? store._repo.activeUserId,
  );
  final currentUserId = _normalizedScopeUserId(
    (userState['userId'] ?? userState['id'] ?? '').toString(),
  );

  final isTemplatePlaceholder = currentUserId == _templateUserIdPlaceholder;

  if (activeScopeUserId != null) {
    // Keep cross-account stale-write protection intact. We only rewrite
    // placeholder/empty ids that come from templates before auth identity
    // has been applied to local state.
    if (currentUserId == null || isTemplatePlaceholder) {
      userState['userId'] = activeScopeUserId;
      userState.remove('id');
    }
    return;
  }

  // In guest scope, strip template placeholder ids so persistence is not
  // blocked by repository guest-scope guards.
  if (isTemplatePlaceholder) {
    userState.remove('userId');
    userState.remove('id');
  }
}

String _activeViewDateKey(
  Map<String, dynamic> userState, {
  DateTime Function()? nowProvider,
  DateTime Function()? calendarNowProvider,
}) {
  final meta = _map(userState['meta']);
  final key = (meta['activeViewDateKey'] ?? '').toString();
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) return key;
  final effectiveCalendarNowProvider =
      calendarNowProvider ?? nowProvider ?? DateTime.now;
  return _todayFrom(effectiveCalendarNowProvider);
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
  _touchLastSavedAt(userState, nowProvider: store._nowProvider);

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

    if (!_isHabitExpectedForDate(habit, date)) {
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
  return HabitScheduleNormalizer.normalize(schedule);
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

bool _isHabitExpectedForDate(Map<String, dynamic> habit, DateTime date) {
  if (_isArchivedHabit(habit)) return false;
  if (!_wasHabitCreatedByDay(habit, date)) return false;
  return _isScheduledForDate(habit, date);
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
  return !_dateOnly(createdAt.toLocal()).isAfter(_dateOnly(day));
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

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

void _touchLastSavedAt(
  Map<String, dynamic> userState, {
  DateTime Function()? nowProvider,
}) {
  final meta = _map(userState['meta']);
  meta['lastSavedAt'] =
      (nowProvider ?? DateTime.now)().toUtc().toIso8601String();
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
  history['habitCompletionTimes'] = _map(history['habitCompletionTimes']);
  history['habitOccurrenceStatuses'] = _map(history['habitOccurrenceStatuses']);
  history['habitStreakBreaks'] = _map(history['habitStreakBreaks']);
  history['habitStreakShields'] = _map(history['habitStreakShields']);
  userState['history'] = history;
  return history;
}

Map<String, dynamic> _ensureClaimsRoot(Map<String, dynamic> userState) {
  final claims = _map(userState['claims']);
  claims['milestonesClaimed'] = _list(claims['milestonesClaimed'])
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty)
      .toSet()
      .toList(growable: false);
  claims['achievementRewardsClaimed'] =
      _list(claims['achievementRewardsClaimed'])
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toSet()
          .toList(growable: false);
  claims['prestigeClaimed'] = _list(claims['prestigeClaimed'])
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty)
      .toSet()
      .toList(growable: false);
  userState['claims'] = claims;
  return claims;
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

Map<String, dynamic> _ensureDailyMoodsRoot(Map<String, dynamic> userState) {
  final moods = _map(userState['dailyMoods']);
  userState['dailyMoods'] = moods;
  return moods;
}

bool _ensureActiveHabitIds(
  Map<String, dynamic> userState, {
  DateTime Function()? calendarNowProvider,
}) {
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
      final createdAt =
          (habit['createdAt'] ?? _today(calendarNowProvider ?? DateTime.now))
              .toString();
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

void _ensureDailyReset(
  UserStateStore store,
  Map<String, dynamic> userState, {
  DateTime Function()? nowProvider,
  DateTime Function()? calendarNowProvider,
  DateTime Function()? technicalNowProvider,
}) {
  final daily = _map(userState['daily']);
  final lastResetDate = (daily['lastResetDate'] ?? '').toString();
  final effectiveCalendarNowProvider =
      calendarNowProvider ?? store._calendarNowProvider;
  final effectiveTechnicalNowProvider =
      technicalNowProvider ?? store._nowProvider;
  final today = _todayFrom(effectiveCalendarNowProvider);

  if (lastResetDate == today) {
    userState['daily'] = daily;
    return;
  }

  final previousDayKey = lastResetDate;
  if (previousDayKey.isNotEmpty) {
    final activeHabits = _list(userState['activeHabits'])
        .whereType<Map>()
        .map((entry) => entry.cast<String, dynamic>())
        .toList();
    _finalizeHabitDayRollover(
      store,
      userState,
      dayKey: previousDayKey,
      activeHabits: activeHabits,
      nowProvider: effectiveTechnicalNowProvider,
    );
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

void _finalizeHabitDayRollover(
  UserStateStore store,
  Map<String, dynamic> userState, {
  required String dayKey,
  required List<Map<String, dynamic>> activeHabits,
  required DateTime Function() nowProvider,
}) {
  final authenticatedUserId =
      (store._currentSupabaseUserIdProvider() ?? '').trim();
  final history = _ensureHistoryRoot(userState);
  final habitCompletions = _map(history['habitCompletions']);
  final habitCountValues = _map(history['habitCountValues']);
  final habitSkips = _map(history['habitSkips']);
  final occurrenceStatuses = _map(history['habitOccurrenceStatuses']);
  final shields = _habitStreakShieldsRoot(userState);
  final breaks = _habitStreakBreaksRoot(userState);

  final previousDone = _map(habitCompletions[dayKey]);
  final previousCounts = _map(habitCountValues[dayKey]);
  final previousSkips = _map(habitSkips[dayKey]);
  final previousStatuses = _map(occurrenceStatuses[dayKey]);

  for (final habit in activeHabits) {
    final habitId = (habit['id'] ?? '').toString().trim();
    if (habitId.isEmpty) continue;
    final remoteHabitId = _habitRemoteIdValue(habit);
    final authenticatedRemoteHabit =
        authenticatedUserId.isNotEmpty && remoteHabitId != null;
    if (!_isHabitExpectedForDate(habit, _dateFromKey(dayKey))) {
      previousStatuses[habitId] = HabitOccurrenceStatus.notScheduled.key;
      continue;
    }

    final type = (habit['type'] ?? 'check').toString();
    final done = type == 'count'
        ? _safeNum(habit['progress'], fallback: 0) >=
            _safePositiveNum(habit['target'], fallback: 1)
        : habit['doneToday'] == true;
    final skipped = habit['skippedToday'] == true;

    previousSkips[habitId] = skipped;
    if (done && !skipped) {
      previousDone[habitId] = true;
      if (type == 'count') {
        previousCounts[habitId] = _safeNum(habit['progress'], fallback: 0);
      }
      previousStatuses[habitId] = HabitOccurrenceStatus.completed.key;
      continue;
    }

    if (authenticatedRemoteHabit) {
      previousDone[habitId] = false;
      previousStatuses[habitId] = HabitOccurrenceStatus.missed.key;
      continue;
    }

    final activeShield = _map(shields[habitId]);
    final shieldModel = activeShield.isNotEmpty
        ? ActiveStreakShield.fromJson(activeShield)
        : null;
    final protectedOccurrenceDateKey =
        shieldModel?.protectedOccurrenceDateKey?.trim() ?? '';
    final hasShield = shieldModel != null &&
        (shieldModel.isActive ||
            (protectedOccurrenceDateKey.isNotEmpty &&
                protectedOccurrenceDateKey == dayKey));
    if (hasShield) {
      previousDone[habitId] = false;
      previousStatuses[habitId] = _habitStreakTypeProtected;
      shields[habitId] = {
        ...activeShield,
        'status': 'consumed',
        'consumedAtMillis': nowProvider().millisecondsSinceEpoch,
        'protectedOccurrenceDateKey': dayKey,
      };
      continue;
    }

    previousDone[habitId] = false;
    previousStatuses[habitId] = HabitOccurrenceStatus.missed.key;

    final activeBreak = _recoverableStreakBreakForHabit(
      userState,
      habitId,
    );
    if (activeBreak != null &&
        (activeBreak['status'] ?? '').toString().trim() == 'recoverable') {
      continue;
    }

    final previousStreak = _currentHabitStreakBeforeDay(
      userState,
      habit,
      _dateFromKey(dayKey),
    );
    final breakId = 'streak_break_${habitId}_$dayKey';
    breaks[breakId] = RecoverableStreakBreak(
      id: breakId,
      userId: (userState['userId'] ?? userState['id'] ?? '').toString().trim(),
      habitId: habitId,
      brokenAtMillis: nowProvider().millisecondsSinceEpoch,
      missedOccurrenceDateKey: dayKey,
      previousStreak: previousStreak,
      currentStreakAfterBreak: 0,
      status: RecoverableStreakBreakStatus.recoverable,
    ).toJson();
  }

  habitCompletions[dayKey] = previousDone;
  habitCountValues[dayKey] = previousCounts;
  habitSkips[dayKey] = previousSkips;
  occurrenceStatuses[dayKey] = previousStatuses;
  history['habitCompletions'] = habitCompletions;
  history['habitCountValues'] = habitCountValues;
  history['habitSkips'] = habitSkips;
  history['habitOccurrenceStatuses'] = occurrenceStatuses;
  history['habitStreakBreaks'] = breaks;
  history['habitStreakShields'] = shields;
  userState['history'] = history;
}

int _currentHabitStreakBeforeDay(
  Map<String, dynamic> userState,
  Map<String, dynamic> habit,
  DateTime closedDay,
) {
  final continuityByDay = _extractHabitStreakContinuityByDay(
    userState,
    habit: habit,
  );
  final reference = closedDay.subtract(const Duration(days: 1));
  return _computeCurrentStreak(continuityByDay, reference);
}

Future<void> _loadStore(
  UserStateStore store, {
  int? expectedScopeEpoch,
  bool force = false,
}) async {
  if (store._loading) {
    if (!force) return;
    var spin = 0;
    while (store._loading && spin < 400) {
      spin += 1;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    if (store._loading) return;
  }

  final epochAtStart = expectedScopeEpoch ?? store._scopeEpoch;
  final scopeAtStart = _normalizedScopeUserId(store._activeLocalScopeUserId);

  store._loading = true;
  store._error = null;
  store._emitChanged();

  try {
    final loaded = await store._repo.loadOrCreate();
    if (epochAtStart != store._scopeEpoch ||
        scopeAtStart != _normalizedScopeUserId(store._activeLocalScopeUserId)) {
      if (kDebugMode) {
        debugPrint(
          '[user_state_store] discarded stale load result '
          '(startEpoch=$epochAtStart, currentEpoch=${store._scopeEpoch}, '
          'startScope=${scopeAtStart ?? 'guest'}, '
          'currentScope=${store._activeLocalScopeUserId ?? 'guest'})',
        );
      }
      return;
    }

    store._state = loaded;

    if (store._state != null) {
      final userState = _ensureUserStateRoot(store._state!);
      _normalizeUserIdForActiveScope(store, userState);
      _ensureDailyReset(
        store,
        userState,
        calendarNowProvider: store._calendarNowProvider,
        technicalNowProvider: store._nowProvider,
      );
      _expireStreakShieldsForLocalDate(
        userState,
        store._calendarNowProvider(),
      );
      _ensureActiveHabitIds(
        userState,
        calendarNowProvider: store._calendarNowProvider,
      );
      _ensureDiaryEntriesRoot(userState);
      _ensureDailyMoodsRoot(userState);
      _ensureDiaryRewardAppliedDateKeys(userState);
      _ensureTodosRoot(userState);
      final achievementSyncOutcome = _syncAchievementsFromCurrentHabits(
        store,
        userState,
      );
      if (store._achievementLevelRewardCoordinator.isEnabled) {
        await _claimCloudAchievementAndLevelRewardsBestEffort(
          store,
          achievementRecords: achievementSyncOutcome.newlyUnlockedRecords,
          resolvePendingFirst: true,
        );
      }
      _primeHydrationBaselineFromUserState(
        store,
        userState,
        XpMutationOrigin.hydration,
      );

      final viewKey = _activeViewDateKey(
        userState,
        calendarNowProvider: store._calendarNowProvider,
      );
      if (viewKey != _todayFrom(store._calendarNowProvider)) {
        _hydrateActiveHabitsForDate(userState, _dateFromKey(viewKey));
      }

      _touchLastSavedAt(userState, nowProvider: store._nowProvider);
      if (epochAtStart != store._scopeEpoch ||
          scopeAtStart !=
              _normalizedScopeUserId(store._activeLocalScopeUserId)) {
        if (kDebugMode) {
          debugPrint(
            '[user_state_store] skipped stale post-load save '
            '(startEpoch=$epochAtStart, currentEpoch=${store._scopeEpoch})',
          );
        }
        return;
      }
      await store._repo.save(store._state!);
      if (kDebugMode && store._debugStreakRecoverSeedEnabled) {
        await _seedDebugRecoverableStreakBreak(store);
      }
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
  _normalizeUserIdForActiveScope(store, userState);
  _ensureDailyReset(
    store,
    userState,
    calendarNowProvider: store._calendarNowProvider,
    technicalNowProvider: store._nowProvider,
  );
  _expireStreakShieldsForLocalDate(userState, store._calendarNowProvider());
  _ensureActiveHabitIds(
    userState,
    calendarNowProvider: store._calendarNowProvider,
  );
  _ensureDiaryEntriesRoot(userState);
  _ensureDailyMoodsRoot(userState);
  _ensureDiaryRewardAppliedDateKeys(userState);
  _ensureTodosRoot(userState);
  _ensureAchievementsRoot(userState);
  _sanitizeFeaturedAchievements(userState);

  final viewKey = _activeViewDateKey(
    userState,
    calendarNowProvider: store._calendarNowProvider,
  );
  if (viewKey != _todayFrom(store._calendarNowProvider)) {
    _hydrateActiveHabitsForDate(userState, _dateFromKey(viewKey));
  }

  _touchLastSavedAt(userState, nowProvider: store._nowProvider);

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
