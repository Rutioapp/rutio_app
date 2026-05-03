part of 'user_state_store.dart';
const String _lastCelebratedLevelMetaKey = 'lastCelebratedLevel';
const LevelEventResolver _levelEventResolver = LevelEventResolver();
const LevelRewardResolver _levelRewardResolver = LevelRewardResolver();

class _HabitProgressResult {
  final int xpGain;
  final int coinsGain;
  final bool grantDailyReward;

  const _HabitProgressResult({
    this.xpGain = 0,
    this.coinsGain = 0,
    this.grantDailyReward = false,
  });
}

class _ProgressSyncSnapshot {
  const _ProgressSyncSnapshot({
    required this.level,
    required this.xp,
    required this.xpInCurrentLevel,
    required this.xpToNextLevel,
    required this.coins,
  });

  final int level;
  final int xp;
  final int xpInCurrentLevel;
  final int xpToNextLevel;
  final int coins;
}

_ProgressSyncSnapshot _buildProgressSyncSnapshot(
  Map<String, dynamic> userState,
) {
  final progression = _map(userState['progression']);
  final wallet = _map(userState['wallet']);

  final rawXp = _safeInt(progression['xp'], fallback: 0);
  final xp = rawXp < 0 ? 0 : rawXp;
  final levelProgress = LevelProgression.fromTotalXp(xp);
  final coins = _safeInt(wallet['coins'], fallback: 0);

  return _ProgressSyncSnapshot(
    level: levelProgress.level,
    xp: xp,
    xpInCurrentLevel: levelProgress.currentLevelXp,
    xpToNextLevel: levelProgress.xpToNextLevel,
    coins: coins,
  );
}

void _updateProgressionLevelFromXp(
  Map<String, dynamic> progression, {
  required int totalXp,
}) {
  final safeTotalXp = totalXp < 0 ? 0 : totalXp;
  final levelProgress = LevelProgression.fromTotalXp(safeTotalXp);
  progression['xp'] = safeTotalXp;
  progression['level'] = levelProgress.level;
}

int _lastCelebratedLevel(Map<String, dynamic> userState) {
  final meta = _map(userState['meta']);
  final rawLevel = _safeInt(meta[_lastCelebratedLevelMetaKey], fallback: 0);
  return rawLevel < 0 ? 0 : rawLevel;
}

void _setLastCelebratedLevel(
  Map<String, dynamic> userState, {
  required int level,
}) {
  final safeLevel = level < 0 ? 0 : level;
  final meta = _map(userState['meta']);
  meta[_lastCelebratedLevelMetaKey] = safeLevel;
  userState['meta'] = meta;
}

void _enqueueLevelCelebration(UserStateStore store, LevelEvent event) {
  if (!_levelEventResolver.isCelebrationEligibleLevel(event.level)) return;
  if (!_canQueueGamificationOverlays(store)) return;

  if (store._pendingLevelCelebrations.isEmpty) {
    store._pendingLevelCelebrations.add(event);
    store._emitChanged();
    return;
  }

  final lastIndex = store._pendingLevelCelebrations.length - 1;
  final queued = store._pendingLevelCelebrations[lastIndex];
  if (event.level >= queued.level) {
    store._pendingLevelCelebrations[lastIndex] = event;
    store._emitChanged();
  }
}

void _queueLevelCelebrationForXpChange(
  UserStateStore store, {
  required Map<String, dynamic> userState,
  required int previousXp,
  required int currentXp,
}) {
  final currentLevel =
      LevelProgression.fromTotalXp(currentXp < 0 ? 0 : currentXp).level;
  if (!_levelEventResolver.isCelebrationEligibleLevel(currentLevel)) return;

  final decision = store._levelUpCelebrationController.evaluateXpChange(
    previousXp: previousXp,
    newXp: currentXp,
    lastCelebratedLevel: _lastCelebratedLevel(userState),
  );
  final event = decision.event;
  if (event == null) return;

  _enqueueLevelCelebration(store, event);
}

void _restorePendingLevelCelebrationFromProgress(
  UserStateStore store, {
  required Map<String, dynamic> userState,
}) {
  if (!_canQueueGamificationOverlays(store, userState: userState)) return;

  final progression = _map(userState['progression']);
  final safeXp = _safeInt(progression['xp'], fallback: 0).clamp(0, 1 << 30);
  final currentLevel = LevelProgression.fromTotalXp(safeXp).level;
  final celebratedLevel = _lastCelebratedLevel(userState);

  if (!_levelEventResolver.isCelebrationEligibleLevel(currentLevel)) return;
  if (currentLevel <= celebratedLevel) return;
  _enqueueLevelCelebration(
    store,
    LevelEvent(
      level: currentLevel,
      type: _levelEventResolver.eventTypeForLevel(currentLevel),
    ),
  );
}

Future<void> _markLevelCelebrationAsCelebrated(
  UserStateStore store, {
  required int level,
}) async {
  if (store._isLoggingOut ||
      store._isResettingUserState ||
      store._suppressGamificationOverlays) {
    return;
  }

  final safeLevel = level < 0 ? 0 : level;

  store._pendingLevelCelebrations
      .removeWhere((queuedEvent) => queuedEvent.level <= safeLevel);
  if (!_levelEventResolver.isCelebrationEligibleLevel(safeLevel)) {
    store._pendingLevelCelebrations.removeWhere(
      (queuedEvent) =>
          !_levelEventResolver.isCelebrationEligibleLevel(queuedEvent.level),
    );
    store._emitChanged();
    return;
  }

  final root = store._state;
  if (root != null) {
    final userState = _ensureUserStateRoot(root);
    final currentCelebratedLevel = _lastCelebratedLevel(userState);
    if (safeLevel > currentCelebratedLevel) {
      final rewardAmbar = _levelRewardResolver.rewardForLevel(safeLevel);
      if (rewardAmbar > 0) {
        final wallet = _map(userState['wallet']);
        final currentCoins = _safeInt(wallet['coins'], fallback: 0);
        wallet['coins'] = currentCoins + rewardAmbar;
        userState['wallet'] = wallet;

        final daily = _map(userState['daily']);
        daily['coinsEarnedToday'] =
            _safeInt(daily['coinsEarnedToday'], fallback: 0) + rewardAmbar;
        userState['daily'] = daily;
      }

      _setLastCelebratedLevel(userState, level: safeLevel);
      await store._repo.save(root);

      if (rewardAmbar > 0) {
        _queueBestEffortProgressAndRewardSync(
          store,
          userState: userState,
          xpDelta: 0,
          coinsDelta: rewardAmbar,
          source: 'level_up_milestone',
          currencyReason: 'level_up_milestone:$safeLevel',
        );
      }
    }
  }

  store._emitChanged();
}

void _queueBestEffortProgressAndRewardSync(
  UserStateStore store, {
  required Map<String, dynamic> userState,
  required int xpDelta,
  required int coinsDelta,
  required String source,
  String? xpReason,
  String? currencyReason,
}) {
  final snapshot = _buildProgressSyncSnapshot(userState);
  final ambarEarnedDelta = coinsDelta > 0 ? coinsDelta : 0;
  final ambarSpentDelta = coinsDelta < 0 ? -coinsDelta : 0;

  if (kDebugMode) {
    debugPrint(
      '[user_progress_sync] reward sync triggered '
      '(xpDelta=$xpDelta, currencyDelta=$coinsDelta, source=$source)',
    );
  }

  unawaited(() async {
    await store._userProgressSyncService.syncCurrentProgressFromLocalState(
      level: snapshot.level,
      totalXp: snapshot.xp,
      currentLevelXp: snapshot.xpInCurrentLevel,
      nextLevelXp: snapshot.xpToNextLevel,
      ambarBalance: snapshot.coins,
      ambarEarnedDelta: ambarEarnedDelta,
      ambarSpentDelta: ambarSpentDelta,
      expectedLocalUserId: store.userId,
    );

    if (xpDelta != 0) {
      await store._userProgressSyncService.recordXpEvent(
        amount: xpDelta,
        source: source,
        description: xpReason ?? 'habit reward',
        expectedLocalUserId: store.userId,
      );
    }

    if (coinsDelta != 0) {
      await store._userProgressSyncService.recordCurrencyEvent(
        amount: coinsDelta,
        currency: 'ambar',
        source: source,
        description: currencyReason ?? 'habit reward',
        expectedLocalUserId: store.userId,
      );
    }
  }());
}

int _xpForCheck() => 10;
int _coinsForCheck() => 5;

int _xpForCountCompletion(num target) =>
    ((target / 5).ceil() * 2 + 5).clamp(5, 15);

int _coinsForCountCompletion(num xp) => (xp / 2).floor().clamp(0, 10);

num _habitTarget(Map<String, dynamic> habit) =>
    _safePositiveNum(habit['target'], fallback: 1);

String _habitFamilyId(Map<String, dynamic> habit) =>
    _normalizeFamilyId((habit['familyId'] ?? 'mind').toString());

void _setHabitCompletionForDay(
  Map<String, dynamic> userState, {
  required String dateKey,
  required String habitId,
  required bool done,
}) {
  final history = _ensureHistoryRoot(userState);
  final habitCompletions = _map(history['habitCompletions']);
  final dayDone = _map(habitCompletions[dateKey]);
  dayDone[habitId] = done;
  habitCompletions[dateKey] = dayDone;
  history['habitCompletions'] = habitCompletions;
  userState['history'] = history;
}

void _setHabitSkipForDay(
  Map<String, dynamic> userState, {
  required String dateKey,
  required String habitId,
  required bool skipped,
}) {
  final history = _ensureHistoryRoot(userState);
  final habitSkips = _map(history['habitSkips']);
  final daySkips = _map(habitSkips[dateKey]);
  daySkips[habitId] = skipped;
  habitSkips[dateKey] = daySkips;
  history['habitSkips'] = habitSkips;
  userState['history'] = history;
}

void _setHabitCountValueForDay(
  Map<String, dynamic> userState, {
  required String dateKey,
  required String habitId,
  required num value,
}) {
  final history = _ensureHistoryRoot(userState);
  final habitCountValues = _map(history['habitCountValues']);
  final dayValues = _map(habitCountValues[dateKey]);
  dayValues[habitId] = value;
  habitCountValues[dateKey] = dayValues;
  history['habitCountValues'] = habitCountValues;
  userState['history'] = history;
}

void _setHabitCompletionTimeState(
  Map<String, dynamic> userState, {
  required String dateKey,
  required String habitId,
  required bool done,
  required int epochMillis,
}) {
  if (done) {
    _setCompletionTime(
      userState: userState,
      dateKey: dateKey,
      habitId: habitId,
      epochMillis: epochMillis,
    );
    return;
  }

  _removeCompletionTime(
    userState: userState,
    dateKey: dateKey,
    habitId: habitId,
  );
}

void _syncHabitHistoryFromState(
  Map<String, dynamic> userState, {
  required String dateKey,
  required String habitId,
  required Map<String, dynamic> habit,
}) {
  _setHabitCompletionForDay(
    userState,
    dateKey: dateKey,
    habitId: habitId,
    done: habit['doneToday'] == true,
  );
  _setHabitSkipForDay(
    userState,
    dateKey: dateKey,
    habitId: habitId,
    skipped: habit['skippedToday'] == true,
  );

  if (_isCountHabit(habit)) {
    _setHabitCountValueForDay(
      userState,
      dateKey: dateKey,
      habitId: habitId,
      value: _safeNum(habit['progress'], fallback: 0),
    );
  }
}

void _applyHabitRewards(
  UserStateStore store,
  Map<String, dynamic> userState, {
  required String familyId,
  required int xpGain,
  required int coinsGain,
}) {
  if (xpGain <= 0 && coinsGain <= 0) return;

  final progression = _map(userState['progression']);
  final currentXp = ((progression['xp'] as num?) ?? 0).toInt();
  final newXp = currentXp + xpGain;
  _updateProgressionLevelFromXp(
    progression,
    totalXp: newXp,
  );
  _queueLevelCelebrationForXpChange(
    store,
    userState: userState,
    previousXp: currentXp,
    currentXp: newXp,
  );

  final wallet = _map(userState['wallet']);
  final currentCoins = ((wallet['coins'] as num?) ?? 0).toInt();
  wallet['coins'] = currentCoins + coinsGain;

  final familyXp = _map(userState['familyXp']);
  familyXp[familyId] = ((familyXp[familyId] as num?) ?? 0).toInt() + xpGain;

  final daily = _map(userState['daily']);
  daily['xpEarnedToday'] =
      ((daily['xpEarnedToday'] as num?) ?? 0).toInt() + xpGain;
  daily['coinsEarnedToday'] =
      ((daily['coinsEarnedToday'] as num?) ?? 0).toInt() + coinsGain;

  userState['progression'] = progression;
  userState['wallet'] = wallet;
  userState['familyXp'] = familyXp;
  userState['daily'] = daily;
}

_HabitProgressResult _setCountHabitProgress(
  Map<String, dynamic> habit, {
  required num value,
  required bool rewardAlreadyGranted,
}) {
  final target = _habitTarget(habit);
  final safeValue = _safeDouble(value, fallback: 0).clamp(0, double.infinity);

  habit['progress'] = safeValue;
  habit['skippedToday'] = false;
  habit['doneToday'] = safeValue >= target;

  if (habit['doneToday'] == true && !rewardAlreadyGranted) {
    final xpGain = _xpForCountCompletion(target);
    return _HabitProgressResult(
      xpGain: xpGain,
      coinsGain: _coinsForCountCompletion(xpGain),
      grantDailyReward: true,
    );
  }

  return const _HabitProgressResult();
}

_HabitProgressResult _applyHabitProgressDelta(
  Map<String, dynamic> habit, {
  required num delta,
  required bool rewardAlreadyGranted,
}) {
  if (!_isCountHabit(habit)) {
    habit['doneToday'] = true;
    habit['skippedToday'] = false;
    return _HabitProgressResult(
      xpGain: _xpForCheck(),
      coinsGain: _coinsForCheck(),
      grantDailyReward: true,
    );
  }

  final current = _safeNum(habit['progress'], fallback: 0);
  final next = current + delta;
  return _setCountHabitProgress(
    habit,
    value: next < 0 ? 0 : next,
    rewardAlreadyGranted: rewardAlreadyGranted,
  );
}
