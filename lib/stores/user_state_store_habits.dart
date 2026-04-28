part of 'user_state_store.dart';

const String _supabaseHabitsBackfillCompletedByUserKey =
    'supabaseHabitsBackfillCompletedByUser';
const String _supabaseHabitLogsBackfillCompletedByUserKey =
    'supabaseHabitLogsBackfillCompletedByUser';
const String _supabaseUserProgressBackfillCompletedByUserKey =
    'supabaseUserProgressBackfillCompletedByUser';

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

String? _normalizedRemoteHabitId(dynamic value) {
  final normalized = (value ?? '').toString().trim();
  if (normalized.isEmpty) return null;
  return normalized;
}

String? _habitRemoteIdValue(Map<String, dynamic> habit) {
  return _normalizedRemoteHabitId(
    habit['remoteId'] ?? habit['remoteHabitId'] ?? habit['supabaseHabitId'],
  );
}

Future<void> _persistHabitRemoteId(
  UserStateStore store, {
  required String localHabitId,
  required String remoteHabitId,
}) async {
  final normalizedLocalId = localHabitId.trim();
  final normalizedRemoteId = remoteHabitId.trim();
  if (normalizedLocalId.isEmpty || normalizedRemoteId.isEmpty) return;

  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);
  _ensureActiveHabitIds(userState);

  final activeHabits = _mutableActiveHabits(userState);
  final index = _activeHabitIndex(activeHabits, normalizedLocalId);
  if (index == -1) return;

  final current = Map<String, dynamic>.from(activeHabits[index]);
  final existingRemoteId = _habitRemoteIdValue(current);
  if (existingRemoteId == normalizedRemoteId) return;

  current['remoteId'] = normalizedRemoteId;
  activeHabits[index] = current;
  userState['activeHabits'] = activeHabits;
  await store.save(root);
}

Future<HabitBackfillSummary> _syncExistingLocalHabitsOnce(
  UserStateStore store, {
  bool force = false,
}) async {
  if (store._isSupabaseHabitsBackfillRunning) {
    _debugBackfill('habit backfill skipped: already running');
    return const HabitBackfillSummary(
      totalCandidates: 0,
      uploadedCount: 0,
      skippedCount: 0,
      failedCount: 0,
    );
  }

  store._isSupabaseHabitsBackfillRunning = true;
  try {
    if (store._state == null) {
      if (!store._loading) {
        await store.load();
      }
      if (store._state == null) {
        _debugBackfill('habit backfill skipped: local state unavailable');
        return const HabitBackfillSummary(
          totalCandidates: 0,
          uploadedCount: 0,
          skippedCount: 0,
          failedCount: 0,
        );
      }
    }

    final authenticatedUserId = _authenticatedSupabaseUserId();
    if (authenticatedUserId == null) {
      _debugBackfill('habit backfill skipped: no authenticated Supabase user');
      return const HabitBackfillSummary(
        totalCandidates: 0,
        uploadedCount: 0,
        skippedCount: 0,
        failedCount: 0,
      );
    }

    final localUserId = (store.userId ?? '').trim();
    if (localUserId.isEmpty || localUserId != authenticatedUserId) {
      _debugBackfill(
        'habit backfill skipped: local user does not match auth session',
      );
      return const HabitBackfillSummary(
        totalCandidates: 0,
        uploadedCount: 0,
        skippedCount: 0,
        failedCount: 0,
      );
    }

    final root = store._state!;
    final userState = _ensureUserStateRoot(root);
    final markerCompleted = _isBackfillCompletedForUser(
      userState,
      authenticatedUserId,
    );
    final hasEligibleCandidates = _countEligibleBackfillCandidates(userState) > 0;

    if (markerCompleted && !force && !hasEligibleCandidates) {
      _debugBackfill(
        'habit backfill skipped: completion marker already set for user',
      );
      return const HabitBackfillSummary(
        totalCandidates: 0,
        uploadedCount: 0,
        skippedCount: 0,
        failedCount: 0,
      );
    }

    final activeHabits = _list(userState['activeHabits'])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(_map(entry)))
        .toList(growable: false);

    final summary = await store._habitSyncService.backfillLocalHabitsWithoutRemoteId(
      localHabits: activeHabits,
      expectedLocalUserId: authenticatedUserId,
      onRemoteIdAssigned: ({
        required String localHabitId,
        required String remoteHabitId,
      }) =>
          _persistHabitRemoteId(
            store,
            localHabitId: localHabitId,
            remoteHabitId: remoteHabitId,
          ),
    );

    final updatedRoot = store._state;
    if (updatedRoot == null) return summary;

    final updatedUserState = _ensureUserStateRoot(updatedRoot);
    final remainingEligible = _countEligibleBackfillCandidates(updatedUserState);
    final shouldMarkCompleted = remainingEligible == 0 && summary.failedCount == 0;

    final wasCompleted = _isBackfillCompletedForUser(
      updatedUserState,
      authenticatedUserId,
    );
    if (shouldMarkCompleted != wasCompleted) {
      _setBackfillCompletedForUser(
        updatedUserState,
        authenticatedUserId,
        completed: shouldMarkCompleted,
      );
      await store.save(updatedRoot);
    }

    _debugBackfill(
      'habit backfill summary for "$authenticatedUserId": '
      'total=${summary.totalCandidates}, uploaded=${summary.uploadedCount}, '
      'skipped=${summary.skippedCount}, failed=${summary.failedCount}, '
      'remainingEligible=$remainingEligible, completed=$shouldMarkCompleted',
    );

    return summary;
  } catch (error) {
    _debugBackfill('habit backfill unexpected store error: $error');
    return const HabitBackfillSummary(
      totalCandidates: 0,
      uploadedCount: 0,
      skippedCount: 0,
      failedCount: 1,
    );
  } finally {
    store._isSupabaseHabitsBackfillRunning = false;
  }
}

Future<HabitLogBackfillSummary> _syncExistingLocalHabitLogsOnce(
  UserStateStore store, {
  bool force = false,
}) async {
  if (store._isSupabaseHabitLogsBackfillRunning) {
    _debugHabitLogBackfill('habit log backfill skipped: already running');
    return const HabitLogBackfillSummary(
      totalCandidates: 0,
      uploadedCount: 0,
      skippedCount: 0,
      failedCount: 0,
    );
  }

  store._isSupabaseHabitLogsBackfillRunning = true;
  try {
    if (store._state == null) {
      if (!store._loading) {
        await store.load();
      }
      if (store._state == null) {
        _debugHabitLogBackfill(
          'habit log backfill skipped: local state unavailable',
        );
        return const HabitLogBackfillSummary(
          totalCandidates: 0,
          uploadedCount: 0,
          skippedCount: 0,
          failedCount: 0,
        );
      }
    }

    final authenticatedUserId = _authenticatedSupabaseUserId();
    if (authenticatedUserId == null) {
      _debugHabitLogBackfill(
        'habit log backfill skipped: no authenticated Supabase user',
      );
      return const HabitLogBackfillSummary(
        totalCandidates: 0,
        uploadedCount: 0,
        skippedCount: 0,
        failedCount: 0,
      );
    }

    final localUserId = (store.userId ?? '').trim();
    if (localUserId.isEmpty || localUserId != authenticatedUserId) {
      _debugHabitLogBackfill(
        'habit log backfill skipped: local user does not match auth session',
      );
      return const HabitLogBackfillSummary(
        totalCandidates: 0,
        uploadedCount: 0,
        skippedCount: 0,
        failedCount: 0,
      );
    }

    final root = store._state!;
    final userState = _ensureUserStateRoot(root);
    final markerCompleted = _isHabitLogBackfillCompletedForUser(
      userState,
      authenticatedUserId,
    );

    if (markerCompleted && !force) {
      _debugHabitLogBackfill(
        'habit log backfill skipped: completion marker already set for user',
      );
      return const HabitLogBackfillSummary(
        totalCandidates: 0,
        uploadedCount: 0,
        skippedCount: 0,
        failedCount: 0,
      );
    }

    final candidates = _collectHistoricalHabitLogBackfillCandidates(userState);
    final summary = candidates.isEmpty
        ? const HabitLogBackfillSummary(
            totalCandidates: 0,
            uploadedCount: 0,
            skippedCount: 0,
            failedCount: 0,
          )
        : await store._habitLogSyncService.backfillHistoricalHabitLogs(
            candidates: candidates,
            expectedLocalUserId: authenticatedUserId,
          );

    final updatedRoot = store._state;
    if (updatedRoot == null) return summary;

    final updatedUserState = _ensureUserStateRoot(updatedRoot);
    final shouldMarkCompleted = summary.failedCount == 0;
    final wasCompleted = _isHabitLogBackfillCompletedForUser(
      updatedUserState,
      authenticatedUserId,
    );
    if (shouldMarkCompleted != wasCompleted) {
      _setHabitLogBackfillCompletedForUser(
        updatedUserState,
        authenticatedUserId,
        completed: shouldMarkCompleted,
      );
      await store.save(updatedRoot);
    }

    _debugHabitLogBackfill(
      'habit log backfill summary for "$authenticatedUserId": '
      'total=${summary.totalCandidates}, uploaded=${summary.uploadedCount}, '
      'skipped=${summary.skippedCount}, failed=${summary.failedCount}, '
      'completed=$shouldMarkCompleted',
    );
    return summary;
  } catch (error) {
    _debugHabitLogBackfill('habit log backfill unexpected store error: $error');
    return const HabitLogBackfillSummary(
      totalCandidates: 0,
      uploadedCount: 0,
      skippedCount: 0,
      failedCount: 1,
    );
  } finally {
    store._isSupabaseHabitLogsBackfillRunning = false;
  }
}

Future<bool> _syncSupabaseUserProgressBackfillOnce(
  UserStateStore store, {
  bool force = false,
}) async {
  if (store._isSupabaseUserProgressBackfillRunning) {
    _debugUserProgressBackfill('progress backfill skipped: already running');
    return false;
  }

  store._isSupabaseUserProgressBackfillRunning = true;
  try {
    if (store._state == null) {
      if (!store._loading) {
        await store.load();
      }
      if (store._state == null) {
        _debugUserProgressBackfill(
          'progress backfill skipped: local state unavailable',
        );
        return false;
      }
    }

    final authenticatedUserId = _authenticatedSupabaseUserId();
    if (authenticatedUserId == null) {
      _debugUserProgressBackfill(
        'progress backfill skipped: no authenticated Supabase user',
      );
      return false;
    }

    final localUserId = (store.userId ?? '').trim();
    if (localUserId.isEmpty || localUserId != authenticatedUserId) {
      _debugUserProgressBackfill(
        'progress backfill skipped: local user does not match auth session',
      );
      return false;
    }

    final root = store._state!;
    final userState = _ensureUserStateRoot(root);
    final markerCompleted = _isUserProgressBackfillCompletedForUser(
      userState,
      authenticatedUserId,
    );

    if (markerCompleted && !force) {
      _debugUserProgressBackfill(
        'progress backfill skipped: completion marker already set for user',
      );
      return false;
    }

    final snapshot = _buildProgressSyncSnapshot(userState);
    final synced = await store._userProgressSyncService
        .syncCurrentProgressFromLocalState(
      level: snapshot.level,
      totalXp: snapshot.xp,
      currentLevelXp: snapshot.xpInCurrentLevel,
      nextLevelXp: snapshot.xpToNextLevel,
      ambarBalance: snapshot.coins,
      expectedLocalUserId: authenticatedUserId,
    );

    if (!synced) {
      _debugUserProgressBackfill(
        'progress backfill failed for "$authenticatedUserId"',
      );
      return false;
    }

    final wasCompleted = _isUserProgressBackfillCompletedForUser(
      userState,
      authenticatedUserId,
    );
    if (!wasCompleted) {
      _setUserProgressBackfillCompletedForUser(
        userState,
        authenticatedUserId,
        completed: true,
      );
      await store.save(root);
    }

    _debugUserProgressBackfill(
      'progress backfill completed for "$authenticatedUserId": '
      'xp=${snapshot.xp}, level=${snapshot.level}, coins=${snapshot.coins}',
    );
    return true;
  } catch (error) {
    _debugUserProgressBackfill('progress backfill unexpected store error: $error');
    return false;
  } finally {
    store._isSupabaseUserProgressBackfillRunning = false;
  }
}

List<HabitLogBackfillCandidate> _collectHistoricalHabitLogBackfillCandidates(
  Map<String, dynamic> userState,
) {
  final history = _ensureHistoryRoot(userState);
  final completionsRoot = _map(history['habitCompletions']);
  final skipsRoot = _map(history['habitSkips']);
  final countValuesRoot = _map(history['habitCountValues']);

  final noteRoots = <Map<String, dynamic>>[
    _map(history['habitLogNotes']),
    _map(history['habitNotes']),
    _map(history['habitDailyNotes']),
    _map(history['habitCompletionNotes']),
  ];

  final activeHabitsById = <String, Map<String, dynamic>>{};
  for (final entry in _list(userState['activeHabits']).whereType<Map>()) {
    final habit = Map<String, dynamic>.from(_map(entry));
    final habitId = _habitIdValue(habit);
    if (habitId == null || habitId.trim().isEmpty) continue;
    activeHabitsById[habitId.trim()] = habit;
  }

  final dateKeys = <String>{
    ...completionsRoot.keys.map((key) => key.toString()),
    ...skipsRoot.keys.map((key) => key.toString()),
    ...countValuesRoot.keys.map((key) => key.toString()),
    ..._noteDateKeys(noteRoots),
  }.toList()
    ..sort();

  final candidates = <HabitLogBackfillCandidate>[];

  for (final dateKey in dateKeys) {
    final parsedDate = _parseHistoryDateKey(dateKey);
    if (parsedDate == null) continue;

    final dayCompletions = _map(completionsRoot[dateKey]);
    final daySkips = _map(skipsRoot[dateKey]);
    final dayCountValues = _map(countValuesRoot[dateKey]);

    final dayHabitIds = <String>{
      ...dayCompletions.keys.map((key) => key.toString().trim()),
      ...daySkips.keys.map((key) => key.toString().trim()),
      ...dayCountValues.keys.map((key) => key.toString().trim()),
      ..._noteHabitIdsForDay(noteRoots, dateKey),
    }.where((habitId) => habitId.isNotEmpty).toList()
      ..sort();

    for (final habitId in dayHabitIds) {
      final localHabit = Map<String, dynamic>.from(
        activeHabitsById[habitId] ?? <String, dynamic>{'id': habitId},
      );
      localHabit['id'] = (localHabit['id'] ?? habitId).toString().trim();

      final hasCompletionEntry = dayCompletions.containsKey(habitId);
      final hasSkipEntry = daySkips.containsKey(habitId);
      final hasCountEntry = dayCountValues.containsKey(habitId);

      final isCompleted = hasCompletionEntry
          ? _dynamicToBool(dayCompletions[habitId])
          : null;
      final isSkipped = hasSkipEntry ? _dynamicToBool(daySkips[habitId]) : null;
      final countValue = hasCountEntry
          ? _safeNum(dayCountValues[habitId], fallback: 0)
              .clamp(0, double.infinity)
          : 0;
      final note = _extractHistoryNoteForDayHabit(
        noteRoots: noteRoots,
        dateKey: dateKey,
        habitId: habitId,
      );

      candidates.add(
        HabitLogBackfillCandidate(
          localHabit: localHabit,
          date: parsedDate,
          isCompleted: isCompleted,
          isSkipped: isSkipped,
          countValue: countValue,
          note: note,
        ),
      );
    }
  }

  return candidates;
}

bool _isHabitLogBackfillCompletedForUser(
  Map<String, dynamic> userState,
  String userId,
) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return false;

  final byUser = _habitLogBackfillCompletedByUser(userState);
  return byUser[normalizedUserId] == true;
}

void _setHabitLogBackfillCompletedForUser(
  Map<String, dynamic> userState,
  String userId, {
  required bool completed,
}) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return;

  final byUser = _habitLogBackfillCompletedByUser(userState);
  if (completed) {
    byUser[normalizedUserId] = true;
  } else {
    byUser.remove(normalizedUserId);
  }

  final meta = _map(userState['meta']);
  meta[_supabaseHabitLogsBackfillCompletedByUserKey] = byUser;
  userState['meta'] = meta;
}

Map<String, dynamic> _habitLogBackfillCompletedByUser(
  Map<String, dynamic> userState,
) {
  final meta = _map(userState['meta']);
  final byUser = _map(meta[_supabaseHabitLogsBackfillCompletedByUserKey]);
  meta[_supabaseHabitLogsBackfillCompletedByUserKey] = byUser;
  userState['meta'] = meta;
  return byUser;
}

bool _isUserProgressBackfillCompletedForUser(
  Map<String, dynamic> userState,
  String userId,
) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return false;

  final byUser = _userProgressBackfillCompletedByUser(userState);
  return byUser[normalizedUserId] == true;
}

void _setUserProgressBackfillCompletedForUser(
  Map<String, dynamic> userState,
  String userId, {
  required bool completed,
}) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return;

  final byUser = _userProgressBackfillCompletedByUser(userState);
  if (completed) {
    byUser[normalizedUserId] = true;
  } else {
    byUser.remove(normalizedUserId);
  }

  final meta = _map(userState['meta']);
  meta[_supabaseUserProgressBackfillCompletedByUserKey] = byUser;
  userState['meta'] = meta;
}

Map<String, dynamic> _userProgressBackfillCompletedByUser(
  Map<String, dynamic> userState,
) {
  final meta = _map(userState['meta']);
  final byUser = _map(meta[_supabaseUserProgressBackfillCompletedByUserKey]);
  meta[_supabaseUserProgressBackfillCompletedByUserKey] = byUser;
  userState['meta'] = meta;
  return byUser;
}

Set<String> _noteDateKeys(List<Map<String, dynamic>> noteRoots) {
  final keys = <String>{};
  for (final noteRoot in noteRoots) {
    for (final key in noteRoot.keys) {
      final dateKey = key.toString();
      if (_parseHistoryDateKey(dateKey) == null) continue;
      keys.add(dateKey);
    }
  }
  return keys;
}

Set<String> _noteHabitIdsForDay(
  List<Map<String, dynamic>> noteRoots,
  String dateKey,
) {
  final habitIds = <String>{};
  for (final noteRoot in noteRoots) {
    final dayMap = _map(noteRoot[dateKey]);
    for (final key in dayMap.keys) {
      final habitId = key.toString().trim();
      if (habitId.isEmpty) continue;
      habitIds.add(habitId);
    }
  }
  return habitIds;
}

DateTime? _parseHistoryDateKey(String key) {
  final normalized = key.trim();
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(normalized)) {
    return null;
  }

  final parts = normalized.split('-');
  if (parts.length != 3) return null;

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;

  if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }

  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }

  return parsed;
}

String? _extractHistoryNoteForDayHabit({
  required List<Map<String, dynamic>> noteRoots,
  required String dateKey,
  required String habitId,
}) {
  for (final noteRoot in noteRoots) {
    final dayMap = _map(noteRoot[dateKey]);
    final dayValue = _nullableTrim(dayMap[habitId]);
    if (dayValue != null) return dayValue;

    final habitMap = _map(noteRoot[habitId]);
    final reverseValue = _nullableTrim(habitMap[dateKey]);
    if (reverseValue != null) return reverseValue;
  }

  return null;
}

String? _nullableTrim(dynamic value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}

String? _authenticatedSupabaseUserId() {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id.trim();
    if (userId == null || userId.isEmpty) return null;
    return userId;
  } catch (_) {
    return null;
  }
}

int _countEligibleBackfillCandidates(Map<String, dynamic> userState) {
  final activeHabits = _list(userState['activeHabits'])
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(_map(entry)))
      .toList(growable: false);

  var count = 0;
  for (final habit in activeHabits) {
    final hasRemoteId = _habitRemoteIdValue(habit);
    if (hasRemoteId != null) continue;

    final localHabitId = _habitIdValue(habit);
    final isDeleted = habit['deleted'] == true || habit['isDeleted'] == true;
    final name = (habit['name'] ?? habit['title'] ?? '').toString().trim();

    if (isDeleted || localHabitId == null || localHabitId.trim().isEmpty) {
      continue;
    }
    if (name.isEmpty) continue;
    count += 1;
  }

  return count;
}

bool _isBackfillCompletedForUser(
  Map<String, dynamic> userState,
  String userId,
) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return false;

  final byUser = _backfillCompletedByUser(userState);
  return byUser[normalizedUserId] == true;
}

void _setBackfillCompletedForUser(
  Map<String, dynamic> userState,
  String userId, {
  required bool completed,
}) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return;

  final byUser = _backfillCompletedByUser(userState);
  if (completed) {
    byUser[normalizedUserId] = true;
  } else {
    byUser.remove(normalizedUserId);
  }

  final meta = _map(userState['meta']);
  meta[_supabaseHabitsBackfillCompletedByUserKey] = byUser;
  userState['meta'] = meta;
}

Map<String, dynamic> _backfillCompletedByUser(Map<String, dynamic> userState) {
  final meta = _map(userState['meta']);
  final byUser = _map(meta[_supabaseHabitsBackfillCompletedByUserKey]);
  meta[_supabaseHabitsBackfillCompletedByUserKey] = byUser;
  userState['meta'] = meta;
  return byUser;
}

void _debugBackfill(String message) {
  if (!kDebugMode) return;
  debugPrint('[habit_backfill] $message');
}

void _debugHabitLogBackfill(String message) {
  if (!kDebugMode) return;
  debugPrint('[habit_log_backfill] $message');
}

void _debugUserProgressBackfill(String message) {
  if (!kDebugMode) return;
  debugPrint('[user_progress_backfill] $message');
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

  final index = _activeHabitIndex(activeHabits, normalizedId);
  if (index == -1) return;

  final removedHabit = Map<String, dynamic>.from(activeHabits[index]);
  activeHabits.removeAt(index);

  userState['activeHabits'] = activeHabits;

  if (purgeHistory) {
    _removeHabitFromHistory(userState, habitId: normalizedId);
  }

  await store.save(root);
  unawaited(
    store._habitSyncService.syncHabitDeleted(
      localHabitId: normalizedId,
      localHabitSnapshot: removedHabit,
      expectedLocalUserId: store.userId,
    ),
  );
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
  final initialRemoteId = _habitRemoteIdValue(habitDef);

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
    if (initialRemoteId != null) 'remoteId': initialRemoteId,
  });

  userState['activeHabits'] = activeHabits;
  await store.save(root);

  final createdHabit = Map<String, dynamic>.from(activeHabits.last);
  unawaited(
    store._habitSyncService.syncHabitCreated(
      localHabit: createdHabit,
      sortOrder: activeHabits.length - 1,
      expectedLocalUserId: store.userId,
      onRemoteIdAssigned: ({
        required String localHabitId,
        required String remoteHabitId,
      }) =>
          _persistHabitRemoteId(
            store,
            localHabitId: localHabitId,
            remoteHabitId: remoteHabitId,
          ),
    ),
  );
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
  final initialRemoteId = _habitRemoteIdValue(habit);

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
    if (initialRemoteId != null) 'remoteId': initialRemoteId,
  });

  userState['activeHabits'] = activeHabits;
  await store.save(root);

  final createdHabit = Map<String, dynamic>.from(activeHabits.last);
  unawaited(
    store._habitSyncService.syncHabitCreated(
      localHabit: createdHabit,
      sortOrder: activeHabits.length - 1,
      expectedLocalUserId: store.userId,
      onRemoteIdAssigned: ({
        required String localHabitId,
        required String remoteHabitId,
      }) =>
          _persistHabitRemoteId(
            store,
            localHabitId: localHabitId,
            remoteHabitId: remoteHabitId,
          ),
    ),
  );
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
  final wasArchived =
      current['archived'] == true || current['isArchived'] == true;

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

  final patchRemoteId = _habitRemoteIdValue(patch);
  if (patchRemoteId != null) {
    current['remoteId'] = patchRemoteId;
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

  final nowArchived =
      current['archived'] == true || current['isArchived'] == true;
  final syncedHabit = Map<String, dynamic>.from(current);
  if (nowArchived != wasArchived) {
    unawaited(
      store._habitSyncService.syncHabitArchived(
        localHabit: syncedHabit,
        sortOrder: index,
        expectedLocalUserId: store.userId,
      ),
    );
    return;
  }

  unawaited(
    store._habitSyncService.syncHabitUpdated(
      localHabit: syncedHabit,
      sortOrder: index,
      expectedLocalUserId: store.userId,
    ),
  );
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
  final achievementSyncOutcome = _syncAchievementsFromCurrentHabits(
    store,
    userState,
    enqueueVisualTrigger: true,
  );

  await store.save(root);
  _queueBestEffortAchievementUnlockSync(
    store,
    userState: userState,
    records: achievementSyncOutcome.newlyUnlockedRecords,
  );
  if (progressResult.xpGain != 0 || progressResult.coinsGain != 0) {
    _queueBestEffortProgressAndRewardSync(
      store,
      userState: userState,
      xpDelta: progressResult.xpGain,
      coinsDelta: progressResult.coinsGain,
      source: 'habit_completion',
      xpReason: 'habit_completion_reward',
      currencyReason: 'habit_completion_reward',
    );
  }
  for (final reward in achievementSyncOutcome.appliedRewards) {
    _queueBestEffortProgressAndRewardSync(
      store,
      userState: userState,
      xpDelta: reward.rewardXp,
      coinsDelta: reward.rewardAmber,
      source: 'achievement_unlocked',
      xpReason: 'achievement_unlocked:${reward.achievementId}',
      currencyReason: 'achievement_unlocked:${reward.achievementId}',
    );
  }
  _queueBestEffortHabitLogSyncForDate(
    store,
    userState: userState,
    habit: habit,
    habitId: habitId,
    date: DateTime.now(),
  );
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
  final achievementSyncOutcome = _syncAchievementsFromCurrentHabits(
    store,
    userState,
    enqueueVisualTrigger: true,
  );

  await store.save(root);
  _queueBestEffortAchievementUnlockSync(
    store,
    userState: userState,
    records: achievementSyncOutcome.newlyUnlockedRecords,
  );
  if (progressResult.xpGain != 0 || progressResult.coinsGain != 0) {
    _queueBestEffortProgressAndRewardSync(
      store,
      userState: userState,
      xpDelta: progressResult.xpGain,
      coinsDelta: progressResult.coinsGain,
      source: 'habit_completion',
      xpReason: 'habit_completion_reward',
      currencyReason: 'habit_completion_reward',
    );
  }
  for (final reward in achievementSyncOutcome.appliedRewards) {
    _queueBestEffortProgressAndRewardSync(
      store,
      userState: userState,
      xpDelta: reward.rewardXp,
      coinsDelta: reward.rewardAmber,
      source: 'achievement_unlocked',
      xpReason: 'achievement_unlocked:${reward.achievementId}',
      currencyReason: 'achievement_unlocked:${reward.achievementId}',
    );
  }
  _queueBestEffortHabitLogSyncForDate(
    store,
    userState: userState,
    habit: habit,
    habitId: habitId,
    date: DateTime.now(),
  );
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
  _queueBestEffortHabitLogSyncForDate(
    store,
    userState: userState,
    habit: habit,
    habitId: habitId,
    date: date,
    isCompletedOverride: !currentlyDone,
  );
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

  final syncHabit = _activeHabitSnapshotForSync(userState, habitId);
  if (syncHabit != null) {
    _queueBestEffortHabitLogSyncForDate(
      store,
      userState: userState,
      habit: syncHabit,
      habitId: habitId,
      date: date,
      isCompletedOverride: done,
      isSkippedOverride: false,
    );
  }
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

  final syncHabit = _activeHabitSnapshotForSync(userState, habitId);
  if (syncHabit != null) {
    _queueBestEffortHabitLogSyncForDate(
      store,
      userState: userState,
      habit: syncHabit,
      habitId: habitId,
      date: date,
      isSkippedOverride: skipped,
      isCompletedOverride: skipped ? false : null,
      countValueOverride: skipped ? 0 : null,
    );
  }
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
  _queueBestEffortHabitLogSyncForDate(
    store,
    userState: userState,
    habit: habit,
    habitId: habitId,
    date: date,
    isCompletedOverride: safeValue >= target,
    isSkippedOverride: false,
    countValueOverride: safeValue,
  );
}

Map<String, dynamic>? _activeHabitSnapshotForSync(
  Map<String, dynamic> userState,
  String habitId,
) {
  final activeHabits = _list(userState['activeHabits'])
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(_map(entry)))
      .toList(growable: false);
  final index = _activeHabitIndex(activeHabits, habitId);
  if (index == -1) return null;
  return Map<String, dynamic>.from(activeHabits[index]);
}

void _queueBestEffortHabitLogSyncForDate(
  UserStateStore store, {
  required Map<String, dynamic> userState,
  required Map<String, dynamic> habit,
  required String habitId,
  required DateTime date,
  bool? isCompletedOverride,
  bool? isSkippedOverride,
  num? countValueOverride,
}) {
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final dayKey = _dateKey(normalizedDate);
  final history = _ensureHistoryRoot(userState);

  final dayCompletions = _map(_map(history['habitCompletions'])[dayKey]);
  final daySkips = _map(_map(history['habitSkips'])[dayKey]);
  final dayCountValues = _map(_map(history['habitCountValues'])[dayKey]);

  final isCompleted =
      isCompletedOverride ?? _dynamicToBool(dayCompletions[habitId]);
  final isSkipped = isSkippedOverride ?? _dynamicToBool(daySkips[habitId]);
  final countValue = _isCountHabit(habit)
      ? (countValueOverride ??
          _safeNum(dayCountValues[habitId], fallback: 0).clamp(0, double.infinity))
      : null;

  final syncedHabit = Map<String, dynamic>.from(habit);
  if ((syncedHabit['id'] ?? '').toString().trim().isEmpty) {
    syncedHabit['id'] = habitId;
  }

  unawaited(
    store._habitLogSyncService.syncDailyLogForHabit(
      localHabit: syncedHabit,
      date: normalizedDate,
      isCompleted: isCompleted,
      isSkipped: isSkipped,
      countValue: countValue,
      expectedLocalUserId: store.userId,
    ),
  );
}

bool _dynamicToBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value > 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
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
