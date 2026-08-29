import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../domain/desired_notification.dart';
import '../domain/notification_native_models.dart';
import '../domain/personalized_notification_models.dart';

enum NotificationReconciliationOperationType {
  keep,
  create,
  replace,
  adopt,
  cancel,
  dropManifest,
}

enum NotificationReconciliationPlanStatus {
  ready,
  scopeMismatch,
  blocked,
}

@immutable
class NotificationReconciliationOperation {
  const NotificationReconciliationOperation({
    required this.type,
    required this.logicalNotificationId,
    required this.platformId,
    this.desired,
    this.manifestEntry,
    this.nativePending,
    this.reason,
  });

  final NotificationReconciliationOperationType type;
  final String logicalNotificationId;
  final int platformId;
  final DesiredNotification? desired;
  final NotificationManifestEntry? manifestEntry;
  final NativePendingNotification? nativePending;
  final String? reason;
}

@immutable
class NotificationReconciliationPlan {
  NotificationReconciliationPlan({
    required this.status,
    required this.scope,
    required this.desiredPlanStatus,
    required List<NotificationReconciliationOperation> operations,
    required List<String> diagnostics,
  })  : operations = UnmodifiableListView<NotificationReconciliationOperation>(
            operations),
        diagnostics = UnmodifiableListView<String>(diagnostics);

  final NotificationReconciliationPlanStatus status;
  final NotificationScope? scope;
  final DesiredNotificationPlanStatus desiredPlanStatus;
  final List<NotificationReconciliationOperation> operations;
  final List<String> diagnostics;
}

@immutable
class NotificationExecutorOperationResult {
  const NotificationExecutorOperationResult({
    required this.type,
    required this.logicalNotificationId,
    required this.success,
    this.platformId,
    this.scheduleAccepted = false,
    this.errorCode,
    this.stateChange = NotificationExecutionStateChange.none,
    this.diagnostics = const <String>[],
  });

  final NotificationReconciliationOperationType type;
  final String logicalNotificationId;
  final bool success;
  final int? platformId;
  final bool scheduleAccepted;
  final NotificationNativeErrorCode? errorCode;
  final NotificationExecutionStateChange stateChange;
  final List<String> diagnostics;
}

@immutable
class NotificationReconciliationResult {
  NotificationReconciliationResult({
    required List<NotificationReconciliationOperation> operationsPlanned,
    required List<NotificationExecutorOperationResult> operationsSucceeded,
    required List<NotificationExecutorOperationResult> operationsFailed,
    required this.nextManifest,
    required List<String> diagnostics,
  })  : operationsPlanned =
            UnmodifiableListView<NotificationReconciliationOperation>(
          operationsPlanned,
        ),
        operationsSucceeded =
            UnmodifiableListView<NotificationExecutorOperationResult>(
          operationsSucceeded,
        ),
        operationsFailed =
            UnmodifiableListView<NotificationExecutorOperationResult>(
          operationsFailed,
        ),
        diagnostics = UnmodifiableListView<String>(diagnostics);

  final List<NotificationReconciliationOperation> operationsPlanned;
  final List<NotificationExecutorOperationResult> operationsSucceeded;
  final List<NotificationExecutorOperationResult> operationsFailed;
  final NotificationScheduleManifest nextManifest;
  final List<String> diagnostics;
}
