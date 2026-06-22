part of 'user_state_store.dart';

const String _diaryRewardAppliedDateKeysMetaKey = 'diaryRewardAppliedDateKeys';
const String _supabaseJournalBackfillCompletedByUserKey =
    'supabaseJournalBackfillCompletedByUser';
final RegExp _dateKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final RegExp _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

class _DiaryRewardResult {
  const _DiaryRewardResult({
    required this.granted,
    this.dateKey,
    this.xpDelta = 0,
    this.coinsDelta = 0,
  });

  final bool granted;
  final String? dateKey;
  final int xpDelta;
  final int coinsDelta;
}

List<DiaryEntry> _diaryEntries(UserStateStore store) {
  final root = store._state;
  if (root == null) return const <DiaryEntry>[];

  final userState = _ensureUserStateRoot(root);
  final rawEntries = _ensureDiaryEntriesRoot(userState);
  _ensureDiaryRewardAppliedDateKeys(userState);

  final entries = rawEntries.map(DiaryEntry.fromJson).toList();
  entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return entries;
}

List<DailyMood> _dailyMoods(UserStateStore store) {
  final root = store._state;
  if (root == null) return const <DailyMood>[];

  final userState = _ensureUserStateRoot(root);
  final rawMoods = _ensureDailyMoodsRoot(userState);
  final moods = rawMoods.entries
      .where((entry) => entry.value is Map)
      .map(
        (entry) => DailyMood.fromJson({
          ..._map(entry.value),
          if (!_map(entry.value).containsKey('date')) 'date': entry.key,
        }),
      )
      .toList(growable: false)
    ..sort((a, b) => b.date.compareTo(a.date));
  return moods;
}

DailyMood? _dailyMoodForDate(UserStateStore store, DateTime date) {
  final root = store._state;
  if (root == null) return null;

  final userState = _ensureUserStateRoot(root);
  final rawMoods = _ensureDailyMoodsRoot(userState);
  final key = _dateKey(date);
  final value = rawMoods[key];
  if (value is! Map) return null;
  return DailyMood.fromJson({
    ..._map(value),
    if (!_map(value).containsKey('date')) 'date': key,
  });
}

List<DailyMood> _dailyMoodsForMonth(UserStateStore store, DateTime month) {
  final normalizedMonth = _dateOnly(month);
  return _dailyMoods(store)
      .where(
        (dailyMood) =>
            dailyMood.date.year == normalizedMonth.year &&
            dailyMood.date.month == normalizedMonth.month,
      )
      .toList(growable: false);
}

List<String> _ensureDiaryRewardAppliedDateKeys(Map<String, dynamic> userState) {
  final meta = _map(userState['meta']);
  final normalized = _list(meta[_diaryRewardAppliedDateKeysMetaKey])
      .map((value) => value.toString().trim())
      .where((value) => _dateKeyPattern.hasMatch(value))
      .toSet()
      .toList()
    ..sort();
  meta[_diaryRewardAppliedDateKeysMetaKey] = normalized;
  userState['meta'] = meta;
  return normalized;
}

bool _isValidDiaryEntryForReward(DiaryEntry entry) {
  return entry.text.trim().isNotEmpty;
}

String _diaryEntryDateKey(DiaryEntry entry) {
  return _dateKey(DateTime.fromMillisecondsSinceEpoch(entry.createdAt));
}

_DiaryRewardResult _tryApplyDailyDiaryReward(
  UserStateStore store,
  Map<String, dynamic> userState,
  DiaryEntry entry,
) {
  if (!_isValidDiaryEntryForReward(entry)) {
    return const _DiaryRewardResult(granted: false);
  }

  final dateKey = _diaryEntryDateKey(entry);
  final claimedKeys = _ensureDiaryRewardAppliedDateKeys(userState);
  final claimedKeySet = claimedKeys.toSet();
  if (claimedKeySet.contains(dateKey)) {
    return _DiaryRewardResult(granted: false, dateKey: dateKey);
  }

  final progression = _map(userState['progression']);
  final currentXp = _safeInt(progression['xp'], fallback: 0);
  final nextXp = currentXp + RewardConstants.dailyDiaryXpReward;
  _updateProgressionLevelFromXp(
    progression,
    totalXp: nextXp,
  );
  _queueLevelCelebrationForXpChange(
    store,
    userState: userState,
    previousXp: currentXp,
    currentXp: nextXp,
  );
  userState['progression'] = progression;

  final wallet = _map(userState['wallet']);
  final currentCoins = _safeInt(wallet['coins'], fallback: 0);
  wallet['coins'] = currentCoins + RewardConstants.dailyDiaryAmbarReward;
  userState['wallet'] = wallet;

  final daily = _map(userState['daily']);
  daily['xpEarnedToday'] = _safeInt(daily['xpEarnedToday'], fallback: 0) +
      RewardConstants.dailyDiaryXpReward;
  daily['coinsEarnedToday'] = _safeInt(daily['coinsEarnedToday'], fallback: 0) +
      RewardConstants.dailyDiaryAmbarReward;
  userState['daily'] = daily;

  claimedKeySet.add(dateKey);
  final updatedKeys = claimedKeySet.toList()..sort();
  final meta = _map(userState['meta']);
  meta[_diaryRewardAppliedDateKeysMetaKey] = updatedKeys;
  userState['meta'] = meta;

  return _DiaryRewardResult(
    granted: true,
    dateKey: dateKey,
    xpDelta: RewardConstants.dailyDiaryXpReward,
    coinsDelta: RewardConstants.dailyDiaryAmbarReward,
  );
}

Future<void> _addDiaryEntry(UserStateStore store, DiaryEntry entry) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);
  final rawEntries = _ensureDiaryEntriesRoot(userState);
  _ensureDiaryRewardAppliedDateKeys(userState);

  final entryMap = Map<String, dynamic>.from(entry.toJson());
  rawEntries.add(entryMap);
  final rewardResult = _tryApplyDailyDiaryReward(store, userState, entry);
  _touchLastSavedAt(userState);

  root['userState'] = userState;
  store._state = root;

  await store._repo.save(root);
  if (rewardResult.granted) {
    _queueBestEffortProgressAndRewardSync(
      store,
      userState: userState,
      xpDelta: rewardResult.xpDelta,
      coinsDelta: rewardResult.coinsDelta,
      source: 'journal_entry',
      xpReason: 'journal_entry_daily_reward:${rewardResult.dateKey}',
      currencyReason: 'journal_entry_daily_reward:${rewardResult.dateKey}',
    );
  }
  store._emitChanged();

  final activeHabits = _activeHabitsSnapshotForDiarySync(userState);
  unawaited(() async {
    await _syncDiaryV2EntryUpsertBestEffort(
      store,
      entry: entry,
      source: 'create',
    );

    final remoteId = await store._journalEntrySyncService.syncEntryCreated(
      localEntry: Map<String, dynamic>.from(entryMap),
      activeHabits: activeHabits,
      expectedLocalUserId: store.userId,
      source: 'manual',
    );
    if (remoteId == null) return;
    await _persistDiaryEntryRemoteId(
      store,
      localEntryId: entry.id,
      remoteEntryId: remoteId,
    );
  }());
}

Future<void> _updateDiaryEntry(UserStateStore store, DiaryEntry entry) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);
  final rawEntries = _ensureDiaryEntriesRoot(userState);
  _ensureDiaryRewardAppliedDateKeys(userState);
  final index = rawEntries.indexWhere(
    (current) => (current['id'] ?? '').toString() == entry.id,
  );

  final entryJson = Map<String, dynamic>.from(entry.toJson());
  final incomingRemoteId = _normalizedRemoteDiaryEntryId(entryJson['remoteId']);
  if (incomingRemoteId == null) {
    entryJson.remove('remoteId');
  } else {
    entryJson['remoteId'] = incomingRemoteId;
  }

  final updatedEntryMap = index >= 0
      ? Map<String, dynamic>.from(rawEntries[index])
      : <String, dynamic>{};
  updatedEntryMap.addAll(entryJson);

  if (index >= 0) {
    rawEntries[index] = updatedEntryMap;
  } else {
    rawEntries.add(updatedEntryMap);
  }
  final rewardResult = _tryApplyDailyDiaryReward(store, userState, entry);

  _touchLastSavedAt(userState);

  root['userState'] = userState;
  store._state = root;

  await store._repo.save(root);
  if (rewardResult.granted) {
    _queueBestEffortProgressAndRewardSync(
      store,
      userState: userState,
      xpDelta: rewardResult.xpDelta,
      coinsDelta: rewardResult.coinsDelta,
      source: 'journal_entry',
      xpReason: 'journal_entry_daily_reward:${rewardResult.dateKey}',
      currencyReason: 'journal_entry_daily_reward:${rewardResult.dateKey}',
    );
  }
  store._emitChanged();

  final syncedDiaryV2Entry = DiaryEntry.fromJson(updatedEntryMap);
  unawaited(
    _syncDiaryV2EntryUpsertBestEffort(
      store,
      entry: syncedDiaryV2Entry,
      source: index >= 0 ? 'update' : 'update-upsert',
    ),
  );

  final activeHabits = _activeHabitsSnapshotForDiarySync(userState);
  final persistedRemoteId = _diaryEntryRemoteIdValue(updatedEntryMap);
  if (persistedRemoteId != null) {
    unawaited(() async {
      final remoteId = await store._journalEntrySyncService.syncEntryUpdated(
        localEntry: Map<String, dynamic>.from(updatedEntryMap),
        activeHabits: activeHabits,
        expectedLocalUserId: store.userId,
      );
      if (remoteId == null || remoteId == persistedRemoteId) return;
      await _persistDiaryEntryRemoteId(
        store,
        localEntryId: entry.id,
        remoteEntryId: remoteId,
      );
    }());
    return;
  }

  // Safe fallback only when update acts as upsert for a brand-new local row.
  if (index < 0) {
    unawaited(() async {
      final remoteId = await store._journalEntrySyncService.syncEntryCreated(
        localEntry: Map<String, dynamic>.from(updatedEntryMap),
        activeHabits: activeHabits,
        expectedLocalUserId: store.userId,
        source: 'manual',
      );
      if (remoteId == null) return;
      await _persistDiaryEntryRemoteId(
        store,
        localEntryId: entry.id,
        remoteEntryId: remoteId,
      );
    }());
  }
}

Future<void> _deleteDiaryEntry(UserStateStore store, String id) async {
  final root = store._state;
  if (root == null) return;

  final localEntryId = id.trim();
  if (localEntryId.isEmpty) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);
  final rawEntries = _ensureDiaryEntriesRoot(userState);
  _ensureDiaryRewardAppliedDateKeys(userState);

  final existingIndex = rawEntries.indexWhere(
    (entry) => (entry['id'] ?? '').toString() == localEntryId,
  );
  final existingEntryMap = existingIndex >= 0
      ? Map<String, dynamic>.from(rawEntries[existingIndex])
      : null;
  final remoteEntryId = existingEntryMap == null
      ? null
      : _diaryEntryRemoteIdValue(existingEntryMap);

  rawEntries
      .removeWhere((entry) => (entry['id'] ?? '').toString() == localEntryId);
  _touchLastSavedAt(userState);

  root['userState'] = userState;
  store._state = root;

  await store._repo.save(root);
  store._emitChanged();

  unawaited(
    _syncDiaryV2EntryDeleteBestEffort(
      store,
      localEntryId: localEntryId,
    ),
  );

  if (remoteEntryId != null) {
    unawaited(
      store._journalEntrySyncService.syncEntryDeleted(
        localEntryId: localEntryId,
        remoteEntryId: remoteEntryId,
        expectedLocalUserId: store.userId,
        preferSoftDelete: true,
      ),
    );
  }
}

Future<void> _setDailyMood(UserStateStore store, DailyMood dailyMood) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);
  final rawMoods = _ensureDailyMoodsRoot(userState);
  final key = _dateKey(dailyMood.date);
  final existing = _dailyMoodForDate(store, dailyMood.date);
  final now = DateTime.now().millisecondsSinceEpoch;
  final persisted = dailyMood.copyWith(
    date: _dateOnly(dailyMood.date),
    createdAt: existing?.createdAt ?? dailyMood.createdAt,
    updatedAt: dailyMood.updatedAt == 0 ? now : dailyMood.updatedAt,
  );

  rawMoods[key] = persisted
      .copyWith(
        createdAt: persisted.createdAt == 0 ? now : persisted.createdAt,
      )
      .toJson();
  _touchLastSavedAt(userState);

  root['userState'] = userState;
  store._state = root;

  await store._repo.save(root);
  store._emitChanged();

  unawaited(
    _syncDailyMoodUpsertBestEffort(
      store,
      dailyMood: DailyMood.fromJson(rawMoods[key]),
      source: existing == null ? 'create' : 'update',
    ),
  );
}

Future<JournalEntryBackfillSummary> _syncExistingLocalJournalEntriesOnce(
  UserStateStore store, {
  bool force = false,
}) async {
  if (store._isSupabaseJournalEntriesBackfillRunning) {
    _debugJournalBackfill('journal backfill skipped: already running');
    return const JournalEntryBackfillSummary(
      totalCandidates: 0,
      uploadedCount: 0,
      skippedCount: 0,
      failedCount: 0,
    );
  }

  store._isSupabaseJournalEntriesBackfillRunning = true;
  try {
    if (store._state == null) {
      if (!store._loading) {
        await store.load();
      }
      if (store._state == null) {
        _debugJournalBackfill(
            'journal backfill skipped: local state unavailable');
        return const JournalEntryBackfillSummary(
          totalCandidates: 0,
          uploadedCount: 0,
          skippedCount: 0,
          failedCount: 0,
        );
      }
    }

    final authenticatedUserId = _authenticatedSupabaseUserId();
    if (authenticatedUserId == null) {
      _debugJournalBackfill('journal backfill skipped: no authenticated user');
      return const JournalEntryBackfillSummary(
        totalCandidates: 0,
        uploadedCount: 0,
        skippedCount: 0,
        failedCount: 0,
      );
    }

    final localUserId = (store.userId ?? '').trim();
    if (localUserId.isEmpty || localUserId != authenticatedUserId) {
      _debugJournalBackfill('journal backfill skipped: local user mismatch');
      return const JournalEntryBackfillSummary(
        totalCandidates: 0,
        uploadedCount: 0,
        skippedCount: 0,
        failedCount: 0,
      );
    }

    final root = store._state!;
    final userState = _ensureUserStateRoot(root);
    final markerCompleted = _isJournalBackfillCompletedForUser(
      userState,
      authenticatedUserId,
    );
    final hasEligibleCandidates =
        _countEligibleJournalBackfillCandidates(userState) > 0;

    if (markerCompleted && !force && !hasEligibleCandidates) {
      _debugJournalBackfill(
        'journal backfill skipped: completion marker already set',
      );
      return const JournalEntryBackfillSummary(
        totalCandidates: 0,
        uploadedCount: 0,
        skippedCount: 0,
        failedCount: 0,
      );
    }

    final localEntries = _ensureDiaryEntriesRoot(userState)
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
    final activeHabits = _activeHabitsSnapshotForDiarySync(userState);

    final summary = await store._journalEntrySyncService
        .syncExistingLocalJournalEntriesOnce(
      localEntries: localEntries,
      activeHabits: activeHabits,
      expectedLocalUserId: authenticatedUserId,
      force: force,
      onRemoteIdAssigned: ({
        required String localEntryId,
        required String remoteEntryId,
      }) =>
          _persistDiaryEntryRemoteId(
        store,
        localEntryId: localEntryId,
        remoteEntryId: remoteEntryId,
      ),
    );

    final updatedRoot = store._state;
    if (updatedRoot == null) return summary;

    final updatedUserState = _ensureUserStateRoot(updatedRoot);
    final remainingEligible =
        _countEligibleJournalBackfillCandidates(updatedUserState);
    final shouldMarkCompleted =
        remainingEligible == 0 && summary.failedCount == 0;

    final wasCompleted = _isJournalBackfillCompletedForUser(
      updatedUserState,
      authenticatedUserId,
    );
    if (shouldMarkCompleted != wasCompleted) {
      _setJournalBackfillCompletedForUser(
        updatedUserState,
        authenticatedUserId,
        completed: shouldMarkCompleted,
      );
      await store.save(updatedRoot);
    }

    _debugJournalBackfill(
      'journal backfill summary for "$authenticatedUserId": '
      'total=${summary.totalCandidates}, uploaded=${summary.uploadedCount}, '
      'skipped=${summary.skippedCount}, failed=${summary.failedCount}, '
      'remainingEligible=$remainingEligible, completed=$shouldMarkCompleted',
    );

    return summary;
  } catch (error) {
    _debugJournalBackfill('journal backfill unexpected store error: $error');
    return const JournalEntryBackfillSummary(
      totalCandidates: 0,
      uploadedCount: 0,
      skippedCount: 0,
      failedCount: 1,
    );
  } finally {
    store._isSupabaseJournalEntriesBackfillRunning = false;
  }
}

Future<void> _autoSyncDiaryV2FromRemoteIfNeeded(UserStateStore store) async {
  if (!_shouldSyncDiaryV2ForCurrentScope(store, operation: 'pull')) return;
  if (store._isDiaryV2RemotePullRunning) {
    _debugDiaryV2Sync('auto pull skipped: already running');
    return;
  }

  final now = store._nowProvider();
  final lastAttemptAt = store._lastDiaryV2RemotePullAttemptAt;
  if (lastAttemptAt != null &&
      now.difference(lastAttemptAt) < UserStateStore.diaryV2AutoPullCooldown) {
    _debugDiaryV2Sync(
      'auto pull skipped: cooldown active '
      '(${now.difference(lastAttemptAt).inMinutes}m since last attempt)',
    );
    return;
  }

  await _runDiaryV2RemotePull(store, source: 'auto');
}

Future<void> _syncDiaryV2FromRemoteBestEffort(UserStateStore store) async {
  await _runDiaryV2RemotePull(store, source: 'manual');
}

Future<void> _runDiaryV2RemotePull(
  UserStateStore store, {
  required String source,
}) async {
  if (!_shouldSyncDiaryV2ForCurrentScope(store, operation: 'pull')) return;
  if (store._isDiaryV2RemotePullRunning) {
    _debugDiaryV2Sync('$source pull skipped: already running');
    return;
  }

  store._isDiaryV2RemotePullRunning = true;
  store._lastDiaryV2RemotePullAttemptAt = store._nowProvider();
  if (store._state == null) {
    await store.load();
  }

  final root = store._state;
  if (root == null) {
    _debugDiaryV2Sync('$source pull skipped: local state unavailable');
    store._isDiaryV2RemotePullRunning = false;
    return;
  }

  try {
    final diaryEntriesResult = await store._diaryV2SupabaseRepository
        .fetchDiaryEntriesForCurrentUser();
    final dailyMoodsResult =
        await store._diaryV2SupabaseRepository.fetchDailyMoodsForCurrentUser();

    if (!diaryEntriesResult.isSuccess) {
      _debugDiaryV2Sync(
        '$source pull failed while fetching diary entries: '
        '${diaryEntriesResult.error?.code.name}: ${diaryEntriesResult.error?.message}',
      );
      return;
    }
    if (!dailyMoodsResult.isSuccess) {
      _debugDiaryV2Sync(
        '$source pull failed while fetching daily moods: '
        '${dailyMoodsResult.error?.code.name}: ${dailyMoodsResult.error?.message}',
      );
      return;
    }

    final userState = _ensureUserStateRoot(root);
    _ensureDailyReset(userState);
    final localEntries = _ensureDiaryEntriesRoot(userState);
    final localMoods = _ensureDailyMoodsRoot(userState);

    final mergedEntries = _mergeRemoteDiaryEntriesIntoLocalState(
      localEntries: localEntries,
      remoteEntries: diaryEntriesResult.data ?? const <DiaryEntry>[],
    );
    final mergedDailyMoods = _mergeRemoteDailyMoodsIntoLocalState(
      localMoods: localMoods,
      remoteMoods: dailyMoodsResult.data ?? const <DailyMood>[],
    );

    if (!mergedEntries.changed && !mergedDailyMoods.changed) {
      store._lastDiaryV2RemotePullSuccessAt = store._nowProvider();
      _debugDiaryV2Sync(
        '$source pull completed: no local Diary V2 changes applied',
      );
      return;
    }

    userState['diaryEntries'] = mergedEntries.entries;
    userState['dailyMoods'] = mergedDailyMoods.moods;
    root['userState'] = userState;
    await store.save(root);
    store._lastDiaryV2RemotePullSuccessAt = store._nowProvider();
  } catch (error) {
    _debugDiaryV2Sync('$source pull unexpected error: $error');
  } finally {
    store._isDiaryV2RemotePullRunning = false;
  }
}

class _DiaryEntryMergeResult {
  const _DiaryEntryMergeResult({
    required this.entries,
    required this.changed,
  });

  final List<Map<String, dynamic>> entries;
  final bool changed;
}

class _DailyMoodMergeResult {
  const _DailyMoodMergeResult({
    required this.moods,
    required this.changed,
  });

  final Map<String, dynamic> moods;
  final bool changed;
}

_DiaryEntryMergeResult _mergeRemoteDiaryEntriesIntoLocalState({
  required List<Map<String, dynamic>> localEntries,
  required List<DiaryEntry> remoteEntries,
}) {
  final mergedEntries = localEntries
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList(growable: true);
  final localIndexesById = <String, int>{};
  for (var index = 0; index < mergedEntries.length; index += 1) {
    final localId = (mergedEntries[index]['id'] ?? '').toString().trim();
    if (localId.isEmpty || localIndexesById.containsKey(localId)) continue;
    localIndexesById[localId] = index;
  }

  var changed = false;

  for (final remoteEntry in remoteEntries) {
    final localId = remoteEntry.id.trim();
    if (localId.isEmpty) continue;

    final existingIndex = localIndexesById[localId];
    final remoteEntryMap = Map<String, dynamic>.from(remoteEntry.toJson());
    if (existingIndex == null) {
      mergedEntries.add(remoteEntryMap);
      localIndexesById[localId] = mergedEntries.length - 1;
      changed = true;
      continue;
    }

    final localEntry = DiaryEntry.fromJson(mergedEntries[existingIndex]);
    if (_shouldReplaceLocalDiaryEntry(
      localEntry: localEntry,
      remoteEntry: remoteEntry,
    )) {
      mergedEntries[existingIndex] = remoteEntryMap;
      changed = true;
    }
  }

  return _DiaryEntryMergeResult(entries: mergedEntries, changed: changed);
}

_DailyMoodMergeResult _mergeRemoteDailyMoodsIntoLocalState({
  required Map<String, dynamic> localMoods,
  required List<DailyMood> remoteMoods,
}) {
  final mergedMoods = <String, dynamic>{
    for (final entry in localMoods.entries)
      entry.key: entry.value is Map
          ? Map<String, dynamic>.from(_map(entry.value))
          : entry.value,
  };

  var changed = false;

  for (final remoteMood in remoteMoods) {
    final dateKey = remoteMood.dateKey;
    if (dateKey.isEmpty) continue;

    final remoteMoodMap = remoteMood.toJson();
    final localMoodMap = _map(mergedMoods[dateKey]);
    if (localMoodMap.isEmpty) {
      mergedMoods[dateKey] = remoteMoodMap;
      changed = true;
      continue;
    }

    final localMood = DailyMood.fromJson({
      ...localMoodMap,
      if (!localMoodMap.containsKey('date')) 'date': dateKey,
    });
    if (_shouldReplaceLocalDailyMood(
      localMood: localMood,
      remoteMood: remoteMood,
    )) {
      mergedMoods[dateKey] = remoteMoodMap;
      changed = true;
    }
  }

  return _DailyMoodMergeResult(moods: mergedMoods, changed: changed);
}

bool _shouldReplaceLocalDiaryEntry({
  required DiaryEntry localEntry,
  required DiaryEntry remoteEntry,
}) {
  final localTimestamp = _robustDiaryEntryMergeTimestamp(localEntry);
  final remoteTimestamp = _robustDiaryEntryMergeTimestamp(remoteEntry);
  if (localTimestamp == null || remoteTimestamp == null) {
    return false;
  }
  return remoteTimestamp > localTimestamp;
}

bool _shouldReplaceLocalDailyMood({
  required DailyMood localMood,
  required DailyMood remoteMood,
}) {
  final localTimestamp = _robustDailyMoodMergeTimestamp(localMood);
  final remoteTimestamp = _robustDailyMoodMergeTimestamp(remoteMood);
  if (localTimestamp == null || remoteTimestamp == null) {
    return false;
  }
  return remoteTimestamp > localTimestamp;
}

int? _robustDiaryEntryMergeTimestamp(DiaryEntry entry) {
  return entry.createdAt > 0 ? entry.createdAt : null;
}

int? _robustDailyMoodMergeTimestamp(DailyMood dailyMood) {
  if (dailyMood.updatedAt > 0) return dailyMood.updatedAt;
  if (dailyMood.createdAt > 0) return dailyMood.createdAt;
  return null;
}

List<Map<String, dynamic>> _activeHabitsSnapshotForDiarySync(
  Map<String, dynamic> userState,
) {
  return _list(userState['activeHabits'])
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(_map(entry)))
      .toList(growable: false);
}

int _countEligibleJournalBackfillCandidates(Map<String, dynamic> userState) {
  final entries = _ensureDiaryEntriesRoot(userState);
  var count = 0;
  for (final entryMap in entries) {
    final remoteId = _diaryEntryRemoteIdValue(entryMap);
    if (remoteId != null) continue;
    final text = (entryMap['text'] ?? '').toString().trim();
    if (text.isEmpty) continue;
    final localId = (entryMap['id'] ?? '').toString().trim();
    if (localId.isEmpty) continue;
    count += 1;
  }
  return count;
}

String? _normalizedRemoteDiaryEntryId(dynamic value) {
  final normalized = (value ?? '').toString().trim();
  if (normalized.isEmpty || !_uuidPattern.hasMatch(normalized)) return null;
  return normalized.toLowerCase();
}

String? _diaryEntryRemoteIdValue(Map<String, dynamic> entry) {
  return _normalizedRemoteDiaryEntryId(
    entry['remoteId'] ??
        entry['remoteJournalEntryId'] ??
        entry['supabaseJournalEntryId'],
  );
}

Future<void> _persistDiaryEntryRemoteId(
  UserStateStore store, {
  required String localEntryId,
  required String remoteEntryId,
}) async {
  final normalizedLocalId = localEntryId.trim();
  final normalizedRemoteId = _normalizedRemoteDiaryEntryId(remoteEntryId);
  if (normalizedLocalId.isEmpty || normalizedRemoteId == null) return;

  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);
  final rawEntries = _ensureDiaryEntriesRoot(userState);

  final index = rawEntries.indexWhere(
    (entry) => (entry['id'] ?? '').toString().trim() == normalizedLocalId,
  );
  if (index == -1) return;

  final current = Map<String, dynamic>.from(rawEntries[index]);
  final existingRemoteId = _diaryEntryRemoteIdValue(current);
  if (existingRemoteId == normalizedRemoteId) return;

  current['remoteId'] = normalizedRemoteId;
  rawEntries[index] = current;
  userState['diaryEntries'] = rawEntries;
  await store.save(root);
}

bool _isJournalBackfillCompletedForUser(
  Map<String, dynamic> userState,
  String userId,
) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return false;

  final byUser = _journalBackfillCompletedByUser(userState);
  return byUser[normalizedUserId] == true;
}

void _setJournalBackfillCompletedForUser(
  Map<String, dynamic> userState,
  String userId, {
  required bool completed,
}) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return;

  final byUser = _journalBackfillCompletedByUser(userState);
  if (completed) {
    byUser[normalizedUserId] = true;
  } else {
    byUser.remove(normalizedUserId);
  }

  final meta = _map(userState['meta']);
  meta[_supabaseJournalBackfillCompletedByUserKey] = byUser;
  userState['meta'] = meta;
}

Map<String, dynamic> _journalBackfillCompletedByUser(
  Map<String, dynamic> userState,
) {
  final meta = _map(userState['meta']);
  final byUser = _map(meta[_supabaseJournalBackfillCompletedByUserKey]);
  meta[_supabaseJournalBackfillCompletedByUserKey] = byUser;
  userState['meta'] = meta;
  return byUser;
}

void _debugJournalBackfill(String message) {
  if (!kDebugMode) return;
  debugPrint('[journal_backfill] $message');
}

Future<void> _syncDiaryV2EntryUpsertBestEffort(
  UserStateStore store, {
  required DiaryEntry entry,
  required String source,
}) async {
  if (!_shouldSyncDiaryV2ForCurrentScope(store, operation: 'upsert')) return;

  try {
    final result =
        await store._diaryV2SupabaseRepository.upsertDiaryEntry(entry);
    if (result.isSuccess) return;
    _debugDiaryV2Sync(
      'entry upsert failed ($source) for localId="${entry.id}": '
      '${result.error?.code.name}: ${result.error?.message}',
    );
  } catch (error) {
    _debugDiaryV2Sync(
      'entry upsert unexpected error ($source) for localId="${entry.id}": $error',
    );
  }
}

Future<void> _syncDiaryV2EntryDeleteBestEffort(
  UserStateStore store, {
  required String localEntryId,
}) async {
  final normalizedLocalId = localEntryId.trim();
  final authUserId = store._currentSupabaseUserIdProvider();
  if (kDebugMode) {
    _debugDiaryV2Sync(
      'entry delete attempt for localId="$normalizedLocalId": '
      'authAvailable=${authUserId != null}',
    );
  }

  if (!_shouldSyncDiaryV2ForCurrentScope(store, operation: 'delete')) return;

  try {
    final result = await store._diaryV2SupabaseRepository
        .deleteDiaryEntryByLocalId(normalizedLocalId);
    if (result.isSuccess) return;
    _debugDiaryV2Sync(
      'entry delete failed for localId="$normalizedLocalId": '
      '${result.error?.code.name}: ${result.error?.message}',
    );
  } catch (error) {
    _debugDiaryV2Sync(
      'entry delete unexpected error for localId="$normalizedLocalId": $error',
    );
  }
}

Future<void> _syncDailyMoodUpsertBestEffort(
  UserStateStore store, {
  required DailyMood dailyMood,
  required String source,
}) async {
  if (!_shouldSyncDiaryV2ForCurrentScope(store,
      operation: 'daily_mood_upsert')) {
    return;
  }

  try {
    final result =
        await store._diaryV2SupabaseRepository.upsertDailyMood(dailyMood);
    if (result.isSuccess) return;
    _debugDiaryV2Sync(
      'daily mood upsert failed ($source) for date="${dailyMood.dateKey}": '
      '${result.error?.code.name}: ${result.error?.message}',
    );
  } catch (error) {
    _debugDiaryV2Sync(
      'daily mood upsert unexpected error ($source) for date="${dailyMood.dateKey}": $error',
    );
  }
}

bool _shouldSyncDiaryV2ForCurrentScope(
  UserStateStore store, {
  required String operation,
}) {
  final authenticatedUserId = store._currentSupabaseUserIdProvider();
  if (authenticatedUserId == null) {
    _debugDiaryV2Sync('$operation skipped: no authenticated Supabase user');
    return false;
  }

  final localUserId = (store.userId ?? '').trim();
  if (localUserId.isEmpty || localUserId != authenticatedUserId) {
    _debugDiaryV2Sync(
      '$operation skipped: local user does not match auth session',
    );
    return false;
  }

  return true;
}

void _debugDiaryV2Sync(String message) {
  if (!kDebugMode) return;
  debugPrint('[diary_v2_sync] $message');
}
