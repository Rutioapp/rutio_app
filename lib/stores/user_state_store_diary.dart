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
  progression['xp'] = nextXp;
  progression['level'] = 1 + (nextXp ~/ 100);
  userState['progression'] = progression;

  final wallet = _map(userState['wallet']);
  final currentCoins = _safeInt(wallet['coins'], fallback: 0);
  wallet['coins'] = currentCoins + RewardConstants.dailyDiaryAmbarReward;
  userState['wallet'] = wallet;

  final daily = _map(userState['daily']);
  daily['xpEarnedToday'] = _safeInt(daily['xpEarnedToday'], fallback: 0) +
      RewardConstants.dailyDiaryXpReward;
  daily['coinsEarnedToday'] =
      _safeInt(daily['coinsEarnedToday'], fallback: 0) +
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
  final rewardResult = _tryApplyDailyDiaryReward(userState, entry);
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
  final rewardResult = _tryApplyDailyDiaryReward(userState, entry);

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

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);
  final rawEntries = _ensureDiaryEntriesRoot(userState);
  _ensureDiaryRewardAppliedDateKeys(userState);

  final existingIndex = rawEntries.indexWhere(
    (entry) => (entry['id'] ?? '').toString() == id,
  );
  final existingEntryMap = existingIndex >= 0
      ? Map<String, dynamic>.from(rawEntries[existingIndex])
      : null;
  final remoteEntryId =
      existingEntryMap == null ? null : _diaryEntryRemoteIdValue(existingEntryMap);

  rawEntries.removeWhere((entry) => (entry['id'] ?? '').toString() == id);
  _touchLastSavedAt(userState);

  root['userState'] = userState;
  store._state = root;

  await store._repo.save(root);
  store._emitChanged();

  if (remoteEntryId != null) {
    unawaited(
      store._journalEntrySyncService.syncEntryDeleted(
        localEntryId: id,
        remoteEntryId: remoteEntryId,
        expectedLocalUserId: store.userId,
        preferSoftDelete: true,
      ),
    );
  }
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
        _debugJournalBackfill('journal backfill skipped: local state unavailable');
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
    final shouldMarkCompleted = remainingEligible == 0 && summary.failedCount == 0;

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
