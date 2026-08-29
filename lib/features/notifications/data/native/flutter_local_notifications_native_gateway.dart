import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/notifications/notification_permission_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/notification_scheduler.dart' as legacy;
import '../../domain/notification_native_gateway.dart';
import '../../domain/notification_native_models.dart';
import '../../domain/notification_payload.dart';
import '../../domain/personalized_notification_models.dart';

class FlutterLocalNotificationsNativeGateway
    implements NotificationNativeGateway {
  FlutterLocalNotificationsNativeGateway({
    NotificationService? notificationService,
  }) : _notificationService =
            notificationService ?? NotificationService.instance;

  final NotificationService _notificationService;

  legacy.NotificationScheduler get _scheduler => _notificationService.scheduler;
  NotificationPermissionService get _permissionService =>
      _notificationService.permissionService;

  @override
  Future<NotificationSchedulingCapabilities> getSchedulingCapabilities() async {
    final initialized =
        await _notificationService.ensureInitializedForFeature();
    if (!initialized) {
      _notifV2Log(
          'gateway capabilities unavailable: notification service not initialized');
      return NotificationSchedulingCapabilities.unsupported;
    }

    final result = await _permissionService.checkStatus();
    final status = _mapPermissionStatus(result.status);
    _notifV2Log(
      'gateway capabilities permission=${status.name} '
      'authorized=${result.isAuthorized} '
      'canRequest=${result.canRequest}',
    );
    return NotificationSchedulingCapabilities(
      permissionStatus: status,
      canScheduleNewEntries: result.isAuthorized,
      canCancelExistingEntries: true,
    );
  }

  @override
  Future<List<NativePendingNotification>> pendingNotifications() async {
    final initialized =
        await _notificationService.ensureInitializedForFeature();
    if (!initialized) {
      _notifV2Log(
          'gateway pending unavailable: notification service not initialized');
      return const <NativePendingNotification>[];
    }

    final requests = await _scheduler.pendingRequests();
    _notifV2Log('gateway pending count=${requests.length}');
    return requests.map(_mapPendingRequest).toList(growable: false);
  }

  @override
  Future<void> scheduleNotification({
    required int platformId,
    required String title,
    required String body,
    required String payload,
    required NotificationScheduleSpec scheduleSpec,
    required String effectiveTimezoneId,
  }) async {
    final initialized =
        await _notificationService.ensureInitializedForFeature();
    if (!initialized) {
      _notifV2Log(
          'gateway schedule aborted: notification service not initialized');
      throw StateError('notification_service_unavailable');
    }

    final location = tz.getLocation(effectiveTimezoneId);
    final scheduledAt = _resolveScheduledAt(
      scheduleSpec: scheduleSpec,
      location: location,
    );
    _notifV2Log(
      'gateway schedule platformId=$platformId '
      'timezone=$effectiveTimezoneId '
      'scheduled=${scheduledAt.toIso8601String()} '
      'repeatDaily=${scheduleSpec.repeats}',
    );
    await _scheduler.scheduleZoned(
      id: platformId,
      title: title,
      body: body,
      when: scheduledAt,
      payload: payload,
      matchTime: scheduleSpec.scheduleType ==
              NotificationScheduleType.dailyClockTime &&
          scheduleSpec.repeats,
    );
  }

  @override
  Future<void> cancelNotification(int platformId) async {
    final initialized =
        await _notificationService.ensureInitializedForFeature();
    if (!initialized) {
      _notifV2Log(
          'gateway cancel aborted: notification service not initialized platformId=$platformId');
      throw StateError('notification_service_unavailable');
    }
    _notifV2Log('gateway cancel platformId=$platformId');
    await _scheduler.cancel(platformId);
  }

  NativePendingNotification _mapPendingRequest(dynamic request) {
    final payload = (request.payload as String?)?.trim();
    NotificationPayloadV2? parsedPayload;
    if (payload != null && payload.isNotEmpty) {
      parsedPayload = NotificationPayloadV2.tryParse(payload);
    }

    return NativePendingNotification(
      platformId: request.id as int,
      title: (request.title as String?)?.trim(),
      body: (request.body as String?)?.trim(),
      payload: payload,
      logicalNotificationId: parsedPayload?.logicalId,
      templateId: parsedPayload?.templateId,
      scopeHash: parsedPayload?.scopeHash,
      scopeEpoch: parsedPayload?.scopeEpoch,
      family: parsedPayload?.family,
      kind: parsedPayload?.kind,
      isOwnedV2: parsedPayload != null,
    );
  }

  tz.TZDateTime _resolveScheduledAt({
    required NotificationScheduleSpec scheduleSpec,
    required tz.Location location,
  }) {
    switch (scheduleSpec.scheduleType) {
      case NotificationScheduleType.exactDateTime:
        final scheduled = scheduleSpec.scheduledLocalDateTime;
        if (scheduled == null) {
          throw ArgumentError('missing_exact_scheduled_local_date_time');
        }
        return tz.TZDateTime(
          location,
          scheduled.year,
          scheduled.month,
          scheduled.day,
          scheduled.hour,
          scheduled.minute,
          scheduled.second,
        );
      case NotificationScheduleType.dailyClockTime:
        final dailyTime = scheduleSpec.dailyTime;
        if (dailyTime == null) {
          throw ArgumentError('missing_daily_clock_time');
        }
        final now = tz.TZDateTime.now(location);
        var scheduled = tz.TZDateTime(
          location,
          now.year,
          now.month,
          now.day,
          dailyTime.hour,
          dailyTime.minute,
        );
        if (!scheduled.isAfter(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        return scheduled;
    }
  }

  NotificationSystemPermissionStatus _mapPermissionStatus(
    NotificationPermissionStatus status,
  ) {
    switch (status) {
      case NotificationPermissionStatus.notDetermined:
        return NotificationSystemPermissionStatus.notDetermined;
      case NotificationPermissionStatus.denied:
        return NotificationSystemPermissionStatus.denied;
      case NotificationPermissionStatus.restricted:
        return NotificationSystemPermissionStatus.restricted;
      case NotificationPermissionStatus.permanentlyDenied:
        return NotificationSystemPermissionStatus.permanentlyDenied;
      case NotificationPermissionStatus.provisional:
        return NotificationSystemPermissionStatus.provisional;
      case NotificationPermissionStatus.authorized:
        return NotificationSystemPermissionStatus.authorized;
      case NotificationPermissionStatus.unknown:
        return NotificationSystemPermissionStatus.unknown;
    }
  }

  void _notifV2Log(String message) {
    if (!kDebugMode) return;
    debugPrint('[NOTIF_V2] $message');
  }
}
