import '../domain/desired_notification.dart';
import '../domain/personalized_notification_models.dart';
import '../domain/personalized_notification_ports.dart';
import 'notification_reconciliation_models.dart';

class NotificationReconciler {
  const NotificationReconciler();

  NotificationReconciliationPlan reconcile({
    required DesiredNotificationPlan desiredPlan,
    required NotificationScheduleManifest manifest,
  }) {
    if (desiredPlan.scope == null) {
      return NotificationReconciliationPlan(
        status: NotificationReconciliationPlanStatus.blocked,
        scope: null,
        desiredPlanStatus: desiredPlan.status,
        operations: const <NotificationReconciliationOperation>[],
        diagnostics: <String>[
          'desired_plan_has_no_scope',
        ],
      );
    }
    if (desiredPlan.scope != manifest.scope) {
      return NotificationReconciliationPlan(
        status: NotificationReconciliationPlanStatus.scopeMismatch,
        scope: desiredPlan.scope,
        desiredPlanStatus: desiredPlan.status,
        operations: const <NotificationReconciliationOperation>[],
        diagnostics: <String>[
          'scope_mismatch_fail_closed',
        ],
      );
    }
    if (desiredPlan.status == DesiredNotificationPlanStatus.contextFailure ||
        desiredPlan.status == DesiredNotificationPlanStatus.notBuilt) {
      return NotificationReconciliationPlan(
        status: NotificationReconciliationPlanStatus.blocked,
        scope: desiredPlan.scope,
        desiredPlanStatus: desiredPlan.status,
        operations: const <NotificationReconciliationOperation>[],
        diagnostics: <String>[
          'desired_plan_not_executable',
        ],
      );
    }

    final desiredById = <String, DesiredNotification>{
      for (final notification in desiredPlan.notifications)
        notification.logicalNotificationId: notification,
    };
    final existingById = <String, NotificationManifestEntry>{
      for (final entry in manifest.entries) entry.notificationKey: entry,
    };
    final operations = <NotificationReconciliationOperation>[];

    for (final desired in desiredPlan.notifications) {
      final existing = existingById[desired.logicalNotificationId];
      if (existing == null) {
        operations.add(
          NotificationReconciliationOperation(
            type: NotificationReconciliationOperationType.create,
            logicalNotificationId: desired.logicalNotificationId,
            platformId: desired.platformId,
            desired: desired,
            reason: 'missing_from_manifest',
          ),
        );
        continue;
      }
      if (_matches(existing, desired)) {
        operations.add(
          NotificationReconciliationOperation(
            type: NotificationReconciliationOperationType.keep,
            logicalNotificationId: desired.logicalNotificationId,
            platformId: desired.platformId,
            desired: desired,
            existing: existing,
            reason: 'fingerprint_unchanged',
          ),
        );
      } else {
        operations.add(
          NotificationReconciliationOperation(
            type: NotificationReconciliationOperationType.replace,
            logicalNotificationId: desired.logicalNotificationId,
            platformId: desired.platformId,
            desired: desired,
            existing: existing,
            reason: 'fingerprint_changed',
          ),
        );
      }
    }

    for (final entry in manifest.entries) {
      if (!entry.notificationKey.startsWith('rutio:v2:')) {
        continue;
      }
      if (desiredById.containsKey(entry.notificationKey)) {
        continue;
      }
      if (entry.family != NotificationFamily.personalizedGeneral) {
        continue;
      }
      operations.add(
        NotificationReconciliationOperation(
          type: NotificationReconciliationOperationType.cancel,
          logicalNotificationId: entry.notificationKey,
          platformId: entry.platformId,
          existing: entry,
          reason: 'absent_from_desired',
        ),
      );
    }

    operations.sort((left, right) {
      final leftRank = _operationRank(left.type);
      final rightRank = _operationRank(right.type);
      if (leftRank != rightRank) {
        return leftRank.compareTo(rightRank);
      }
      return left.logicalNotificationId.compareTo(right.logicalNotificationId);
    });

    return NotificationReconciliationPlan(
      status: NotificationReconciliationPlanStatus.ready,
      scope: desiredPlan.scope,
      desiredPlanStatus: desiredPlan.status,
      operations: operations,
      diagnostics: const <String>[],
    );
  }

  Future<NotificationReconciliationResult> execute({
    required NotificationReconciliationPlan plan,
    required NotificationScheduleManifest manifest,
    required NotificationScheduleExecutor executor,
    required DateTime reconciledAt,
    String? timezoneId,
  }) async {
    final succeeded = <NotificationExecutorOperationResult>[];
    final failed = <NotificationExecutorOperationResult>[];

    for (final operation in plan.operations) {
      switch (operation.type) {
        case NotificationReconciliationOperationType.keep:
          continue;
        case NotificationReconciliationOperationType.create:
          try {
            await executor.create(operation.desired!);
            succeeded.add(
              NotificationExecutorOperationResult(
                type: operation.type,
                logicalNotificationId: operation.logicalNotificationId,
                success: true,
              ),
            );
          } catch (error) {
            failed.add(
              NotificationExecutorOperationResult(
                type: operation.type,
                logicalNotificationId: operation.logicalNotificationId,
                success: false,
                error: '$error',
              ),
            );
          }
          break;
        case NotificationReconciliationOperationType.replace:
          try {
            await executor.replace(
              operation.existing!,
              operation.desired!,
            );
            succeeded.add(
              NotificationExecutorOperationResult(
                type: operation.type,
                logicalNotificationId: operation.logicalNotificationId,
                success: true,
              ),
            );
          } catch (error) {
            failed.add(
              NotificationExecutorOperationResult(
                type: operation.type,
                logicalNotificationId: operation.logicalNotificationId,
                success: false,
                error: '$error',
              ),
            );
          }
          break;
        case NotificationReconciliationOperationType.cancel:
          try {
            await executor.cancel(operation.existing!);
            succeeded.add(
              NotificationExecutorOperationResult(
                type: operation.type,
                logicalNotificationId: operation.logicalNotificationId,
                success: true,
              ),
            );
          } catch (error) {
            failed.add(
              NotificationExecutorOperationResult(
                type: operation.type,
                logicalNotificationId: operation.logicalNotificationId,
                success: false,
                error: '$error',
              ),
            );
          }
          break;
      }
    }

    return NotificationReconciliationResult(
      operationsPlanned: plan.operations,
      operationsSucceeded: succeeded,
      operationsFailed: failed,
      nextManifest: projectNextManifest(
        manifest: manifest,
        plan: plan,
        succeeded: succeeded,
        reconciledAt: reconciledAt,
        timezoneId: timezoneId ?? manifest.timezoneId,
      ),
      diagnostics: failed.isEmpty
          ? const <String>[]
          : <String>['partial_failure_detected'],
    );
  }

  NotificationScheduleManifest projectNextManifest({
    required NotificationScheduleManifest manifest,
    required NotificationReconciliationPlan plan,
    required List<NotificationExecutorOperationResult> succeeded,
    required DateTime reconciledAt,
    required String timezoneId,
  }) {
    final successfulIds = succeeded
        .where((result) => result.success)
        .map((result) => result.logicalNotificationId)
        .toSet();
    final nextById = <String, NotificationManifestEntry>{
      for (final entry in manifest.entries) entry.notificationKey: entry,
    };

    for (final operation in plan.operations) {
      if (operation.type == NotificationReconciliationOperationType.keep) {
        continue;
      }
      if (!successfulIds.contains(operation.logicalNotificationId)) {
        continue;
      }
      switch (operation.type) {
        case NotificationReconciliationOperationType.keep:
          break;
        case NotificationReconciliationOperationType.create:
        case NotificationReconciliationOperationType.replace:
          final desired = operation.desired!;
          nextById[operation.logicalNotificationId] = NotificationManifestEntry(
            notificationKey: desired.logicalNotificationId,
            platformId: desired.platformId,
            family: desired.family,
            kind: desired.kind,
            payload: desired.payload.encode(),
            templateId: desired.templateId,
            scheduledAt: desired.intendedLocalDateTime.toUtc(),
            planVersion: desired.planVersion,
            sourceFingerprint: desired.fingerprint,
          );
          break;
        case NotificationReconciliationOperationType.cancel:
          nextById.remove(operation.logicalNotificationId);
          break;
      }
    }

    return manifest.copyWith(
      timezoneId: timezoneId,
      lastReconciledAt: reconciledAt.toUtc(),
      lastReconciledDate: DateTime(
        reconciledAt.year,
        reconciledAt.month,
        reconciledAt.day,
      ),
      entries: nextById.values.toList(growable: false)
        ..sort(
          (left, right) =>
              left.notificationKey.compareTo(right.notificationKey),
        ),
    );
  }

  bool _matches(
      NotificationManifestEntry existing, DesiredNotification desired) {
    return existing.sourceFingerprint == desired.fingerprint &&
        existing.platformId == desired.platformId &&
        existing.templateId == desired.templateId &&
        existing.kind == desired.kind;
  }
}

int _operationRank(NotificationReconciliationOperationType type) {
  switch (type) {
    case NotificationReconciliationOperationType.keep:
      return 0;
    case NotificationReconciliationOperationType.create:
      return 1;
    case NotificationReconciliationOperationType.replace:
      return 2;
    case NotificationReconciliationOperationType.cancel:
      return 3;
  }
}

class InMemoryNotificationScheduleExecutor
    implements NotificationScheduleExecutor {
  InMemoryNotificationScheduleExecutor({
    Set<String>? createFailures,
    Set<String>? replaceFailures,
    Set<String>? cancelFailures,
  })  : _createFailures = createFailures ?? <String>{},
        _replaceFailures = replaceFailures ?? <String>{},
        _cancelFailures = cancelFailures ?? <String>{};

  final Set<String> _createFailures;
  final Set<String> _replaceFailures;
  final Set<String> _cancelFailures;

  @override
  Future<void> cancel(NotificationManifestEntry existing) async {
    if (_cancelFailures.contains(existing.notificationKey)) {
      throw StateError('cancel_failed');
    }
  }

  @override
  Future<void> create(DesiredNotification notification) async {
    if (_createFailures.contains(notification.logicalNotificationId)) {
      throw StateError('create_failed');
    }
  }

  @override
  Future<void> replace(
    NotificationManifestEntry existing,
    DesiredNotification replacement,
  ) async {
    if (_replaceFailures.contains(replacement.logicalNotificationId)) {
      throw StateError('replace_failed');
    }
  }
}
