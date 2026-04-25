part of 'user_state_store.dart';

Map<String, dynamic> _ensureAchievementsRoot(Map<String, dynamic> userState) {
  final profile = _map(userState['profile']);
  final achievements = _map(profile['achievements']);

  final normalizedUnlocked = <Map<String, dynamic>>[];
  final rawUnlocked = achievements['unlocked'];
  if (rawUnlocked is List) {
    for (final entry in rawUnlocked) {
      if (entry is Map) {
        normalizedUnlocked.add(Map<String, dynamic>.from(_map(entry)));
      }
    }
  } else if (rawUnlocked is Map) {
    for (final value in rawUnlocked.values) {
      if (value is Map) {
        normalizedUnlocked.add(Map<String, dynamic>.from(_map(value)));
      }
    }
  }

  final featured = _list(achievements['featured'])
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);

  achievements['unlocked'] = normalizedUnlocked;
  achievements['featured'] = featured;
  profile['achievements'] = achievements;
  userState['profile'] = profile;
  return achievements;
}

List<UnlockedAchievementRecord> _unlockedAchievementRecords(
  UserStateStore store,
) {
  final root = store._state;
  if (root == null) return const <UnlockedAchievementRecord>[];

  final userState = _ensureUserStateRoot(root);
  final achievements = _ensureAchievementsRoot(userState);
  final rawUnlocked = _list(achievements['unlocked']);

  return rawUnlocked
      .whereType<Map>()
      .map((entry) => UnlockedAchievementRecord.fromJson(_map(entry)))
      .whereType<UnlockedAchievementRecord>()
      .toList()
    ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
}

List<String> _featuredAchievementIds(UserStateStore store) {
  final root = store._state;
  if (root == null) return const <String>[];

  final userState = _ensureUserStateRoot(root);
  final achievements = _ensureAchievementsRoot(userState);
  return _list(achievements['featured'])
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty)
      .take(3)
      .toList(growable: false);
}

Future<void> _setFeaturedAchievementIds(
  UserStateStore store,
  List<String> achievementIds,
) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  final achievements = _ensureAchievementsRoot(userState);
  final unlockedIds = _unlockedAchievementRecords(store)
      .map((record) => record.id)
      .toSet();

  final sanitized = <String>[];
  for (final id in achievementIds) {
    final normalized = id.trim();
    if (normalized.isEmpty) continue;
    if (!unlockedIds.contains(normalized)) continue;
    if (sanitized.contains(normalized)) continue;
    sanitized.add(normalized);
    if (sanitized.length == 3) break;
  }

  achievements['featured'] = sanitized;
  await store.save(root);
}

class _AchievementHistoryStats {
  const _AchievementHistoryStats({
    required this.activeHabitCount,
    required this.activeFamilyCount,
    required this.completedFamilyCount,
    required this.earlyCompletionCount,
    required this.exactTargetHitCount,
    required this.lateCompletionCount,
    required this.onTimeCompletionCount,
    required this.weekendCompletionDays,
    required this.perfectDays,
    required this.bestDailyCompletions,
    required this.bestHabitStreak,
    required this.completionDays,
    required this.totalCompletions,
    required this.currentGlobalStreak,
    required this.bestGlobalStreak,
    required this.recoveryCount,
    required this.socialCompletionDays,
    required this.unlockedAchievementCount,
  });

  final int activeHabitCount;
  final int activeFamilyCount;
  final int completedFamilyCount;
  final int earlyCompletionCount;
  final int exactTargetHitCount;
  final int lateCompletionCount;
  final int onTimeCompletionCount;
  final int weekendCompletionDays;
  final int perfectDays;
  final int bestDailyCompletions;
  final int bestHabitStreak;
  final int completionDays;
  final int totalCompletions;
  final int currentGlobalStreak;
  final int bestGlobalStreak;
  final int recoveryCount;
  final int socialCompletionDays;
  final int unlockedAchievementCount;
}

HabitStreakSnapshot _habitStreakSnapshotForHabitId(
  UserStateStore store, {
  required String habitId,
  DateTime? today,
}) {
  final root = store._state;
  if (root == null) {
    return HabitStreakSnapshot(
      habitId: habitId,
      currentStreak: 0,
      bestStreak: 0,
      totalCompletedDays: 0,
    );
  }

  final userState = _ensureUserStateRoot(root);
  final activeHabits = _mutableActiveHabits(userState);
  final index = _activeHabitIndex(activeHabits, habitId);
  if (index == -1) {
    return HabitStreakSnapshot(
      habitId: habitId,
      currentStreak: 0,
      bestStreak: 0,
      totalCompletedDays: 0,
    );
  }

  final habit = Map<String, dynamic>.from(activeHabits[index]);
  return _habitStreakSnapshotForHabit(
    userState,
    habit: habit,
    today: today ?? DateTime.now(),
  );
}

Map<String, HabitStreakSnapshot> _habitStreakSnapshots(UserStateStore store) {
  final root = store._state;
  if (root == null) return const <String, HabitStreakSnapshot>{};

  final userState = _ensureUserStateRoot(root);
  final activeHabits = _mutableActiveHabits(userState);
  final output = <String, HabitStreakSnapshot>{};

  for (final habit in activeHabits) {
    final habitId = _habitIdValue(habit);
    if (habitId == null || habitId.isEmpty) continue;
    output[habitId] = _habitStreakSnapshotForHabit(userState, habit: habit);
  }

  return output;
}

Map<String, HabitStreakSnapshot> _familyConsistencySnapshots(
  UserStateStore store,
) {
  final root = store._state;
  if (root == null) {
    return {
      for (final familyId in FamilyTheme.order)
        familyId: HabitStreakSnapshot(
          habitId: familyId,
          currentStreak: 0,
          bestStreak: 0,
          totalCompletedDays: 0,
        ),
    };
  }

  final userState = _ensureUserStateRoot(root);
  return _familyConsistencySnapshotsFromUserState(userState);
}

Map<String, HabitStreakSnapshot> _achievementMetricSnapshots(
  UserStateStore store,
) {
  final root = store._state;
  if (root == null) return const <String, HabitStreakSnapshot>{};

  final userState = _ensureUserStateRoot(root);
  return {
    ..._familyConsistencySnapshotsFromUserState(userState),
    ..._specialAchievementSnapshotsFromUserState(userState),
  };
}

Map<String, HabitStreakSnapshot> _familyConsistencySnapshotsFromUserState(
  Map<String, dynamic> userState,
) {
  final output = <String, HabitStreakSnapshot>{};

  for (final familyId in FamilyTheme.order) {
    output[familyId] = _familyConsistencySnapshotForFamily(
      userState,
      familyId: familyId,
    );
  }

  return output;
}

HabitStreakSnapshot _familyConsistencySnapshotForFamily(
  Map<String, dynamic> userState, {
  required String familyId,
  DateTime? today,
}) {
  final normalizedFamilyId = FamilyTheme.order.contains(familyId)
      ? familyId
      : FamilyTheme.fallbackId;
  final activeHabits = _mutableActiveHabits(userState)
      .where((habit) => _habitFamilyId(habit) == normalizedFamilyId)
      .map((habit) => Map<String, dynamic>.from(habit))
      .toList(growable: false);

  if (activeHabits.isEmpty) {
    return HabitStreakSnapshot(
      habitId: normalizedFamilyId,
      currentStreak: 0,
      bestStreak: 0,
      totalCompletedDays: 0,
    );
  }

  final countsByDay = _extractFamilyDoneCountsByDay(
    userState,
    familyId: normalizedFamilyId,
    habits: activeHabits,
  );
  final referenceDay = DateTime(
    (today ?? DateTime.now()).year,
    (today ?? DateTime.now()).month,
    (today ?? DateTime.now()).day,
  );

  return HabitStreakSnapshot(
    habitId: normalizedFamilyId,
    currentStreak: _computeCurrentStreak(countsByDay, referenceDay),
    bestStreak: _computeBestStreak(countsByDay),
    totalCompletedDays:
        countsByDay.values.fold<int>(0, (sum, value) => sum + (value > 0 ? 1 : 0)),
  );
}

HabitStreakSnapshot _habitStreakSnapshotForHabit(
  Map<String, dynamic> userState, {
  required Map<String, dynamic> habit,
  DateTime? today,
}) {
  final habitId = _habitIdValue(habit) ?? '';
  final countsByDay = _extractHabitDoneCountsByDay(
    userState,
    habit: habit,
  );
  final now = DateTime(
    (today ?? DateTime.now()).year,
    (today ?? DateTime.now()).month,
    (today ?? DateTime.now()).day,
  );

  return HabitStreakSnapshot(
    habitId: habitId,
    currentStreak: _computeCurrentStreak(countsByDay, now),
    bestStreak: _computeBestStreak(countsByDay),
    totalCompletedDays:
        countsByDay.values.fold<int>(0, (sum, value) => sum + (value > 0 ? 1 : 0)),
  );
}

Map<DateTime, int> _extractHabitDoneCountsByDay(
  Map<String, dynamic> userState, {
  required Map<String, dynamic> habit,
}) {
  final output = <DateTime, int>{};
  final habitId = _habitIdValue(habit);
  if (habitId == null || habitId.isEmpty) return output;

  final history = _ensureHistoryRoot(userState);
  final completions = _map(history['habitCompletions']);
  final countValues = _map(history['habitCountValues']);
  final keys = <String>{...completions.keys.map((key) => key.toString())};
  keys.addAll(countValues.keys.map((key) => key.toString()));

  for (final dayKey in keys) {
    final date = _dateFromKey(dayKey);
    final day = DateTime(date.year, date.month, date.day);
    if (!_isScheduledForDate(habit, day)) continue;

    final completionMap = _map(completions[dayKey]);
    final countValueMap = _map(countValues[dayKey]);
    final doneValue = _normalizedHabitType(habit['type']) == 'count'
        ? _safeNum(countValueMap[habitId], fallback: 0)
        : (completionMap[habitId] == true ? 1 : 0);
    output[day] = doneValue > 0 ? 1 : 0;
  }

  return output;
}

Map<DateTime, int> _extractFamilyDoneCountsByDay(
  Map<String, dynamic> userState, {
  required String familyId,
  required List<Map<String, dynamic>> habits,
}) {
  final output = <DateTime, int>{};
  if (habits.isEmpty) return output;

  final normalizedFamilyId = FamilyTheme.order.contains(familyId)
      ? familyId
      : FamilyTheme.fallbackId;
  final history = _ensureHistoryRoot(userState);
  final completions = _map(history['habitCompletions']);
  final countValues = _map(history['habitCountValues']);
  final keys = <String>{...completions.keys.map((key) => key.toString())};
  keys.addAll(countValues.keys.map((key) => key.toString()));

  for (final dayKey in keys) {
    final date = _dateFromKey(dayKey);
    final day = DateTime(date.year, date.month, date.day);
    final completionMap = _map(completions[dayKey]);
    final countValueMap = _map(countValues[dayKey]);
    var hasScheduledHabit = false;
    var familyDone = false;

    for (final habit in habits) {
      if (_habitFamilyId(habit) != normalizedFamilyId) continue;
      if (!_isScheduledForDate(habit, day)) continue;

      final habitId = _habitIdValue(habit);
      if (habitId == null || habitId.isEmpty) continue;

      hasScheduledHabit = true;
      final doneValue = _normalizedHabitType(habit['type']) == 'count'
          ? _safeNum(countValueMap[habitId], fallback: 0)
          : (completionMap[habitId] == true ? 1 : 0);
      if (doneValue > 0) {
        familyDone = true;
        break;
      }
    }

    if (!hasScheduledHabit) continue;
    output[day] = familyDone ? 1 : 0;
  }

  return output;
}

bool _habitCompletedOnDate(
  Map<String, dynamic> habit, {
  required Map<String, dynamic> completionMap,
  required Map<String, dynamic> countValueMap,
}) {
  final habitId = _habitIdValue(habit);
  if (habitId == null || habitId.isEmpty) return false;

  return _normalizedHabitType(habit['type']) == 'count'
      ? _safeNum(countValueMap[habitId], fallback: 0) > 0
      : completionMap[habitId] == true;
}

Map<String, HabitStreakSnapshot> _specialAchievementSnapshotsFromUserState(
  Map<String, dynamic> userState,
) {
  final stats = _buildAchievementHistoryStats(userState);
  final output = <String, HabitStreakSnapshot>{};

  for (final achievement in AchievementCatalog.buildSpecialAchievements()) {
    switch (achievement.id) {
      case 'special:madrugador':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.earlyCompletionCount,
        );
        break;
      case 'special:francotirados':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.exactTargetHitCount,
        );
        break;
      case 'special:buho_nocturno':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.lateCompletionCount,
        );
        break;
      case 'special:flash':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.bestDailyCompletions,
        );
        break;
      case 'special:guerrero_del_finde':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.weekendCompletionDays,
        );
        break;
      case 'special:el_arquitecto':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.totalCompletions,
        );
        break;
      case 'special:turista':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.completedFamilyCount,
        );
        break;
      case 'special:polimota':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.activeFamilyCount,
        );
        break;
      case 'special:hay_alguien_ahi':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.socialCompletionDays,
        );
        break;
      case 'special:ave_fenix':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.recoveryCount,
        );
        break;
      case 'special:perfeccionista':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.perfectDays,
        );
        break;
      case 'special:reloj_suizo':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.onTimeCompletionCount,
        );
        break;
      case 'special:el_centurion':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.totalCompletions,
        );
        break;
      case 'special:imparable':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.currentGlobalStreak,
          bestValue: stats.bestGlobalStreak,
        );
        break;
      case 'special:leyenda_viva':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.totalCompletions,
        );
        break;
      case 'special:plusmarquista':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.bestHabitStreak,
        );
        break;
      case 'special:coleccionista':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.unlockedAchievementCount,
        );
        break;
      case 'special:veterano':
        output[achievement.id] = _snapshotFromMetricValue(
          achievement.id,
          value: stats.completionDays,
        );
        break;
    }
  }

  return output;
}

_AchievementHistoryStats _buildAchievementHistoryStats(
  Map<String, dynamic> userState,
) {
  final activeHabits = _mutableActiveHabits(userState)
      .map((habit) => Map<String, dynamic>.from(habit))
      .toList(growable: false);
  final activeFamilyIds = activeHabits.map(_habitFamilyId).toSet();
  final history = _ensureHistoryRoot(userState);
  final completions = _map(history['habitCompletions']);
  final countValues = _map(history['habitCountValues']);
  final completionTimes = _map(history['habitCompletionTimes']);
  final allDayKeys = <String>{
    ...completions.keys.map((key) => key.toString()),
    ...countValues.keys.map((key) => key.toString()),
    ...completionTimes.keys.map((key) => key.toString()),
  }.where((key) => key.trim().isNotEmpty).toList()
    ..sort();

  final globalCountsByDay = <DateTime, int>{};
  final completedFamilyIds = <String>{};
  final socialDays = <DateTime>{};
  var earlyCompletionCount = 0;
  var exactTargetHitCount = 0;
  var lateCompletionCount = 0;
  var onTimeCompletionCount = 0;
  var weekendCompletionDays = 0;
  var perfectDays = 0;
  var bestDailyCompletions = 0;
  var totalCompletions = 0;

  for (final dayKey in allDayKeys) {
    final date = _dateFromKey(dayKey);
    final day = DateTime(date.year, date.month, date.day);
    final completionMap = _map(completions[dayKey]);
    final countValueMap = _map(countValues[dayKey]);
    final timeMap = _map(completionTimes[dayKey]);

    var scheduledCount = 0;
    final completedToday = <String>{};

    for (final habit in activeHabits) {
      if (!_isScheduledForDate(habit, day)) continue;
      scheduledCount += 1;

      if (!_habitCompletedOnDate(
        habit,
        completionMap: completionMap,
        countValueMap: countValueMap,
      )) {
        continue;
      }

      final habitId = _habitIdValue(habit);
      if (habitId == null || habitId.isEmpty) continue;

      completedToday.add(habitId);
      totalCompletions += 1;
      completedFamilyIds.add(_habitFamilyId(habit));
      if (_habitFamilyId(habit) == FamilyTheme.social) {
        socialDays.add(day);
      }
      if (_isExactTargetHit(habit, countValueMap: countValueMap)) {
        exactTargetHitCount += 1;
      }
    }

    if (scheduledCount > 0) {
      globalCountsByDay[day] = completedToday.isNotEmpty ? 1 : 0;
    } else if (completedToday.isNotEmpty) {
      globalCountsByDay[day] = 1;
    }

    if (completedToday.isEmpty) continue;

    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      weekendCompletionDays += 1;
    }

    if (completedToday.length > bestDailyCompletions) {
      bestDailyCompletions = completedToday.length;
    }

    if (scheduledCount > 0 && completedToday.length >= scheduledCount) {
      perfectDays += 1;
    }

    for (final entry in timeMap.entries) {
      final habitId = entry.key.toString();
      if (!completedToday.contains(habitId)) continue;

      final epoch = (entry.value as num?)?.toInt() ?? 0;
      if (epoch <= 0) continue;

      final completedAt = DateTime.fromMillisecondsSinceEpoch(epoch).toLocal();
      if (completedAt.hour < 9) {
        earlyCompletionCount += 1;
      }
      if (completedAt.hour >= 22) {
        lateCompletionCount += 1;
      }
      if (_isOnTimeCompletion(habitId, activeHabits, completedAt)) {
        onTimeCompletionCount += 1;
      }
    }
  }

  var bestHabitStreak = 0;
  for (final habit in activeHabits) {
    final countsByDay = _extractHabitDoneCountsByDay(
      userState,
      habit: habit,
    );
    final streak = _computeBestStreak(countsByDay);
    if (streak > bestHabitStreak) {
      bestHabitStreak = streak;
    }
  }

  final completionDays = globalCountsByDay.values
      .where((value) => value > 0)
      .length;

  final achievements = _ensureAchievementsRoot(userState);
  final unlockedAchievementCount = _list(achievements['unlocked'])
      .whereType<Map>()
      .where((entry) => !_isLegacyHabitStreakEntry(_map(entry)))
      .length;

  return _AchievementHistoryStats(
    activeHabitCount: activeHabits.length,
    activeFamilyCount: activeFamilyIds.length,
    completedFamilyCount: completedFamilyIds.length,
    earlyCompletionCount: earlyCompletionCount,
    exactTargetHitCount: exactTargetHitCount,
    lateCompletionCount: lateCompletionCount,
    onTimeCompletionCount: onTimeCompletionCount,
    weekendCompletionDays: weekendCompletionDays,
    perfectDays: perfectDays,
    bestDailyCompletions: bestDailyCompletions,
    bestHabitStreak: bestHabitStreak,
    completionDays: completionDays,
    totalCompletions: totalCompletions,
    currentGlobalStreak: _computeCurrentStreak(globalCountsByDay, DateTime.now()),
    bestGlobalStreak: _computeBestStreak(globalCountsByDay),
    recoveryCount: _computeRecoveryCount(globalCountsByDay),
    socialCompletionDays: socialDays.length,
    unlockedAchievementCount: unlockedAchievementCount,
  );
}

bool _isExactTargetHit(
  Map<String, dynamic> habit, {
  required Map<String, dynamic> countValueMap,
}) {
  if (_normalizedHabitType(habit['type']) != 'count') return false;

  final habitId = _habitIdValue(habit);
  if (habitId == null || habitId.isEmpty) return false;

  final value = _safeDouble(countValueMap[habitId], fallback: 0);
  final target = _safeDouble(habit['target'], fallback: 1);
  if (value <= 0 || target <= 0) return false;
  return (value - target).abs() < 0.0001;
}

bool _isOnTimeCompletion(
  String habitId,
  List<Map<String, dynamic>> activeHabits,
  DateTime completedAt, {
  int toleranceMinutes = 10,
}) {
  final habit = activeHabits.cast<Map<String, dynamic>?>().firstWhere(
    (candidate) => _habitIdValue(candidate) == habitId,
    orElse: () => null,
  );
  if (habit == null) return false;

  final reminderEnabled =
      habit['reminderEnabled'] == true || habit['remindersEnabled'] == true;
  if (!reminderEnabled) return false;

  final reminderMinutes = _reminderMinutes(habit['reminderTime']);
  if (reminderMinutes == null) return false;

  final completedMinutes = (completedAt.hour * 60) + completedAt.minute;
  return (completedMinutes - reminderMinutes).abs() <= toleranceMinutes;
}

int? _reminderMinutes(dynamic rawValue) {
  final raw = (rawValue ?? '').toString().trim();
  if (raw.isEmpty) return null;

  final parts = raw.split(':');
  if (parts.length != 2) return null;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

  return (hour * 60) + minute;
}

HabitStreakSnapshot _snapshotFromMetricValue(
  String id, {
  required int value,
  int? bestValue,
}) {
  return HabitStreakSnapshot(
    habitId: id,
    currentStreak: value,
    bestStreak: bestValue ?? value,
    totalCompletedDays: bestValue ?? value,
  );
}

int _computeRecoveryCount(Map<DateTime, int> countsByDay) {
  final positiveDays = countsByDay.entries
      .where((entry) => entry.value > 0)
      .map((entry) => entry.key)
      .toList()
    ..sort();

  if (positiveDays.length < 3) return 0;

  var recoveries = 0;
  for (var index = 0; index < positiveDays.length; index += 1) {
    final previous = index == 0 ? null : positiveDays[index - 1];
    if (previous != null && positiveDays[index].difference(previous).inDays == 1) {
      continue;
    }

    var streakLength = 1;
    while (index + streakLength < positiveDays.length &&
        positiveDays[index + streakLength]
                .difference(positiveDays[index + streakLength - 1])
                .inDays ==
            1) {
      streakLength += 1;
    }

    if (previous != null &&
        positiveDays[index].difference(previous).inDays > 1 &&
        streakLength >= 3) {
      recoveries += 1;
    }
  }

  return recoveries;
}

int _computeCurrentStreak(Map<DateTime, int> countsByDay, DateTime today) {
  var streak = 0;
  var cursor = DateTime(today.year, today.month, today.day);

  while ((countsByDay[cursor] ?? 0) > 0) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return streak;
}

int _computeBestStreak(Map<DateTime, int> countsByDay) {
  if (countsByDay.isEmpty) return 0;

  final days = countsByDay.keys.toList()..sort();
  var best = 0;
  var current = 0;
  DateTime? previousDay;

  for (final day in days) {
    final done = countsByDay[day] ?? 0;
    if (done <= 0) {
      current = 0;
      previousDay = day;
      continue;
    }

    if (previousDay == null) {
      current = 1;
    } else {
      current = day.difference(previousDay).inDays == 1 ? current + 1 : 1;
    }

    if (current > best) best = current;
    previousDay = day;
  }

  return best;
}

bool _isLegacyHabitStreakEntry(Map<String, dynamic> entry) {
  return (entry['type'] ?? '').toString().trim().toLowerCase() ==
      AchievementType.habitStreak.key;
}

bool _isRemovedFamilyConsistencyTier(Map<String, dynamic> entry) {
  final type = (entry['type'] ?? '').toString().trim().toLowerCase();
  if (type != AchievementType.familyConsistency.key) return false;

  final tier = AchievementTierX.fromKey((entry['tier'] ?? '').toString());
  return tier == AchievementTier.oldWood;
}

DateTime? _parsedUnlockedAt(Map<String, dynamic> entry) {
  final raw = (entry['unlockedAt'] ?? '').toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

Map<String, DateTime> _legacyUnlockedDatesByFamilyTier(
  List<Map<String, dynamic>> unlockedEntries,
) {
  final output = <String, DateTime>{};

  for (final entry in unlockedEntries) {
    if (!_isLegacyHabitStreakEntry(entry)) continue;

    final familyId = (entry['familyId'] ?? '').toString().trim();
    if (!FamilyTheme.order.contains(familyId)) continue;

    final tier = AchievementTierX.fromKey((entry['tier'] ?? '').toString());
    final unlockedAt = _parsedUnlockedAt(entry);
    if (unlockedAt == null) continue;

    final key = '$familyId:${tier.key}';
    final existing = output[key];
    if (existing == null || unlockedAt.isBefore(existing)) {
      output[key] = unlockedAt;
    }
  }

  return output;
}

void _sanitizeFeaturedAchievements(Map<String, dynamic> userState) {
  final achievements = _ensureAchievementsRoot(userState);
  final unlockedIds = _list(achievements['unlocked'])
      .whereType<Map>()
      .map((entry) => UnlockedAchievementRecord.fromJson(_map(entry)))
      .whereType<UnlockedAchievementRecord>()
      .map((record) => record.id)
      .toSet();

  achievements['featured'] = _list(achievements['featured'])
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty && unlockedIds.contains(entry))
      .take(3)
      .toList(growable: false);
}

void _syncAchievementsFromCurrentHabits(
  UserStateStore store,
  Map<String, dynamic> userState, {
  bool enqueueVisualTrigger = false,
}) {
  final achievements = _ensureAchievementsRoot(userState);
  final rawUnlocked = _list(achievements['unlocked'])
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(_map(entry)))
      .toList(growable: false);
  final legacyUnlockDates = _legacyUnlockedDatesByFamilyTier(rawUnlocked);
  final unlockedById = <String, Map<String, dynamic>>{};

  for (final entry in rawUnlocked) {
    if (_isLegacyHabitStreakEntry(entry)) continue;
    if (_isRemovedFamilyConsistencyTier(entry)) continue;

    final id = (entry['id'] ?? '').toString().trim();
    if (id.isEmpty) continue;
    unlockedById.putIfAbsent(id, () => entry);
  }

  final snapshotsByFamily = _familyConsistencySnapshotsFromUserState(userState);
  final specialSnapshots = _specialAchievementSnapshotsFromUserState(userState);

  for (final familyId in FamilyTheme.order) {
    final snapshot = snapshotsByFamily[familyId] ??
        HabitStreakSnapshot(
          habitId: familyId,
          currentStreak: 0,
          bestStreak: 0,
          totalCompletedDays: 0,
        );

    for (final milestone in AchievementCatalog.streakMilestones) {
      if (snapshot.bestStreak < milestone.targetValue) continue;

      final achievementId = AchievementCatalog.familyConsistencyAchievementId(
        familyId: familyId,
        tier: milestone.tier,
      );
      if (unlockedById.containsKey(achievementId)) continue;

      final legacyKey = '$familyId:${milestone.tier.key}';
      final record = UnlockedAchievementRecord(
        id: achievementId,
        type: AchievementType.familyConsistency,
        tier: milestone.tier,
        unlockedAt: legacyUnlockDates[legacyKey] ?? DateTime.now(),
        habitId: familyId,
        habitName: AchievementCatalog.familyAchievementTitle(
          familyId: familyId,
          tier: milestone.tier,
        ),
        familyId: familyId,
        targetValue: milestone.targetValue,
      );

      unlockedById[achievementId] = record.toJson();

      if (enqueueVisualTrigger && snapshot.currentStreak == milestone.targetValue) {
        store._pendingAchievementUnlocks.add(record);
      }
    }
  }

  for (final achievement in AchievementCatalog.buildSpecialAchievements()) {
    final snapshot = specialSnapshots[achievement.id] ??
        HabitStreakSnapshot(
          habitId: achievement.id,
          currentStreak: 0,
          bestStreak: 0,
          totalCompletedDays: 0,
        );
    if (snapshot.bestStreak < achievement.targetValue) continue;
    if (unlockedById.containsKey(achievement.id)) continue;

    final record = UnlockedAchievementRecord(
      id: achievement.id,
      type: achievement.type,
      tier: achievement.tier,
      unlockedAt: DateTime.now(),
      habitId: achievement.habitId,
      habitName: achievement.habitName,
      familyId: achievement.familyId,
      targetValue: achievement.targetValue,
    );

    unlockedById[achievement.id] = record.toJson();

    if (enqueueVisualTrigger && snapshot.currentStreak == achievement.targetValue) {
      store._pendingAchievementUnlocks.add(record);
    }
  }

  final unlocked = unlockedById.values.toList(growable: false)
    ..sort((a, b) {
      final aDate = _parsedUnlockedAt(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = _parsedUnlockedAt(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

  achievements['unlocked'] = unlocked;
  _sanitizeFeaturedAchievements(userState);
}
