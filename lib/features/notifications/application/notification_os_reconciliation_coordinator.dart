import '../domain/desired_notification.dart';
import '../domain/personalized_notification_models.dart';
import '../domain/personalized_notification_ports.dart';
import 'notification_reconciliation_models.dart';
import 'notification_reconciler.dart';

class NotificationOsReconciliationCoordinator {
  NotificationOsReconciliationCoordinator({
    required NotificationScheduleStore scheduleStore,
    required NotificationHistoryStore historyStore,
    required NotificationScheduleExecutor executor,
    NotificationReconciler? reconciler,
    DateTime Function()? now,
  })  : _scheduleStore = scheduleStore,
        _historyStore = historyStore,
        _executor = executor,
        _reconciler = reconciler ?? const NotificationReconciler(),
        _now = now ?? DateTime.now;

  final NotificationScheduleStore _scheduleStore;
  final NotificationHistoryStore _historyStore;
  final NotificationScheduleExecutor _executor;
  final NotificationReconciler _reconciler;
  final DateTime Function() _now;

  Future<NotificationReconciliationResult> reconcileDesiredPlan(
    DesiredNotificationPlan desiredPlan,
  ) async {
    final scope = desiredPlan.scope;
    if (scope == null) {
      final emptyManifest = _emptyManifest(
        NotificationScope(
          userId: 'unknown',
          scopeEpoch: 0,
          installId: 'unknown',
          locale: 'es',
        ),
        timezoneId: 'unknown',
      );
      return NotificationReconciliationResult(
        operationsPlanned: const <NotificationReconciliationOperation>[],
        operationsSucceeded: const <NotificationExecutorOperationResult>[],
        operationsFailed: const <NotificationExecutorOperationResult>[],
        nextManifest: emptyManifest,
        diagnostics: const <String>['desired_plan_has_no_scope'],
      );
    }

    final manifest = await _scheduleStore.load(scope) ??
        _emptyManifest(
          scope,
          timezoneId: _manifestTimezone(desiredPlan),
        );
    final osPending = await _executor.pendingNotifications();
    final plan = _reconciler.reconcile(
      desiredPlan: desiredPlan,
      manifest: manifest,
      osPendingNotifications: osPending,
    );
    final result = await _reconciler.execute(
      plan: plan,
      manifest: manifest,
      executor: _executor,
      reconciledAt: _now(),
      timezoneId: _manifestTimezone(desiredPlan),
    );
    await _scheduleStore.save(scope, result.nextManifest);
    await _recordHistory(result, plan);
    return result;
  }

  Future<NotificationReconciliationResult> cancelOwnedNotificationsForScope(
    NotificationScope scope,
  ) {
    return reconcileDesiredPlan(
      DesiredNotificationPlan.ready(
        scope: scope,
        generatedAt: _now(),
        horizonStart: _now(),
        horizonEnd: _now().add(const Duration(hours: 24)),
        notifications: const <DesiredNotification>[],
        opportunities: const <NotificationOpportunity>[],
        diagnostics: DesiredNotificationPlanDiagnostics(
          notes: const <String>['explicit_scope_cleanup'],
          selectedTemplateIds: const <String>[],
          suppressedOpportunityIds: const <String>[],
          usedWakeUpFallback: false,
          habitReminderLoadUnavailable: false,
        ),
      ),
    );
  }

  NotificationScheduleManifest _emptyManifest(
    NotificationScope scope, {
    required String timezoneId,
  }) {
    final now = _now();
    return NotificationScheduleManifest(
      scope: scope,
      scopeEpochAtPlanTime: scope.scopeEpoch,
      timezoneId: timezoneId,
      lastReconciledAt: now.toUtc(),
      lastReconciledDate: DateTime(now.year, now.month, now.day),
      entries: const <NotificationManifestEntry>[],
      platformIdIndex: const <String, int>{},
    );
  }

  String _manifestTimezone(DesiredNotificationPlan plan) {
    if (plan.notifications.isNotEmpty) {
      return plan.notifications.first.timezoneIdAtPlanTime;
    }
    return 'unknown';
  }

  Future<void> _recordHistory(
    NotificationReconciliationResult result,
    NotificationReconciliationPlan plan,
  ) async {
    final scope = plan.scope;
    if (scope == null) {
      return;
    }
    var history =
        await _historyStore.load(scope) ?? NotificationMessageHistorySnapshot();
    final operationsById = <String, NotificationReconciliationOperation>{
      for (final operation in plan.operations)
        operation.logicalNotificationId: operation,
    };
    for (final success in result.operationsSucceeded) {
      if (!success.scheduleAccepted) {
        continue;
      }
      if (success.type != NotificationReconciliationOperationType.create &&
          success.type != NotificationReconciliationOperationType.replace) {
        continue;
      }
      final desired = operationsById[success.logicalNotificationId]?.desired;
      if (desired == null) {
        continue;
      }
      final record = NotificationDeliveryRecord(
        notificationKey: desired.logicalNotificationId,
        userId: scope.userId,
        templateId: desired.templateId,
        kind: desired.kind,
        scheduledAt: _now().toUtc(),
        categoryTag: desired.categoryTag,
      );
      history = history.copyWith(
        recentDeliveries: <NotificationDeliveryRecord>[
          record,
          ...history.recentDeliveries,
        ],
        lastSelectedAtByTemplateId: <String, DateTime>{
          ...history.lastSelectedAtByTemplateId,
          record.templateId: record.scheduledAt,
        },
        lastSelectedAtByKind: <String, DateTime>{
          ...history.lastSelectedAtByKind,
          record.kind.name: record.scheduledAt,
        },
        lastSelectedAtByCategoryTag: <String, DateTime>{
          ...history.lastSelectedAtByCategoryTag,
          if (record.categoryTag != null)
            record.categoryTag!: record.scheduledAt,
        },
      );
    }
    await _historyStore.save(scope, history);
  }
}
