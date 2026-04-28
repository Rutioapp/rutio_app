part of 'user_state_store.dart';

const String _diaryRewardAppliedDateKeysMetaKey = 'diaryRewardAppliedDateKeys';
final RegExp _dateKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

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

  rawEntries.add(entry.toJson());
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

  if (index >= 0) {
    rawEntries[index] = entry.toJson();
  } else {
    rawEntries.add(entry.toJson());
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
}

Future<void> _deleteDiaryEntry(UserStateStore store, String id) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);
  final rawEntries = _ensureDiaryEntriesRoot(userState);
  _ensureDiaryRewardAppliedDateKeys(userState);

  rawEntries.removeWhere((entry) => (entry['id'] ?? '').toString() == id);
  _touchLastSavedAt(userState);

  root['userState'] = userState;
  store._state = root;

  await store._repo.save(root);
  store._emitChanged();
}
