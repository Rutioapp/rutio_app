import 'package:flutter/foundation.dart';

import 'personalized_notification_models.dart';

enum NotificationNativeErrorCode {
  permissionDenied,
  invalidTimezone,
  invalidSchedule,
  nativeFailure,
  capacityExceeded,
  staleScope,
  unknown,
}

enum NotificationExecutionStateChange {
  none,
  scheduled,
  cancelled,
  replaced,
  adopted,
  manifestOnly,
}

@immutable
class NativePendingNotification {
  const NativePendingNotification({
    required this.platformId,
    this.title,
    this.body,
    this.payload,
    this.logicalNotificationId,
    this.templateId,
    this.scopeHash,
    this.scopeEpoch,
    this.family,
    this.kind,
    required this.isOwnedV2,
  });

  final int platformId;
  final String? title;
  final String? body;
  final String? payload;
  final String? logicalNotificationId;
  final String? templateId;
  final String? scopeHash;
  final int? scopeEpoch;
  final NotificationFamily? family;
  final NotificationKind? kind;
  final bool isOwnedV2;

  bool belongsToScope(NotificationScope scope) {
    return isOwnedV2 &&
        scopeHash == scope.scopeHash &&
        scopeEpoch == scope.scopeEpoch;
  }
}

@immutable
class NotificationNativeExecutionResult {
  const NotificationNativeExecutionResult({
    required this.operationAccepted,
    required this.scheduleAccepted,
    required this.stateChanged,
    required this.stateChange,
    this.platformId,
    this.errorCode,
    this.diagnostics = const <String>[],
  });

  final bool operationAccepted;
  final bool scheduleAccepted;
  final bool stateChanged;
  final NotificationExecutionStateChange stateChange;
  final int? platformId;
  final NotificationNativeErrorCode? errorCode;
  final List<String> diagnostics;

  bool get isSuccess => operationAccepted;

  factory NotificationNativeExecutionResult.success({
    required NotificationExecutionStateChange stateChange,
    required int platformId,
    bool scheduleAccepted = false,
    List<String> diagnostics = const <String>[],
  }) {
    return NotificationNativeExecutionResult(
      operationAccepted: true,
      scheduleAccepted: scheduleAccepted,
      stateChanged: stateChange != NotificationExecutionStateChange.none,
      stateChange: stateChange,
      platformId: platformId,
      diagnostics: diagnostics,
    );
  }

  factory NotificationNativeExecutionResult.failure({
    required NotificationNativeErrorCode errorCode,
    int? platformId,
    NotificationExecutionStateChange stateChange =
        NotificationExecutionStateChange.none,
    List<String> diagnostics = const <String>[],
  }) {
    return NotificationNativeExecutionResult(
      operationAccepted: false,
      scheduleAccepted: false,
      stateChanged: stateChange != NotificationExecutionStateChange.none,
      stateChange: stateChange,
      platformId: platformId,
      errorCode: errorCode,
      diagnostics: diagnostics,
    );
  }
}
