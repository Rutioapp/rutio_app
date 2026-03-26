import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_models.dart';
import 'notification_types.dart';

class NotificationScheduler {
  NotificationScheduler(
    this._plugin, {
    String Function()? androidSmallIcon,
    Future<void> Function(
      String operation,
      Object error,
      StackTrace stackTrace,
    )? onRecoverablePluginError,
  })  : _androidSmallIcon = androidSmallIcon ??
            (() => RutioNotificationChannel.androidSmallIcon),
        _onRecoverablePluginError = onRecoverablePluginError;

  final FlutterLocalNotificationsPlugin _plugin;
  final String Function() _androidSmallIcon;
  final Future<void> Function(
    String operation,
    Object error,
    StackTrace stackTrace,
  )? _onRecoverablePluginError;

  NotificationDetails buildDetails() {
    final androidDetails = AndroidNotificationDetails(
      RutioNotificationChannel.id,
      RutioNotificationChannel.name,
      channelDescription: RutioNotificationChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: _androidSmallIcon(),
    );

    const iosDetails = DarwinNotificationDetails();

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  Future<void> createChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        RutioNotificationChannel.id,
        RutioNotificationChannel.name,
        description: RutioNotificationChannel.description,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    logNotification(
      'Android channel ready: ${RutioNotificationChannel.id}',
    );
  }

  Future<void> scheduleDaily({
    required int id,
    required NotificationCopy copy,
    required NotificationTime time,
    required String payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (!first.isAfter(now)) {
      first = first.add(const Duration(days: 1));
    }

    await cancel(id);
    await _safeZonedSchedule(
      id: id,
      title: copy.title,
      body: copy.body,
      when: first,
      payload: payload,
      matchTime: true,
    );
  }

  Future<void> scheduleOneTime(ScheduledNotificationRequest request) async {
    await cancel(request.id);
    await _safeZonedSchedule(
      id: request.id,
      title: request.copy.title,
      body: request.copy.body,
      when: tz.TZDateTime.from(request.scheduledFor, tz.local),
      payload: request.payload,
    );
  }

  Future<void> showNow({
    required int id,
    required NotificationCopy copy,
    required String payload,
  }) async {
    await _runPluginVoidOperation(
      'showNow($id)',
      () => _plugin.show(
        id,
        copy.title,
        copy.body,
        buildDetails(),
        payload: payload,
      ),
      retryAfterRecovery: true,
    );
  }

  Future<void> cancel(int id) async {
    await _runPluginVoidOperation(
      'cancel($id)',
      () => _plugin.cancel(id),
      retryAfterRecovery: true,
      swallowAfterRecoveryFailure: true,
    );
  }

  Future<void> cancelAll() async {
    await _runPluginVoidOperation(
      'cancelAll()',
      () => _plugin.cancelAll(),
      retryAfterRecovery: true,
      swallowAfterRecoveryFailure: true,
    );
  }

  Future<void> cancelMany(Iterable<int> ids) async {
    for (final id in ids.toSet()) {
      await cancel(id);
    }
  }

  Future<void> cancelHabitReminder(String habitId) async {
    final baseId = RutioNotificationIds.habitReminder(habitId);
    for (var index = 0; index < 64; index++) {
      await cancel(baseId + index);
    }
  }

  Future<void> cancelByPayloadPrefix(String prefix) async {
    final pending = await pendingRequests();
    for (final request in pending) {
      if ((request.payload ?? '').startsWith(prefix)) {
        await cancel(request.id);
      }
    }
  }

  Future<List<PendingNotificationRequest>> pendingRequests() async {
    return _runPluginListOperation(
      'pendingNotificationRequests()',
      () => _plugin.pendingNotificationRequests(),
      retryAfterRecovery: true,
    );
  }

  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String payload,
    bool matchTime = false,
  }) async {
    bool? canExact;
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      try {
        canExact = await android?.canScheduleExactNotifications();
      } catch (_) {
        canExact = null;
      }
    }

    final scheduleMode = (Platform.isAndroid && canExact == true)
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    logNotification(
      'Scheduling notification id=$id at ${when.toIso8601String()} '
      'mode=$scheduleMode exactGranted=${canExact == true}',
    );

    try {
      await _runPluginVoidOperation(
        'zonedSchedule($id)',
        () => _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          buildDetails(),
          payload: payload,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchTime ? DateTimeComponents.time : null,
        ),
        retryAfterRecovery: true,
      );
    } on PlatformException catch (error) {
      final message = (error.message ?? '').toLowerCase();
      final exactAlarmDenied = error.code == 'exact_alarms_not_permitted' ||
          message.contains('exact alarms') ||
          message.contains('alarmclock');

      if (!Platform.isAndroid || !exactAlarmDenied) {
        rethrow;
      }

      logNotificationError(
        'Exact alarm permission unavailable for notification id=$id. '
        'Retrying with inexactAllowWhileIdle.',
      );

      await _runPluginVoidOperation(
        'zonedScheduleFallback($id)',
        () => _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          buildDetails(),
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchTime ? DateTimeComponents.time : null,
        ),
        retryAfterRecovery: true,
      );
    }
  }

  Future<void> _runPluginVoidOperation(
    String operation,
    Future<void> Function() action, {
    bool retryAfterRecovery = false,
    bool swallowAfterRecoveryFailure = false,
  }) async {
    try {
      await action();
    } catch (error, stackTrace) {
      final recovered = await _attemptRecovery(operation, error, stackTrace);
      if (recovered && retryAfterRecovery) {
        try {
          await action();
          return;
        } catch (retryError, retryStackTrace) {
          logNotificationError(
            'Notification plugin operation failed after recovery: '
            '$operation -> $retryError',
            stackTrace: retryStackTrace,
          );
          if (swallowAfterRecoveryFailure) {
            return;
          }
          rethrow;
        }
      }

      if (swallowAfterRecoveryFailure && recovered) {
        return;
      }
      rethrow;
    }
  }

  Future<List<PendingNotificationRequest>> _runPluginListOperation(
    String operation,
    Future<List<PendingNotificationRequest>> Function() action, {
    bool retryAfterRecovery = false,
  }) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      final recovered = await _attemptRecovery(operation, error, stackTrace);
      if (recovered && retryAfterRecovery) {
        try {
          return await action();
        } catch (retryError, retryStackTrace) {
          logNotificationError(
            'Notification plugin list operation failed after recovery: '
            '$operation -> $retryError',
            stackTrace: retryStackTrace,
          );
        }
      }
      rethrow;
    }
  }

  Future<bool> _attemptRecovery(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) async {
    if (_onRecoverablePluginError == null) return false;

    final normalized = error.toString().toLowerCase();
    final isRecoverableCacheError =
        normalized.contains('missing type parameter') ||
            normalized.contains('loadschedulednotifications') ||
            normalized.contains('removenotificationfromcache') ||
            normalized.contains('failed to handle method call') ||
            normalized.contains('flutter/local_notifications');

    if (!isRecoverableCacheError) {
      return false;
    }

    await _onRecoverablePluginError!(operation, error, stackTrace);
    return true;
  }
}
