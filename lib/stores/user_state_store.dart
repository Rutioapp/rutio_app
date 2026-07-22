import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/account_deletion_service.dart';
import '../constants/reward_constants.dart';
import '../data/services/achievement_sync_service.dart';
import '../data/services/habit_log_sync_service.dart';
import '../data/services/habit_sync_service.dart';
import '../data/services/journal_entry_sync_service.dart';
import '../data/mappers/habit_remote_mapper.dart';
import '../data/models/remote/remote_habit.dart';
import '../data/models/remote/remote_habit_log.dart';
import '../data/models/remote/remote_user_progress.dart';
import '../data/repositories/diary_v2_supabase_repository.dart';
import '../data/repositories/habit_log_repository.dart';
import '../data/repositories/habit_repository.dart';
import '../data/repositories/repository_result.dart';
import '../data/repositories/user_progress_repository.dart';
import '../data/services/user_progress_sync_service.dart';
import '../data/repositories/journal_entry_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/user_state_repository.dart';
import '../devtools/demo_seed/demo_seed_models.dart';
import '../devtools/rutio_runtime_profile.dart';
import '../features/achievements/application/achievement_catalog.dart';
import '../features/achievements/application/achievement_level_reward_coordinator.dart';
import '../features/achievements/application/achievement_reward_resolver.dart';
import '../features/achievements/data/cloud/achievement_level_reward_config.dart';
import '../features/achievements/data/cloud/achievement_level_reward_repository.dart';
import '../features/achievements/data/cloud/shared_preferences_pending_reward_claim_store.dart';
import '../features/achievements/domain/models/achievement.dart';
import '../features/achievements/domain/models/habit_streak_snapshot.dart';
import '../features/achievements/domain/models/unlocked_achievement_record.dart';
import '../features/gamification/application/level_up_celebration_controller.dart';
import '../features/habits/domain/models/habit_occurrence_status.dart';
import '../features/habits/application/habit_currency_reward_coordinator.dart';
import '../features/habits/data/cloud/habit_currency_reward_repository.dart';
import '../features/habits/data/cloud/habit_currency_rewards_config.dart';
import '../features/habits/data/cloud/shared_preferences_pending_currency_operation_store.dart';
import '../models/daily_mood.dart';
import '../features/global_wallet/application/global_wallet_controller.dart';
import '../features/shop/application/shop_service.dart';
import '../features/shop/data/shop_catalog.dart';
import '../features/shop/data/local_active_utility_effects_repository.dart';
import '../features/shop/data/cloud/utility_consumption_config.dart';
import '../features/shop/data/cloud/utility_consumption_repository.dart';
import '../features/shop/data/shop_local_repository.dart';
import '../features/shop/domain/active_utility_effects_repository.dart';
import '../features/shop/domain/models/active_utility_effect.dart';
import '../features/habits/domain/habit_reward_calculator.dart';
import '../features/habits/domain/models/active_streak_shield.dart';
import '../features/habits/domain/models/recoverable_streak_break.dart';
import '../features/habits/domain/models/streak_recover_operation_result.dart';
import '../features/habits/domain/models/streak_shield_operation_result.dart';
import '../features/gamification/domain/level_event.dart';
import '../features/gamification/domain/level_event_resolver.dart';
import '../features/gamification/domain/level_progression.dart';
import '../features/gamification/domain/level_reward_resolver.dart';
import '../features/habits/data/local_habit_reward_transaction_repository.dart';
import '../features/habits/domain/habit_reward_transaction_repository.dart';
import '../features/habits/domain/models/habit_reward_transaction.dart';
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

enum SupabaseUserProgressRestoreStatus {
  restored,
  alreadyAligned,
  skippedNoAuthUser,
  skippedNoRemoteRow,
  skippedLocalConflict,
  failedRemoteStateUnknown,
}

@immutable
class SupabaseUserProgressRestoreResult {
  const SupabaseUserProgressRestoreResult({
    required this.status,
    this.error,
  });

  final SupabaseUserProgressRestoreStatus status;
  final RepositoryError? error;

  bool get restored =>
      status == SupabaseUserProgressRestoreStatus.restored ||
      status == SupabaseUserProgressRestoreStatus.alreadyAligned;

  bool get shouldAllowBackfill =>
      status == SupabaseUserProgressRestoreStatus.restored ||
      status == SupabaseUserProgressRestoreStatus.alreadyAligned ||
      status == SupabaseUserProgressRestoreStatus.skippedNoRemoteRow;
}

@immutable
class SupabaseUserProgressBootstrapResult {
  const SupabaseUserProgressBootstrapResult({
    required this.restoreResult,
    required this.backfillSynced,
  });

  final SupabaseUserProgressRestoreResult restoreResult;
  final bool backfillSynced;
}

class UserStateStore extends ChangeNotifier {
  static const Duration diaryV2AutoPullCooldown = Duration(minutes: 10);
  static const Duration habitsAutoPullCooldown = Duration(minutes: 10);

  final UserStateRepository _repo;
  final AchievementSyncService _achievementSyncService;
  final HabitSyncService _habitSyncService;
  final HabitLogSyncService _habitLogSyncService;
  final UserProgressSyncService _userProgressSyncService;
  final JournalEntrySyncService _journalEntrySyncService;
  final HabitCurrencyRewardCoordinator _habitCurrencyRewardCoordinator;
  final AchievementLevelRewardCoordinator _achievementLevelRewardCoordinator;
  DiaryV2SupabaseRepository? _diaryV2SupabaseRepository;
  HabitRepository? _habitRepository;
  HabitLogRepository? _habitLogRepository;
  ActiveUtilityEffectsRepository? _activeUtilityEffectsRepository;
  final UtilityConsumptionRepository? _utilityConsumptionRepository;
  final bool? _cloudHabitRewardsEnabledOverride;
  HabitRewardTransactionRepository? _habitRewardTransactionRepository;
  final UserProgressRepository? _userProgressRepository;
  final ProfileRepository? _profileRepository;
  final GlobalWalletController? _globalWalletController;
  final LevelUpCelebrationController _levelUpCelebrationController;
  final CurrentUserIdProvider _currentSupabaseUserIdProvider;
  final DateTime Function() _nowProvider;

  UserStateStore(
    this._repo, {
    AchievementSyncService? achievementSyncService,
    HabitSyncService? habitSyncService,
    HabitLogSyncService? habitLogSyncService,
    UserProgressSyncService? userProgressSyncService,
    JournalEntrySyncService? journalEntrySyncService,
    HabitCurrencyRewardCoordinator? habitCurrencyRewardCoordinator,
    DiaryV2SupabaseRepository? diaryV2SupabaseRepository,
    HabitRepository? habitRepository,
    HabitLogRepository? habitLogRepository,
    ActiveUtilityEffectsRepository? activeUtilityEffectsRepository,
    UtilityConsumptionRepository? utilityConsumptionRepository,
    bool? utilityConsumptionEnabledOverride,
    bool? cloudHabitRewardsEnabledOverride,
    HabitRewardTransactionRepository? habitRewardTransactionRepository,
    UserProgressRepository? userProgressRepository,
    ProfileRepository? profileRepository,
    GlobalWalletController? globalWalletController,
    AchievementLevelRewardCoordinator? achievementLevelRewardCoordinator,
    CurrentUserIdProvider? currentSupabaseUserIdProvider,
    DateTime Function()? nowProvider,
  })  : _achievementSyncService =
            achievementSyncService ?? AchievementSyncService(),
        _habitSyncService = habitSyncService ?? HabitSyncService(),
        _habitLogSyncService = habitLogSyncService ?? HabitLogSyncService(),
        _userProgressSyncService =
            userProgressSyncService ?? UserProgressSyncService(),
        _journalEntrySyncService = journalEntrySyncService ??
            JournalEntrySyncService(
              journalEntryRepository: JournalEntryRepository(),
            ),
        _habitCurrencyRewardCoordinator = habitCurrencyRewardCoordinator ??
            HabitCurrencyRewardCoordinator(
              rewardRepository: SupabaseHabitCurrencyRewardRepository(),
              pendingOperationStore:
                  SharedPreferencesPendingCurrencyOperationStore(),
              transactionRepository: habitRewardTransactionRepository ??
                  LocalHabitRewardTransactionRepository(),
              currentUserIdProvider:
                  currentSupabaseUserIdProvider ?? _authenticatedSupabaseUserId,
              enabled: HabitCurrencyRewardsConfig.resolveEnabled(),
            ),
        _achievementLevelRewardCoordinator =
            achievementLevelRewardCoordinator ??
                AchievementLevelRewardCoordinator(
                  rewardRepository: SupabaseAchievementLevelRewardRepository(),
                  pendingClaimStore: SharedPreferencesPendingRewardClaimStore(),
                  currentUserIdProvider: currentSupabaseUserIdProvider ??
                      _authenticatedSupabaseUserId,
                  enabled: AchievementLevelRewardConfig.resolveEnabled(),
                ),
        _diaryV2SupabaseRepository = diaryV2SupabaseRepository,
        _habitRepository = habitRepository,
        _habitLogRepository = habitLogRepository,
        _utilityConsumptionRepository = utilityConsumptionRepository ??
            (UtilityConsumptionConfig.resolveEnabled(
                    override: utilityConsumptionEnabledOverride)
                ? SupabaseUtilityConsumptionRepository()
                : null),
        _activeUtilityEffectsRepository = activeUtilityEffectsRepository ??
            (UtilityConsumptionConfig.resolveEnabled(
                    override: utilityConsumptionEnabledOverride)
                ? ((utilityConsumptionRepository ??
                        SupabaseUtilityConsumptionRepository())
                    as ActiveUtilityEffectsRepository)
                : null),
        _habitRewardTransactionRepository = habitRewardTransactionRepository,
        _cloudHabitRewardsEnabledOverride = cloudHabitRewardsEnabledOverride,
        _userProgressRepository = userProgressRepository,
        _profileRepository = profileRepository,
        _globalWalletController = globalWalletController,
        _levelUpCelebrationController = const LevelUpCelebrationController(),
        _currentSupabaseUserIdProvider =
            currentSupabaseUserIdProvider ?? _authenticatedSupabaseUserId,
        _nowProvider = nowProvider ?? DateTime.now;

  Map<String, dynamic>? _state;
  bool _loading = false;
  Object? _error;
  bool _isDeletingAccount = false;
  bool _isLoggingOut = false;
  bool _isResettingUserState = false;
  bool _suppressGamificationOverlays = false;
  bool _isSupabaseAchievementsBackfillRunning = false;
  bool _isSupabaseHabitsBackfillRunning = false;
  bool _isSupabaseHabitLogsBackfillRunning = false;
  bool _isSupabaseUserProgressBackfillRunning = false;
  bool _isSupabaseJournalEntriesBackfillRunning = false;
  bool _isDiaryV2RemotePullRunning = false;
  bool _isHabitsRemotePullRunning = false;
  DateTime? _lastDiaryV2RemotePullAttemptAt;
  DateTime? _lastDiaryV2RemotePullSuccessAt;
  DateTime? _lastHabitsRemotePullAttemptAt;
  DateTime? _lastHabitsRemotePullSuccessAt;
  Object? _accountDeletionError;
  String? _activeLocalScopeUserId;
  int _scopeEpoch = 0;
  Future<void> _scopeSwitchChain = Future<void>.value();
  final Map<String, int> _hydratedXpBaselineByUserId = <String, int>{};
  final Map<String, int> _hydratedLevelBaselineByUserId = <String, int>{};
  final List<UnlockedAchievementRecord> _pendingAchievementUnlocks =
      <UnlockedAchievementRecord>[];
  final List<LevelEvent> _pendingLevelCelebrations = <LevelEvent>[];
  final bool _debugStreakRecoverSeedEnabled = const bool.fromEnvironment(
    'RUTIO_DEBUG_STREAK_RECOVER_SEED',
    defaultValue: false,
  );
  bool _debugStreakRecoverSeedAttempted = false;

  Map<String, dynamic>? get state => _state;
  bool get isLoading => _loading;
  Object? get error => _error;
  bool get isDeletingAccount => _isDeletingAccount;
  bool get isLoggingOut => _isLoggingOut;
  bool get isResettingUserState => _isResettingUserState;
  bool get suppressGamificationOverlays => _suppressGamificationOverlays;
  bool get shouldShowGamificationOverlays =>
      !_isLoggingOut &&
      !_isResettingUserState &&
      !RutioRuntimeProfile.isScreenshotMode &&
      !_suppressGamificationOverlays &&
      ((userId ?? '').trim().isNotEmpty);
  String? get activeLocalScopeUserId => _activeLocalScopeUserId;
  int get scopeEpoch => _scopeEpoch;
  bool get isSupabaseAchievementsBackfillRunning =>
      _isSupabaseAchievementsBackfillRunning;
  bool get isSupabaseHabitsBackfillRunning => _isSupabaseHabitsBackfillRunning;
  bool get isSupabaseHabitLogsBackfillRunning =>
      _isSupabaseHabitLogsBackfillRunning;
  bool get isSupabaseUserProgressBackfillRunning =>
      _isSupabaseUserProgressBackfillRunning;
  bool get isSupabaseJournalEntriesBackfillRunning =>
      _isSupabaseJournalEntriesBackfillRunning;
  bool get isDiaryV2RemotePullRunning => _isDiaryV2RemotePullRunning;
  bool get isHabitsRemotePullRunning => _isHabitsRemotePullRunning;
  DateTime? get lastDiaryV2RemotePullAttemptAt =>
      _lastDiaryV2RemotePullAttemptAt;
  DateTime? get lastDiaryV2RemotePullSuccessAt =>
      _lastDiaryV2RemotePullSuccessAt;
  DateTime? get lastHabitsRemotePullAttemptAt => _lastHabitsRemotePullAttemptAt;
  DateTime? get lastHabitsRemotePullSuccessAt => _lastHabitsRemotePullSuccessAt;
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
  Future<void> seedDebugRecoverableStreakBreak({bool forceEnabled = false}) =>
      _seedDebugRecoverableStreakBreak(
        this,
        forceEnabled: forceEnabled,
      );
  Future<void> switchLocalScope({
    String? userId,
    bool forceReload = false,
  }) {
    _scopeSwitchChain = _scopeSwitchChain.then(
      (_) => _switchLocalScope(
        this,
        userId: userId,
        forceReload: forceReload,
      ),
    );
    return _scopeSwitchChain;
  }

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
  void clearTransientGamificationState() =>
      _clearTransientGamificationState(this);
  void suppressGamificationOverlaysDuringLogout() =>
      _suppressGamificationOverlaysDuringLogout(this);
  void restoreGamificationOverlaysAfterLogout() =>
      _restoreGamificationOverlaysAfterLogout(this);
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

  Future<AchievementBackfillSummary> syncExistingLocalAchievementsOnce({
    bool force = false,
  }) =>
      _syncExistingLocalAchievementsOnce(this, force: force);

  Future<HabitLogBackfillSummary> syncExistingLocalHabitLogsOnce({
    bool force = false,
  }) =>
      _syncExistingLocalHabitLogsOnce(this, force: force);

  Future<bool> syncSupabaseUserProgressBackfillOnce({bool force = false}) =>
      _syncSupabaseUserProgressBackfillOnce(this, force: force);

  Future<SupabaseUserProgressRestoreResult>
      restoreSupabaseUserProgressBestEffort() =>
          _restoreSupabaseUserProgressBestEffort(this);

  Future<SupabaseUserProgressBootstrapResult>
      syncSupabaseUserProgressBootstrapBestEffort({bool force = false}) =>
          _syncSupabaseUserProgressBootstrapBestEffort(this, force: force);

  Future<JournalEntryBackfillSummary> syncExistingLocalJournalEntriesOnce({
    bool force = false,
  }) =>
      _syncExistingLocalJournalEntriesOnce(this, force: force);

  Future<void> autoSyncDiaryV2FromRemoteIfNeeded() =>
      _autoSyncDiaryV2FromRemoteIfNeeded(this);

  Future<void> syncDiaryV2FromRemoteBestEffort() =>
      _syncDiaryV2FromRemoteBestEffort(this);

  Future<void> syncHabitsFromRemoteBestEffort() =>
      _syncHabitsFromRemoteBestEffort(this);

  Future<void> maybeSyncHabitsFromRemoteBestEffort({
    bool ignoreCooldown = false,
  }) =>
      _maybeSyncHabitsFromRemoteBestEffort(
        this,
        ignoreCooldown: ignoreCooldown,
      );

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
  List<DailyMood> get dailyMoods => _dailyMoods(this);

  DailyMood? dailyMoodForDate(DateTime date) => _dailyMoodForDate(this, date);

  List<DailyMood> dailyMoodsForMonth(DateTime month) =>
      _dailyMoodsForMonth(this, month);

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

  Future<void> setDailyMood(DailyMood dailyMood) =>
      _setDailyMood(this, dailyMood);

  dynamic getActiveHabitById(String id) => _getActiveHabitById(this, id);

  List<Map<String, dynamic>> get activeHabits => _activeHabits(this);

  List<UnlockedAchievementRecord> get unlockedAchievementRecords =>
      _unlockedAchievementRecords(this);

  Map<String, UnlockedAchievementRecord> get unlockedAchievementsById =>
      {for (final record in unlockedAchievementRecords) record.id: record};

  List<String> get featuredAchievementIds => _featuredAchievementIds(this);

  Future<void> setFeaturedAchievementIds(List<String> achievementIds) =>
      _setFeaturedAchievementIds(this, achievementIds);

  List<ActiveStreakShield> get activeStreakShields =>
      _activeStreakShields(this);

  List<RecoverableStreakBreak> get recoverableStreakBreaks =>
      _recoverableStreakBreaks(this);

  ActiveStreakShield? activeStreakShieldForHabit(String habitId) =>
      _activeStreakShieldForHabit(this, habitId);

  RecoverableStreakBreak? recoverableStreakBreakForHabit(String habitId) =>
      _recoverableStreakBreakForHabitStore(this, habitId);

  Future<StreakShieldOperationResult> activateStreakShield({
    required String habitId,
    required String operationId,
    String? utilityId,
  }) =>
      _activateStreakShield(
        this,
        habitId: habitId,
        operationId: operationId,
        utilityId: utilityId,
      );

  Future<StreakRecoverOperationResult> recoverStreakBreak({
    required String breakId,
    required String operationId,
  }) =>
      _recoverStreakBreak(
        this,
        breakId: breakId,
        operationId: operationId,
      );

  Future<void> expireRecoverableStreakBreaks() =>
      _expireRecoverableStreakBreaks(this);

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

  int get pendingLevelCelebrationCount => _pendingLevelCelebrations.length;
  int get pendingAchievementUnlockCount => _pendingAchievementUnlocks.length;

  LevelEvent? peekNextPendingLevelCelebration() {
    if (_pendingLevelCelebrations.isEmpty) return null;
    return _pendingLevelCelebrations.first;
  }

  Future<void> markLevelCelebrationAsCelebrated({
    required int level,
  }) =>
      _markLevelCelebrationAsCelebrated(this, level: level);

  LevelEvent? consumeNextPendingLevelCelebration() {
    if (_pendingLevelCelebrations.isEmpty) return null;
    final next = _pendingLevelCelebrations.removeAt(0);
    _emitChanged();
    return next;
  }

  UnlockedAchievementRecord? consumeNextPendingAchievementUnlock() {
    if (_pendingAchievementUnlocks.isEmpty) return null;
    final next = _pendingAchievementUnlocks.removeAt(0);
    _emitChanged();
    return next;
  }
}
