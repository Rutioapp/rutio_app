import 'dart:io';

import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/desired_notification.dart';
import '../../domain/notification_native_gateway.dart';
import '../../domain/notification_native_models.dart';
import '../../domain/personalized_notification_models.dart';
import '../../domain/personalized_notification_ports.dart';

class NativeNotificationScheduleExecutor
    implements NotificationScheduleExecutor {
  NativeNotificationScheduleExecutor({
    required NotificationNativeGateway gateway,
    required Future<bool> Function() isScopeActive,
    this.iosPendingLimit = 64,
    this.iosReservedSlots = 4,
    DateTime Function()? now,
    bool Function()? isIos,
  })  : _gateway = gateway,
        _isScopeActive = isScopeActive,
        _now = now ?? DateTime.now,
        _isIos = isIos ?? (() => Platform.isIOS);

  final NotificationNativeGateway _gateway;
  final Future<bool> Function() _isScopeActive;
  final int iosPendingLimit;
  final int iosReservedSlots;
  final DateTime Function() _now;
  final bool Function() _isIos;

  int get _safeIosCapacity => iosPendingLimit - iosReservedSlots;

  @override
  Future<NotificationNativeExecutionResult> adopt(
    NativePendingNotification pending,
    DesiredNotification desired,
  ) async {
    if (!await _isScopeActive()) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.staleScope,
        platformId: desired.platformId,
      );
    }
    return NotificationNativeExecutionResult.success(
      stateChange: NotificationExecutionStateChange.adopted,
      platformId: desired.platformId,
    );
  }

  @override
  Future<NotificationNativeExecutionResult> cancel(
    NotificationManifestEntry existing,
  ) async {
    if (!await _isScopeActive()) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.staleScope,
        platformId: existing.platformId,
      );
    }
    return _cancelPlatformId(existing.platformId);
  }

  @override
  Future<NotificationNativeExecutionResult> cancelPending(
    NativePendingNotification pending,
  ) {
    return _cancelPlatformId(pending.platformId);
  }

  @override
  Future<NotificationNativeExecutionResult> create(
    DesiredNotification notification,
  ) async {
    if (!await _isScopeActive()) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.staleScope,
        platformId: notification.platformId,
      );
    }
    if (!_isFutureSchedule(notification)) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.invalidSchedule,
        platformId: notification.platformId,
      );
    }

    final capabilities = await _gateway.getSchedulingCapabilities();
    if (!capabilities.canScheduleNewEntries) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.permissionDenied,
        platformId: notification.platformId,
      );
    }

    final pending = await _gateway.pendingNotifications();
    if (_wouldExceedCapacity(currentPendingCount: pending.length)) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.capacityExceeded,
        platformId: notification.platformId,
        diagnostics: <String>[
          'ios_capacity_limit=$_safeIosCapacity',
          'pending_count=${pending.length}',
        ],
      );
    }

    return _scheduleNotification(notification);
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
  Future<NotificationSchedulingCapabilities> getSchedulingCapabilities() {
    return _gateway.getSchedulingCapabilities();
  }

  @override
  Future<List<NativePendingNotification>> pendingNotifications() {
    return _gateway.pendingNotifications();
  }

  @override
  Future<NotificationNativeExecutionResult> replace(
    NotificationManifestEntry existing,
    DesiredNotification replacement,
  ) async {
    if (!await _isScopeActive()) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.staleScope,
        platformId: replacement.platformId,
      );
    }
    if (!_isFutureSchedule(replacement)) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.invalidSchedule,
        platformId: replacement.platformId,
      );
    }

    final capabilities = await _gateway.getSchedulingCapabilities();
    if (!capabilities.canScheduleNewEntries) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.permissionDenied,
        platformId: replacement.platformId,
      );
    }

    final pending = await _gateway.pendingNotifications();
    final existingPending = pending.where((candidate) {
      return candidate.platformId == existing.platformId ||
          candidate.logicalNotificationId == existing.notificationKey;
    }).toList(growable: false);

    if (existingPending.isEmpty &&
        _wouldExceedCapacity(currentPendingCount: pending.length)) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.capacityExceeded,
        platformId: replacement.platformId,
        diagnostics: <String>[
          'ios_capacity_limit=$_safeIosCapacity',
          'pending_count=${pending.length}',
        ],
      );
    }

    if (existingPending.isNotEmpty) {
      final cancelResult = await _cancelPlatformId(existing.platformId);
      if (!cancelResult.isSuccess) {
        return cancelResult;
      }
      final scheduledResult = await _scheduleNotification(replacement);
      if (!scheduledResult.isSuccess) {
        return NotificationNativeExecutionResult.failure(
          errorCode:
              scheduledResult.errorCode ?? NotificationNativeErrorCode.unknown,
          platformId: replacement.platformId,
          stateChange: NotificationExecutionStateChange.cancelled,
          diagnostics: scheduledResult.diagnostics,
        );
      }
      return NotificationNativeExecutionResult.success(
        stateChange: NotificationExecutionStateChange.replaced,
        platformId: replacement.platformId,
        scheduleAccepted: true,
      );
    }

    final scheduledResult = await _scheduleNotification(replacement);
    if (!scheduledResult.isSuccess) {
      return scheduledResult;
    }
    return NotificationNativeExecutionResult.success(
      stateChange: NotificationExecutionStateChange.replaced,
      platformId: replacement.platformId,
      scheduleAccepted: true,
    );
  }

  Future<NotificationNativeExecutionResult> _cancelPlatformId(
      int platformId) async {
    try {
      await _gateway.cancelNotification(platformId);
      return NotificationNativeExecutionResult.success(
        stateChange: NotificationExecutionStateChange.cancelled,
        platformId: platformId,
      );
    } on PlatformException catch (error) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.nativeFailure,
        platformId: platformId,
        diagnostics: <String>[
          if ((error.code).trim().isNotEmpty) error.code,
          if ((error.message ?? '').trim().isNotEmpty) error.message!.trim(),
        ],
      );
    } catch (error) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.nativeFailure,
        platformId: platformId,
        diagnostics: <String>['$error'],
      );
    }
  }

  bool _isFutureSchedule(DesiredNotification notification) =>
      notification.intendedLocalDateTime.isAfter(_now());

  Future<NotificationNativeExecutionResult> _scheduleNotification(
    DesiredNotification notification,
  ) async {
    try {
      tz.getLocation(notification.timezoneIdAtPlanTime);
    } catch (_) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.invalidTimezone,
        platformId: notification.platformId,
      );
    }

    try {
      await _gateway.scheduleNotification(
        platformId: notification.platformId,
        title: notification.renderedTitle,
        body: notification.renderedBody,
        payload: notification.payload.encode(),
        scheduleSpec: NotificationScheduleSpec(
          scheduleType: NotificationScheduleType.exactDateTime,
          scheduledLocalDateTime: notification.intendedLocalDateTime,
          repeats: false,
          anchorSource: notification.opportunityId,
          timezoneIdAtPlanTime: notification.timezoneIdAtPlanTime,
        ),
        effectiveTimezoneId: notification.timezoneIdAtPlanTime,
      );
      return NotificationNativeExecutionResult.success(
        stateChange: NotificationExecutionStateChange.scheduled,
        platformId: notification.platformId,
        scheduleAccepted: true,
      );
    } on PlatformException catch (error) {
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.nativeFailure,
        platformId: notification.platformId,
        diagnostics: <String>[
          if (error.code.trim().isNotEmpty) error.code,
          if ((error.message ?? '').trim().isNotEmpty) error.message!.trim(),
        ],
      );
    } catch (error) {
      if ('$error'.contains('doesn\'t exist')) {
        return NotificationNativeExecutionResult.failure(
          errorCode: NotificationNativeErrorCode.invalidTimezone,
          platformId: notification.platformId,
        );
      }
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.nativeFailure,
        platformId: notification.platformId,
        diagnostics: <String>['$error'],
      );
    }
  }

  bool _wouldExceedCapacity({required int currentPendingCount}) {
    if (!_isIos()) {
      return false;
    }
    return currentPendingCount >= _safeIosCapacity;
  }
}
