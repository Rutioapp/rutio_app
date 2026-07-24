part of 'user_state_store.dart';

HabitRepository _habitRepositoryForStore(UserStateStore store) {
  return store._habitRepository ??= HabitRepository();
}

HabitLogRepository _habitLogRepositoryForStore(UserStateStore store) {
  return store._habitLogRepository ??= HabitLogRepository();
}

const HabitRewardCalculator _habitRewardCalculator = HabitRewardCalculator();

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

String? _cloudRewardHabitId(Map<String, dynamic> habit) {
  final candidates = <Object?>[
    habit['remoteId'],
    habit['remoteHabitId'],
    habit['supabaseHabitId'],
  ];
  for (final candidate in candidates) {
    final normalized = (candidate ?? '').toString().trim().toLowerCase();
    if (normalized.isEmpty) continue;
    if (HabitRemoteMapper.isUuid(normalized)) {
      return normalized;
    }
  }
  return null;
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
  _ensureDailyReset(userState, nowProvider: store._nowProvider);
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

Future<void> _syncHabitsFromRemoteBestEffort(UserStateStore store) async {
  await _runHabitsRemotePull(store, source: 'manual');
}

Future<void> _maybeSyncHabitsFromRemoteBestEffort(
  UserStateStore store, {
  bool ignoreCooldown = false,
}) async {
  final authenticatedUserId = _currentHabitPullAuthenticatedUserId(store);
  if (!_shouldSyncHabitsForCurrentScope(
    store,
    authenticatedUserId: authenticatedUserId,
  )) {
    return;
  }
  if (authenticatedUserId == null) {
    return;
  }
  if (store._isHabitsRemotePullRunning) {
    _debugHabitPull('auto pull skipped: already running');
    return;
  }
  if (store._isSupabaseHabitsBackfillRunning ||
      store._isSupabaseHabitLogsBackfillRunning ||
      store._isSupabaseUserProgressBackfillRunning) {
    _debugHabitPull('auto pull skipped: backfill or restore already running');
    return;
  }

  final now = store._nowProvider();
  final lastAttemptAt = store._lastHabitsRemotePullAttemptAt;
  if (!ignoreCooldown &&
      lastAttemptAt != null &&
      now.difference(lastAttemptAt) < UserStateStore.habitsAutoPullCooldown) {
    _debugHabitPull(
      'auto pull skipped: cooldown active '
      '(${now.difference(lastAttemptAt).inMinutes}m since last attempt)',
    );
    return;
  }

  await _runHabitsRemotePull(store, source: ignoreCooldown ? 'manual' : 'auto');
}

Future<void> _runHabitsRemotePull(
  UserStateStore store, {
  required String source,
}) async {
  final authenticatedUserId = _currentHabitPullAuthenticatedUserId(store);
  if (!_shouldSyncHabitsForCurrentScope(
    store,
    authenticatedUserId: authenticatedUserId,
  )) {
    return;
  }
  if (authenticatedUserId == null) {
    return;
  }
  if (store._isHabitsRemotePullRunning) {
    _debugHabitPull('$source pull skipped: already running');
    return;
  }

  store._isHabitsRemotePullRunning = true;
  store._lastHabitsRemotePullAttemptAt = store._nowProvider();
  final scopeEpochAtStart = store._scopeEpoch;
  final scopeUserAtStart =
      _normalizedScopeUserId(store._activeLocalScopeUserId);

  try {
    if (store._state == null) {
      await store.load();
    }

    final habitsResult =
        await _habitRepositoryForStore(store).fetchHabitsForCurrentUser();
    if (!habitsResult.isSuccess) {
      _debugHabitPull(
        '$source pull failed while fetching habits: '
        '${habitsResult.error?.code.name}: ${habitsResult.error?.message}',
      );
      return;
    }

    final remoteHabits = habitsResult.data ?? const <RemoteHabit>[];
    final remoteHabitScopeValidation = _validateRemoteHabitsScopeForPull(
      remoteHabits,
      authenticatedUserId: authenticatedUserId,
    );
    if (!remoteHabitScopeValidation.isSafe) {
      _debugHabitPull(
        '$source pull aborted: unsafe remote habit scope detected '
        '(${remoteHabitScopeValidation.reason})',
      );
      return;
    }

    final remoteLogs = <RemoteHabitLog>[];
    for (final remoteHabit in remoteHabits) {
      final remoteHabitId = (remoteHabit.id ?? '').trim();
      if (remoteHabitId.isEmpty) continue;

      final logsResult =
          await _habitLogRepositoryForStore(store).fetchLogsForHabit(
        remoteHabitId,
      );
      if (!logsResult.isSuccess) {
        _debugHabitPull(
          '$source pull failed while fetching logs for remote habit '
          '"$remoteHabitId": ${logsResult.error?.code.name}: '
          '${logsResult.error?.message}',
        );
        return;
      }

      final scopedLogs = logsResult.data ?? const <RemoteHabitLog>[];
      final remoteLogScopeValidation = _validateRemoteHabitLogsScopeForPull(
        scopedLogs,
        authenticatedUserId: authenticatedUserId,
        allowedRemoteHabitIds: <String>{remoteHabitId},
      );
      if (!remoteLogScopeValidation.isSafe) {
        _debugHabitPull(
          '$source pull aborted: unsafe remote habit log scope detected '
          'for remoteHabitId="$remoteHabitId" '
          '(${remoteLogScopeValidation.reason})',
        );
        return;
      }
      remoteLogs.addAll(scopedLogs);
    }

    if (scopeEpochAtStart != store._scopeEpoch ||
        scopeUserAtStart !=
            _normalizedScopeUserId(store._activeLocalScopeUserId)) {
      _debugHabitPull('$source pull skipped: scope changed during fetch');
      return;
    }

    final root = store._state;
    if (root == null) {
      _debugHabitPull('$source pull skipped: local state unavailable');
      return;
    }

    final userState = _ensureUserStateRoot(root);
    _ensureDailyReset(userState, nowProvider: store._nowProvider);
    final streakShieldExpired = _expireStreakShieldsForLocalDate(
      userState,
      store._nowProvider(),
    );
    _ensureActiveHabitIds(userState);

    final mergedHabits = _mergeRemoteHabitsIntoLocalState(
      localHabits: _mutableActiveHabits(userState),
      remoteHabits: remoteHabits,
      authenticatedUserId: authenticatedUserId,
    );
    final mergedLogs = _mergeRemoteHabitLogsIntoLocalState(
      userState: userState,
      activeHabits: mergedHabits.habits,
      remoteLogs: remoteLogs,
      authenticatedUserId: authenticatedUserId,
    );

    if (!mergedHabits.changed && !mergedLogs.changed && !streakShieldExpired) {
      store._lastHabitsRemotePullSuccessAt = store._nowProvider();
      _debugHabitPull('$source pull completed: no local habit changes applied');
      return;
    }

    userState['activeHabits'] = mergedHabits.habits;
    _hydrateActiveHabitsForDate(
        userState,
        _dateFromKey(
          _activeViewDateKey(userState, nowProvider: store._nowProvider),
        ));
    root['userState'] = userState;
    await store.save(root);
    store._lastHabitsRemotePullSuccessAt = store._nowProvider();
  } catch (error) {
    _debugHabitPull('$source pull unexpected error: $error');
  } finally {
    store._isHabitsRemotePullRunning = false;
  }
}

bool _shouldSyncHabitsForCurrentScope(
  UserStateStore store, {
  required String? authenticatedUserId,
}) {
  if (RutioRuntimeProfile.isDemo) {
    _debugHabitPull('pull skipped: demo runtime profile is active');
    return false;
  }

  if (authenticatedUserId == null) {
    _debugHabitPull('pull skipped: no authenticated Supabase user');
    return false;
  }

  final localUserId = (store.userId ?? '').trim();
  if (localUserId.isEmpty || localUserId != authenticatedUserId) {
    _debugHabitPull(
      'pull skipped: local scoped user does not match auth session',
    );
    return false;
  }

  if (localUserId == DemoSeedScope.userId) {
    _debugHabitPull('pull skipped: demo local scope is active');
    return false;
  }

  return true;
}

String? _currentHabitPullAuthenticatedUserId(UserStateStore store) {
  final rawUserId = store._currentSupabaseUserIdProvider();
  final normalized = (rawUserId ?? '').trim();
  return normalized.isEmpty ? null : normalized;
}

_HabitRemoteMergeResult _pruneForeignRemoteHabitsFromLocalState({
  required List<Map<String, dynamic>> localHabits,
  required String authenticatedUserId,
}) {
  if (authenticatedUserId.trim().isEmpty) {
    return _HabitRemoteMergeResult(
      habits: localHabits
          .map((habit) => Map<String, dynamic>.from(habit))
          .toList(growable: false),
      changed: false,
    );
  }

  final prunedHabits = <Map<String, dynamic>>[];
  var changed = false;

  for (final habit in localHabits) {
    final copy = Map<String, dynamic>.from(habit);
    if (_isClearlyForeignRemoteOwnedHabit(
      copy,
      authenticatedUserId: authenticatedUserId,
    )) {
      changed = true;
      _debugHabitPull(
        'pruned local habit with foreign remote ownership metadata: '
        'localHabitId="${_habitIdValue(copy) ?? ''}" '
        'remoteHabitId="${_habitRemoteIdValue(copy) ?? ''}" '
        'ownerUserId="${_remoteHabitOwnerUserIdValue(copy) ?? ''}"',
      );
      continue;
    }

    prunedHabits.add(copy);
  }

  return _HabitRemoteMergeResult(habits: prunedHabits, changed: changed);
}

class _HabitRemoteMergeResult {
  const _HabitRemoteMergeResult({
    required this.habits,
    required this.changed,
  });

  final List<Map<String, dynamic>> habits;
  final bool changed;
}

class _HabitLogRemoteMergeResult {
  const _HabitLogRemoteMergeResult({required this.changed});

  final bool changed;
}

_HabitRemoteMergeResult _mergeRemoteHabitsIntoLocalState({
  required List<Map<String, dynamic>> localHabits,
  required List<RemoteHabit> remoteHabits,
  required String authenticatedUserId,
}) {
  if (authenticatedUserId.trim().isEmpty) {
    return _HabitRemoteMergeResult(
      habits: localHabits
          .map((habit) => Map<String, dynamic>.from(habit))
          .toList(growable: false),
      changed: false,
    );
  }

  final prunedLocalHabits = _pruneForeignRemoteHabitsFromLocalState(
    localHabits: localHabits,
    authenticatedUserId: authenticatedUserId,
  );
  final mergedHabits = prunedLocalHabits.habits.toList(growable: true);
  final localIndexesByRemoteId = <String, int>{};
  for (var index = 0; index < mergedHabits.length; index += 1) {
    final remoteId = _habitRemoteIdValue(mergedHabits[index]);
    if (remoteId == null || localIndexesByRemoteId.containsKey(remoteId)) {
      continue;
    }
    localIndexesByRemoteId[remoteId] = index;
  }

  var changed = prunedLocalHabits.changed;

  for (final remoteHabit in remoteHabits) {
    if (!_isRemoteHabitScopedToUser(
      remoteHabit,
      authenticatedUserId: authenticatedUserId,
    )) {
      _debugHabitPull(
        'skipped remote habit outside authenticated scope: '
        'habitId="${remoteHabit.id ?? ''}" userId="${remoteHabit.userId}"',
      );
      continue;
    }

    final remoteHabitId = (remoteHabit.id ?? '').trim();
    if (remoteHabitId.isEmpty) continue;

    final existingIndex = localIndexesByRemoteId[remoteHabitId];
    if (existingIndex != null) {
      final localHabit = mergedHabits[existingIndex];
      if (!_areHabitTypesCompatible(localHabit, remoteHabit)) {
        continue;
      }
      if (!_shouldReplaceLocalHabitWithRemote(
        localHabit: localHabit,
        remoteHabit: remoteHabit,
      )) {
        continue;
      }

      mergedHabits[existingIndex] = _mergeRemoteHabitIntoExistingLocal(
        localHabit: localHabit,
        remoteHabit: remoteHabit,
      );
      changed = true;
      continue;
    }

    if (remoteHabit.isArchived) {
      continue;
    }

    final newLocalHabit = _localHabitFromRemote(remoteHabit);
    mergedHabits.add(newLocalHabit);
    localIndexesByRemoteId[remoteHabitId] = mergedHabits.length - 1;
    changed = true;
  }

  return _HabitRemoteMergeResult(habits: mergedHabits, changed: changed);
}

_HabitLogRemoteMergeResult _mergeRemoteHabitLogsIntoLocalState({
  required Map<String, dynamic> userState,
  required List<Map<String, dynamic>> activeHabits,
  required List<RemoteHabitLog> remoteLogs,
  required String authenticatedUserId,
}) {
  if (authenticatedUserId.trim().isEmpty) {
    return const _HabitLogRemoteMergeResult(changed: false);
  }

  if (remoteLogs.isEmpty) {
    return const _HabitLogRemoteMergeResult(changed: false);
  }

  final habitsByLocalId = <String, Map<String, dynamic>>{};
  final localHabitIdByRemoteId = <String, String>{};
  for (final habit in activeHabits) {
    final habitId = _habitIdValue(habit);
    if (habitId == null || habitId.isEmpty) continue;
    habitsByLocalId[habitId] = habit;

    final remoteId = _habitRemoteIdValue(habit);
    if (remoteId != null && remoteId.isNotEmpty) {
      localHabitIdByRemoteId[remoteId] = habitId;
    }
  }

  var changed = false;
  for (final remoteLog in remoteLogs) {
    if (!_isRemoteHabitLogScopedToUser(
      remoteLog,
      authenticatedUserId: authenticatedUserId,
    )) {
      _debugHabitPull(
        'skipped remote habit log outside authenticated scope: '
        'logId="${remoteLog.id}" userId="${remoteLog.userId}" '
        'habitId="${remoteLog.habitId}"',
      );
      continue;
    }

    final localHabitId = localHabitIdByRemoteId[remoteLog.habitId];
    if (localHabitId == null || localHabitId.isEmpty) continue;

    final localHabit = habitsByLocalId[localHabitId];
    if (localHabit == null) continue;
    if (!_remoteLogHasMeaningfulState(remoteLog)) continue;

    final dateKey = _dateKey(remoteLog.logDate.toLocal());
    if (_hasLocalProgressForHabitDate(
      userState,
      habitId: localHabitId,
      dateKey: dateKey,
    )) {
      if (!_shouldReplaceLocalProgressWithRemote(
        userState: userState,
        localHabit: localHabit,
        habitId: localHabitId,
        dateKey: dateKey,
        remoteLog: remoteLog,
      )) {
        continue;
      }
    }

    _applyRemoteLogToLocalHistory(
      userState: userState,
      localHabit: localHabit,
      habitId: localHabitId,
      dateKey: dateKey,
      remoteLog: remoteLog,
    );
    changed = true;
  }

  return _HabitLogRemoteMergeResult(changed: changed);
}

class _RemotePullScopeValidation {
  const _RemotePullScopeValidation.safe()
      : isSafe = true,
        reason = null;

  const _RemotePullScopeValidation.unsafe(this.reason) : isSafe = false;

  final bool isSafe;
  final String? reason;
}

_RemotePullScopeValidation _validateRemoteHabitsScopeForPull(
  List<RemoteHabit> remoteHabits, {
  required String authenticatedUserId,
}) {
  final normalizedAuthenticatedUserId = authenticatedUserId.trim();
  if (normalizedAuthenticatedUserId.isEmpty) {
    return const _RemotePullScopeValidation.unsafe(
      'missing authenticated user id',
    );
  }

  final distinctUserIds = <String>{};
  for (final remoteHabit in remoteHabits) {
    final remoteHabitId = (remoteHabit.id ?? '').trim();
    final normalizedUserId = remoteHabit.userId.trim();
    if (normalizedUserId.isEmpty) {
      return _RemotePullScopeValidation.unsafe(
        'habit missing user_id (habitId="$remoteHabitId")',
      );
    }

    distinctUserIds.add(normalizedUserId);
    if (normalizedUserId != normalizedAuthenticatedUserId) {
      return _RemotePullScopeValidation.unsafe(
        'habit user_id mismatch '
        '(habitId="$remoteHabitId" userId="$normalizedUserId" '
        'expected="$normalizedAuthenticatedUserId")',
      );
    }
  }

  if (distinctUserIds.length > 1) {
    return _RemotePullScopeValidation.unsafe(
      'multiple habit user_id values returned (${distinctUserIds.join(', ')})',
    );
  }

  return const _RemotePullScopeValidation.safe();
}

_RemotePullScopeValidation _validateRemoteHabitLogsScopeForPull(
  List<RemoteHabitLog> remoteLogs, {
  required String authenticatedUserId,
  Set<String>? allowedRemoteHabitIds,
}) {
  final normalizedAuthenticatedUserId = authenticatedUserId.trim();
  if (normalizedAuthenticatedUserId.isEmpty) {
    return const _RemotePullScopeValidation.unsafe(
      'missing authenticated user id',
    );
  }

  final normalizedAllowedRemoteHabitIds = allowedRemoteHabitIds
      ?.map((habitId) => habitId.trim())
      .where((habitId) => habitId.isNotEmpty)
      .toSet();
  final distinctUserIds = <String>{};

  for (final remoteLog in remoteLogs) {
    final normalizedLogId = remoteLog.id.trim();
    final normalizedUserId = remoteLog.userId.trim();
    if (normalizedUserId.isEmpty) {
      return _RemotePullScopeValidation.unsafe(
        'log missing user_id (logId="$normalizedLogId")',
      );
    }

    distinctUserIds.add(normalizedUserId);
    if (normalizedUserId != normalizedAuthenticatedUserId) {
      return _RemotePullScopeValidation.unsafe(
        'log user_id mismatch '
        '(logId="$normalizedLogId" userId="$normalizedUserId" '
        'expected="$normalizedAuthenticatedUserId")',
      );
    }

    final normalizedHabitId = remoteLog.habitId.trim();
    if (normalizedHabitId.isEmpty) {
      return _RemotePullScopeValidation.unsafe(
        'log missing habit_id (logId="$normalizedLogId")',
      );
    }

    if (normalizedAllowedRemoteHabitIds != null &&
        normalizedAllowedRemoteHabitIds.isNotEmpty &&
        !normalizedAllowedRemoteHabitIds.contains(normalizedHabitId)) {
      return _RemotePullScopeValidation.unsafe(
        'log habit_id mismatch '
        '(logId="$normalizedLogId" habitId="$normalizedHabitId")',
      );
    }
  }

  if (distinctUserIds.length > 1) {
    return _RemotePullScopeValidation.unsafe(
      'multiple log user_id values returned (${distinctUserIds.join(', ')})',
    );
  }

  return const _RemotePullScopeValidation.safe();
}

bool _isRemoteHabitScopedToUser(
  RemoteHabit remoteHabit, {
  required String authenticatedUserId,
}) {
  final normalizedUserId = remoteHabit.userId.trim();
  final normalizedAuthenticatedUserId = authenticatedUserId.trim();
  return normalizedAuthenticatedUserId.isNotEmpty &&
      normalizedUserId.isNotEmpty &&
      normalizedUserId == normalizedAuthenticatedUserId;
}

bool _isRemoteHabitLogScopedToUser(
  RemoteHabitLog remoteLog, {
  required String authenticatedUserId,
}) {
  final normalizedAuthenticatedUserId = authenticatedUserId.trim();
  final normalizedUserId = remoteLog.userId.trim();
  final normalizedHabitId = remoteLog.habitId.trim();
  return normalizedAuthenticatedUserId.isNotEmpty &&
      normalizedUserId.isNotEmpty &&
      normalizedUserId == normalizedAuthenticatedUserId &&
      normalizedHabitId.isNotEmpty;
}

String? _remoteHabitOwnerUserIdValue(Map<String, dynamic> habit) {
  for (final key in const <String>[
    'remoteUserId',
    'remote_user_id',
    'supabaseUserId',
    'supabase_user_id',
    'userId',
    'user_id',
  ]) {
    final normalized = (habit[key] ?? '').toString().trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }

  return null;
}

bool _isClearlyForeignRemoteOwnedHabit(
  Map<String, dynamic> habit, {
  required String authenticatedUserId,
}) {
  final normalizedAuthenticatedUserId = authenticatedUserId.trim();
  if (normalizedAuthenticatedUserId.isEmpty) {
    return false;
  }

  final ownerUserId = _remoteHabitOwnerUserIdValue(habit);
  if (ownerUserId == null || ownerUserId == normalizedAuthenticatedUserId) {
    return false;
  }

  // Only remove records whose ownership is explicit. Habits without reliable
  // ownership metadata are kept to avoid destructive cleanup of valid local-only
  // items after the earlier cross-user import bug.
  return true;
}

bool _areHabitTypesCompatible(
  Map<String, dynamic> localHabit,
  RemoteHabit remoteHabit,
) {
  return _normalizedHabitType(localHabit['type']) == remoteHabit.habitType;
}

bool _shouldReplaceLocalHabitWithRemote({
  required Map<String, dynamic> localHabit,
  required RemoteHabit remoteHabit,
}) {
  final remoteUpdatedAt = remoteHabit.updatedAt;
  if (remoteUpdatedAt == null) return false;

  final localUpdatedAt = _parseHabitDate(
    localHabit['updatedAt'] ?? localHabit['updated_at'],
  );
  if (localUpdatedAt == null) return false;

  return remoteUpdatedAt.isAfter(localUpdatedAt);
}

Map<String, dynamic> _mergeRemoteHabitIntoExistingLocal({
  required Map<String, dynamic> localHabit,
  required RemoteHabit remoteHabit,
}) {
  final merged = Map<String, dynamic>.from(localHabit);

  merged['remoteId'] = remoteHabit.id;
  merged['remoteUserId'] = remoteHabit.userId;
  merged['name'] = remoteHabit.name;
  merged['title'] = remoteHabit.name;
  merged['habitTitle'] = remoteHabit.name;
  merged['familyId'] = remoteHabit.familyId;
  merged['emoji'] = remoteHabit.emoji ?? merged['emoji'];
  merged['reminderEnabled'] = remoteHabit.reminderEnabled;
  merged['reminderTime'] = remoteHabit.reminderTime;
  merged['colorId'] = remoteHabit.colorId;
  if (remoteHabit.hasExplicitSchedule) {
    merged['schedule'] =
        HabitScheduleNormalizer.normalize(remoteHabit.schedule);
  } else if (merged['schedule'] is! Map) {
    merged['schedule'] = Map<String, dynamic>.from(
      HabitScheduleNormalizer.daily,
    );
  }
  merged['updatedAt'] = remoteHabit.updatedAt?.toUtc().toIso8601String();
  merged['createdAt'] =
      merged['createdAt'] ?? remoteHabit.createdAt?.toUtc().toIso8601String();

  if (_normalizedHabitType(merged['type']) == 'count') {
    merged['unit'] = remoteHabit.unit;
    if (remoteHabit.targetCount != null) {
      merged['target'] = remoteHabit.targetCount;
    }
  }

  if (merged['archived'] != true) {
    merged['archived'] = remoteHabit.isArchived;
  }

  return merged;
}

Map<String, dynamic> _localHabitFromRemote(RemoteHabit remoteHabit) {
  final remoteHabitId = (remoteHabit.id ?? '').trim().toLowerCase();
  final localHabitId = 'remote_$remoteHabitId';

  return <String, dynamic>{
    'id': localHabitId,
    'habitId': localHabitId,
    'remoteId': remoteHabitId,
    'remoteUserId': remoteHabit.userId,
    'createdAt': remoteHabit.createdAt?.toUtc().toIso8601String() ?? _today(),
    'updatedAt': remoteHabit.updatedAt?.toUtc().toIso8601String(),
    'name': remoteHabit.name,
    'title': remoteHabit.name,
    'habitTitle': remoteHabit.name,
    'emoji': remoteHabit.emoji ?? '?',
    'familyId': remoteHabit.familyId,
    'type': remoteHabit.habitType,
    'unit': remoteHabit.habitType == 'count' ? remoteHabit.unit : null,
    'target':
        remoteHabit.habitType == 'count' ? (remoteHabit.targetCount ?? 1) : 1,
    'progress': 0,
    'doneToday': false,
    'skippedToday': false,
    'schedule': HabitScheduleNormalizer.normalize(remoteHabit.schedule),
    'reminderEnabled': remoteHabit.reminderEnabled,
    'reminderTime': remoteHabit.reminderTime,
    'colorId': remoteHabit.colorId,
    'archived': remoteHabit.isArchived,
  };
}

bool _remoteLogHasMeaningfulState(RemoteHabitLog remoteLog) {
  return remoteLog.isCompleted || remoteLog.value > 0;
}

bool _hasLocalProgressForHabitDate(
  Map<String, dynamic> userState, {
  required String habitId,
  required String dateKey,
}) {
  final history = _ensureHistoryRoot(userState);
  final completions = _map(_map(history['habitCompletions'])[dateKey]);
  final countValues = _map(_map(history['habitCountValues'])[dateKey]);
  final skips = _map(_map(history['habitSkips'])[dateKey]);

  return completions.containsKey(habitId) ||
      countValues.containsKey(habitId) ||
      skips.containsKey(habitId);
}

bool _shouldReplaceLocalProgressWithRemote({
  required Map<String, dynamic> userState,
  required Map<String, dynamic> localHabit,
  required String habitId,
  required String dateKey,
  required RemoteHabitLog remoteLog,
}) {
  if (_normalizedHabitType(localHabit['type']) == 'count') {
    return false;
  }

  if (!remoteLog.isCompleted) {
    return false;
  }

  final remoteUpdatedAt = remoteLog.updatedAt;
  if (remoteUpdatedAt == null) {
    return false;
  }

  final history = _ensureHistoryRoot(userState);
  final completionTimes = _map(_map(history['habitCompletionTimes'])[dateKey]);
  final localEpoch = _safeInt(completionTimes[habitId], fallback: 0);
  if (localEpoch <= 0) {
    return false;
  }

  final localTimestamp =
      DateTime.fromMillisecondsSinceEpoch(localEpoch, isUtc: false);
  return remoteUpdatedAt.isAfter(localTimestamp);
}

void _applyRemoteLogToLocalHistory({
  required Map<String, dynamic> userState,
  required Map<String, dynamic> localHabit,
  required String habitId,
  required String dateKey,
  required RemoteHabitLog remoteLog,
}) {
  final type = _normalizedHabitType(localHabit['type']);
  if (type == 'count') {
    final remoteValue = remoteLog.value < 0 ? 0 : remoteLog.value;
    _setHabitCountValueForDay(
      userState,
      dateKey: dateKey,
      habitId: habitId,
      value: remoteValue,
    );
    _setHabitCompletionForDay(
      userState,
      dateKey: dateKey,
      habitId: habitId,
      done: remoteLog.isCompleted || remoteValue >= _habitTarget(localHabit),
    );
    _setHabitSkipForDay(
      userState,
      dateKey: dateKey,
      habitId: habitId,
      skipped: false,
    );
    return;
  }

  _setHabitCompletionForDay(
    userState,
    dateKey: dateKey,
    habitId: habitId,
    done: remoteLog.isCompleted,
  );
  _setHabitSkipForDay(
    userState,
    dateKey: dateKey,
    habitId: habitId,
    skipped: false,
  );
  _setHabitCompletionTimeState(
    userState,
    dateKey: dateKey,
    habitId: habitId,
    done: remoteLog.isCompleted,
    epochMillis: remoteLog.updatedAt?.toLocal().millisecondsSinceEpoch ?? 0,
  );
}

void _debugHabitPull(String message) {
  if (!kDebugMode) return;
  debugPrint('[habit_pull] $message');
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

    final authenticatedUserId = store._currentSupabaseUserIdProvider();
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
    final hasEligibleCandidates =
        _countEligibleBackfillCandidates(userState) > 0;

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

    final summary =
        await store._habitSyncService.backfillLocalHabitsWithoutRemoteId(
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
    final remainingEligible =
        _countEligibleBackfillCandidates(updatedUserState);
    final shouldMarkCompleted =
        remainingEligible == 0 && summary.failedCount == 0;

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

    final authenticatedUserId = store._currentSupabaseUserIdProvider();
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

    final authenticatedUserId = store._currentSupabaseUserIdProvider();
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
    final synced =
        await store._userProgressSyncService.syncCurrentProgressFromLocalState(
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
    _debugUserProgressBackfill(
        'progress backfill unexpected store error: $error');
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

      final isCompleted =
          hasCompletionEntry ? _dynamicToBool(dayCompletions[habitId]) : null;
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
  return HabitScheduleNormalizer.normalizeWeekdays(rawWeekdays);
}

bool _isTimesPerWeekFrequencyMode(dynamic rawMode) =>
    (rawMode ?? '').toString().trim().toLowerCase() == 'timesperweek';

int? _readLegacyTimesPerWeekTarget(Map<String, dynamic> source) {
  for (final key in const [
    'timesPerWeekTarget',
    'timesPerWeek',
    'goal',
    'times'
  ]) {
    final value = source[key];
    if (value == null) continue;
    final target = _safePositiveNum(value, fallback: 0).toInt();
    if (target >= 1) return target;
  }
  return null;
}

Map<String, dynamic> _resolvedScheduleForHabitSave({
  required String habitType,
  required Map<String, dynamic> source,
  Map<String, dynamic>? fallbackSchedule,
}) {
  final fallback = HabitScheduleNormalizer.normalize(fallbackSchedule);
  final rawSchedule = _map(source['schedule']);
  final normalizedSchedule = rawSchedule.isEmpty
      ? <String, dynamic>{}
      : HabitScheduleNormalizer.normalize(rawSchedule);
  final normalizedType = (normalizedSchedule['type'] ?? '').toString();

  if (habitType == 'count') {
    if (normalizedSchedule.isEmpty || normalizedType == 'timesPerWeek') {
      return Map<String, dynamic>.from(fallback);
    }
    return normalizedSchedule;
  }

  if (normalizedType == 'timesPerWeek') {
    final target = _safePositiveNum(
      normalizedSchedule['timesPerWeek'] ??
          _readLegacyTimesPerWeekTarget(source),
      fallback: 1,
    ).toInt();
    final rawWeekStartsOn =
        _safeInt(normalizedSchedule['weekStartsOn'], fallback: 1);
    final weekStartsOn =
        rawWeekStartsOn >= 1 && rawWeekStartsOn <= 7 ? rawWeekStartsOn : 1;
    return HabitScheduleNormalizer.normalize({
      'type': 'timesPerWeek',
      'timesPerWeek': target,
      'weekStartsOn': weekStartsOn,
    });
  }

  final legacyTarget = _readLegacyTimesPerWeekTarget(source);
  final indicatesTimesPerWeek =
      _isTimesPerWeekFrequencyMode(source['frequencyMode']) ||
          _isTimesPerWeekFrequencyMode(source['mode']);
  if (indicatesTimesPerWeek &&
      legacyTarget != null &&
      (normalizedSchedule.isEmpty || normalizedType == 'daily')) {
    return HabitScheduleNormalizer.normalize({
      'type': 'timesPerWeek',
      'timesPerWeek': legacyTarget,
      'weekStartsOn': 1,
    });
  }

  if (normalizedSchedule.isNotEmpty) {
    return normalizedSchedule;
  }
  return Map<String, dynamic>.from(fallback);
}

Map<String, dynamic> _habitSchedule({
  String scheduleType = 'daily',
  String? scheduledDate,
  List<int>? weekdays,
  int? timesPerWeek,
  int? weekStartsOn,
}) {
  if (scheduleType == 'once') {
    return HabitScheduleNormalizer.normalize({
      'type': 'once',
      'date': (scheduledDate ?? '').toString(),
    });
  }

  if (scheduleType == 'weekly') {
    return HabitScheduleNormalizer.normalize({
      'type': 'weekly',
      'weekdays': weekdays ?? const <int>[],
    });
  }

  if (scheduleType == 'timesPerWeek') {
    return HabitScheduleNormalizer.normalize({
      'type': 'timesPerWeek',
      'timesPerWeek': _safePositiveNum(timesPerWeek, fallback: 1).toInt(),
      'weekStartsOn': _safeInt(weekStartsOn, fallback: 1),
    });
  }

  return HabitScheduleNormalizer.normalize({'type': 'daily'});
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
  _ensureDailyReset(userState, nowProvider: store._nowProvider);
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
  _ensureDailyReset(userState, nowProvider: store._nowProvider);

  final activeHabits = _mutableActiveHabits(userState);

  final id = (habitDef['id'] ?? '').toString();
  if (id.isEmpty) return;
  if (_activeHabitIndex(activeHabits, id) != -1) return;

  final type = _normalizedHabitType(habitDef['type']);
  final metric = _map(habitDef['metric']);
  final resolvedTarget = _safePositiveNum(
    target ?? (type == 'check' ? 1 : 10),
    fallback: type == 'check' ? 1 : 10,
  );
  final rawResolvedUnit = type == 'count'
      ? (habitDef['unit'] ??
              habitDef['unitLabel'] ??
              metric['unit'] ??
              metric['label'] ??
              '')
          .toString()
          .trim()
      : '';
  final resolvedUnit = rawResolvedUnit.isEmpty ? null : rawResolvedUnit;
  final requestedSchedule = _habitSchedule(
    scheduleType: scheduleType,
    scheduledDate: scheduledDate,
    weekdays: weekdays,
  );
  final resolvedSchedule = _resolvedScheduleForHabitSave(
    habitType: type,
    source: <String, dynamic>{
      ...habitDef,
      'type': type,
      'target': resolvedTarget,
      'targetCount': resolvedTarget,
      if (resolvedUnit != null) 'unit': resolvedUnit,
      'schedule': requestedSchedule,
    },
    fallbackSchedule: requestedSchedule,
  );

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
    'unit': resolvedUnit,
    'unitLabel': resolvedUnit,
    'target': resolvedTarget,
    'targetCount': resolvedTarget,
    'progress': 0,
    'doneToday': false,
    'skippedToday': false,
    'schedule': resolvedSchedule,
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
  _ensureDailyReset(userState, nowProvider: store._nowProvider);

  final activeHabits = _mutableActiveHabits(userState);

  final providedId = (habit['id'] ?? '').toString().trim();
  final id = providedId.isNotEmpty
      ? providedId
      : 'custom_${DateTime.now().millisecondsSinceEpoch}';

  if (_activeHabitIndex(activeHabits, id) != -1) {
    return;
  }

  final type = _normalizedHabitType(habit['type']);
  final source = _map(habit);
  final routineDays = _normalizedWeekdays(habit['routineDays']);
  final fallbackSchedule = routineDays.isEmpty || routineDays.length == 7
      ? _habitSchedule()
      : _habitSchedule(scheduleType: 'weekly', weekdays: routineDays);
  final schedule = _resolvedScheduleForHabitSave(
    habitType: type,
    source: source,
    fallbackSchedule: fallbackSchedule,
  );

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
  final rawUnit = (habit['unit'] ?? habit['unitLabel'] ?? '').toString().trim();
  final resolvedUnit = type == 'count' && rawUnit.isNotEmpty ? rawUnit : null;
  final resolvedTarget =
      type == 'count' ? _safePositiveNum(habit['target'], fallback: 1) : 1;

  activeHabits.add(<String, dynamic>{
    'id': id,
    'createdAt':
        (habit['createdAt'] ?? habit['created_at'] ?? _today()).toString(),
    'name': (habit['name'] ?? habit['title'] ?? 'Habito').toString(),
    'emoji': resolvedEmoji,
    'description': (habit['description'] ?? '').toString(),
    'familyId': resolvedFamilyId,
    'allFamilies': allFamilies,
    'type': type,
    'unit': resolvedUnit,
    'unitLabel': resolvedUnit,
    'target': resolvedTarget,
    'targetCount': resolvedTarget,
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
  _ensureDailyReset(userState, nowProvider: store._nowProvider);

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
  _ensureDailyReset(userState, nowProvider: store._nowProvider);

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
  _ensureDailyReset(userState, nowProvider: store._nowProvider);

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
  if (patch.containsKey('frequencyMode')) {
    current['frequencyMode'] = patch['frequencyMode'];
  }

  final shouldResolveSchedule = patch.containsKey('schedule') ||
      patch.containsKey('frequencyMode') ||
      patch.containsKey('timesPerWeekTarget') ||
      patch.containsKey('goal') ||
      patch.containsKey('times') ||
      patch.containsKey('type') ||
      patch.containsKey('trackingType') ||
      patch.containsKey('habitType') ||
      patch.containsKey('tracking');
  if (shouldResolveSchedule) {
    final mergedForSchedule = Map<String, dynamic>.from(current)..addAll(patch);
    current['schedule'] = _resolvedScheduleForHabitSave(
      habitType: type,
      source: mergedForSchedule,
      fallbackSchedule: _map(current['schedule']),
    );
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
  final originalRoot = _cloneMap(root);
  final now = store._nowProvider();

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState, nowProvider: store._nowProvider);

  final activeHabits = _mutableActiveHabits(userState);

  final index = _activeHabitIndex(activeHabits, habitId);
  if (index == -1) return;

  final habit = Map<String, dynamic>.from(activeHabits[index]);
  if (!_isHabitExpectedForDate(habit, now)) return;
  if (!_isCountHabit(habit)) return;

  final dayKey = _dateKey(now);
  final existingTransaction = await _habitRewardTransactionForDate(
    store,
    habitId: habitId,
    localDateKey: dayKey,
  );
  final hasActiveRewardTransaction =
      existingTransaction != null && !existingTransaction.isReversed;
  final hasConfirmedCloudRewardTransaction =
      _isConfirmedCloudHabitRewardTransaction(existingTransaction);
  final hasReversedRewardTransaction = existingTransaction?.isReversed == true;
  final wasCompletedBeforeChange = habit['doneToday'] == true;
  final cloudHabitRewardsEnabled = HabitCurrencyRewardsConfig.resolveEnabled(
    override: store._cloudHabitRewardsEnabledOverride,
  );
  final rewardAlreadyGranted = cloudHabitRewardsEnabled
      ? hasConfirmedCloudRewardTransaction
      : hasActiveRewardTransaction;
  final progressResult = _setCountHabitProgress(
    habit,
    value: value,
    rewardAlreadyGranted: rewardAlreadyGranted,
  );
  _logHabitCloudReward(
    'complete habit=$habitId cloud=$cloudHabitRewardsEnabled '
    'existing=${existingTransaction != null} '
    'legacy=${existingTransaction != null && !hasConfirmedCloudRewardTransaction} '
    'cloudConfirmed=$hasConfirmedCloudRewardTransaction '
    'rewardAlreadyGranted=$rewardAlreadyGranted '
    'grantDailyReward=${progressResult.grantDailyReward}',
  );

  _setHabitCompletionTimeState(
    userState,
    dateKey: dayKey,
    habitId: habitId,
    done: habit['doneToday'] == true,
    epochMillis: now.millisecondsSinceEpoch,
  );

  _HabitRewardCompletionOutcome completionOutcome =
      const _HabitRewardCompletionOutcome(
    granted: false,
    baseXp: 0,
    bonusXp: 0,
    baseCoins: 0,
    bonusCoins: 0,
    appliedEffectIds: <String>[],
  );
  _HabitRewardRestorationOutcome restorationOutcome =
      const _HabitRewardRestorationOutcome(
    restored: false,
    restoredCoins: 0,
    transaction: null,
  );

  if (cloudHabitRewardsEnabled) {
    if (habit['doneToday'] == true && progressResult.grantDailyReward) {
      completionOutcome = await _applyHabitRewardCompletion(
        store,
        userState,
        habit: habit,
        habitId: habitId,
        dateKey: dayKey,
        baseXp: progressResult.xpGain,
        baseCoins: progressResult.coinsGain,
      );
      if (completionOutcome.granted) {
        _setDailyRewardGrant(userState, habitId: habitId, granted: true);
      }
    }
  } else if (hasReversedRewardTransaction && habit['doneToday'] == true) {
    restorationOutcome = await _restoreHabitRewardCompletion(
      store,
      userState,
      habitId: habitId,
      dateKey: dayKey,
    );
  } else if (progressResult.grantDailyReward && !hasActiveRewardTransaction) {
    completionOutcome = await _applyHabitRewardCompletion(
      store,
      userState,
      habit: habit,
      habitId: habitId,
      dateKey: dayKey,
      baseXp: progressResult.xpGain,
      baseCoins: progressResult.coinsGain,
    );
    if (completionOutcome.granted) {
      _setDailyRewardGrant(userState, habitId: habitId, granted: true);
    }
  }

  final shouldReverse = hasActiveRewardTransaction &&
      wasCompletedBeforeChange &&
      habit['doneToday'] != true;
  final revokedOutcome = shouldReverse
      ? await _reverseHabitRewardCompletion(
          store,
          userState,
          habit: habit,
          habitId: habitId,
          dateKey: dayKey,
        )
      : const _HabitRewardReversalOutcome(
          revokedXp: 0,
          revokedCoins: 0,
          reversed: false,
        );

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

  try {
    await store.save(root);
    if (completionOutcome.granted && !cloudHabitRewardsEnabled) {
      await _saveActiveUtilityEffectsForStore(
        store,
        completionOutcome.nextEffects,
      );
      if (completionOutcome.transaction != null) {
        await _saveHabitRewardTransactionForStore(
          store,
          completionOutcome.transaction!,
        );
      }
    }
    if (restorationOutcome.restored && restorationOutcome.transaction != null) {
      await _saveHabitRewardTransactionForStore(
        store,
        restorationOutcome.transaction!,
      );
    }
    if (revokedOutcome.reversed && revokedOutcome.transaction != null) {
      await _saveHabitRewardTransactionForStore(
          store, revokedOutcome.transaction!);
    }
  } catch (_) {
    await _rollbackHabitRewardPersistence(
      store,
      originalRoot: originalRoot,
      originalEffects:
          completionOutcome.granted ? completionOutcome.sourceEffects : null,
    );
    rethrow;
  }

  _queueBestEffortAchievementUnlockSync(
    store,
    userState: userState,
    records: achievementSyncOutcome.newlyUnlockedRecords,
  );
  if (store._achievementLevelRewardCoordinator.isEnabled) {
    await _claimCloudAchievementAndLevelRewardsBestEffort(
      store,
      achievementRecords: achievementSyncOutcome.newlyUnlockedRecords,
      resolvePendingFirst: false,
    );
  }
  if (completionOutcome.granted && !cloudHabitRewardsEnabled) {
    _queueBestEffortProgressAndRewardSync(
      store,
      userState: userState,
      xpDelta: completionOutcome.totalXp,
      coinsDelta: completionOutcome.totalCoins,
      source: 'habit_completion',
      xpReason: 'habit_completion_reward',
      currencyReason: 'habit_completion_reward',
    );
  }
  if (restorationOutcome.restored && !cloudHabitRewardsEnabled) {
    _queueBestEffortProgressAndRewardSync(
      store,
      userState: userState,
      xpDelta: 0,
      coinsDelta: restorationOutcome.restoredCoins,
      source: 'habit_completion_restore',
      currencyReason: 'habit_completion_restore',
    );
  }
  if (revokedOutcome.reversed && !cloudHabitRewardsEnabled) {
    _queueBestEffortProgressAndRewardSync(
      store,
      userState: userState,
      xpDelta: 0,
      coinsDelta: -revokedOutcome.revokedCoins,
      source: 'refund',
      currencyReason: 'habit_completion_rollback',
    );
  }
  if (!store._achievementLevelRewardCoordinator.isEnabled) {
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
  }
  _queueBestEffortHabitLogSyncForDate(
    store,
    userState: userState,
    habit: habit,
    habitId: habitId,
    date: now,
  );
}

Future<void> _completeHabit(
  UserStateStore store, {
  required String habitId,
  num delta = 1,
}) async {
  final root = store._state;
  if (root == null) return;
  final originalRoot = _cloneMap(root);
  final now = store._nowProvider();

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState, nowProvider: store._nowProvider);

  final activeHabits = _mutableActiveHabits(userState);

  final index = _activeHabitIndex(activeHabits, habitId);
  if (index == -1) return;

  final habit = Map<String, dynamic>.from(activeHabits[index]);
  if (!_isHabitExpectedForDate(habit, now)) return;

  final type = _normalizedHabitType(habit['type']);
  final dayKey = _dateKey(now);
  final existingTransaction = await _habitRewardTransactionForDate(
    store,
    habitId: habitId,
    localDateKey: dayKey,
  );
  final hasActiveRewardTransaction =
      existingTransaction != null && !existingTransaction.isReversed;
  final hasConfirmedCloudRewardTransaction =
      _isConfirmedCloudHabitRewardTransaction(existingTransaction);
  final hasReversedRewardTransaction = existingTransaction?.isReversed == true;
  final cloudHabitRewardsEnabled = HabitCurrencyRewardsConfig.resolveEnabled(
    override: store._cloudHabitRewardsEnabledOverride,
  );
  final rewardAlreadyGranted = cloudHabitRewardsEnabled
      ? hasConfirmedCloudRewardTransaction
      : hasActiveRewardTransaction;

  if (type == 'check') {
    if (habit['doneToday'] == true) return;
  }

  final progressResult = _applyHabitProgressDelta(
    habit,
    delta: delta,
    rewardAlreadyGranted: rewardAlreadyGranted,
  );
  _logHabitCloudReward(
    'complete habit=$habitId cloud=$cloudHabitRewardsEnabled '
    'existing=${existingTransaction != null} '
    'legacy=${existingTransaction != null && !hasConfirmedCloudRewardTransaction} '
    'cloudConfirmed=$hasConfirmedCloudRewardTransaction '
    'rewardAlreadyGranted=$rewardAlreadyGranted '
    'grantDailyReward=${progressResult.grantDailyReward}',
  );
  _setHabitCompletionTimeState(
    userState,
    dateKey: dayKey,
    habitId: habitId,
    done: habit['doneToday'] == true,
    epochMillis: now.millisecondsSinceEpoch,
  );
  _HabitRewardCompletionOutcome completionOutcome =
      const _HabitRewardCompletionOutcome(
    granted: false,
    baseXp: 0,
    bonusXp: 0,
    baseCoins: 0,
    bonusCoins: 0,
    appliedEffectIds: <String>[],
  );
  _HabitRewardRestorationOutcome restorationOutcome =
      const _HabitRewardRestorationOutcome(
    restored: false,
    restoredCoins: 0,
    transaction: null,
  );

  if (cloudHabitRewardsEnabled) {
    if (habit['doneToday'] == true && progressResult.grantDailyReward) {
      completionOutcome = await _applyHabitRewardCompletion(
        store,
        userState,
        habit: habit,
        habitId: habitId,
        dateKey: dayKey,
        baseXp: progressResult.xpGain,
        baseCoins: progressResult.coinsGain,
      );
      if (completionOutcome.granted) {
        _setDailyRewardGrant(userState, habitId: habitId, granted: true);
      }
    }
  } else if (hasReversedRewardTransaction && habit['doneToday'] == true) {
    restorationOutcome = await _restoreHabitRewardCompletion(
      store,
      userState,
      habitId: habitId,
      dateKey: dayKey,
    );
  } else if (habit['doneToday'] == true &&
      progressResult.grantDailyReward &&
      !hasActiveRewardTransaction) {
    completionOutcome = await _applyHabitRewardCompletion(
      store,
      userState,
      habit: habit,
      habitId: habitId,
      dateKey: dayKey,
      baseXp: progressResult.xpGain,
      baseCoins: progressResult.coinsGain,
    );
    if (completionOutcome.granted) {
      _setDailyRewardGrant(userState, habitId: habitId, granted: true);
    }
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

  try {
    await store.save(root);
    if (completionOutcome.granted && !cloudHabitRewardsEnabled) {
      await _saveActiveUtilityEffectsForStore(
        store,
        completionOutcome.nextEffects,
      );
      if (completionOutcome.transaction != null) {
        await _saveHabitRewardTransactionForStore(
          store,
          completionOutcome.transaction!,
        );
      }
    }
    if (restorationOutcome.restored && restorationOutcome.transaction != null) {
      await _saveHabitRewardTransactionForStore(
        store,
        restorationOutcome.transaction!,
      );
    }
  } catch (_) {
    await _rollbackHabitRewardPersistence(
      store,
      originalRoot: originalRoot,
      originalEffects:
          completionOutcome.granted ? completionOutcome.sourceEffects : null,
    );
    rethrow;
  }
  _queueBestEffortAchievementUnlockSync(
    store,
    userState: userState,
    records: achievementSyncOutcome.newlyUnlockedRecords,
  );
  if (completionOutcome.granted && !cloudHabitRewardsEnabled) {
    _queueBestEffortProgressAndRewardSync(
      store,
      userState: userState,
      xpDelta: completionOutcome.totalXp,
      coinsDelta: completionOutcome.totalCoins,
      source: 'habit_completion',
      xpReason: 'habit_completion_reward',
      currencyReason: 'habit_completion_reward',
    );
  }
  if (restorationOutcome.restored && !cloudHabitRewardsEnabled) {
    _queueBestEffortProgressAndRewardSync(
      store,
      userState: userState,
      xpDelta: 0,
      coinsDelta: restorationOutcome.restoredCoins,
      source: 'habit_completion_restore',
      currencyReason: 'habit_completion_restore',
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
    date: now,
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

  if (_isSameDay(date, store._nowProvider())) {
    await store.completeHabit(habitId: habitId);
    return;
  }

  _ensureDailyReset(userState, nowProvider: store._nowProvider);

  final activeHabits = _mutableActiveHabits(userState);

  final index = _activeHabitIndex(activeHabits, habitId);
  if (index == -1) return;

  final habit = Map<String, dynamic>.from(activeHabits[index]);
  if (!_isHabitExpectedForDate(habit, date)) return;

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
  _ensureDailyReset(userState, nowProvider: store._nowProvider);

  final date = _dateFromKey(dateKey);
  final originalRoot = _cloneMap(root);
  final activeHabits = _mutableActiveHabits(userState);
  final index = _activeHabitIndex(activeHabits, habitId);
  if (index == -1) return;
  final habit = Map<String, dynamic>.from(activeHabits[index]);
  if (!_isHabitExpectedForDate(habit, date)) return;
  var revokedOutcome = const _HabitRewardReversalOutcome(
    revokedXp: 0,
    revokedCoins: 0,
    reversed: false,
  );

  if (_isSameDay(date, store._nowProvider())) {
    if (done) {
      await store.completeHabit(habitId: habitId);
      return;
    }
    final existingTransaction = await _habitRewardTransactionForDate(
      store,
      habitId: habitId,
      localDateKey: dateKey,
    );
    if (existingTransaction != null && !existingTransaction.isReversed) {
      revokedOutcome = await _reverseHabitRewardCompletion(
        store,
        userState,
        habit: habit,
        habitId: habitId,
        dateKey: dateKey,
      );
    }

    habit['doneToday'] = false;
    habit['skippedToday'] = false;
    final type = _normalizedHabitType(habit['type']);
    habit['progress'] =
        type == 'count' ? _safeNum(habit['progress'], fallback: 0) : 0;

    activeHabits[index] = habit;
    userState['activeHabits'] = activeHabits;
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

  try {
    await store.save(root);
    if (revokedOutcome.reversed && revokedOutcome.transaction != null) {
      await _saveHabitRewardTransactionForStore(
          store, revokedOutcome.transaction!);
    }
  } catch (_) {
    await _rollbackHabitRewardPersistence(
      store,
      originalRoot: originalRoot,
    );
    rethrow;
  }
  if (revokedOutcome.reversed) {
    _queueBestEffortProgressAndRewardSync(
      store,
      userState: userState,
      xpDelta: 0,
      coinsDelta: -revokedOutcome.revokedCoins,
      source: 'refund',
      currencyReason: 'habit_completion_rollback',
    );
  }

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
  _ensureDailyReset(userState, nowProvider: store._nowProvider);

  final date = _dateFromKey(dateKey);
  final originalRoot = _cloneMap(root);
  final activeHabits = _mutableActiveHabits(userState);
  final index = _activeHabitIndex(activeHabits, habitId);
  if (index == -1) return;
  final habit = Map<String, dynamic>.from(activeHabits[index]);
  if (!_isHabitExpectedForDate(habit, date)) return;
  var revokedOutcome = const _HabitRewardReversalOutcome(
    revokedXp: 0,
    revokedCoins: 0,
    reversed: false,
  );

  if (_isSameDay(date, store._nowProvider())) {
    if (skipped) {
      final existingTransaction = await _habitRewardTransactionForDate(
        store,
        habitId: habitId,
        localDateKey: dateKey,
      );
      if (existingTransaction != null && !existingTransaction.isReversed) {
        revokedOutcome = await _reverseHabitRewardCompletion(
          store,
          userState,
          habit: habit,
          habitId: habitId,
          dateKey: dateKey,
        );
      }
    }
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

  try {
    await store.save(root);
    if (revokedOutcome.reversed && revokedOutcome.transaction != null) {
      await _saveHabitRewardTransactionForStore(
          store, revokedOutcome.transaction!);
    }
  } catch (_) {
    await _rollbackHabitRewardPersistence(
      store,
      originalRoot: originalRoot,
    );
    rethrow;
  }
  if (revokedOutcome.reversed) {
    _queueBestEffortProgressAndRewardSync(
      store,
      userState: userState,
      xpDelta: 0,
      coinsDelta: -revokedOutcome.revokedCoins,
      source: 'refund',
      currencyReason: 'habit_completion_rollback',
    );
  }

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

  if (_isSameDay(date, store._nowProvider())) {
    await store.setCountHabitValue(habitId: habitId, value: value);
    return;
  }

  _ensureDailyReset(userState, nowProvider: store._nowProvider);

  final activeHabits = _mutableActiveHabits(userState);

  final index = _activeHabitIndex(activeHabits, habitId);
  if (index == -1) return;

  final habit = Map<String, dynamic>.from(activeHabits[index]);
  if (!_isCountHabit(habit)) return;
  if (!_isHabitExpectedForDate(habit, date)) return;

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
          _safeNum(dayCountValues[habitId], fallback: 0)
              .clamp(0, double.infinity))
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

ActiveUtilityEffectsRepository _activeUtilityEffectsRepositoryForStore(
  UserStateStore store,
) {
  return store._activeUtilityEffectsRepository ??=
      LocalActiveUtilityEffectsRepository(
    scopeResolver: () => store.activeLocalScopeUserId ?? store.userId,
    nowProvider: store._nowProvider,
  );
}

HabitRewardTransactionRepository _habitRewardTransactionRepositoryForStore(
  UserStateStore store,
) {
  return store._habitRewardTransactionRepository ??=
      LocalHabitRewardTransactionRepository(
    scopeResolver: () => store.activeLocalScopeUserId ?? store.userId,
  );
}

String _rewardScopeForStore(UserStateStore store) {
  return (store.activeLocalScopeUserId ?? store.userId ?? '').trim();
}

Future<HabitRewardTransaction?> _habitRewardTransactionForDate(
  UserStateStore store, {
  required String habitId,
  required String localDateKey,
}) {
  return _habitRewardTransactionRepositoryForStore(store).findByCompletion(
    userScope: _rewardScopeForStore(store),
    habitId: habitId,
    localDateKey: localDateKey,
  );
}

Future<void> _saveHabitRewardTransactionForStore(
  UserStateStore store,
  HabitRewardTransaction transaction,
) {
  return _habitRewardTransactionRepositoryForStore(store).saveTransaction(
    _rewardScopeForStore(store),
    transaction,
  );
}

Future<void> _saveActiveUtilityEffectsForStore(
  UserStateStore store,
  List<ActiveUtilityEffect> effects,
) {
  return _activeUtilityEffectsRepositoryForStore(store).saveEffects(
    _rewardScopeForStore(store),
    effects,
  );
}

bool _isConfirmedCloudHabitRewardTransaction(
  HabitRewardTransaction? transaction,
) {
  final cloudOperationType = transaction?.cloudOperationType?.trim() ?? '';
  final applyRequestId = transaction?.applyRequestId?.trim() ?? '';
  final completionEventId = transaction?.completionEventId?.trim() ?? '';
  return transaction != null &&
      transaction.isReversed == false &&
      cloudOperationType == 'apply' &&
      applyRequestId.isNotEmpty &&
      completionEventId.isNotEmpty;
}

String _cloudHabitRewardCompletionEventId({
  required String habitId,
  required String dateKey,
  HabitRewardTransaction? existingTransaction,
}) {
  final existingCompletionEventId =
      existingTransaction?.completionEventId?.trim() ?? '';
  if (existingCompletionEventId.isNotEmpty) {
    return existingCompletionEventId;
  }
  return 'habit_cloud_reward|${habitId.trim()}|${dateKey.trim()}';
}

void _logHabitCloudReward(String message) {
  if (kDebugMode) {
    debugPrint('[habit_cloud_reward] $message');
  }
}

void _logStreakShieldCloud(String message) {
  if (kDebugMode) {
    debugPrint('[streak_shield_cloud] $message');
  }
}

void _logStreakRecoverCloud(String message) {
  if (kDebugMode) {
    debugPrint('[streak_recover_cloud] $message');
  }
}

void _logStreakRecoverDebugSeed({
  required String habitId,
  required String breakId,
  required String missedOccurrenceDateKey,
  required String result,
}) {
  if (!kDebugMode) return;
  debugPrint(
    '[streak_recover_debug_seed] habitId=$habitId breakId=$breakId '
    'missedOccurrenceDateKey=$missedOccurrenceDateKey result=$result',
  );
}

Future<void> _seedDebugRecoverableStreakBreak(
  UserStateStore store, {
  bool forceEnabled = false,
}) async {
  if (!kDebugMode) return;
  if (!store._debugStreakRecoverSeedEnabled && !forceEnabled) return;
  if (store._debugStreakRecoverSeedAttempted) return;

  store._debugStreakRecoverSeedAttempted = true;

  if (store.state == null) {
    await store.load();
    if (store.state == null) return;
  }

  final root = store._state;
  if (root == null) return;
  final userState = _ensureUserStateRoot(root);
  final activeHabits = _list(userState['activeHabits'])
      .whereType<Map>()
      .map((entry) => _map(entry))
      .where((entry) => _habitIdValue(entry) != null)
      .toList(growable: false);

  if (activeHabits.isEmpty) {
    _logStreakRecoverDebugSeed(
      habitId: '<none>',
      breakId: '<none>',
      missedOccurrenceDateKey: '<none>',
      result: 'skipped',
    );
    return;
  }

  final habit = activeHabits.firstWhere(
    (entry) => _habitIdValue(entry) == 'proyecto_personal',
    orElse: () => activeHabits.first,
  );
  final habitId = (_habitIdValue(habit) ?? '').trim();
  if (habitId.isEmpty) {
    _logStreakRecoverDebugSeed(
      habitId: '<none>',
      breakId: '<none>',
      missedOccurrenceDateKey: '<none>',
      result: 'skipped',
    );
    return;
  }

  final now = store._nowProvider();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final missedOccurrenceDateKey = _dateKey(yesterday);
  final breakId = 'debug_streak_break_${habitId}_$missedOccurrenceDateKey';
  final breaks = _habitStreakBreaksRoot(userState);
  final existing = _map(breaks[breakId]);
  if (existing.isNotEmpty) {
    _logStreakRecoverDebugSeed(
      habitId: habitId,
      breakId: breakId,
      missedOccurrenceDateKey: missedOccurrenceDateKey,
      result: 'already_exists',
    );
    return;
  }

  final seededBreak = RecoverableStreakBreak(
    id: breakId,
    userId: (store.activeLocalScopeUserId ?? store.userId ?? '').trim(),
    habitId: habitId,
    brokenAtMillis: now.millisecondsSinceEpoch,
    missedOccurrenceDateKey: missedOccurrenceDateKey,
    previousStreak: 3,
    currentStreakAfterBreak: 0,
    status: RecoverableStreakBreakStatus.recoverable,
    shieldProtected: false,
  );

  final nextRoot = _cloneMap(root);
  final nextUserState = _ensureUserStateRoot(nextRoot);
  final nextBreaks = _habitStreakBreaksRoot(nextUserState);
  nextBreaks[breakId] = seededBreak.toJson();

  await store._repo.save(nextRoot);
  store._state = nextRoot;
  store._emitChanged();
  _logStreakRecoverDebugSeed(
    habitId: habitId,
    breakId: breakId,
    missedOccurrenceDateKey: missedOccurrenceDateKey,
    result: 'created',
  );
}

ActiveUtilityEffect? _activeUtilityEffectForType(
  List<ActiveUtilityEffect> effects,
  ActiveUtilityEffectType type,
) {
  final matches = effects
      .where((effect) => effect.type == type)
      .toList(growable: false)
    ..sort((a, b) {
      final byActivated = b.activatedAtMillis.compareTo(a.activatedAtMillis);
      if (byActivated != 0) return byActivated;
      return b.id.compareTo(a.id);
    });
  if (matches.isEmpty) return null;
  return matches.first;
}

String _habitRewardTransactionId(
  String habitId,
  String localDateKey,
) {
  return 'habit_reward_${habitId.trim()}_${localDateKey.trim()}';
}

void _applyHabitRewardValues(
  UserStateStore store,
  Map<String, dynamic> userState, {
  required Map<String, dynamic> habit,
  required int totalXp,
  required int totalCoins,
}) {
  if (totalXp == 0 && totalCoins == 0) return;

  final familyId = _habitFamilyId(habit);
  final progression = _map(userState['progression']);
  final currentXp = _safeInt(progression['xp'], fallback: 0);
  final nextXp = currentXp + totalXp;
  _queueLevelCelebrationForXpChange(
    store,
    userState: userState,
    previousXp: currentXp,
    currentXp: nextXp,
    origin: XpMutationOrigin.gameplayReward,
  );
  _updateProgressionLevelFromXp(progression, totalXp: nextXp);
  progression['xp'] = nextXp < 0 ? 0 : nextXp;
  userState['progression'] = progression;

  if (totalXp != 0) {
    final familyXp = _map(userState['familyXp']);
    familyXp[familyId] = (_safeInt(familyXp[familyId], fallback: 0) + totalXp)
        .clamp(0, 1 << 30)
        .toInt();
    userState['familyXp'] = familyXp;
  }

  final wallet = _map(userState['wallet']);
  final currentCoins = _safeInt(wallet['coins'], fallback: 0);
  wallet['coins'] = (currentCoins + totalCoins).clamp(0, 1 << 30).toInt();
  userState['wallet'] = wallet;

  final daily = _map(userState['daily']);
  daily['xpEarnedToday'] =
      (_safeInt(daily['xpEarnedToday'], fallback: 0) + totalXp)
          .clamp(0, 1 << 30)
          .toInt();
  daily['coinsEarnedToday'] =
      (_safeInt(daily['coinsEarnedToday'], fallback: 0) + totalCoins)
          .clamp(0, 1 << 30)
          .toInt();
  userState['daily'] = daily;
}

void _revokeHabitRewardValues(
  Map<String, dynamic> userState, {
  required int revokedCoins,
}) {
  if (revokedCoins == 0) return;

  final wallet = _map(userState['wallet']);
  final currentCoins = _safeInt(wallet['coins'], fallback: 0);
  wallet['coins'] = (currentCoins - revokedCoins).clamp(0, 1 << 30).toInt();
  userState['wallet'] = wallet;

  final daily = _map(userState['daily']);
  daily['coinsEarnedToday'] =
      (_safeInt(daily['coinsEarnedToday'], fallback: 0) - revokedCoins)
          .clamp(0, 1 << 30)
          .toInt();
  userState['daily'] = daily;
}

void _restoreHabitRewardValues(
  Map<String, dynamic> userState, {
  required int restoredCoins,
}) {
  if (restoredCoins == 0) return;

  final wallet = _map(userState['wallet']);
  final currentCoins = _safeInt(wallet['coins'], fallback: 0);
  wallet['coins'] = (currentCoins + restoredCoins).clamp(0, 1 << 30).toInt();
  userState['wallet'] = wallet;

  final daily = _map(userState['daily']);
  daily['coinsEarnedToday'] =
      (_safeInt(daily['coinsEarnedToday'], fallback: 0) + restoredCoins)
          .clamp(0, 1 << 30)
          .toInt();
  userState['daily'] = daily;
}

Future<_HabitRewardCompletionOutcome> _applyHabitRewardCompletion(
  UserStateStore store,
  Map<String, dynamic> userState, {
  required Map<String, dynamic> habit,
  required String habitId,
  required String dateKey,
  required int baseXp,
  required int baseCoins,
}) async {
  final cloudHabitRewardsEnabled = HabitCurrencyRewardsConfig.resolveEnabled(
    override: store._cloudHabitRewardsEnabledOverride,
  );
  final cloudRewardHabitId = _cloudRewardHabitId(habit);
  final existingTransaction = await _habitRewardTransactionForDate(
    store,
    habitId: habitId,
    localDateKey: dateKey,
  );
  final hasConfirmedCloudRewardTransaction =
      _isConfirmedCloudHabitRewardTransaction(existingTransaction);
  if (existingTransaction != null) {
    if (cloudHabitRewardsEnabled && hasConfirmedCloudRewardTransaction) {
      _logHabitCloudReward(
        'apply skipped habit=$habitId date=$dateKey '
        'cloud=$cloudHabitRewardsEnabled existing=true cloudConfirmed=true',
      );
      return _HabitRewardCompletionOutcome(
        granted: false,
        baseXp: existingTransaction.baseXp,
        bonusXp: existingTransaction.bonusXp,
        baseCoins: existingTransaction.baseCoins,
        bonusCoins: existingTransaction.bonusCoins,
        appliedEffectIds: existingTransaction.appliedEffectIds,
        transaction: existingTransaction,
      );
    }
  }

  if (cloudHabitRewardsEnabled) {
    _logHabitCloudReward(
      'apply start habit=$habitId date=$dateKey '
      'cloud=$cloudHabitRewardsEnabled existing=${existingTransaction != null} '
      'legacy=${existingTransaction != null && !hasConfirmedCloudRewardTransaction} '
      'cloudConfirmed=$hasConfirmedCloudRewardTransaction '
      'remoteHabitId=${cloudRewardHabitId ?? "<missing>"}',
    );
  }

  if (!cloudHabitRewardsEnabled && existingTransaction != null) {
    return _HabitRewardCompletionOutcome(
      granted: false,
      baseXp: existingTransaction.baseXp,
      bonusXp: existingTransaction.bonusXp,
      baseCoins: existingTransaction.baseCoins,
      bonusCoins: existingTransaction.bonusCoins,
      appliedEffectIds: existingTransaction.appliedEffectIds,
      transaction: existingTransaction,
    );
  }

  if (cloudHabitRewardsEnabled) {
    if (cloudRewardHabitId == null) {
      _logHabitCloudReward(
        'missing remote habit id habit=$habitId date=$dateKey',
      );
      return _HabitRewardCompletionOutcome(
        granted: false,
        baseXp: 0,
        bonusXp: 0,
        baseCoins: 0,
        bonusCoins: 0,
        appliedEffectIds: const <String>[],
        transaction: existingTransaction,
      );
    }

    final completionEventId = _cloudHabitRewardCompletionEventId(
      habitId: habitId,
      dateKey: dateKey,
      existingTransaction: existingTransaction,
    );
    final result = await store._habitCurrencyRewardCoordinator.applyHabitReward(
      habitId: habitId,
      remoteHabitId: cloudRewardHabitId,
      logicalDateKey: dateKey,
      completionEventId: completionEventId,
      requestId: _habitRewardTransactionId(habitId, dateKey),
    );
    final failure = result.failure;
    _logHabitCloudReward(
      'apply result habit=$habitId date=$dateKey '
      'success=${result.isSuccess} pending=${result.isPending} '
      'state=${result.state} '
      'failureCode=${failure?.code} '
      'failureMessage=${failure?.message} '
      'failureDefinitive=${failure?.definitive} '
      'failureRetryable=${failure?.retryable} '
      'failureCause=${failure?.cause}',
    );
    if (result.isSuccess && result.transaction != null) {
      final transaction = result.transaction!;
      await _activeUtilityEffectsRepositoryForStore(store).loadEffects(
        _rewardScopeForStore(store),
      );
      return _HabitRewardCompletionOutcome(
        granted: true,
        baseXp: transaction.baseXp,
        bonusXp: transaction.bonusXp,
        baseCoins: transaction.baseCoins,
        bonusCoins: transaction.bonusCoins,
        appliedEffectIds: transaction.appliedEffectIds,
        transaction: transaction,
      );
    }

    return _HabitRewardCompletionOutcome(
      granted: false,
      baseXp: 0,
      bonusXp: 0,
      baseCoins: 0,
      bonusCoins: 0,
      appliedEffectIds: const <String>[],
      transaction: result.transaction ?? existingTransaction,
    );
  }

  final scope = _rewardScopeForStore(store);
  final effectRepo = _activeUtilityEffectsRepositoryForStore(store);
  final currentEffects = await effectRepo.loadEffects(scope);
  final now = store._nowProvider();
  final xpBoost = _activeUtilityEffectForType(
    currentEffects,
    ActiveUtilityEffectType.xpBoost,
  );
  final coinBoost = _activeUtilityEffectForType(
    currentEffects,
    ActiveUtilityEffectType.coinBoost,
  );
  final reward = _habitRewardCalculator.calculate(
    baseXp: baseXp,
    baseCoins: baseCoins,
    xpBoost: xpBoost,
    coinBoost: coinBoost,
  );

  final nextEffects = <ActiveUtilityEffect>[];
  final appliedEffectIds = <String>[];

  for (final effect in currentEffects) {
    var nextEffect = effect;
    var consumed = false;

    if (xpBoost != null &&
        effect.id == xpBoost.id &&
        reward.consumesXpBoostUse &&
        effect.remainingUses > 0) {
      nextEffect = effect.copyWith(remainingUses: effect.remainingUses - 1);
      consumed = true;
    } else if (coinBoost != null &&
        effect.id == coinBoost.id &&
        reward.consumesCoinBoostUse &&
        effect.remainingUses > 0) {
      nextEffect = effect.copyWith(remainingUses: effect.remainingUses - 1);
      consumed = true;
    }

    if (consumed) {
      appliedEffectIds.add(effect.id);
      if (nextEffect.remainingUses > 0) {
        nextEffects.add(nextEffect);
      }
      continue;
    }

    nextEffects.add(nextEffect);
  }

  _applyHabitRewardValues(
    store,
    userState,
    habit: habit,
    totalXp: reward.totalXp,
    totalCoins: reward.totalCoins,
  );

  final transaction = HabitRewardTransaction(
    id: _habitRewardTransactionId(habitId, dateKey),
    habitId: habitId,
    localDateKey: dateKey,
    baseXp: reward.baseXp,
    bonusXp: reward.bonusXp,
    baseCoins: reward.baseCoins,
    bonusCoins: reward.bonusCoins,
    appliedEffectIds: appliedEffectIds,
    createdAtMillis: now.millisecondsSinceEpoch,
    isReversed: false,
  );

  return _HabitRewardCompletionOutcome(
    granted: true,
    baseXp: reward.baseXp,
    bonusXp: reward.bonusXp,
    baseCoins: reward.baseCoins,
    bonusCoins: reward.bonusCoins,
    appliedEffectIds: appliedEffectIds,
    nextEffects: nextEffects,
    sourceEffects: currentEffects,
    transaction: transaction,
  );
}

Future<_HabitRewardReversalOutcome> _reverseHabitRewardCompletion(
  UserStateStore store,
  Map<String, dynamic> userState, {
  required Map<String, dynamic> habit,
  required String habitId,
  required String dateKey,
}) async {
  final existingTransaction = await _habitRewardTransactionForDate(
    store,
    habitId: habitId,
    localDateKey: dateKey,
  );
  if (existingTransaction == null || existingTransaction.isReversed) {
    return const _HabitRewardReversalOutcome(
      revokedXp: 0,
      revokedCoins: 0,
      reversed: false,
    );
  }

  final cloudHabitRewardsEnabled = HabitCurrencyRewardsConfig.resolveEnabled(
    override: store._cloudHabitRewardsEnabledOverride,
  );
  final cloudRewardHabitId = _cloudRewardHabitId(habit);
  if (cloudHabitRewardsEnabled &&
      _isConfirmedCloudHabitRewardTransaction(existingTransaction)) {
    if (cloudRewardHabitId == null) {
      _logHabitCloudReward(
        'missing remote habit id habit=$habitId date=$dateKey',
      );
      return _HabitRewardReversalOutcome(
        revokedXp: 0,
        revokedCoins: 0,
        reversed: false,
        transaction: existingTransaction,
      );
    }

    final result =
        await store._habitCurrencyRewardCoordinator.reverseHabitReward(
      habitId: habitId,
      remoteHabitId: cloudRewardHabitId,
      logicalDateKey: dateKey,
      completionEventId: existingTransaction.completionEventId,
      requestId: _habitRewardTransactionId(habitId, dateKey),
    );
    if (result.isSuccess) {
      await _activeUtilityEffectsRepositoryForStore(store).loadEffects(
        _rewardScopeForStore(store),
      );
      final revokedXp =
          (existingTransaction.baseXp + existingTransaction.bonusXp)
              .clamp(0, 1 << 30)
              .toInt();
      final revokedCoins =
          (existingTransaction.baseCoins + existingTransaction.bonusCoins)
              .clamp(0, 1 << 30)
              .toInt();
      final updatedTransaction = (result.transaction ?? existingTransaction)
          .copyWith(isReversed: true);
      return _HabitRewardReversalOutcome(
        revokedXp: revokedXp,
        revokedCoins: revokedCoins,
        reversed: true,
        transaction: updatedTransaction,
      );
    }

    return _HabitRewardReversalOutcome(
      revokedXp: 0,
      revokedCoins: 0,
      reversed: false,
      transaction: existingTransaction,
    );
  }

  final revokedXp = (existingTransaction.baseXp + existingTransaction.bonusXp)
      .clamp(0, 1 << 30)
      .toInt();
  final revokedCoins =
      (existingTransaction.baseCoins + existingTransaction.bonusCoins)
          .clamp(0, 1 << 30)
          .toInt();

  _revokeHabitRewardValues(
    userState,
    revokedCoins: revokedCoins,
  );
  _setDailyRewardGrant(userState, habitId: habitId, granted: false);

  final updatedTransaction = existingTransaction.copyWith(isReversed: true);
  return _HabitRewardReversalOutcome(
    revokedXp: revokedXp,
    revokedCoins: revokedCoins,
    reversed: true,
    transaction: updatedTransaction,
  );
}

Future<_HabitRewardRestorationOutcome> _restoreHabitRewardCompletion(
  UserStateStore store,
  Map<String, dynamic> userState, {
  required String habitId,
  required String dateKey,
}) async {
  final existingTransaction = await _habitRewardTransactionForDate(
    store,
    habitId: habitId,
    localDateKey: dateKey,
  );
  if (existingTransaction == null || !existingTransaction.isReversed) {
    return const _HabitRewardRestorationOutcome(
      restored: false,
      restoredCoins: 0,
      transaction: null,
    );
  }

  final restoredCoins = existingTransaction.totalCoins;
  _restoreHabitRewardValues(
    userState,
    restoredCoins: restoredCoins,
  );
  _setDailyRewardGrant(userState, habitId: habitId, granted: true);

  final updatedTransaction = existingTransaction.copyWith(isReversed: false);
  return _HabitRewardRestorationOutcome(
    restored: true,
    restoredCoins: restoredCoins,
    transaction: updatedTransaction,
  );
}

class _HabitRewardCompletionOutcome {
  const _HabitRewardCompletionOutcome({
    required this.granted,
    required this.baseXp,
    required this.bonusXp,
    required this.baseCoins,
    required this.bonusCoins,
    required this.appliedEffectIds,
    this.nextEffects = const <ActiveUtilityEffect>[],
    this.sourceEffects = const <ActiveUtilityEffect>[],
    this.transaction,
  });

  final bool granted;
  final int baseXp;
  final int bonusXp;
  final int baseCoins;
  final int bonusCoins;
  final List<String> appliedEffectIds;
  final List<ActiveUtilityEffect> nextEffects;
  final List<ActiveUtilityEffect> sourceEffects;
  final HabitRewardTransaction? transaction;

  int get totalXp => baseXp + bonusXp;
  int get totalCoins => baseCoins + bonusCoins;
}

class _HabitRewardReversalOutcome {
  const _HabitRewardReversalOutcome({
    required this.revokedXp,
    required this.revokedCoins,
    required this.reversed,
    this.transaction,
  });

  final int revokedXp;
  final int revokedCoins;
  final bool reversed;
  final HabitRewardTransaction? transaction;
}

class _HabitRewardRestorationOutcome {
  const _HabitRewardRestorationOutcome({
    required this.restored,
    required this.restoredCoins,
    required this.transaction,
  });

  final bool restored;
  final int restoredCoins;
  final HabitRewardTransaction? transaction;
}

Future<void> _rollbackHabitRewardPersistence(
  UserStateStore store, {
  required Map<String, dynamic> originalRoot,
  List<ActiveUtilityEffect>? originalEffects,
}) async {
  try {
    if (originalEffects != null) {
      await _saveActiveUtilityEffectsForStore(store, originalEffects);
    }
  } finally {
    store._state = originalRoot;
    await store._repo.save(originalRoot);
  }
}

const Duration streakRecoveryWindow = Duration(hours: 48);
const String _habitOccurrenceStatusesKey = 'habitOccurrenceStatuses';
const String _habitStreakBreaksKey = 'habitStreakBreaks';
const String _habitStreakShieldsKey = 'habitStreakShields';
const String _habitStreakTypeProtected = 'protected';

Map<String, dynamic> _habitStreakBreaksRoot(Map<String, dynamic> userState) {
  final history = _ensureHistoryRoot(userState);
  final breaks = _map(history[_habitStreakBreaksKey]);
  history[_habitStreakBreaksKey] = breaks;
  userState['history'] = history;
  return breaks;
}

Map<String, dynamic> _habitStreakShieldsRoot(Map<String, dynamic> userState) {
  final history = _ensureHistoryRoot(userState);
  final shields = _map(history[_habitStreakShieldsKey]);
  history[_habitStreakShieldsKey] = shields;
  userState['history'] = history;
  return shields;
}

bool _isStreakShieldActiveForLocalDate(
  ActiveStreakShield shield,
  DateTime now,
) {
  return shield.isActiveForLocalDate(now);
}

bool _expireStreakShieldsForLocalDate(
  Map<String, dynamic> userState,
  DateTime now,
) {
  final shields = _habitStreakShieldsRoot(userState);
  var changed = false;

  for (final entry in shields.entries.toList(growable: false)) {
    final rawShield = _map(entry.value);
    if (rawShield.isEmpty) continue;
    final shield = ActiveStreakShield.fromJson(rawShield);
    if (!shield.isActive) continue;
    if (_isStreakShieldActiveForLocalDate(shield, now)) continue;

    shields[entry.key] = shield
        .copyWith(
          status: ActiveStreakShieldStatus.expired,
          clearProtectedOccurrenceDateKey: true,
          clearConsumedAtMillis: true,
        )
        .toJson();
    changed = true;
  }

  return changed;
}

Map<String, dynamic>? _activeStreakShieldRecordForHabit(
  Map<String, dynamic> userState,
  String habitId,
) {
  final shields = _habitStreakShieldsRoot(userState);
  final raw = _map(shields[habitId.trim()]);
  if (raw.isEmpty) return null;
  return raw;
}

List<Map<String, dynamic>> _recoverableStreakBreakRecords(
  Map<String, dynamic> userState,
) {
  final breaks = _habitStreakBreaksRoot(userState);
  return breaks.values
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(_map(entry)))
      .where((entry) {
    final status = (entry['status'] ?? '').toString().trim();
    return status == 'recoverable' || status == 'recovered';
  }).toList(growable: false);
}

Map<String, dynamic>? _recoverableStreakBreakForHabit(
  Map<String, dynamic> userState,
  String habitId,
) {
  final breaks = _habitStreakBreaksRoot(userState);
  final candidates = breaks.values
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(_map(entry)))
      .where((entry) {
    return (entry['habitId'] ?? '').toString().trim() == habitId.trim() &&
        (entry['status'] ?? '').toString().trim() != 'expired';
  }).toList(growable: false)
    ..sort((a, b) {
      final byBroken = (b['brokenAtMillis'] as num? ?? 0)
          .toInt()
          .compareTo((a['brokenAtMillis'] as num? ?? 0).toInt());
      if (byBroken != 0) return byBroken;
      return (b['id'] ?? '').toString().compareTo((a['id'] ?? '').toString());
    });
  if (candidates.isEmpty) return null;
  return candidates.first;
}

bool _isWithinRecoveryWindow(
  DateTime now,
  String missedOccurrenceDateKey,
) {
  final missedDate = _dateFromKey(missedOccurrenceDateKey);
  final missedAt = DateTime(missedDate.year, missedDate.month, missedDate.day);
  return now.difference(missedAt) <= streakRecoveryWindow;
}

int _habitContinuityDaysAfterDate(
  Map<String, dynamic> userState, {
  required Map<String, dynamic> habit,
  required String afterDateKey,
  required DateTime until,
}) {
  final continuityByDay = _extractHabitStreakContinuityByDay(
    userState,
    habit: habit,
  );
  var streak = 0;
  var cursor = _dateFromKey(afterDateKey).add(const Duration(days: 1));
  final end = DateTime(until.year, until.month, until.day);
  while (!cursor.isAfter(end)) {
    final value = continuityByDay[cursor] ?? 0;
    if (value <= 0) break;
    streak += 1;
    cursor = cursor.add(const Duration(days: 1));
  }
  return streak;
}

Map<DateTime, int> _extractHabitStreakContinuityByDay(
  Map<String, dynamic> userState, {
  required Map<String, dynamic> habit,
}) {
  final output = <DateTime, int>{};
  final habitId = _habitIdValue(habit);
  if (habitId == null || habitId.isEmpty) return output;

  final history = _ensureHistoryRoot(userState);
  final completions = _map(history['habitCompletions']);
  final countValues = _map(history['habitCountValues']);
  final occurrenceStatuses = _map(history[_habitOccurrenceStatusesKey]);
  final breakRecords = _map(history[_habitStreakBreaksKey]);
  final keys = <String>{
    ...completions.keys.map((key) => key.toString()),
    ...countValues.keys.map((key) => key.toString()),
    ...occurrenceStatuses.keys.map((key) => key.toString()),
    ...breakRecords.values
        .whereType<Map>()
        .map((entry) => (entry['missedOccurrenceDateKey'] ?? '').toString())
        .where((key) => key.trim().isNotEmpty),
  };

  for (final dayKey in keys) {
    final date = _dateFromKey(dayKey);
    final day = DateTime(date.year, date.month, date.day);
    if (!_isScheduledForDate(habit, day)) continue;

    final completionMap = _map(completions[dayKey]);
    final countValueMap = _map(countValues[dayKey]);
    final statusMap = _map(occurrenceStatuses[dayKey]);
    final status = (statusMap[habitId] ?? '').toString().trim();
    final breakForDay = _recoverableStreakBreakForHabitDate(
      userState,
      habitId: habitId,
      dateKey: dayKey,
    );

    final continuity = _normalizedHabitType(habit['type']) == 'count'
        ? _safeNum(countValueMap[habitId], fallback: 0) > 0
        : completionMap[habitId] == true;
    final protected = status == _habitStreakTypeProtected;
    final recovered =
        breakForDay != null && breakForDay['status'] == 'recovered';

    output[day] = (continuity || protected || recovered) ? 1 : 0;
  }

  return output;
}

Map<String, dynamic>? _recoverableStreakBreakForHabitDate(
  Map<String, dynamic> userState, {
  required String habitId,
  required String dateKey,
}) {
  final breaks = _habitStreakBreaksRoot(userState);
  for (final entry in breaks.values.whereType<Map>()) {
    final record = Map<String, dynamic>.from(_map(entry));
    final recordHabitId = (record['habitId'] ?? '').toString().trim();
    final recordDate =
        (record['missedOccurrenceDateKey'] ?? '').toString().trim();
    if (recordHabitId == habitId.trim() && recordDate == dateKey.trim()) {
      return record;
    }
  }
  return null;
}

int _computeHabitCurrentStreak(
  Map<DateTime, int> continuityByDay,
  DateTime today, {
  required Map<String, dynamic> userState,
  required String habitId,
}) {
  final derived = _computeCurrentStreak(continuityByDay, today);
  final breakRecord = _recoverableStreakBreakForHabit(
    userState,
    habitId,
  );
  if (breakRecord == null) return derived;

  final status = (breakRecord['status'] ?? '').toString().trim();
  if (status != 'recovered') return derived;

  final missedOccurrenceDateKey =
      (breakRecord['missedOccurrenceDateKey'] ?? '').toString().trim();
  if (missedOccurrenceDateKey.isEmpty) return derived;

  final streakAfterRecovery = _habitContinuityDaysAfterDate(
    userState,
    habit: _habitByIdFromState(userState, habitId) ??
        <String, dynamic>{'id': habitId},
    afterDateKey: missedOccurrenceDateKey,
    until: today,
  );

  final previousStreak =
      (_safeInt(breakRecord['previousStreak'], fallback: 0)).clamp(0, 1 << 30);
  final recoveredFloor = previousStreak + streakAfterRecovery;
  return derived > recoveredFloor ? derived : recoveredFloor;
}

int _computeHabitBestStreak(
  Map<DateTime, int> continuityByDay, {
  required Map<String, dynamic> userState,
  required String habitId,
}) {
  final derived = _computeBestStreak(continuityByDay);
  final breakRecords = _habitStreakBreaksRoot(userState)
      .values
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(_map(entry)))
      .where((entry) {
    return (entry['habitId'] ?? '').toString().trim() == habitId.trim() &&
        (entry['status'] ?? '').toString().trim() == 'recovered';
  }).toList(growable: false);

  var best = derived;
  for (final record in breakRecords) {
    final previousStreak = _safeInt(record['previousStreak'], fallback: 0);
    final streakAfterRecovery = _habitContinuityDaysAfterDate(
      userState,
      habit: _habitByIdFromState(userState, habitId) ??
          <String, dynamic>{'id': habitId},
      afterDateKey: (record['missedOccurrenceDateKey'] ?? '').toString(),
      until: DateTime.now(),
    );
    final recovered = previousStreak + streakAfterRecovery;
    if (recovered > best) best = recovered;
  }

  return best;
}

Map<String, dynamic>? _habitByIdFromState(
  Map<String, dynamic> userState,
  String habitId,
) {
  final activeHabits = _list(userState['activeHabits']).whereType<Map>();
  for (final habit in activeHabits) {
    final mapHabit = Map<String, dynamic>.from(_map(habit));
    if (_habitIdValue(mapHabit) == habitId) return mapHabit;
  }
  return null;
}

List<ActiveStreakShield> _activeStreakShields(UserStateStore store) {
  final root = store._state;
  if (root == null) return const <ActiveStreakShield>[];
  final rootCopy = _cloneMap(root);
  final userState = _ensureUserStateRoot(rootCopy);
  final now = store._nowProvider();
  final expired = _expireStreakShieldsForLocalDate(userState, now);
  final active = _habitStreakShieldsRoot(userState)
      .entries
      .where((entry) =>
          _activeStreakShieldRecordForHabit(
            userState,
            entry.key.toString(),
          ) !=
          null)
      .map((entry) => Map<String, dynamic>.from(_map(entry.value)))
      .map(ActiveStreakShield.fromJson)
      .where((shield) => shield.isActiveForLocalDate(now))
      .toList(growable: false);

  if (expired) {
    unawaited(store.save(rootCopy));
  }

  return active;
}

List<RecoverableStreakBreak> _recoverableStreakBreaks(UserStateStore store) {
  final root = store._state;
  if (root == null) return const <RecoverableStreakBreak>[];
  final userState = _ensureUserStateRoot(root);
  return _recoverableStreakBreakRecords(userState)
      .map(RecoverableStreakBreak.fromJson)
      .toList(growable: false);
}

ActiveStreakShield? _activeStreakShieldForHabit(
  UserStateStore store,
  String habitId,
) {
  final root = store._state;
  if (root == null) return null;
  final rootCopy = _cloneMap(root);
  final userState = _ensureUserStateRoot(rootCopy);
  final now = store._nowProvider();
  final expired = _expireStreakShieldsForLocalDate(userState, now);
  final record = _activeStreakShieldRecordForHabit(userState, habitId);
  if (expired) {
    unawaited(store.save(rootCopy));
  }
  if (record == null) return null;
  final shield = ActiveStreakShield.fromJson(record);
  return shield.isActiveForLocalDate(now) ? shield : null;
}

RecoverableStreakBreak? _recoverableStreakBreakForHabitStore(
  UserStateStore store,
  String habitId,
) {
  final root = store._state;
  if (root == null) return null;
  final userState = _ensureUserStateRoot(root);
  final record = _recoverableStreakBreakForHabit(userState, habitId);
  if (record == null) return null;
  return RecoverableStreakBreak.fromJson(record);
}

Future<StreakShieldOperationResult> _activateStreakShield(
  UserStateStore store, {
  required String habitId,
  required String operationId,
  String? utilityId,
}) async {
  final root = store._state;
  if (root == null) {
    return const StreakShieldOperationResult(
      status: StreakShieldOperationStatus.persistenceFailure,
    );
  }

  final normalizedHabitId = habitId.trim();
  final normalizedOperationId = operationId.trim();
  final normalizedUtilityId = (utilityId ?? 'utility_streak_shield_1').trim();
  if (normalizedHabitId.isEmpty || normalizedOperationId.isEmpty) {
    return const StreakShieldOperationResult(
      status: StreakShieldOperationStatus.operationAlreadyProcessed,
    );
  }

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState, nowProvider: store._nowProvider);
  final now = store._nowProvider();
  _expireStreakShieldsForLocalDate(userState, now);
  final habit = _habitByIdFromState(userState, normalizedHabitId);
  if (habit == null) {
    return const StreakShieldOperationResult(
      status: StreakShieldOperationStatus.habitNotFound,
    );
  }
  if (_isArchivedHabit(habit)) {
    return const StreakShieldOperationResult(
      status: StreakShieldOperationStatus.habitNotEligible,
    );
  }

  final currentShield = _activeStreakShieldRecordForHabit(
    userState,
    normalizedHabitId,
  );
  if (currentShield != null) {
    final currentShieldModel = ActiveStreakShield.fromJson(currentShield);
    final currentOperationId =
        (currentShield['operationId'] ?? '').toString().trim();
    if (currentOperationId == normalizedOperationId) {
      return StreakShieldOperationResult(
        status: StreakShieldOperationStatus.success,
        shield: currentShieldModel,
      );
    }
    if (currentShieldModel.isActiveForLocalDate(now)) {
      return const StreakShieldOperationResult(
        status: StreakShieldOperationStatus.shieldAlreadyActive,
      );
    }
  }

  if (store._utilityConsumptionRepository != null) {
    final cloudRewardHabitId = _cloudRewardHabitId(habit);
    final requestId =
        'utility_activate:${(store.activeLocalScopeUserId ?? store.userId ?? '').trim()}:$normalizedOperationId';
    _logStreakShieldCloud(
      'start habitId=$normalizedHabitId remoteHabitId=${cloudRewardHabitId ?? "<missing>"} '
      'operationId=$normalizedOperationId requestId=$requestId',
    );
    if (cloudRewardHabitId == null) {
      _logStreakShieldCloud(
        'error habitId=$normalizedHabitId remoteHabitId=<missing> '
        'operationId=$normalizedOperationId reason=missing_remote_habit_uuid',
      );
      return const StreakShieldOperationResult(
        status: StreakShieldOperationStatus.persistenceFailure,
        errorMessage:
            'Missing remote habit UUID for cloud streak shield activation.',
      );
    }
    try {
      final ledger =
          await store._utilityConsumptionRepository!.activateUtilityEffect(
        requestId: requestId,
        utilityId: normalizedUtilityId,
        operationType: 'activate',
        sourceType: 'streak_shield',
        sourceId: normalizedOperationId,
        habitId: cloudRewardHabitId,
      );
      _logStreakShieldCloud(
        'result habitId=$normalizedHabitId remoteHabitId=$cloudRewardHabitId '
        'operationId=$normalizedOperationId ledgerId=${ledger.id} '
        'idempotent=${ledger.isIdempotent}',
      );
    } catch (error) {
      _logStreakShieldCloud(
        'error habitId=$normalizedHabitId remoteHabitId=$cloudRewardHabitId '
        'operationId=$normalizedOperationId error=$error',
      );
      return StreakShieldOperationResult(
        status: StreakShieldOperationStatus.persistenceFailure,
        errorMessage: error.toString(),
      );
    }
  }

  final shield = ActiveStreakShield(
    id: 'streak_shield_${normalizedHabitId}_$normalizedOperationId',
    userId: (store.activeLocalScopeUserId ?? store.userId ?? '').trim(),
    habitId: normalizedHabitId,
    utilityId: normalizedUtilityId,
    activatedAtMillis: now.millisecondsSinceEpoch,
    status: ActiveStreakShieldStatus.armed,
    protectedOccurrenceDateKey: _dateKey(now),
    operationId: normalizedOperationId,
  );

  final rootCopy = _cloneMap(root);
  final nextUserState = _ensureUserStateRoot(rootCopy);
  final shields = _habitStreakShieldsRoot(nextUserState);
  shields[normalizedHabitId] = shield.toJson();
  final history = _ensureHistoryRoot(nextUserState);
  history[_habitStreakShieldsKey] = shields;
  nextUserState['history'] = history;
  rootCopy['userState'] = nextUserState;

  try {
    await store.save(rootCopy);
  } catch (error) {
    return StreakShieldOperationResult(
      status: StreakShieldOperationStatus.persistenceFailure,
      errorMessage: error.toString(),
    );
  }

  return StreakShieldOperationResult(
    status: StreakShieldOperationStatus.success,
    shield: shield,
  );
}

Future<StreakRecoverOperationResult> _recoverStreakBreak(
  UserStateStore store, {
  required String breakId,
  required String operationId,
}) async {
  final root = store._state;
  if (root == null) {
    return const StreakRecoverOperationResult(
      status: StreakRecoverOperationStatus.persistenceFailure,
    );
  }

  final normalizedBreakId = breakId.trim();
  final normalizedOperationId = operationId.trim();
  if (normalizedBreakId.isEmpty || normalizedOperationId.isEmpty) {
    return const StreakRecoverOperationResult(
      status: StreakRecoverOperationStatus.operationAlreadyProcessed,
    );
  }

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState, nowProvider: store._nowProvider);
  final breaks = _habitStreakBreaksRoot(userState);
  final rawBreak = _map(breaks[normalizedBreakId]);
  if (rawBreak.isEmpty) {
    return const StreakRecoverOperationResult(
      status: StreakRecoverOperationStatus.noRecoverableBreak,
    );
  }

  final breakRecord = RecoverableStreakBreak.fromJson(rawBreak);
  if (breakRecord.isRecovered) {
    if ((rawBreak['recoveryOperationId'] ?? '').toString().trim() ==
        normalizedOperationId) {
      return StreakRecoverOperationResult(
        status: StreakRecoverOperationStatus.success,
        recoveredBreak: breakRecord,
      );
    }
    return const StreakRecoverOperationResult(
      status: StreakRecoverOperationStatus.alreadyRecovered,
    );
  }

  final now = store._nowProvider();
  if (!_isWithinRecoveryWindow(now, breakRecord.missedOccurrenceDateKey)) {
    final expired = breakRecord.copyWith(
      status: RecoverableStreakBreakStatus.expired,
    );
    breaks[normalizedBreakId] = expired.toJson();
    final history = _ensureHistoryRoot(userState);
    history[_habitStreakBreaksKey] = breaks;
    userState['history'] = history;
    final nextRoot = _cloneMap(root);
    nextRoot['userState'] = userState;
    await store.save(nextRoot);
    return const StreakRecoverOperationResult(
      status: StreakRecoverOperationStatus.recoveryExpired,
    );
  }

  if (store._utilityConsumptionRepository != null) {
    final requestId =
        'utility_recover:${(store.activeLocalScopeUserId ?? store.userId ?? '').trim()}:$normalizedBreakId:$normalizedOperationId';
    _logStreakRecoverCloud(
      'start breakId=$normalizedBreakId operationId=$normalizedOperationId requestId=$requestId',
    );
    try {
      final ledger =
          await store._utilityConsumptionRepository!.applyStreakRecover(
        requestId: requestId,
        utilityId: 'utility_streak_recover_1',
        operationType: 'recover',
        breakId: normalizedBreakId,
      );
      _logStreakRecoverCloud(
        'result breakId=$normalizedBreakId operationId=$normalizedOperationId requestId=$requestId ledgerId=${ledger.id} idempotent=${ledger.isIdempotent}',
      );
    } catch (error) {
      _logStreakRecoverCloud(
        'error breakId=$normalizedBreakId operationId=$normalizedOperationId requestId=$requestId error=$error',
      );
      return StreakRecoverOperationResult(
        status: StreakRecoverOperationStatus.persistenceFailure,
        errorMessage: error.toString(),
      );
    }
  }

  final updated = breakRecord.copyWith(
    status: RecoverableStreakBreakStatus.recovered,
    recoveredAtMillis: now.millisecondsSinceEpoch,
    recoveryOperationId: normalizedOperationId,
  );
  breaks[normalizedBreakId] = updated.toJson();
  final history = _ensureHistoryRoot(userState);
  history[_habitStreakBreaksKey] = breaks;
  userState['history'] = history;
  final nextRoot = _cloneMap(root);
  nextRoot['userState'] = userState;

  try {
    await store.save(nextRoot);
  } catch (error) {
    return StreakRecoverOperationResult(
      status: StreakRecoverOperationStatus.persistenceFailure,
      errorMessage: error.toString(),
    );
  }

  return StreakRecoverOperationResult(
    status: StreakRecoverOperationStatus.success,
    recoveredBreak: updated,
  );
}

Future<void> _expireRecoverableStreakBreaks(UserStateStore store) async {
  final root = store._state;
  if (root == null) return;
  final userState = _ensureUserStateRoot(root);
  final breaks = _habitStreakBreaksRoot(userState);
  final now = store._nowProvider();
  var changed = false;

  for (final entry in breaks.entries.toList(growable: false)) {
    final rawBreak = _map(entry.value);
    if (rawBreak.isEmpty) continue;
    final breakRecord = RecoverableStreakBreak.fromJson(rawBreak);
    if (!breakRecord.isRecoverable) continue;
    if (_isWithinRecoveryWindow(now, breakRecord.missedOccurrenceDateKey)) {
      continue;
    }

    breaks[entry.key] = breakRecord
        .copyWith(status: RecoverableStreakBreakStatus.expired)
        .toJson();
    changed = true;
  }

  if (!changed) return;
  final history = _ensureHistoryRoot(userState);
  history[_habitStreakBreaksKey] = breaks;
  userState['history'] = history;
  final nextRoot = _cloneMap(root);
  nextRoot['userState'] = userState;
  await store.save(nextRoot);
}
