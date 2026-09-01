import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';

void main() {
  final scope = NotificationScope(
    userId: 'user-a',
    scopeEpoch: 1,
    installId: 'install-a',
    locale: 'es',
  );

  DesiredNotification buildDesired({
    String fingerprint = 'fp-1',
    NotificationKind kind = NotificationKind.generalProgressNudge,
    NotificationFamily family = NotificationFamily.personalizedGeneral,
    String? logicalId,
    String categoryTag = 'encouragement',
  }) {
    final resolvedLogicalId = logicalId ??
        'rutio:v2:general:generalProgressNudge:scope:today:morning';
    return DesiredNotification(
      logicalNotificationId: resolvedLogicalId,
      platformId: 20010,
      kind: kind,
      family: family,
      templateId: 'template-1',
      renderedTitle: 'Rutio',
      renderedBody: 'Body',
      intendedLocalDateTime: DateTime(2026, 8, 29, 9, 30),
      timezoneSemantics: NotificationTimezoneSemantics.localClockTime,
      timezoneIdAtPlanTime: 'Europe/Madrid',
      payload: NotificationPayloadV2(
        schema: 2,
        family: family,
        kind: kind,
        logicalId: resolvedLogicalId,
        templateId: 'template-1',
        scopeHash: scope.scopeHash,
        scopeEpoch: scope.scopeEpoch,
        categoryTag: categoryTag,
      ),
      fingerprint: fingerprint,
      scope: scope,
      categoryTag: categoryTag,
      opportunityId: 'morning',
      planVersion: 1,
      metadata: const <String, String>{},
    );
  }

  DesiredNotificationPlan buildPlan(List<DesiredNotification> notifications) {
    return DesiredNotificationPlan.ready(
      scope: scope,
      generatedAt: DateTime(2026, 8, 29, 9, 0),
      horizonStart: DateTime(2026, 8, 29, 9, 0),
      horizonEnd: DateTime(2026, 8, 30, 9, 0),
      notifications: notifications,
      opportunities: const <NotificationOpportunity>[],
      diagnostics: DesiredNotificationPlanDiagnostics(
        usedWakeUpFallback: false,
        habitReminderLoadUnavailable: false,
      ),
    );
  }

  test('create -> keep -> recreate flow updates manifest and history correctly',
      () async {
    final scheduleStore = _InMemoryScheduleStore();
    final historyStore = _InMemoryHistoryStore();
    final executor = InMemoryNotificationScheduleExecutorWithPending();
    final coordinator = NotificationOsReconciliationCoordinator(
      scheduleStore: scheduleStore,
      historyStore: historyStore,
      executor: executor,
      now: () => DateTime(2026, 8, 29, 9, 0),
    );
    final desired = buildDesired();

    final first = await coordinator.reconcileDesiredPlan(
      buildPlan(<DesiredNotification>[desired]),
    );
    final second = await coordinator.reconcileDesiredPlan(
      buildPlan(<DesiredNotification>[desired]),
    );
    executor.pending.clear();
    final third = await coordinator.reconcileDesiredPlan(
      buildPlan(<DesiredNotification>[desired.copyWith(fingerprint: 'fp-2')]),
    );

    expect(
      first.operationsSucceeded.any(
        (item) => item.type == NotificationReconciliationOperationType.create,
      ),
      isTrue,
    );
    expect(
      second.operationsPlanned.single.type,
      NotificationReconciliationOperationType.keep,
    );
    expect(
      third.operationsSucceeded.any(
        (item) => item.type == NotificationReconciliationOperationType.create,
      ),
      isTrue,
    );
    expect((await historyStore.load(scope))?.recentDeliveries.length, 2);
    expect((await scheduleStore.load(scope))?.entries.length, 1);
  });

  test('cancels a stale diary journal notification and is idempotent',
      () async {
    final scheduleStore = _InMemoryScheduleStore();
    final historyStore = _InMemoryHistoryStore();
    final executor = InMemoryNotificationScheduleExecutorWithPending();
    final coordinator = NotificationOsReconciliationCoordinator(
      scheduleStore: scheduleStore,
      historyStore: historyStore,
      executor: executor,
      now: () => DateTime(2026, 8, 29, 20),
    );
    final journal = buildDesired(
      kind: NotificationKind.journalNudge,
      family: NotificationFamily.diary,
      logicalId: 'rutio:v2:diary:journalNudge:scope:milestone:event:evening',
      categoryTag: 'journalNudge',
    );

    await coordinator.reconcileDesiredPlan(
      buildPlan(<DesiredNotification>[journal]),
    );
    final cancelled = await coordinator.reconcileDesiredPlan(buildPlan([]));
    final repeated = await coordinator.reconcileDesiredPlan(buildPlan([]));

    expect(
      cancelled.operationsSucceeded.any(
        (item) => item.type == NotificationReconciliationOperationType.cancel,
      ),
      isTrue,
    );
    expect(executor.pending, isEmpty);
    expect((await scheduleStore.load(scope))?.entries, isEmpty);
    expect(repeated.operationsPlanned, isEmpty);
  });
}

class _InMemoryScheduleStore implements NotificationScheduleStore {
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

class _InMemoryHistoryStore implements NotificationHistoryStore {
  final Map<String, NotificationMessageHistorySnapshot> _history =
      <String, NotificationMessageHistorySnapshot>{};

  @override
  Future<void> clear(NotificationScope scope) async {
    _history.remove(scope.scopeKey);
  }

  @override
  Future<NotificationMessageHistorySnapshot?> load(
      NotificationScope scope) async {
    return _history[scope.scopeKey];
  }

  @override
  Future<void> save(
    NotificationScope scope,
    NotificationMessageHistorySnapshot history,
  ) async {
    _history[scope.scopeKey] = history;
  }
}

class InMemoryNotificationScheduleExecutorWithPending
    extends InMemoryNotificationScheduleExecutor {
  final List<NativePendingNotification> pending = <NativePendingNotification>[];

  @override
  Future<NotificationNativeExecutionResult> create(
    DesiredNotification notification,
  ) async {
    final result = await super.create(notification);
    if (result.isSuccess) {
      pending.add(
        NativePendingNotification(
          platformId: notification.platformId,
          title: notification.renderedTitle,
          body: notification.renderedBody,
          payload: notification.payload.encode(),
          logicalNotificationId: notification.logicalNotificationId,
          templateId: notification.templateId,
          scopeHash: notification.scope.scopeHash,
          scopeEpoch: notification.scope.scopeEpoch,
          family: notification.family,
          kind: notification.kind,
          isOwnedV2: true,
        ),
      );
    }
    return result;
  }

  @override
  Future<List<NativePendingNotification>> pendingNotifications() async {
    return List<NativePendingNotification>.from(pending);
  }

  @override
  Future<NotificationNativeExecutionResult> cancel(
    NotificationManifestEntry existing,
  ) async {
    pending.removeWhere((item) => item.platformId == existing.platformId);
    return NotificationNativeExecutionResult.success(
      stateChange: NotificationExecutionStateChange.cancelled,
      platformId: existing.platformId,
    );
  }

  @override
  Future<NotificationNativeExecutionResult> cancelPending(
    NativePendingNotification pendingNotification,
  ) async {
    pending.removeWhere(
      (item) => item.platformId == pendingNotification.platformId,
    );
    return NotificationNativeExecutionResult.success(
      stateChange: NotificationExecutionStateChange.cancelled,
      platformId: pendingNotification.platformId,
    );
  }
}
