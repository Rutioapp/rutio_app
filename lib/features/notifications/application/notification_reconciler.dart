import '../domain/desired_notification.dart';
import '../domain/notification_native_models.dart';
import '../domain/personalized_notification_models.dart';
import '../domain/personalized_notification_ports.dart';
import 'notification_reconciliation_models.dart';

class NotificationReconciler {
  const NotificationReconciler();

  NotificationReconciliationPlan reconcile({
    required DesiredNotificationPlan desiredPlan,
    required NotificationScheduleManifest manifest,
    List<NativePendingNotification> osPendingNotifications =
        const <NativePendingNotification>[],
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
    final nativeOwnedById = <String, NativePendingNotification>{
      for (final entry in osPendingNotifications)
        if (entry.logicalNotificationId != null &&
            entry.belongsToScope(desiredPlan.scope!))
          entry.logicalNotificationId!: entry,
    };
    final operations = <NotificationReconciliationOperation>[];

    for (final desired in desiredPlan.notifications) {
      final existing = existingById[desired.logicalNotificationId];
      final nativePending = nativeOwnedById[desired.logicalNotificationId];
      if (existing == null && nativePending == null) {
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
      if (existing == null && nativePending != null) {
        final nativeMatchesDesired = _nativeMatchesDesired(
          nativePending,
          desired,
        );
        operations.add(
          NotificationReconciliationOperation(
            type: nativeMatchesDesired
                ? NotificationReconciliationOperationType.adopt
                : NotificationReconciliationOperationType.replace,
            logicalNotificationId: desired.logicalNotificationId,
            platformId: desired.platformId,
            desired: desired,
            nativePending: nativePending,
            reason: nativeMatchesDesired
                ? 'native_owned_recovered'
                : 'native_owned_unverified',
          ),
        );
        continue;
      }

      if (existing != null &&
          _matches(existing, desired) &&
          nativePending != null &&
          _nativeMatchesDesired(nativePending, desired)) {
        operations.add(
          NotificationReconciliationOperation(
            type: NotificationReconciliationOperationType.keep,
            logicalNotificationId: desired.logicalNotificationId,
            platformId: desired.platformId,
            desired: desired,
            manifestEntry: existing,
            nativePending: nativePending,
            reason: 'fingerprint_unchanged',
          ),
        );
      } else if (nativePending == null) {
        operations.add(
          NotificationReconciliationOperation(
            type: NotificationReconciliationOperationType.create,
            logicalNotificationId: desired.logicalNotificationId,
            platformId: desired.platformId,
            desired: desired,
            manifestEntry: existing,
            reason: existing == null
                ? 'missing_from_manifest'
                : 'native_missing_recreate',
          ),
        );
      } else {
        operations.add(
          NotificationReconciliationOperation(
            type: NotificationReconciliationOperationType.replace,
            logicalNotificationId: desired.logicalNotificationId,
            platformId: desired.platformId,
            desired: desired,
            manifestEntry: existing,
            nativePending: nativePending,
            reason: existing != null && _matches(existing, desired)
                ? 'native_diverged'
                : 'fingerprint_changed',
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
      if (!entry.family.isPersonalizedV2Owned) {
        continue;
      }
      final nativePending = nativeOwnedById[entry.notificationKey];
      operations.add(
        NotificationReconciliationOperation(
          type: nativePending == null
              ? NotificationReconciliationOperationType.dropManifest
              : NotificationReconciliationOperationType.cancel,
          logicalNotificationId: entry.notificationKey,
          platformId: entry.platformId,
          manifestEntry: entry,
          nativePending: nativePending,
          reason: nativePending == null
              ? 'manifest_stale_os_missing'
              : 'absent_from_desired',
        ),
      );
    }

    for (final pending in osPendingNotifications) {
      if (!pending.belongsToScope(desiredPlan.scope!)) {
        continue;
      }
      final logicalId = pending.logicalNotificationId;
      if (logicalId == null) {
        continue;
      }
      if (desiredById.containsKey(logicalId) ||
          existingById.containsKey(logicalId)) {
        continue;
      }
      operations.add(
        NotificationReconciliationOperation(
          type: NotificationReconciliationOperationType.cancel,
          logicalNotificationId: logicalId,
          platformId: pending.platformId,
          nativePending: pending,
          reason: 'orphan_native_owned_for_scope',
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
          final createResult = await executor.create(operation.desired!);
          _collectOperationResult(
            operation: operation,
            result: createResult,
            succeeded: succeeded,
            failed: failed,
          );
          break;
        case NotificationReconciliationOperationType.replace:
          final replaceResult = await executor.replace(
            operation.manifestEntry ??
                NotificationManifestEntry(
                  notificationKey: operation.logicalNotificationId,
                  platformId: operation.platformId,
                  family: operation.desired!.family,
                  kind: operation.desired!.kind,
                  payload: operation.nativePending?.payload ?? '',
                  templateId: operation.nativePending?.templateId ?? '',
                  scheduledAt: operation.desired!.intendedLocalDateTime.toUtc(),
                  planVersion: operation.desired!.planVersion,
                  sourceFingerprint: '',
                ),
            operation.desired!,
          );
          _collectOperationResult(
            operation: operation,
            result: replaceResult,
            succeeded: succeeded,
            failed: failed,
          );
          break;
        case NotificationReconciliationOperationType.adopt:
          final adoptResult = await executor.adopt(
            operation.nativePending!,
            operation.desired!,
          );
          _collectOperationResult(
            operation: operation,
            result: adoptResult,
            succeeded: succeeded,
            failed: failed,
          );
          break;
        case NotificationReconciliationOperationType.cancel:
          final cancelResult = operation.manifestEntry != null
              ? await executor.cancel(operation.manifestEntry!)
              : await executor.cancelPending(operation.nativePending!);
          _collectOperationResult(
            operation: operation,
            result: cancelResult,
            succeeded: succeeded,
            failed: failed,
          );
          break;
        case NotificationReconciliationOperationType.dropManifest:
          final dropResult = await executor.dropManifestEntry(
            operation.manifestEntry!,
          );
          _collectOperationResult(
            operation: operation,
            result: dropResult,
            succeeded: succeeded,
            failed: failed,
          );
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
        failed: failed,
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
    List<NotificationExecutorOperationResult> failed =
        const <NotificationExecutorOperationResult>[],
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
        case NotificationReconciliationOperationType.adopt:
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
        case NotificationReconciliationOperationType.dropManifest:
          nextById.remove(operation.logicalNotificationId);
          break;
      }
    }

    for (final failure in failed) {
      if (failure.type != NotificationReconciliationOperationType.replace) {
        continue;
      }
      if (failure.stateChange != NotificationExecutionStateChange.cancelled) {
        continue;
      }
      nextById.remove(failure.logicalNotificationId);
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

  bool _nativeMatchesDesired(
    NativePendingNotification pending,
    DesiredNotification desired,
  ) {
    return pending.isOwnedV2 &&
        pending.platformId == desired.platformId &&
        pending.logicalNotificationId == desired.logicalNotificationId &&
        pending.templateId == desired.templateId &&
        pending.kind == desired.kind &&
        pending.family == desired.family &&
        pending.title == desired.renderedTitle &&
        pending.body == desired.renderedBody &&
        pending.scopeHash == desired.scope.scopeHash &&
        pending.scopeEpoch == desired.scope.scopeEpoch;
  }

  void _collectOperationResult({
    required NotificationReconciliationOperation operation,
    required NotificationNativeExecutionResult result,
    required List<NotificationExecutorOperationResult> succeeded,
    required List<NotificationExecutorOperationResult> failed,
  }) {
    final projected = NotificationExecutorOperationResult(
      type: operation.type,
      logicalNotificationId: operation.logicalNotificationId,
      success: result.isSuccess,
      platformId: result.platformId,
      scheduleAccepted: result.scheduleAccepted,
      errorCode: result.errorCode,
      stateChange: result.stateChange,
      diagnostics: result.diagnostics,
    );
    if (result.isSuccess) {
      succeeded.add(projected);
    } else {
      failed.add(projected);
    }
  }
}

int _operationRank(NotificationReconciliationOperationType type) {
  switch (type) {
    case NotificationReconciliationOperationType.keep:
      return 0;
    case NotificationReconciliationOperationType.adopt:
      return 1;
    case NotificationReconciliationOperationType.dropManifest:
      return 2;
    case NotificationReconciliationOperationType.cancel:
      return 3;
    case NotificationReconciliationOperationType.replace:
      return 4;
    case NotificationReconciliationOperationType.create:
      return 5;
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
  Future<NotificationNativeExecutionResult> cancel(
    NotificationManifestEntry existing,
  ) async {
    if (_cancelFailures.contains(existing.notificationKey)) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.nativeFailure,
        platformId: existing.platformId,
      );
    }
    return NotificationNativeExecutionResult.success(
      stateChange: NotificationExecutionStateChange.cancelled,
      platformId: existing.platformId,
    );
  }

  @override
  Future<NotificationNativeExecutionResult> create(
    DesiredNotification notification,
  ) async {
    if (_createFailures.contains(notification.logicalNotificationId)) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.nativeFailure,
        platformId: notification.platformId,
      );
    }
    return NotificationNativeExecutionResult.success(
      stateChange: NotificationExecutionStateChange.scheduled,
      platformId: notification.platformId,
      scheduleAccepted: true,
    );
  }

  @override
  Future<NotificationNativeExecutionResult> replace(
    NotificationManifestEntry existing,
    DesiredNotification replacement,
  ) async {
    if (_replaceFailures.contains(replacement.logicalNotificationId)) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.nativeFailure,
        platformId: replacement.platformId,
      );
    }
    return NotificationNativeExecutionResult.success(
      stateChange: NotificationExecutionStateChange.replaced,
      platformId: replacement.platformId,
      scheduleAccepted: true,
    );
  }

  @override
  Future<NotificationNativeExecutionResult> adopt(
    NativePendingNotification pending,
    DesiredNotification desired,
  ) async {
    return NotificationNativeExecutionResult.success(
      stateChange: NotificationExecutionStateChange.adopted,
      platformId: desired.platformId,
    );
  }

  @override
  Future<NotificationNativeExecutionResult> cancelPending(
    NativePendingNotification pending,
  ) async {
    if (_cancelFailures.contains(pending.logicalNotificationId ?? '')) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.nativeFailure,
        platformId: pending.platformId,
      );
    }
    return NotificationNativeExecutionResult.success(
      stateChange: NotificationExecutionStateChange.cancelled,
      platformId: pending.platformId,
    );
  }

  @override
  Future<NotificationNativeExecutionResult> dropManifestEntry(
    NotificationManifestEntry existing,
  ) async {
    return NotificationNativeExecutionResult.success(
      stateChange: NotificationExecutionStateChange.manifestOnly,
      platformId: existing.platformId,
    );
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
}
