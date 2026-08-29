import 'dart:io';

import 'package:flutter/foundation.dart';
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
    _notifV2Log(
      'executor adopt attempt platformId=${desired.platformId} '
      'logicalId=${desired.logicalNotificationId} '
      'nativePending=${pending.platformId}',
    );
    if (!await _isScopeActive()) {
      _notifV2Log('executor adopt rejected: stale scope');
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.staleScope,
        platformId: desired.platformId,
      );
    }
    _notifV2Log(
      'executor adopt accepted platformId=${desired.platformId} '
      'stateChange=adopted',
    );
    return NotificationNativeExecutionResult.success(
      stateChange: NotificationExecutionStateChange.adopted,
      platformId: desired.platformId,
    );
  }

  @override
  Future<NotificationNativeExecutionResult> cancel(
    NotificationManifestEntry existing,
  ) async {
    _notifV2Log(
      'executor cancel attempt platformId=${existing.platformId} '
      'logicalId=${existing.notificationKey}',
    );
    if (!await _isScopeActive()) {
      _notifV2Log('executor cancel rejected: stale scope');
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
    _notifV2Log(
      'executor create attempt platformId=${notification.platformId} '
      'logicalId=${notification.logicalNotificationId} '
      'timezone=${notification.timezoneIdAtPlanTime} '
      'intended=${notification.intendedLocalDateTime.toIso8601String()}',
    );
    if (!await _isScopeActive()) {
      _notifV2Log('executor create rejected: stale scope');
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.staleScope,
        platformId: notification.platformId,
      );
    }
    if (!_isFutureSchedule(notification)) {
      _notifV2Log('executor create rejected: invalid schedule in the past');
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.invalidSchedule,
        platformId: notification.platformId,
      );
    }

    final capabilities = await _gateway.getSchedulingCapabilities();
    _notifV2Log(
      'executor create capability permission=${capabilities.permissionStatus.name} '
      'canSchedule=${capabilities.canScheduleNewEntries} '
      'canCancel=${capabilities.canCancelExistingEntries}',
    );
    if (!capabilities.canScheduleNewEntries) {
      _notifV2Log('executor create rejected: permission denied');
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.permissionDenied,
        platformId: notification.platformId,
      );
    }

    final pending = await _gateway.pendingNotifications();
    _notifV2Log('executor create pendingBefore=${pending.length}');
    if (_wouldExceedCapacity(currentPendingCount: pending.length)) {
      _notifV2Log(
        'executor create rejected: capacity exceeded iosLimit=$_safeIosCapacity '
        'pending=${pending.length}',
      );
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
    _notifV2Log(
      'executor replace attempt platformId=${replacement.platformId} '
      'logicalId=${replacement.logicalNotificationId} '
      'existingPlatformId=${existing.platformId}',
    );
    if (!await _isScopeActive()) {
      _notifV2Log('executor replace rejected: stale scope');
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
    _notifV2Log(
      'executor replace capability permission=${capabilities.permissionStatus.name} '
      'canSchedule=${capabilities.canScheduleNewEntries} '
      'canCancel=${capabilities.canCancelExistingEntries}',
    );
    if (!capabilities.canScheduleNewEntries) {
      _notifV2Log('executor replace rejected: permission denied');
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.permissionDenied,
        platformId: replacement.platformId,
      );
    }

    final pending = await _gateway.pendingNotifications();
    _notifV2Log('executor replace pendingBefore=${pending.length}');
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
        _notifV2Log(
          'executor replace cancel failed error=${cancelResult.errorCode?.name ?? "unknown"} '
          'platformId=${existing.platformId}',
        );
        return cancelResult;
      }
      final scheduledResult = await _scheduleNotification(replacement);
      if (!scheduledResult.isSuccess) {
        _notifV2Log(
          'executor replace schedule failed error=${scheduledResult.errorCode?.name ?? "unknown"} '
          'platformId=${replacement.platformId}',
        );
        return NotificationNativeExecutionResult.failure(
          errorCode:
              scheduledResult.errorCode ?? NotificationNativeErrorCode.unknown,
          platformId: replacement.platformId,
          stateChange: NotificationExecutionStateChange.cancelled,
          diagnostics: scheduledResult.diagnostics,
        );
      }
      final postPending = await _gateway.pendingNotifications();
      _notifV2Log(
        'executor replace success platformId=${replacement.platformId} '
        'pendingAfter=${postPending.length} '
        'containsPlatform=${postPending.any((pending) => pending.platformId == replacement.platformId)}',
      );
      return NotificationNativeExecutionResult.success(
        stateChange: NotificationExecutionStateChange.replaced,
        platformId: replacement.platformId,
        scheduleAccepted: true,
      );
    }

    final scheduledResult = await _scheduleNotification(replacement);
    if (!scheduledResult.isSuccess) {
      _notifV2Log(
        'executor replace schedule failed error=${scheduledResult.errorCode?.name ?? "unknown"} '
        'platformId=${replacement.platformId}',
      );
      return scheduledResult;
    }
    final postPending = await _gateway.pendingNotifications();
    _notifV2Log(
      'executor replace success platformId=${replacement.platformId} '
      'pendingAfter=${postPending.length} '
      'containsPlatform=${postPending.any((pending) => pending.platformId == replacement.platformId)}',
    );
    return NotificationNativeExecutionResult.success(
      stateChange: NotificationExecutionStateChange.replaced,
      platformId: replacement.platformId,
      scheduleAccepted: true,
    );
  }

  Future<NotificationNativeExecutionResult> _cancelPlatformId(
      int platformId) async {
    try {
      _notifV2Log('executor native cancel platformId=$platformId');
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
      _notifV2Log(
        'executor schedule rejected: invalid timezone '
        'platformId=${notification.platformId} '
        'timezone=${notification.timezoneIdAtPlanTime}',
      );
      return NotificationNativeExecutionResult.failure(
        errorCode: NotificationNativeErrorCode.invalidTimezone,
        platformId: notification.platformId,
      );
    }

    try {
      _notifV2Log(
        'executor schedule native call platformId=${notification.platformId} '
        'timezone=${notification.timezoneIdAtPlanTime} '
        'intended=${notification.intendedLocalDateTime.toIso8601String()}',
      );
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
      _notifV2Log(
        'executor schedule failed platformId=${notification.platformId} '
        'error=platform_exception code=${error.code}',
      );
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
        _notifV2Log(
          'executor schedule failed platformId=${notification.platformId} '
          'error=invalid_timezone',
        );
        return NotificationNativeExecutionResult.failure(
          errorCode: NotificationNativeErrorCode.invalidTimezone,
          platformId: notification.platformId,
        );
      }
      _notifV2Log(
        'executor schedule failed platformId=${notification.platformId} '
        'error=${error.runtimeType}',
      );
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

  void _notifV2Log(String message) {
    if (!kDebugMode) return;
    debugPrint('[NOTIF_V2] $message');
  }
}
