import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_models.dart';
import 'notification_types.dart';

class NotificationScheduler {
  NotificationScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  NotificationDetails buildDetails() {
    const androidDetails = AndroidNotificationDetails(
      RutioNotificationChannel.id,
      RutioNotificationChannel.name,
      channelDescription: RutioNotificationChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: RutioNotificationChannel.androidSmallIcon,
    );

    const iosDetails = DarwinNotificationDetails();

    return const NotificationDetails(
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
  }) {
    return _plugin.show(
      id,
      copy.title,
      copy.body,
      buildDetails(),
      payload: payload,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelMany(Iterable<int> ids) async {
    for (final id in ids.toSet()) {
      await _plugin.cancel(id);
    }
  }

  Future<void> cancelHabitReminder(String habitId) async {
    final baseId = RutioNotificationIds.habitReminder(habitId);
    for (var index = 0; index < 64; index++) {
      await _plugin.cancel(baseId + index);
    }
  }

  Future<void> cancelByPayloadPrefix(String prefix) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if ((request.payload ?? '').startsWith(prefix)) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<List<PendingNotificationRequest>> pendingRequests() {
    return _plugin.pendingNotificationRequests();
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
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.inexact;

    try {
      await _plugin.zonedSchedule(
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
      );
    } on PlatformException catch (error) {
      final message = (error.message ?? '').toLowerCase();
      final exactAlarmDenied = error.code == 'exact_alarms_not_permitted' ||
          message.contains('exact alarms') ||
          message.contains('alarmclock');

      if (!Platform.isAndroid || !exactAlarmDenied) {
        rethrow;
      }

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        buildDetails(),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchTime ? DateTimeComponents.time : null,
      );
    }
  }
}
