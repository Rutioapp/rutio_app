import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/account_deletion_service.dart';
import '../data/services/habit_sync_service.dart';
import '../data/repositories/user_state_repository.dart';
import '../features/achievements/application/achievement_catalog.dart';
import '../features/achievements/domain/models/achievement.dart';
import '../features/achievements/domain/models/habit_streak_snapshot.dart';
import '../features/achievements/domain/models/unlocked_achievement_record.dart';
import '../models/diary_entry.dart';
import '../screens/todo/models/todo_item.dart';
import '../utils/family_theme.dart';

part 'user_state_store_account.dart';
part 'user_state_store_achievements.dart';
part 'user_state_store_core.dart';
part 'user_state_store_diary.dart';
part 'user_state_store_habits.dart';
part 'user_state_store_habit_progress.dart';
part 'user_state_store_todos.dart';

class UserStateStore extends ChangeNotifier {
  final UserStateRepository _repo;
  final HabitSyncService _habitSyncService;

  UserStateStore(
    this._repo, {
    HabitSyncService? habitSyncService,
  }) : _habitSyncService = habitSyncService ?? HabitSyncService();

  Map<String, dynamic>? _state;
  bool _loading = false;
  Object? _error;
  bool _isDeletingAccount = false;
  bool _isSupabaseHabitsBackfillRunning = false;
  Object? _accountDeletionError;
  final List<UnlockedAchievementRecord> _pendingAchievementUnlocks =
      <UnlockedAchievementRecord>[];

  Map<String, dynamic>? get state => _state;
  bool get isLoading => _loading;
  Object? get error => _error;
  bool get isDeletingAccount => _isDeletingAccount;
  bool get isSupabaseHabitsBackfillRunning => _isSupabaseHabitsBackfillRunning;
  Object? get accountDeletionError => _accountDeletionError;

  void _emitChanged() => notifyListeners();

  bool get hasSession => onboardingDone;
  bool get onboardingDone => _onboardingDone(this);

  Future<void> setOnboardingDone(bool done, {String? email}) =>
      _setOnboardingDone(this, done, email: email);

  Future<void> setActiveViewDate(DateTime date) =>
      _setActiveViewDate(this, date);

  Future<void> deleteHabitById(String id, {bool purgeHistory = true}) =>
      _deleteHabitById(this, id, purgeHistory: purgeHistory);

  Future<void> deleteHabit(String id) => deleteHabitById(id);
  Future<void> removeHabit(String id) => deleteHabitById(id);

  Future<void> load() => _loadStore(this);
  Future<void> save(Map<String, dynamic> newState) =>
      _saveStore(this, newState);

  Map<String, dynamic> get notificationSettings => _notificationSettings(this);

  bool get notificationsEnabled => notificationSettings['enabled'] == true;
  bool get habitRemindersEnabled =>
      notificationSettings['habitReminders'] != false;
  bool get dayClosureEnabled => notificationSettings['dayClosure'] != false;
  bool get streakRiskEnabled => notificationSettings['streakRisk'] != false;
  bool get streakCelebrationEnabled =>
      notificationSettings['streakCelebration'] != false;
  bool get inactivityReengagementEnabled =>
      notificationSettings['inactivityReengagement'] != false;
  bool get dailyMotivationEnabled =>
      notificationSettings['dailyMotivation'] == true;
  bool get marketingNotificationsEnabled =>
      notificationSettings['marketing'] == true;

  String? get preferredLanguageCode => _preferredLanguageCode(this);

  Locale? get preferredLocale {
    final code = preferredLanguageCode;
    if (code == null) return null;
    return Locale(code);
  }

  String get dailyMotivationTime =>
      (notificationSettings['dailyMotivationTime'] ?? '21:00').toString();

  String get dayClosureTime =>
      (notificationSettings['dayClosureTime'] ?? '21:00').toString();

  Map<String, dynamic> get notificationMetadata => _notificationMetadata(this);

  Future<void> setNotificationsEnabled(bool enabled) =>
      _setNotificationsEnabled(this, enabled);

  Future<void> setDailyMotivationEnabled(bool enabled) =>
      _setDailyMotivationEnabled(this, enabled);

  Future<void> setMarketingNotificationsEnabled(bool enabled) =>
      _setMarketingNotificationsEnabled(this, enabled);

  Future<void> setDailyMotivationTime(String hhmm) =>
      _setDailyMotivationTime(this, hhmm);

  Future<void> updateNotificationSettings(Map<String, dynamic> patch) =>
      _updateNotificationSettings(this, patch);

  Future<void> updateNotificationMetadata(Map<String, dynamic> patch) =>
      _updateNotificationMetadata(this, patch);

  Future<void> setPreferredLanguageCode(String languageCode) =>
      _setPreferredLanguageCode(this, languageCode);

  Future<void> clearLocalAccountData({bool preserveLanguageCode = true}) =>
      _clearLocalAccountData(
        this,
        preserveLanguageCode: preserveLanguageCode,
      );
  Future<void> clearAuthSessionState() => _clearAuthSessionState(this);
  Future<void> deleteAccount() => _deleteAccount(this);
  void clearDeleteAccountError() => _clearDeleteAccountError(this);

  Future<void> applySupabaseIdentity({
    required String userId,
    String? email,
    String? displayName,
    String? avatarUrl,
  }) =>
      _applySupabaseIdentity(
        this,
        userId: userId,
        email: email,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

  Future<void> clearSupabaseIdentity() => _clearSupabaseIdentity(this);

  Map<String, dynamic> get profile => _profile(this);

  String? get displayName {
    final currentProfile = profile;
    final value = currentProfile['displayName'] ??
        currentProfile['name'] ??
        currentProfile['username'];
    return value?.toString();
  }

  String? get bioText => profile['bio']?.toString();
  String? get goalText => profile['goal']?.toString();
  String? get avatarUrl => profile['avatarUrl']?.toString();
  String? get userId {
    final root = _state;
    if (root == null) return null;

    final userState = _ensureUserStateRoot(root);
    final value =
        (userState['userId'] ?? userState['id'] ?? '').toString().trim();
    return value.isEmpty ? null : value;
  }

  String? get authEmail {
    final root = _state;
    if (root == null) return null;

    final userState = _ensureUserStateRoot(root);
    final meta = _map(userState['meta']);
    final profile = _map(userState['profile']);
    final value =
        (meta['authEmail'] ?? profile['email'] ?? profile['mail'] ?? '')
            .toString()
            .trim();
    return value.isEmpty ? null : value;
  }

  Future<void> updateProfileFields({
    String? displayName,
    String? bio,
    String? goal,
    String? avatarUrl,
  }) =>
      _updateProfileFields(
        this,
        displayName: displayName,
        bio: bio,
        goal: goal,
        avatarUrl: avatarUrl,
      );

  Future<bool> buyItem({
    required String itemId,
    required int price,
  }) =>
      _buyItem(this, itemId: itemId, price: price);

  Future<void> equip({
    required String slot,
    required String itemId,
  }) =>
      _equip(this, slot: slot, itemId: itemId);

  Future<void> addHabitFromCatalog({
    required Map<String, dynamic> habitDef,
    required String familyId,
    num? target,
    String scheduleType = 'daily',
    String? scheduledDate,
    List<int>? weekdays,
    String? routine,
  }) =>
      _addHabitFromCatalog(
        this,
        habitDef: habitDef,
        familyId: familyId,
        target: target,
        scheduleType: scheduleType,
        scheduledDate: scheduledDate,
        weekdays: weekdays,
        routine: routine,
      );

  Future<void> addCustomHabit(Map<String, dynamic> habit) =>
      _addCustomHabit(this, habit);

  Future<void> addHabitCustom(Map<String, dynamic> habit) =>
      addCustomHabit(habit);

  Future<void> addHabit(Map<String, dynamic> habit) => addCustomHabit(habit);

  Future<void> addActiveHabit(Map<String, dynamic> habit) =>
      addCustomHabit(habit);
  Future<HabitBackfillSummary> syncExistingLocalHabitsOnce({
    bool force = false,
  }) =>
      _syncExistingLocalHabitsOnce(this, force: force);

  Future<void> reorderVisibleHabits({
    required List<String> orderedVisibleIds,
  }) =>
      _reorderVisibleHabits(this, orderedVisibleIds: orderedVisibleIds);

  Future<void> updateHabitPlan({
    required String habitId,
    String? scheduleType,
    String? scheduledDate,
    List<int>? weekdays,
    String? routine,
  }) =>
      _updateHabitPlan(
        this,
        habitId: habitId,
        scheduleType: scheduleType,
        scheduledDate: scheduledDate,
        weekdays: weekdays,
        routine: routine,
      );

  Future<void> updateHabitDetailsFromEdit(dynamic updatedHabit) =>
      _updateHabitDetailsFromEdit(this, updatedHabit);

  Future<void> setCountHabitValue({
    required String habitId,
    required num value,
  }) =>
      _setCountHabitValue(this, habitId: habitId, value: value);

  Future<void> completeHabit({
    required String habitId,
    num delta = 1,
  }) =>
      _completeHabit(this, habitId: habitId, delta: delta);

  Future<void> toggleHabitDoneForDate({
    required String habitId,
    required DateTime date,
  }) =>
      _toggleHabitDoneForDate(this, habitId: habitId, date: date);

  Future<void> setHabitCompletionForKey({
    required String habitId,
    required String dateKey,
    required bool done,
  }) =>
      _setHabitCompletionForKey(
        this,
        habitId: habitId,
        dateKey: dateKey,
        done: done,
      );

  Future<void> setCheckHabitDoneForKey({
    required String habitId,
    required String dateKey,
    required bool done,
  }) =>
      setHabitCompletionForKey(
        habitId: habitId,
        dateKey: dateKey,
        done: done,
      );

  Future<void> setHabitCompletion({
    required String habitId,
    required DateTime date,
    required bool done,
  }) =>
      setHabitCompletionForKey(
        habitId: habitId,
        dateKey: _dateKey(date),
        done: done,
      );

  Future<void> setHabitSkipForKey({
    required String habitId,
    required String dateKey,
    required bool skipped,
  }) =>
      _setHabitSkipForKey(
        this,
        habitId: habitId,
        dateKey: dateKey,
        skipped: skipped,
      );

  Future<void> setHabitSkip({
    required String habitId,
    required DateTime date,
    required bool skipped,
  }) =>
      setHabitSkipForKey(
        habitId: habitId,
        dateKey: _dateKey(date),
        skipped: skipped,
      );

  Future<void> setCountHabitValueForDate({
    required String habitId,
    required DateTime date,
    required num value,
  }) =>
      _setCountHabitValueForDate(
        this,
        habitId: habitId,
        date: date,
        value: value,
      );

  List<DiaryEntry> get diaryEntries => _diaryEntries(this);

  List<TodoItem> get todoItems => _todoItems(this);

  Future<void> upsertTodoItem(TodoItem item) => _upsertTodoItem(this, item);

  Future<void> deleteTodoItem(String id) => _deleteTodoItem(this, id);

  Future<void> setTodoCompleted({
    required String todoId,
    required bool isCompleted,
  }) =>
      _setTodoCompleted(
        this,
        todoId: todoId,
        isCompleted: isCompleted,
      );

  Future<void> addDiaryEntry(DiaryEntry entry) => _addDiaryEntry(this, entry);

  Future<void> updateDiaryEntry(DiaryEntry entry) =>
      _updateDiaryEntry(this, entry);

  Future<void> deleteDiaryEntry(String id) => _deleteDiaryEntry(this, id);

  dynamic getActiveHabitById(String id) => _getActiveHabitById(this, id);

  List<Map<String, dynamic>> get activeHabits => _activeHabits(this);

  List<UnlockedAchievementRecord> get unlockedAchievementRecords =>
      _unlockedAchievementRecords(this);

  Map<String, UnlockedAchievementRecord> get unlockedAchievementsById =>
      {for (final record in unlockedAchievementRecords) record.id: record};

  List<String> get featuredAchievementIds => _featuredAchievementIds(this);

  Future<void> setFeaturedAchievementIds(List<String> achievementIds) =>
      _setFeaturedAchievementIds(this, achievementIds);

  HabitStreakSnapshot habitStreakSnapshotForHabitId(
    String habitId, {
    DateTime? today,
  }) =>
      _habitStreakSnapshotForHabitId(this, habitId: habitId, today: today);

  Map<String, HabitStreakSnapshot> get habitStreakSnapshots =>
      _habitStreakSnapshots(this);

  Map<String, HabitStreakSnapshot> get familyConsistencySnapshots =>
      _familyConsistencySnapshots(this);

  Map<String, HabitStreakSnapshot> get achievementMetricSnapshots =>
      _achievementMetricSnapshots(this);

  int get pendingAchievementUnlockCount => _pendingAchievementUnlocks.length;

  UnlockedAchievementRecord? consumeNextPendingAchievementUnlock() {
    if (_pendingAchievementUnlocks.isEmpty) return null;
    final next = _pendingAchievementUnlocks.removeAt(0);
    _emitChanged();
    return next;
  }
}
