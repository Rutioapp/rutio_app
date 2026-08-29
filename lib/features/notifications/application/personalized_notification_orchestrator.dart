import 'dart:async';

import '../../../stores/user_state_store.dart';
import '../domain/desired_notification.dart';
import '../domain/notification_clock.dart';
import '../domain/personalized_notification_models.dart';
import '../domain/personalized_notification_ports.dart';
import 'notification_os_reconciliation_coordinator.dart';
import 'notification_reconciliation_models.dart';
import 'personalized_notification_plan_builder.dart';

enum NotificationReconciliationReason {
  login,
  bootstrapReady,
  foreground,
  permissionStatusChanged,
  preferencesChanged,
  habitCreated,
  habitUpdated,
  habitDeleted,
  habitArchived,
  habitCompleted,
  habitSkipped,
  habitUncompleted,
  habitReminderChanged,
  timezoneChanged,
  localDateChanged,
  manualDebug,
  logoutCleanup,
}

enum PersonalizedNotificationOrchestrationStatus {
  executed,
  coalesced,
  skippedDisabled,
  skippedNoUser,
  skippedPermissions,
  skippedThrottled,
  contextFailure,
  staleScope,
}

abstract class PersonalizedNotificationsActivationPolicy {
  const PersonalizedNotificationsActivationPolicy();

  Future<bool> isEnabledForScope(NotificationScope scope);
}

class EnvironmentPersonalizedNotificationsActivationPolicy
    implements PersonalizedNotificationsActivationPolicy {
  const EnvironmentPersonalizedNotificationsActivationPolicy({
    this.enabled = _enabledByDefault,
  });

  static const bool _enabledByDefault = bool.fromEnvironment(
    'RUTIO_ENABLE_PERSONALIZED_NOTIFICATIONS_V2',
    defaultValue: false,
  );

  final bool enabled;

  @override
  Future<bool> isEnabledForScope(NotificationScope scope) async => enabled;
}

class FixedPersonalizedNotificationsActivationPolicy
    implements PersonalizedNotificationsActivationPolicy {
  const FixedPersonalizedNotificationsActivationPolicy(this.enabled);

  final bool enabled;

  @override
  Future<bool> isEnabledForScope(NotificationScope scope) async => enabled;
}

abstract class NotificationOrchestrationObserver {
  const NotificationOrchestrationObserver();

  void onRequested(
    NotificationScope scope,
    Set<NotificationReconciliationReason> reasons,
  ) {}

  void onCompleted(PersonalizedNotificationOrchestrationResult result) {}
}

class NoopNotificationOrchestrationObserver
    extends NotificationOrchestrationObserver {
  const NoopNotificationOrchestrationObserver();
}

class StoreBackedPersonalizedNotificationPreferencesResolver {
  StoreBackedPersonalizedNotificationPreferencesResolver({
    required NotificationPreferencesStore store,
    required UserStateStore userStateStore,
  }) : _store = store;

  final NotificationPreferencesStore _store;

  Future<NotificationPreferences> load(NotificationScope scope) async {
    return _store.load(scope);
  }
}

class PersonalizedNotificationOrchestrationResult {
  const PersonalizedNotificationOrchestrationResult({
    required this.status,
    required this.reason,
    required this.coalescedReasons,
    this.scope,
    this.capabilities,
    this.preferences,
    this.reconciliationResult,
    this.diagnostics = const <String>[],
    this.cleanedUpWhileDisabled = false,
  });

  final PersonalizedNotificationOrchestrationStatus status;
  final NotificationReconciliationReason reason;
  final Set<NotificationReconciliationReason> coalescedReasons;
  final NotificationScope? scope;
  final NotificationSchedulingCapabilities? capabilities;
  final NotificationPreferences? preferences;
  final NotificationReconciliationResult? reconciliationResult;
  final List<String> diagnostics;
  final bool cleanedUpWhileDisabled;
}

class PersonalizedNotificationOrchestrator
    implements UserStateNotificationMutationObserver {
  PersonalizedNotificationOrchestrator({
    required UserStateStore userStateStore,
    required NotificationInstallIdProvider installIdProvider,
    required StoreBackedPersonalizedNotificationPreferencesResolver
        preferencesResolver,
    required NotificationScheduleStore scheduleStore,
    required NotificationScheduleExecutor scheduleExecutor,
    required PersonalizedNotificationPlanBuilder planBuilder,
    required NotificationOsReconciliationCoordinator coordinator,
    PersonalizedNotificationsActivationPolicy? activationPolicy,
    NotificationClock? clock,
    NotificationOrchestrationObserver? observer,
    Duration foregroundThrottle = const Duration(seconds: 15),
  })  : _userStateStore = userStateStore,
        _installIdProvider = installIdProvider,
        _preferencesResolver = preferencesResolver,
        _scheduleStore = scheduleStore,
        _scheduleExecutor = scheduleExecutor,
        _planBuilder = planBuilder,
        _coordinator = coordinator,
        _activationPolicy = activationPolicy ??
            const EnvironmentPersonalizedNotificationsActivationPolicy(),
        _clock = clock ?? const SystemNotificationClock(),
        _observer = observer ?? const NoopNotificationOrchestrationObserver(),
        _foregroundThrottle = foregroundThrottle;

  final UserStateStore _userStateStore;
  final NotificationInstallIdProvider _installIdProvider;
  final StoreBackedPersonalizedNotificationPreferencesResolver
      _preferencesResolver;
  final NotificationScheduleStore _scheduleStore;
  final NotificationScheduleExecutor _scheduleExecutor;
  final PersonalizedNotificationPlanBuilder _planBuilder;
  final NotificationOsReconciliationCoordinator _coordinator;
  final PersonalizedNotificationsActivationPolicy _activationPolicy;
  final NotificationClock _clock;
  final NotificationOrchestrationObserver _observer;
  final Duration _foregroundThrottle;

  final Map<String, Future<PersonalizedNotificationOrchestrationResult>>
      _inFlightByScopeKey =
      <String, Future<PersonalizedNotificationOrchestrationResult>>{};
  final Map<String, Set<NotificationReconciliationReason>>
      _pendingReasonsByScopeKey =
      <String, Set<NotificationReconciliationReason>>{};
  final Map<String, DateTime> _lastForegroundAtByScopeKey =
      <String, DateTime>{};

  Future<PersonalizedNotificationOrchestrationResult>
      reconcilePersonalizedNotificationsNow({
    NotificationReconciliationReason reason =
        NotificationReconciliationReason.manualDebug,
  }) async {
    final scope = await _resolveActiveScope();
    if (scope == null) {
      return PersonalizedNotificationOrchestrationResult(
        status: PersonalizedNotificationOrchestrationStatus.skippedNoUser,
        reason: reason,
        coalescedReasons: <NotificationReconciliationReason>{reason},
        diagnostics: const <String>['no_active_user_scope'],
      );
    }
    return _enqueue(scope, <NotificationReconciliationReason>{reason});
  }

  Future<PersonalizedNotificationOrchestrationResult>
      reconcileForBootstrapReady() {
    return reconcilePersonalizedNotificationsNow(
      reason: NotificationReconciliationReason.bootstrapReady,
    );
  }

  Future<PersonalizedNotificationOrchestrationResult>
      reconcileForForeground() async {
    final scope = await _resolveActiveScope();
    if (scope == null) {
      return PersonalizedNotificationOrchestrationResult(
        status: PersonalizedNotificationOrchestrationStatus.skippedNoUser,
        reason: NotificationReconciliationReason.foreground,
        coalescedReasons: const <NotificationReconciliationReason>{
          NotificationReconciliationReason.foreground,
        },
        diagnostics: const <String>['no_active_user_scope'],
      );
    }

    final effectiveReason = await _resolveForegroundReason(scope);
    if (effectiveReason == NotificationReconciliationReason.foreground &&
        _shouldThrottleForeground(scope)) {
      return PersonalizedNotificationOrchestrationResult(
        status: PersonalizedNotificationOrchestrationStatus.skippedThrottled,
        reason: effectiveReason,
        coalescedReasons: <NotificationReconciliationReason>{effectiveReason},
        scope: scope,
        diagnostics: const <String>['foreground_throttled'],
      );
    }
    return _enqueue(scope, <NotificationReconciliationReason>{effectiveReason});
  }

  Future<PersonalizedNotificationOrchestrationResult>
      cleanupCurrentScopeForLogout() async {
    final scope = await _resolveActiveScope();
    if (scope == null) {
      return const PersonalizedNotificationOrchestrationResult(
        status: PersonalizedNotificationOrchestrationStatus.skippedNoUser,
        reason: NotificationReconciliationReason.logoutCleanup,
        coalescedReasons: <NotificationReconciliationReason>{
          NotificationReconciliationReason.logoutCleanup,
        },
        diagnostics: <String>['no_active_user_scope'],
      );
    }
    return _executeCleanup(
      scope,
      reasons: const <NotificationReconciliationReason>{
        NotificationReconciliationReason.logoutCleanup,
      },
      capabilities: await _scheduleExecutor.getSchedulingCapabilities(),
    );
  }

  @override
  void onHabitCreated(String habitId) {
    _fireAndForget(NotificationReconciliationReason.habitCreated);
  }

  @override
  void onHabitUpdated(
    String habitId, {
    bool reminderChanged = false,
    bool archived = false,
  }) {
    if (archived) {
      _fireAndForget(NotificationReconciliationReason.habitArchived);
      return;
    }
    _fireAndForget(
      reminderChanged
          ? NotificationReconciliationReason.habitReminderChanged
          : NotificationReconciliationReason.habitUpdated,
    );
  }

  @override
  void onHabitDeleted(String habitId) {
    _fireAndForget(NotificationReconciliationReason.habitDeleted);
  }

  @override
  void onHabitCompleted(String habitId) {
    _fireAndForget(NotificationReconciliationReason.habitCompleted);
  }

  @override
  void onHabitUncompleted(String habitId) {
    _fireAndForget(NotificationReconciliationReason.habitUncompleted);
  }

  @override
  void onHabitSkipped(String habitId) {
    _fireAndForget(NotificationReconciliationReason.habitSkipped);
  }

  @override
  void onNotificationPreferencesChanged() {
    _fireAndForget(NotificationReconciliationReason.preferencesChanged);
  }

  Future<PersonalizedNotificationOrchestrationResult> _enqueue(
    NotificationScope scope,
    Set<NotificationReconciliationReason> reasons,
  ) async {
    final scopeKey = scope.scopeKey;
    final existing = _inFlightByScopeKey[scopeKey];
    if (existing != null) {
      _pendingReasonsByScopeKey
          .putIfAbsent(scopeKey, () => <NotificationReconciliationReason>{})
          .addAll(reasons);
      return PersonalizedNotificationOrchestrationResult(
        status: PersonalizedNotificationOrchestrationStatus.coalesced,
        reason: _selectPrimaryReason(reasons),
        coalescedReasons: reasons,
        scope: scope,
        diagnostics: const <String>['single_flight_coalesced'],
      );
    }

    late final Future<PersonalizedNotificationOrchestrationResult> future;
    future = _runSingleFlight(scope, initialReasons: reasons).whenComplete(() {
      if (identical(_inFlightByScopeKey[scopeKey], future)) {
        _inFlightByScopeKey.remove(scopeKey);
      }
    });
    _inFlightByScopeKey[scopeKey] = future;
    return future;
  }

  Future<PersonalizedNotificationOrchestrationResult> _runSingleFlight(
    NotificationScope scope, {
    required Set<NotificationReconciliationReason> initialReasons,
  }) async {
    var pendingReasons = <NotificationReconciliationReason>{...initialReasons};
    PersonalizedNotificationOrchestrationResult? lastResult;
    while (pendingReasons.isNotEmpty) {
      final scopeKey = scope.scopeKey;
      _observer.onRequested(scope, pendingReasons);
      final result = await _executeScopeRun(
        scope,
        reasons: pendingReasons,
      );
      _observer.onCompleted(result);
      lastResult = result;
      final queued = _pendingReasonsByScopeKey.remove(scopeKey);
      if (queued == null || queued.isEmpty) {
        return result;
      }
      pendingReasons = queued;
    }
    return lastResult ??
        PersonalizedNotificationOrchestrationResult(
          status: PersonalizedNotificationOrchestrationStatus.staleScope,
          reason: NotificationReconciliationReason.manualDebug,
          coalescedReasons: const <NotificationReconciliationReason>{},
          scope: scope,
          diagnostics: const <String>['single_flight_without_run'],
        );
  }

  Future<PersonalizedNotificationOrchestrationResult> _executeScopeRun(
    NotificationScope scope, {
    required Set<NotificationReconciliationReason> reasons,
  }) async {
    if (!await _isScopeActive(scope)) {
      return PersonalizedNotificationOrchestrationResult(
        status: PersonalizedNotificationOrchestrationStatus.staleScope,
        reason: _selectPrimaryReason(reasons),
        coalescedReasons: reasons,
        scope: scope,
        diagnostics: const <String>['scope_not_active_at_start'],
      );
    }

    final capabilities = await _scheduleExecutor.getSchedulingCapabilities();
    if (!await _isScopeActive(scope)) {
      return PersonalizedNotificationOrchestrationResult(
        status: PersonalizedNotificationOrchestrationStatus.staleScope,
        reason: _selectPrimaryReason(reasons),
        coalescedReasons: reasons,
        scope: scope,
        capabilities: capabilities,
        diagnostics: const <String>['scope_changed_after_capabilities'],
      );
    }

    final enabled = await _activationPolicy.isEnabledForScope(scope);
    if (!enabled) {
      final hadOwnedState = await _hasOwnedState(scope);
      if (!hadOwnedState) {
        return PersonalizedNotificationOrchestrationResult(
          status: PersonalizedNotificationOrchestrationStatus.skippedDisabled,
          reason: _selectPrimaryReason(reasons),
          coalescedReasons: reasons,
          scope: scope,
          capabilities: capabilities,
          diagnostics: const <String>['activation_policy_disabled'],
        );
      }
      return _executeCleanup(
        scope,
        reasons: reasons,
        capabilities: capabilities,
        statusWhenDone:
            PersonalizedNotificationOrchestrationStatus.skippedDisabled,
        diagnostics: const <String>['activation_policy_disabled_cleanup'],
      );
    }

    final preferences = await _preferencesResolver.load(scope);
    if (!await _isScopeActive(scope)) {
      return PersonalizedNotificationOrchestrationResult(
        status: PersonalizedNotificationOrchestrationStatus.staleScope,
        reason: _selectPrimaryReason(reasons),
        coalescedReasons: reasons,
        scope: scope,
        capabilities: capabilities,
        preferences: preferences,
        diagnostics: const <String>['scope_changed_after_preferences'],
      );
    }

    if (!preferences.masterEnabled ||
        !preferences.generalNotificationsEnabled) {
      final cleanup = await _executeCleanup(
        scope,
        reasons: reasons,
        capabilities: capabilities,
        preferences: preferences,
        statusWhenDone:
            PersonalizedNotificationOrchestrationStatus.skippedDisabled,
        diagnostics: const <String>['preferences_disabled_cleanup'],
      );
      return cleanup;
    }

    if (!_canProceedWithPermissions(capabilities)) {
      final hadOwnedState = await _hasOwnedState(scope);
      if (hadOwnedState && capabilities.canCancelExistingEntries) {
        return _executeCleanup(
          scope,
          reasons: reasons,
          capabilities: capabilities,
          preferences: preferences,
          statusWhenDone:
              PersonalizedNotificationOrchestrationStatus.skippedPermissions,
          diagnostics: const <String>['permissions_block_new_entries_cleanup'],
        );
      }
      return PersonalizedNotificationOrchestrationResult(
        status: PersonalizedNotificationOrchestrationStatus.skippedPermissions,
        reason: _selectPrimaryReason(reasons),
        coalescedReasons: reasons,
        scope: scope,
        capabilities: capabilities,
        preferences: preferences,
        diagnostics: const <String>['permissions_block_new_entries'],
      );
    }

    final plan = await _planBuilder.build(
      scope: scope,
      trigger: _mapPlanTrigger(_selectPrimaryReason(reasons)),
      preferences: preferences,
      schedulingCapabilities: capabilities,
    );
    if (!await _isScopeActive(scope)) {
      return PersonalizedNotificationOrchestrationResult(
        status: PersonalizedNotificationOrchestrationStatus.staleScope,
        reason: _selectPrimaryReason(reasons),
        coalescedReasons: reasons,
        scope: scope,
        capabilities: capabilities,
        preferences: preferences,
        diagnostics: const <String>['scope_changed_after_plan'],
      );
    }

    if (plan.status == DesiredNotificationPlanStatus.contextFailure ||
        plan.status == DesiredNotificationPlanStatus.notBuilt) {
      return PersonalizedNotificationOrchestrationResult(
        status: PersonalizedNotificationOrchestrationStatus.contextFailure,
        reason: _selectPrimaryReason(reasons),
        coalescedReasons: reasons,
        scope: scope,
        capabilities: capabilities,
        preferences: preferences,
        diagnostics: plan.diagnostics.notes,
      );
    }

    final reconciliationResult = await _coordinator.reconcileDesiredPlan(plan);
    _lastForegroundAtByScopeKey[scope.scopeKey] = _clock.localNow();
    return PersonalizedNotificationOrchestrationResult(
      status: PersonalizedNotificationOrchestrationStatus.executed,
      reason: _selectPrimaryReason(reasons),
      coalescedReasons: reasons,
      scope: scope,
      capabilities: capabilities,
      preferences: preferences,
      reconciliationResult: reconciliationResult,
      diagnostics: reconciliationResult.diagnostics,
    );
  }

  Future<PersonalizedNotificationOrchestrationResult> _executeCleanup(
    NotificationScope scope, {
    required Set<NotificationReconciliationReason> reasons,
    required NotificationSchedulingCapabilities capabilities,
    NotificationPreferences? preferences,
    PersonalizedNotificationOrchestrationStatus statusWhenDone =
        PersonalizedNotificationOrchestrationStatus.executed,
    List<String> diagnostics = const <String>[],
  }) async {
    if (!await _isScopeActive(scope) &&
        !reasons.contains(NotificationReconciliationReason.logoutCleanup)) {
      return PersonalizedNotificationOrchestrationResult(
        status: PersonalizedNotificationOrchestrationStatus.staleScope,
        reason: _selectPrimaryReason(reasons),
        coalescedReasons: reasons,
        scope: scope,
        capabilities: capabilities,
        preferences: preferences,
        diagnostics: const <String>['scope_not_active_before_cleanup'],
      );
    }

    final reconciliationResult =
        await _coordinator.cancelOwnedNotificationsForScope(scope);
    return PersonalizedNotificationOrchestrationResult(
      status: statusWhenDone,
      reason: _selectPrimaryReason(reasons),
      coalescedReasons: reasons,
      scope: scope,
      capabilities: capabilities,
      preferences: preferences,
      reconciliationResult: reconciliationResult,
      diagnostics:
          diagnostics.isEmpty ? reconciliationResult.diagnostics : diagnostics,
      cleanedUpWhileDisabled: true,
    );
  }

  Future<NotificationScope?> _resolveActiveScope() async {
    final activeScopeUserId =
        _normalized(_userStateStore.activeLocalScopeUserId);
    final storeUserId = _normalized(_userStateStore.userId);
    if (activeScopeUserId == null ||
        storeUserId == null ||
        activeScopeUserId != storeUserId) {
      return null;
    }
    final installId = await _installIdProvider.getOrCreateInstallId();
    return NotificationScope(
      userId: activeScopeUserId,
      scopeEpoch: _userStateStore.scopeEpoch,
      installId: installId,
      locale: _userStateStore.preferredLanguageCode ?? 'es',
    );
  }

  Future<bool> _isScopeActive(NotificationScope scope) async {
    final activeScopeUserId =
        _normalized(_userStateStore.activeLocalScopeUserId);
    final storeUserId = _normalized(_userStateStore.userId);
    return activeScopeUserId == scope.userId &&
        storeUserId == scope.userId &&
        _userStateStore.scopeEpoch == scope.scopeEpoch;
  }

  Future<bool> _hasOwnedState(NotificationScope scope) async {
    final manifest = await _scheduleStore.load(scope);
    if (manifest == null) {
      return false;
    }
    return manifest.entries.isNotEmpty || manifest.platformIdIndex.isNotEmpty;
  }

  Future<NotificationReconciliationReason> _resolveForegroundReason(
    NotificationScope scope,
  ) async {
    final manifest = await _scheduleStore.load(scope);
    if (manifest == null) {
      return NotificationReconciliationReason.foreground;
    }

    final currentDate = _clock.localDate();
    final currentTimezone = _clock.timezoneId();
    if (manifest.timezoneId.trim().isNotEmpty &&
        manifest.timezoneId != 'unknown' &&
        manifest.timezoneId != currentTimezone) {
      return NotificationReconciliationReason.timezoneChanged;
    }
    if (manifest.lastReconciledDate != currentDate) {
      return NotificationReconciliationReason.localDateChanged;
    }
    return NotificationReconciliationReason.foreground;
  }

  bool _shouldThrottleForeground(NotificationScope scope) {
    final lastRunAt = _lastForegroundAtByScopeKey[scope.scopeKey];
    if (lastRunAt == null) {
      return false;
    }
    return _clock.localNow().difference(lastRunAt) < _foregroundThrottle;
  }

  bool _canProceedWithPermissions(
    NotificationSchedulingCapabilities capabilities,
  ) {
    return capabilities.permissionStatus ==
            NotificationSystemPermissionStatus.authorized ||
        capabilities.permissionStatus ==
            NotificationSystemPermissionStatus.provisional;
  }

  NotificationTriggerReason _mapPlanTrigger(
    NotificationReconciliationReason reason,
  ) {
    switch (reason) {
      case NotificationReconciliationReason.login:
        return NotificationTriggerReason.postLogin;
      case NotificationReconciliationReason.bootstrapReady:
        return NotificationTriggerReason.appBootstrap;
      case NotificationReconciliationReason.foreground:
      case NotificationReconciliationReason.permissionStatusChanged:
        return NotificationTriggerReason.appResumed;
      case NotificationReconciliationReason.preferencesChanged:
        return NotificationTriggerReason.preferencesChanged;
      case NotificationReconciliationReason.habitCreated:
        return NotificationTriggerReason.habitCreated;
      case NotificationReconciliationReason.habitUpdated:
      case NotificationReconciliationReason.habitUncompleted:
        return NotificationTriggerReason.habitUpdated;
      case NotificationReconciliationReason.habitDeleted:
        return NotificationTriggerReason.habitDeleted;
      case NotificationReconciliationReason.habitArchived:
        return NotificationTriggerReason.habitArchived;
      case NotificationReconciliationReason.habitCompleted:
      case NotificationReconciliationReason.habitSkipped:
        return NotificationTriggerReason.habitUpdated;
      case NotificationReconciliationReason.habitReminderChanged:
        return NotificationTriggerReason.habitReminderToggleChanged;
      case NotificationReconciliationReason.timezoneChanged:
        return NotificationTriggerReason.timezoneChanged;
      case NotificationReconciliationReason.localDateChanged:
        return NotificationTriggerReason.dayBoundary;
      case NotificationReconciliationReason.manualDebug:
        return NotificationTriggerReason.manualRecovery;
      case NotificationReconciliationReason.logoutCleanup:
        return NotificationTriggerReason.logout;
    }
  }

  NotificationReconciliationReason _selectPrimaryReason(
    Set<NotificationReconciliationReason> reasons,
  ) {
    NotificationReconciliationReason? selected;
    var bestRank = 1 << 30;
    for (final reason in reasons) {
      final rank = _reasonRank(reason);
      if (rank < bestRank) {
        bestRank = rank;
        selected = reason;
      }
    }
    return selected ?? NotificationReconciliationReason.manualDebug;
  }

  int _reasonRank(NotificationReconciliationReason reason) {
    switch (reason) {
      case NotificationReconciliationReason.logoutCleanup:
        return 0;
      case NotificationReconciliationReason.bootstrapReady:
      case NotificationReconciliationReason.login:
        return 1;
      case NotificationReconciliationReason.timezoneChanged:
      case NotificationReconciliationReason.localDateChanged:
        return 2;
      case NotificationReconciliationReason.preferencesChanged:
      case NotificationReconciliationReason.permissionStatusChanged:
        return 3;
      case NotificationReconciliationReason.habitDeleted:
      case NotificationReconciliationReason.habitArchived:
      case NotificationReconciliationReason.habitReminderChanged:
        return 4;
      case NotificationReconciliationReason.habitCreated:
      case NotificationReconciliationReason.habitUpdated:
      case NotificationReconciliationReason.habitCompleted:
      case NotificationReconciliationReason.habitSkipped:
      case NotificationReconciliationReason.habitUncompleted:
        return 5;
      case NotificationReconciliationReason.foreground:
        return 6;
      case NotificationReconciliationReason.manualDebug:
        return 7;
    }
  }

  void _fireAndForget(NotificationReconciliationReason reason) {
    unawaited(
      () async {
        try {
          await reconcilePersonalizedNotificationsNow(reason: reason);
        } catch (_) {}
      }(),
    );
  }

  String? _normalized(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
