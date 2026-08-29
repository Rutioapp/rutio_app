import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/notifications/application/notification_context_builder.dart';
import 'package:rutio/features/notifications/application/notification_os_reconciliation_coordinator.dart';
import 'package:rutio/features/notifications/application/notification_reconciliation_models.dart';
import 'package:rutio/features/notifications/application/personalized_notification_orchestrator.dart';
import 'package:rutio/features/notifications/application/personalized_notification_plan_builder.dart';
import 'package:rutio/features/notifications/domain/desired_notification.dart';
import 'package:rutio/features/notifications/domain/notification_native_models.dart';
import 'package:rutio/features/notifications/domain/notification_template_content.dart';
import 'package:rutio/features/notifications/domain/notification_selection_models.dart';
import 'package:rutio/features/notifications/domain/personalized_notification_models.dart';
import 'package:rutio/features/notifications/domain/personalized_notification_ports.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersonalizedNotificationOrchestrator', () {
    test('defaults to OFF and skips orchestration without owned state',
        () async {
      final fixture = await _createFixture(
        activationPolicy: const FixedPersonalizedNotificationsActivationPolicy(
          false,
        ),
      );

      final result =
          await fixture.orchestrator.reconcilePersonalizedNotificationsNow();

      expect(result.status,
          PersonalizedNotificationOrchestrationStatus.skippedDisabled);
      expect(fixture.coordinator.reconcileCalls, 0);
      expect(fixture.coordinator.cleanupCalls, 0);
    });

    test('cleanupCurrentScopeForLogout cancels owned notifications', () async {
      final fixture = await _createFixture();

      final result = await fixture.orchestrator.cleanupCurrentScopeForLogout();

      expect(
          result.status, PersonalizedNotificationOrchestrationStatus.executed);
      expect(fixture.coordinator.cleanupCalls, 1);
      expect(fixture.coordinator.reconcileCalls, 0);
    });

    test('reconcileForBootstrapReady executes when enabled', () async {
      final fixture = await _createFixture();

      final result = await fixture.orchestrator.reconcileForBootstrapReady();

      expect(
        result.status,
        PersonalizedNotificationOrchestrationStatus.executed,
      );
      expect(fixture.coordinator.reconcileCalls, 1);
    });
  });
}

class _OrchestratorFixture {
  _OrchestratorFixture({
    required this.store,
    required this.orchestrator,
    required this.planBuilder,
    required this.coordinator,
  });

  final UserStateStore store;
  final PersonalizedNotificationOrchestrator orchestrator;
  final PersonalizedNotificationPlanBuilder planBuilder;
  final _FakeCoordinator coordinator;
}

Future<_OrchestratorFixture> _createFixture({
  PersonalizedNotificationsActivationPolicy activationPolicy =
      const FixedPersonalizedNotificationsActivationPolicy(true),
  PersonalizedNotificationPlanBuilder? planBuilder,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('user-123');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState());
  await store.switchLocalScope(
    userId: 'user-123',
    forceReload: true,
  );

  final buildPlan = planBuilder ?? _FixedPlanBuilder();
  final coordinator = _FakeCoordinator();
  final orchestrator = PersonalizedNotificationOrchestrator(
    userStateStore: store,
    installIdProvider: _FixedInstallIdProvider(),
    preferencesResolver: StoreBackedPersonalizedNotificationPreferencesResolver(
      store: _MemoryNotificationPreferencesStore(),
      userStateStore: store,
    ),
    scheduleStore: _MemoryNotificationScheduleStore(),
    scheduleExecutor: _FakeScheduleExecutor(),
    planBuilder: buildPlan,
    coordinator: coordinator,
    activationPolicy: activationPolicy,
  );

  return _OrchestratorFixture(
    store: store,
    orchestrator: orchestrator,
    planBuilder: buildPlan,
    coordinator: coordinator,
  );
}

Map<String, dynamic> _baseState() {
  final today = DateTime(2026, 8, 29);
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'user-123',
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': today.toUtc().toIso8601String(),
        'activeViewDateKey': '2026-08-29',
        'diaryRewardAppliedDateKeys': <dynamic>[],
      },
      'settings': <String, dynamic>{
        'locale': <String, dynamic>{'languageCode': 'es'},
        'notifications': <String, dynamic>{
          'enabled': true,
          'habitReminders': true,
        },
      },
      'progression': <String, dynamic>{'level': 1, 'xp': 0, 'prestige': 0},
      'wallet': <String, dynamic>{'coins': 0},
      'inventory': <String, dynamic>{'items': <dynamic>[]},
      'profile': <String, dynamic>{
        'equipped': <String, dynamic>{
          'avatar_skin': null,
          'aura': null,
          'badge': null,
          'title': null,
          'animation': null,
        },
        'badges': <String, dynamic>{'owned': <dynamic>[], 'shown': null},
        'achievements': <String, dynamic>{
          'unlocked': <dynamic>[],
          'featured': <dynamic>[],
          'rewardAppliedAchievementIds': <dynamic>[],
          'progress': <String, dynamic>{},
        },
      },
      'activeHabits': <dynamic>[],
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitLogs': <String, dynamic>{},
      },
      'daily': <String, dynamic>{
        'habitsCompletedToday': <String, dynamic>{},
      },
    },
  };
}

class _FixedInstallIdProvider implements NotificationInstallIdProvider {
  @override
  Future<String> getOrCreateInstallId() async => 'install-1';
}

class _MemoryNotificationPreferencesStore
    implements NotificationPreferencesStore {
  final Map<String, NotificationPreferences> _values =
      <String, NotificationPreferences>{};

  @override
  Future<NotificationPreferences> load(NotificationScope scope) async {
    return _values[scope.scopeKey] ?? NotificationPreferences.defaults();
  }

  @override
  Future<NotificationPreferences> update(
    NotificationScope scope,
    NotificationPreferences Function(NotificationPreferences current) update,
  ) async {
    final next = update(await load(scope));
    _values[scope.scopeKey] = next;
    return next;
  }

  @override
  Future<void> reset(NotificationScope scope) async {
    _values.remove(scope.scopeKey);
  }

  @override
  Future<void> save(
    NotificationScope scope,
    NotificationPreferences preferences,
  ) async {
    _values[scope.scopeKey] = preferences;
  }
}

class _MemoryNotificationScheduleStore implements NotificationScheduleStore {
  final Map<String, NotificationScheduleManifest> _manifests =
      <String, NotificationScheduleManifest>{};

  @override
  Future<void> clear(NotificationScope scope) async {
    _manifests.remove(scope.scopeKey);
  }

  @override
  Future<NotificationScheduleManifest?> load(NotificationScope scope) async {
    return _manifests[scope.scopeKey];
  }

  @override
  Future<void> save(
    NotificationScope scope,
    NotificationScheduleManifest manifest,
  ) async {
    _manifests[scope.scopeKey] = manifest;
  }
}

class _FakeScheduleExecutor implements NotificationScheduleExecutor {
  @override
  Future<NotificationNativeExecutionResult> adopt(
    NativePendingNotification pending,
    DesiredNotification desired,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<NotificationNativeExecutionResult> cancel(
    NotificationManifestEntry existing,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<NotificationNativeExecutionResult> cancelPending(
    NativePendingNotification pending,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<NotificationNativeExecutionResult> create(
    DesiredNotification notification,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<NotificationSchedulingCapabilities> getSchedulingCapabilities() async {
    return const NotificationSchedulingCapabilities(
      permissionStatus: NotificationSystemPermissionStatus.authorized,
      canScheduleNewEntries: true,
      canCancelExistingEntries: true,
    );
  }

  @override
  Future<List<NativePendingNotification>> pendingNotifications() async {
    return const <NativePendingNotification>[];
  }

  @override
  Future<NotificationNativeExecutionResult> replace(
    NotificationManifestEntry existing,
    DesiredNotification replacement,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<NotificationNativeExecutionResult> dropManifestEntry(
    NotificationManifestEntry existing,
  ) async {
    throw UnimplementedError();
  }
}

class _FakeCoordinator extends NotificationOsReconciliationCoordinator {
  _FakeCoordinator()
      : super(
          scheduleStore: _MemoryNotificationScheduleStore(),
          historyStore: _MemoryNotificationHistoryStore(),
          executor: _FakeScheduleExecutor(),
          now: () => DateTime(2026, 8, 29, 9, 0),
        );

  int reconcileCalls = 0;
  int cleanupCalls = 0;

  @override
  Future<NotificationReconciliationResult> reconcileDesiredPlan(
    DesiredNotificationPlan desiredPlan,
  ) async {
    reconcileCalls += 1;
    return _resultForScope(desiredPlan.scope!);
  }

  @override
  Future<NotificationReconciliationResult> cancelOwnedNotificationsForScope(
    NotificationScope scope,
  ) async {
    cleanupCalls += 1;
    return _resultForScope(scope);
  }

  NotificationReconciliationResult _resultForScope(NotificationScope scope) {
    final now = DateTime(2026, 8, 29, 9, 0);
    return NotificationReconciliationResult(
      operationsPlanned: const <NotificationReconciliationOperation>[],
      operationsSucceeded: const <NotificationExecutorOperationResult>[],
      operationsFailed: const <NotificationExecutorOperationResult>[],
      nextManifest: NotificationScheduleManifest(
        scope: scope,
        scopeEpochAtPlanTime: scope.scopeEpoch,
        timezoneId: 'Europe/Madrid',
        lastReconciledAt: now.toUtc(),
        lastReconciledDate: DateTime(now.year, now.month, now.day),
        entries: const <NotificationManifestEntry>[],
        platformIdIndex: const <String, int>{},
      ),
      diagnostics: const <String>[],
    );
  }
}

class _MemoryNotificationHistoryStore implements NotificationHistoryStore {
  final Map<String, NotificationMessageHistorySnapshot> _values =
      <String, NotificationMessageHistorySnapshot>{};

  @override
  Future<void> clear(NotificationScope scope) async {
    _values.remove(scope.scopeKey);
  }

  @override
  Future<NotificationMessageHistorySnapshot?> load(
      NotificationScope scope) async {
    return _values[scope.scopeKey];
  }

  @override
  Future<void> save(
    NotificationScope scope,
    NotificationMessageHistorySnapshot history,
  ) async {
    _values[scope.scopeKey] = history;
  }
}

class _FixedContextBuilder implements NotificationPlanningContextBuilder {
  const _FixedContextBuilder();

  @override
  Future<NotificationContextBuildResult> buildForScope({
    required NotificationScope scope,
    required NotificationTriggerReason trigger,
    NotificationSchedulingCapabilities schedulingCapabilities =
        NotificationSchedulingCapabilities.unsupported,
  }) async {
    return NotificationContextBuildResult.success(
      quality: NotificationContextQuality.rich,
      diagnostics: const NotificationContextDiagnostics(
        startedScopeKey: 'scope',
        completedScopeKey: 'scope',
        hasDisplayName: true,
        hasReliableProgress: true,
        hasReliableStreak: true,
        hasReliableInactivity: false,
        hasDiarySignal: false,
        hasMoodSignal: false,
        hasWakeUpTime: false,
        missingSignals: <String>[],
      ),
      snapshot: NotificationContextSnapshot(
        scope: scope,
        now: DateTime(2026, 8, 29, 9, 0),
        timezoneId: 'Europe/Madrid',
        calendarDate: DateTime(2026, 8, 29),
        pendingHabitsToday: const <String>[],
        completedHabitsToday: const <String>[],
        schedulingCapabilities: schedulingCapabilities,
      ),
      selectionContext: NotificationSelectionContext.fromSnapshot(
        NotificationContextSnapshot(
          scope: scope,
          now: DateTime(2026, 8, 29, 9, 0),
          timezoneId: 'Europe/Madrid',
          calendarDate: DateTime(2026, 8, 29),
          pendingHabitsToday: const <String>[],
          completedHabitsToday: const <String>[],
          schedulingCapabilities: schedulingCapabilities,
        ),
        displayName: 'Nora',
        habitName: 'Leer',
        weekdayLabel: 'sabado',
        timeOfDayLabel: '09:00',
      ),
    );
  }
}

class _FixedTemplateCatalog implements NotificationTemplateCatalog {
  const _FixedTemplateCatalog();

  @override
  Future<NotificationTemplateDescriptor?> getById(String templateId) async =>
      null;

  @override
  Future<List<NotificationTemplateDescriptor>> listAll() async =>
      const <NotificationTemplateDescriptor>[];

  @override
  Future<List<NotificationTemplateDescriptor>> listByCategory(
    NotificationTemplateCategory category,
  ) async =>
      const <NotificationTemplateDescriptor>[];

  @override
  Future<List<NotificationTemplateDescriptor>> listByKind(
    NotificationKind kind,
  ) async =>
      const <NotificationTemplateDescriptor>[];
}

class _FixedPlatformIdProvider implements NotificationPlatformIdProvider {
  @override
  Future<int> getOrAllocate(
    NotificationScope scope, {
    required NotificationFamily family,
    required String notificationKey,
    String timezoneId = '',
  }) async {
    return 1;
  }
}

class _FixedPlanBuilder extends PersonalizedNotificationPlanBuilder {
  _FixedPlanBuilder()
      : super(
          contextBuilder: const _FixedContextBuilder(),
          templateCatalog: const _FixedTemplateCatalog(),
          platformIdProvider: _FixedPlatformIdProvider(),
        );

  @override
  Future<DesiredNotificationPlan> build({
    required NotificationScope scope,
    required NotificationTriggerReason trigger,
    required NotificationPreferences preferences,
    NotificationSchedulingCapabilities schedulingCapabilities =
        NotificationSchedulingCapabilities.unsupported,
  }) async {
    return _readyPlan(scope);
  }
}

DesiredNotificationPlan _readyPlan(NotificationScope scope) {
  return DesiredNotificationPlan.ready(
    scope: scope,
    generatedAt: DateTime(2026, 8, 29, 9, 0),
    horizonStart: DateTime(2026, 8, 29, 9, 0),
    horizonEnd: DateTime(2026, 8, 30, 9, 0),
    notifications: const <DesiredNotification>[],
    opportunities: const <NotificationOpportunity>[],
    diagnostics: DesiredNotificationPlanDiagnostics(
      usedWakeUpFallback: false,
      habitReminderLoadUnavailable: false,
    ),
  );
}
