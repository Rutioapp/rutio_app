part of 'user_state_store.dart';

StreakProtectionRepository _streakProtectionRepositoryForStore(
  UserStateStore store,
) {
  return store._streakProtectionRepository ??=
      SupabaseStreakProtectionRepository();
}

StreakProtectionPendingOperationStore
    _streakProtectionPendingOperationStoreForStore(UserStateStore store) {
  return store._streakProtectionPendingOperationStore ??=
      SharedPreferencesStreakProtectionPendingOperationStore();
}

class _StreakProtectionRemoteSnapshot {
  const _StreakProtectionRemoteSnapshot({
    required this.timeZoneChanged,
    required this.shields,
    required this.breaks,
    required this.isComplete,
  });

  final bool timeZoneChanged;
  final List<HabitStreakShieldRemote> shields;
  final List<HabitStreakBreakRemote> breaks;
  final bool isComplete;
}

Future<void> _syncStreakProtectionFromRemoteBestEffort(
  UserStateStore store,
) async {
  try {
    if (store._state == null) {
      await store.load();
    }

    final root = store._state;
    if (root == null) return;
    final userState = _ensureUserStateRoot(root);
    final changed = await _syncStreakProtectionIntoUserState(
      store,
      userState: userState,
    );
    if (!changed) return;

    final nextRoot = _cloneMap(root);
    nextRoot['userState'] = userState;
    _touchLastSavedAt(userState, nowProvider: store._nowProvider);
    store._state = nextRoot;
    await store._repo.save(nextRoot);
    store._emitChanged();
  } catch (error) {
    if (kDebugMode) {
      debugPrint('[streak_protection_sync] unexpected sync error: $error');
    }
  }
}

Future<bool> _syncStreakProtectionIntoUserState(
  UserStateStore store, {
  required Map<String, dynamic> userState,
}) async {
  final authenticatedUserId = store._currentSupabaseUserIdProvider();
  if ((authenticatedUserId ?? '').trim().isEmpty) {
    return false;
  }
  final localUserId =
      (userState['userId'] ?? userState['id'] ?? '').toString().trim();
  if (localUserId.isEmpty || localUserId != authenticatedUserId!.trim()) {
    return false;
  }

  final closeChanged =
      await _closeRemoteMissedHabitOccurrencesBestEffort(store, userState);

  final snapshot = await _fetchStreakProtectionSnapshot(store, userState);
  var changed = closeChanged;
  if (snapshot == null) {
    return changed;
  }

  if (snapshot.timeZoneChanged) {
    final timeZone = await _currentDeviceTimeZoneBestEffort(store);
    if (timeZone != null) {
      final meta = _map(userState['meta']);
      meta['lastSyncedHabitTimeZone'] = timeZone;
      userState['meta'] = meta;
      changed = true;
    }
  }

  if (!snapshot.isComplete) {
    return changed;
  }

  changed = _reconcileRemoteStreakProtectionSnapshot(
        userState,
        shields: snapshot.shields,
        breaks: snapshot.breaks,
      ) ||
      changed;
  return changed;
}

Future<_StreakProtectionRemoteSnapshot?> _fetchStreakProtectionSnapshot(
  UserStateStore store,
  Map<String, dynamic> userState,
) async {
  return _fetchSharedStreakProtectionSnapshot(store, userState);
}

Future<_StreakProtectionRemoteSnapshot?> _fetchFreshStreakProtectionSnapshot(
  UserStateStore store,
  Map<String, dynamic> userState,
) async {
  final activeFetch = store._streakProtectionRemoteSyncFuture;
  if (activeFetch != null) {
    await activeFetch;
  }
  return _fetchSharedStreakProtectionSnapshot(store, userState);
}

Future<_StreakProtectionRemoteSnapshot?> _fetchSharedStreakProtectionSnapshot(
  UserStateStore store,
  Map<String, dynamic> userState,
) async {
  final activeFetch = store._streakProtectionRemoteSyncFuture;
  if (activeFetch != null) {
    return activeFetch;
  }

  late final Future<_StreakProtectionRemoteSnapshot?> fetchFuture;
  fetchFuture = _runStreakProtectionSnapshotFetch(store, userState);
  store._streakProtectionRemoteSyncFuture = fetchFuture;

  try {
    return await fetchFuture;
  } finally {
    if (identical(store._streakProtectionRemoteSyncFuture, fetchFuture)) {
      store._streakProtectionRemoteSyncFuture = null;
    }
  }
}

Future<_StreakProtectionRemoteSnapshot?> _runStreakProtectionSnapshotFetch(
  UserStateStore store,
  Map<String, dynamic> userState,
) async {
  final repository = _streakProtectionRepositoryForStore(store);
  final timeZoneChanged = await _syncHabitTimeZoneCacheBestEffort(
    store,
    userState: userState,
    repository: repository,
  );

  final shieldsResult = await repository.fetchShieldsForCurrentUser();
  if (!shieldsResult.isSuccess) {
    _debugStreakProtectionSync(
      'shield fetch skipped: ${shieldsResult.error?.message}',
    );
    return _StreakProtectionRemoteSnapshot(
      timeZoneChanged: timeZoneChanged,
      shields: const <HabitStreakShieldRemote>[],
      breaks: const <HabitStreakBreakRemote>[],
      isComplete: false,
    );
  }

  final breaksResult = await repository.fetchBreaksForCurrentUser();
  if (!breaksResult.isSuccess) {
    _debugStreakProtectionSync(
      'break fetch skipped: ${breaksResult.error?.message}',
    );
    return _StreakProtectionRemoteSnapshot(
      timeZoneChanged: timeZoneChanged,
      shields: const <HabitStreakShieldRemote>[],
      breaks: const <HabitStreakBreakRemote>[],
      isComplete: false,
    );
  }

  return _StreakProtectionRemoteSnapshot(
    timeZoneChanged: timeZoneChanged,
    shields: shieldsResult.data ?? const <HabitStreakShieldRemote>[],
    breaks: breaksResult.data ?? const <HabitStreakBreakRemote>[],
    isComplete: true,
  );
}

Future<bool> _syncHabitTimeZoneCacheBestEffort(
  UserStateStore store, {
  required Map<String, dynamic> userState,
  required StreakProtectionRepository repository,
}) async {
  String? timeZone;
  try {
    timeZone =
        (await store._deviceTimeZoneProvider.getLocalIanaTimeZone())?.trim();
  } catch (error) {
    _debugStreakProtectionSync('device timezone unavailable: $error');
    return false;
  }

  if (timeZone == null || timeZone.isEmpty) {
    _debugStreakProtectionSync('device timezone unavailable');
    return false;
  }
  if (RegExp(r'^[+-]\d{2}:\d{2}$').hasMatch(timeZone)) {
    _debugStreakProtectionSync('offset timezone rejected: $timeZone');
    return false;
  }

  final meta = _map(userState['meta']);
  final lastSynced = (meta['lastSyncedHabitTimeZone'] ?? '').toString().trim();
  if (lastSynced == timeZone) return false;

  final result = await repository.setHabitTimeZone(timeZone);
  if (!result.isSuccess) {
    _debugStreakProtectionSync(
      'timezone sync failed: ${result.error?.message}',
    );
    return false;
  }

  return true;
}

Future<String?> _currentDeviceTimeZoneBestEffort(
  UserStateStore store,
) async {
  try {
    final timeZone =
        (await store._deviceTimeZoneProvider.getLocalIanaTimeZone())?.trim();
    if (timeZone == null || timeZone.isEmpty) return null;
    if (RegExp(r'^[+-]\d{2}:\d{2}$').hasMatch(timeZone)) return null;
    return timeZone;
  } catch (_) {
    return null;
  }
}

bool _reconcileRemoteStreakProtectionSnapshot(
  Map<String, dynamic> userState, {
  required List<HabitStreakShieldRemote> shields,
  required List<HabitStreakBreakRemote> breaks,
}) {
  final shieldsChanged = _reconcileRemoteStreakShields(userState, shields);
  final breaksChanged = _reconcileRemoteStreakBreaks(userState, breaks);
  return shieldsChanged || breaksChanged;
}

bool _isAuthenticatedStreakProtectionUser(
  UserStateStore store,
  Map<String, dynamic> userState,
) {
  final authenticatedUserId = store._currentSupabaseUserIdProvider();
  if ((authenticatedUserId ?? '').trim().isEmpty) return false;
  final localUserId =
      (userState['userId'] ?? userState['id'] ?? '').toString().trim();
  return localUserId.isNotEmpty && localUserId == authenticatedUserId!.trim();
}

Future<void> _syncHabitTimeZoneForMutationBestEffort(
  UserStateStore store,
  Map<String, dynamic> userState,
) async {
  await _syncHabitTimeZoneCacheBestEffort(
    store,
    userState: userState,
    repository: _streakProtectionRepositoryForStore(store),
  );
}

Future<PendingStreakShieldOperation> _pendingStreakShieldOperationForMutation(
  UserStateStore store, {
  required String remoteHabitId,
  required String operationId,
  required String protectedOccurrenceDate,
  required String utilityId,
}) async {
  final pendingStore = _streakProtectionPendingOperationStoreForStore(store);
  final userId = (store.activeLocalScopeUserId ?? store.userId ?? '').trim();
  final existing = await pendingStore.loadShieldOperation(userId, operationId);
  if (existing != null) return existing;

  final now = store._nowProvider().toUtc();
  final pending = PendingStreakShieldOperation(
    userId: userId,
    requestId:
        'streak-shield:$remoteHabitId:$operationId:$protectedOccurrenceDate:${now.microsecondsSinceEpoch}',
    operationId: operationId,
    remoteHabitId: remoteHabitId,
    protectedOccurrenceDate: protectedOccurrenceDate,
    utilityId: utilityId,
    createdAtMillis: now.millisecondsSinceEpoch,
  );
  await pendingStore.saveShieldOperation(pending);
  return pending;
}

Future<PendingStreakRecoverOperation> _pendingStreakRecoverOperationForMutation(
  UserStateStore store, {
  required String breakId,
  required String operationId,
  required String utilityId,
}) async {
  final pendingStore = _streakProtectionPendingOperationStoreForStore(store);
  final userId = (store.activeLocalScopeUserId ?? store.userId ?? '').trim();
  final existing = await pendingStore.loadRecoverOperation(userId, operationId);
  if (existing != null) return existing;

  final now = store._nowProvider().toUtc();
  final pending = PendingStreakRecoverOperation(
    userId: userId,
    requestId:
        'streak-recover:$breakId:$operationId:${now.microsecondsSinceEpoch}',
    operationId: operationId,
    breakId: breakId,
    utilityId: utilityId,
    createdAtMillis: now.millisecondsSinceEpoch,
  );
  await pendingStore.saveRecoverOperation(pending);
  return pending;
}

Future<bool> _confirmStreakProtectionSnapshotAfterMutation(
  UserStateStore store,
  Map<String, dynamic> userState,
) async {
  final snapshot = await _fetchFreshStreakProtectionSnapshot(store, userState);
  if (snapshot == null || !snapshot.isComplete) return false;
  var changed = false;
  if (snapshot.timeZoneChanged) {
    final timeZone = await _currentDeviceTimeZoneBestEffort(store);
    if (timeZone != null) {
      final meta = _map(userState['meta']);
      meta['lastSyncedHabitTimeZone'] = timeZone;
      userState['meta'] = meta;
      changed = true;
    }
  }
  return _reconcileRemoteStreakProtectionSnapshot(
        userState,
        shields: snapshot.shields,
        breaks: snapshot.breaks,
      ) ||
      changed;
}

Future<bool> _closeRemoteMissedHabitOccurrencesBestEffort(
  UserStateStore store,
  Map<String, dynamic> userState,
) async {
  final activeClose = store._streakProtectionRemoteCloseFuture;
  if (activeClose != null) {
    return activeClose;
  }

  late final Future<bool> sharedFuture;
  sharedFuture =
      _runCloseRemoteMissedHabitOccurrencesBestEffort(store, userState);
  store._streakProtectionRemoteCloseFuture = sharedFuture;
  try {
    return await sharedFuture;
  } finally {
    if (identical(store._streakProtectionRemoteCloseFuture, sharedFuture)) {
      store._streakProtectionRemoteCloseFuture = null;
    }
  }
}

Future<bool> _runCloseRemoteMissedHabitOccurrencesBestEffort(
  UserStateStore store,
  Map<String, dynamic> userState,
) async {
  if (!_isAuthenticatedStreakProtectionUser(store, userState)) return false;
  if (store.isCalendarSimulated) {
    if (kDebugMode) {
      debugPrint(
        '[calendar-clock] skipped remote date mutation because simulated calendar is active operation=close_missed_occurrence',
      );
    }
    return false;
  }
  final todayKey = _todayFrom(store._calendarNowProvider);
  final history = _ensureHistoryRoot(userState);
  final occurrenceStatuses = _map(history[_habitOccurrenceStatusesKey]);
  final habitsById = <String, Map<String, dynamic>>{};
  for (final habit in _list(userState['activeHabits']).whereType<Map>()) {
    final map = Map<String, dynamic>.from(_map(habit));
    final id = _habitIdValue(map);
    if (id != null) habitsById[id] = map;
  }

  final repository = _streakProtectionRepositoryForStore(store);

  var changed = false;
  for (final dayEntry in occurrenceStatuses.entries.toList(growable: false)) {
    final dayKey = dayEntry.key.toString().trim();
    if (dayKey.isEmpty || dayKey.compareTo(todayKey) >= 0) continue;
    final statuses = _map(dayEntry.value);
    for (final statusEntry in statuses.entries.toList(growable: false)) {
      final localHabitId = statusEntry.key.toString().trim();
      if (localHabitId.isEmpty) continue;
      if ((statusEntry.value ?? '').toString().trim() !=
          HabitOccurrenceStatus.missed.key) {
        continue;
      }
      if (_hasRemoteProtectionForOccurrence(
        userState,
        habitId: localHabitId,
        dateKey: dayKey,
      )) {
        continue;
      }
      final remoteHabitId = _cloudRewardHabitId(habitsById[localHabitId] ?? {});
      if (remoteHabitId == null) continue;

      final requestId = 'streak-close:$remoteHabitId:$dayKey';
      final breakId = 'streak-break:$remoteHabitId:$dayKey';
      final result = await repository.closeMissedHabitOccurrence(
        requestId: requestId,
        habitId: remoteHabitId,
        logicalDate: dayKey,
        breakId: breakId,
      );
      if (!result.isSuccess || result.data == null) {
        _debugStreakProtectionSync(
          'close skipped habitId=$localHabitId date=$dayKey: '
          '${result.error?.message}',
        );
        continue;
      }
      changed = _applyClosedOccurrenceRemoteResult(
            userState,
            localHabitId: localHabitId,
            dateKey: dayKey,
            result: result.data!,
          ) ||
          changed;
    }
  }
  return changed;
}

bool _applyClosedOccurrenceRemoteResult(
  Map<String, dynamic> userState, {
  required String localHabitId,
  required String dateKey,
  required CloseMissedHabitOccurrenceRemoteResult result,
}) {
  var changed = false;
  switch (result.status) {
    case CloseMissedHabitOccurrenceRemoteStatus.alreadyContinuous:
      changed = _removeBreaksForLocalOccurrence(
            userState,
            habitId: localHabitId,
            dateKey: dateKey,
          ) ||
          changed;
      break;
    case CloseMissedHabitOccurrenceRemoteStatus.shieldConsumed:
      final shield = result.shield;
      if (shield != null) {
        changed =
            _upsertRemoteStreakShieldInCache(userState, shield) || changed;
      }
      changed = _removeBreaksForLocalOccurrence(
            userState,
            habitId: localHabitId,
            dateKey: dateKey,
          ) ||
          changed;
      break;
    case CloseMissedHabitOccurrenceRemoteStatus.breakRecorded:
    case CloseMissedHabitOccurrenceRemoteStatus.breakExpired:
      final breakRecord = result.breakRecord;
      if (breakRecord != null) {
        changed = _removeBreaksForLocalOccurrence(
              userState,
              habitId: localHabitId,
              dateKey: dateKey,
            ) ||
            changed;
        changed =
            _upsertRemoteStreakBreakInCache(userState, breakRecord) || changed;
      }
      break;
  }
  return changed;
}

bool _upsertRemoteStreakShieldInCache(
  Map<String, dynamic> userState,
  HabitStreakShieldRemote remote,
) {
  final localHabitId = _localHabitIdByRemoteHabitId(userState)[remote.habitId];
  if (localHabitId == null) return false;
  final shields = _habitStreakShieldsRoot(userState);
  final next = _localShieldJsonFromRemote(
    remote,
    localHabitId: localHabitId,
    userId: (userState['userId'] ?? userState['id'] ?? '').toString(),
  );
  if (_deepJsonEquals(_map(shields[localHabitId]), next)) return false;
  shields[localHabitId] = next;
  final history = _ensureHistoryRoot(userState);
  history[_habitStreakShieldsKey] = shields;
  userState['history'] = history;
  return true;
}

bool _hasRemoteProtectionForOccurrence(
  Map<String, dynamic> userState, {
  required String habitId,
  required String dateKey,
}) {
  for (final entry in _habitStreakBreaksRoot(userState).values) {
    final streakBreak = _map(entry);
    if (!_hasRemoteBreakMarkers(streakBreak)) continue;
    if ((streakBreak['habitId'] ?? '').toString().trim() == habitId &&
        (streakBreak['missedOccurrenceDateKey'] ?? '').toString().trim() ==
            dateKey) {
      return true;
    }
  }
  for (final entry in _habitStreakShieldsRoot(userState).values) {
    final shield = _map(entry);
    if (!_hasRemoteShieldMarkers(shield)) continue;
    if ((shield['habitId'] ?? '').toString().trim() != habitId) continue;
    if ((shield['protectedOccurrenceDateKey'] ?? '').toString().trim() !=
        dateKey) {
      continue;
    }
    if ((shield['status'] ?? '').toString().trim() == 'consumed') {
      return true;
    }
  }
  return false;
}

bool _removeBreaksForLocalOccurrence(
  Map<String, dynamic> userState, {
  required String habitId,
  required String dateKey,
}) {
  final breaks = _habitStreakBreaksRoot(userState);
  var changed = false;
  for (final entry in breaks.entries.toList(growable: false)) {
    final current = _map(entry.value);
    if ((current['habitId'] ?? '').toString().trim() == habitId &&
        (current['missedOccurrenceDateKey'] ?? '').toString().trim() ==
            dateKey) {
      breaks.remove(entry.key);
      changed = true;
    }
  }
  if (changed) {
    final history = _ensureHistoryRoot(userState);
    history[_habitStreakBreaksKey] = breaks;
    userState['history'] = history;
  }
  return changed;
}

bool _upsertRemoteStreakBreakInCache(
  Map<String, dynamic> userState,
  HabitStreakBreakRemote remote,
) {
  final localHabitId = _localHabitIdByRemoteHabitId(userState)[remote.habitId];
  if (localHabitId == null) return false;
  final breaks = _habitStreakBreaksRoot(userState);
  final next = _localBreakJsonFromRemote(
    remote,
    localHabitId: localHabitId,
    userId: (userState['userId'] ?? userState['id'] ?? '').toString(),
  );
  if (_deepJsonEquals(_map(breaks[remote.breakId]), next)) return false;
  breaks[remote.breakId] = next;
  final history = _ensureHistoryRoot(userState);
  history[_habitStreakBreaksKey] = breaks;
  userState['history'] = history;
  return true;
}

bool _reconcileRemoteStreakShields(
  Map<String, dynamic> userState,
  List<HabitStreakShieldRemote> remoteShields,
) {
  final localHabitIdByRemoteId = _localHabitIdByRemoteHabitId(userState);
  final shields = _habitStreakShieldsRoot(userState);
  final remoteShieldIds = remoteShields.map((shield) => shield.id).toSet();
  var changed = false;

  for (final entry in shields.entries.toList(growable: false)) {
    final current = _map(entry.value);
    if (!_hasRemoteShieldMarkers(current)) continue;
    final currentId = (current['id'] ?? '').toString().trim();
    if (currentId.isNotEmpty && remoteShieldIds.contains(currentId)) continue;
    shields.remove(entry.key);
    changed = true;
  }

  for (final remote in remoteShields) {
    final localHabitId = localHabitIdByRemoteId[remote.habitId];
    if (localHabitId == null) continue;

    final next = _localShieldJsonFromRemote(
      remote,
      localHabitId: localHabitId,
      userId: (userState['userId'] ?? userState['id'] ?? '').toString(),
    );
    if (!_deepJsonEquals(_map(shields[localHabitId]), next)) {
      shields[localHabitId] = next;
      changed = true;
    }
  }

  return changed;
}

bool _reconcileRemoteStreakBreaks(
  Map<String, dynamic> userState,
  List<HabitStreakBreakRemote> remoteBreaks,
) {
  final localHabitIdByRemoteId = _localHabitIdByRemoteHabitId(userState);
  final breaks = _habitStreakBreaksRoot(userState);
  final remoteBreakIds = remoteBreaks.map((entry) => entry.breakId).toSet();
  final remoteRowIds = remoteBreaks.map((entry) => entry.id).toSet();
  var changed = false;

  for (final entry in breaks.entries.toList(growable: false)) {
    final current = _map(entry.value);
    if (!_hasRemoteBreakMarkers(current)) continue;
    final currentBreakId = (current['id'] ?? '').toString().trim();
    final currentRemoteId = (current['remoteId'] ?? '').toString().trim();
    final stillRemote = (currentBreakId.isNotEmpty &&
            remoteBreakIds.contains(currentBreakId)) ||
        (currentRemoteId.isNotEmpty && remoteRowIds.contains(currentRemoteId));
    if (stillRemote) continue;
    breaks.remove(entry.key);
    changed = true;
  }

  for (final remote in remoteBreaks) {
    final localHabitId = localHabitIdByRemoteId[remote.habitId];
    if (localHabitId == null) continue;

    final dateKey = _dateKey(remote.missedOccurrenceDate);
    for (final entry in breaks.entries.toList(growable: false)) {
      final current = _map(entry.value);
      if ((current['habitId'] ?? '').toString().trim() == localHabitId &&
          (current['missedOccurrenceDateKey'] ?? '').toString().trim() ==
              dateKey &&
          entry.key.toString() != remote.breakId) {
        breaks.remove(entry.key);
        changed = true;
      }
    }

    final next = _localBreakJsonFromRemote(
      remote,
      localHabitId: localHabitId,
      userId: (userState['userId'] ?? userState['id'] ?? '').toString(),
    );
    if (!_deepJsonEquals(_map(breaks[remote.breakId]), next)) {
      breaks[remote.breakId] = next;
      changed = true;
    }
  }

  return changed;
}

Map<String, String> _localHabitIdByRemoteHabitId(
  Map<String, dynamic> userState,
) {
  final output = <String, String>{};
  for (final habit in _list(userState['activeHabits']).whereType<Map>()) {
    final local = Map<String, dynamic>.from(_map(habit));
    final localId = _habitIdValue(local);
    final remoteId = _habitRemoteIdValue(local);
    if (localId == null || remoteId == null) continue;
    output[remoteId] = localId;
  }
  return output;
}

bool _hasRemoteShieldMarkers(Map<String, dynamic> shield) {
  return (shield['effectId'] ?? '').toString().trim().isNotEmpty ||
      (shield['remoteHabitId'] ?? '').toString().trim().isNotEmpty ||
      (shield['logicalTimeZone'] ?? '').toString().trim().isNotEmpty;
}

bool _hasRemoteBreakMarkers(Map<String, dynamic> streakBreak) {
  return (streakBreak['remoteId'] ?? '').toString().trim().isNotEmpty ||
      (streakBreak['remoteHabitId'] ?? '').toString().trim().isNotEmpty ||
      (streakBreak['logicalTimeZone'] ?? '').toString().trim().isNotEmpty;
}

Map<String, dynamic> _localShieldJsonFromRemote(
  HabitStreakShieldRemote remote, {
  required String localHabitId,
  required String userId,
}) {
  return ActiveStreakShield(
    id: remote.id,
    userId: userId.trim(),
    habitId: localHabitId,
    utilityId: remote.utilityId,
    activatedAtMillis: remote.activatedAt.millisecondsSinceEpoch,
    status: ActiveStreakShieldStatusX.fromKey(remote.status) ??
        ActiveStreakShieldStatus.expired,
    protectedOccurrenceDateKey: _dateKey(remote.protectedOccurrenceDate),
    consumedAtMillis: remote.consumedAt?.millisecondsSinceEpoch,
    operationId: remote.operationId,
  ).toJson()
    ..['remoteHabitId'] = remote.habitId
    ..['effectId'] = remote.effectId
    ..['logicalTimeZone'] = remote.logicalTimeZone
    ..['requestId'] = remote.requestId
    ..['operationId'] = remote.operationId;
}

Map<String, dynamic> _localBreakJsonFromRemote(
  HabitStreakBreakRemote remote, {
  required String localHabitId,
  required String userId,
}) {
  return RecoverableStreakBreak(
    id: remote.breakId,
    userId: userId.trim(),
    habitId: localHabitId,
    brokenAtMillis: remote.brokenAt.millisecondsSinceEpoch,
    missedOccurrenceDateKey: _dateKey(remote.missedOccurrenceDate),
    previousStreak: remote.previousStreak,
    currentStreakAfterBreak: remote.currentStreakAfterBreak,
    status: RecoverableStreakBreakStatusX.fromKey(remote.status) ??
        RecoverableStreakBreakStatus.expired,
    recoveredAtMillis: remote.recoveredAt?.millisecondsSinceEpoch,
    shieldProtected: false,
  ).toJson()
    ..['remoteId'] = remote.id
    ..['remoteHabitId'] = remote.habitId
    ..['logicalTimeZone'] = remote.logicalTimeZone
    ..['recoverableUntilMillis'] =
        remote.recoverableUntil.millisecondsSinceEpoch
    ..['requestId'] = remote.requestId
    ..['recoveryRequestId'] = remote.recoveryRequestId;
}

bool _deepJsonEquals(Map<String, dynamic> left, Map<String, dynamic> right) {
  return jsonEncode(left) == jsonEncode(right);
}

void _debugStreakProtectionSync(String message) {
  if (kDebugMode) {
    debugPrint('[streak_protection_sync] $message');
  }
}
