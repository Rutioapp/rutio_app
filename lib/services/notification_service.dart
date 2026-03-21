import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/notifications/notification_permission_service.dart';
import '../stores/user_state_store.dart';
import 'notification_copy.dart';
import 'notification_debug_helpers.dart';
import 'notification_models.dart';
import 'notification_preferences.dart';
import 'notification_rules.dart';
import 'notification_scheduler.dart';
import 'notification_types.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  late final NotificationPermissionService _permissionService =
      NotificationPermissionService(plugin: _plugin);

  late final NotificationScheduler _scheduler = NotificationScheduler(_plugin);
  late final NotificationDebugHelpers _debugHelpers =
      NotificationDebugHelpers(_scheduler);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Madrid'));

    const androidInit = AndroidInitializationSettings(
      RutioNotificationChannel.androidSmallIcon,
    );
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    try {
      await _plugin.initialize(
        InitializationSettings(android: androidInit, iOS: iosInit),
      );
    } on PlatformException catch (error) {
      logNotification('Notification init error: $error');
    }

    await _scheduler.createChannel();
  }

  Future<bool> requestPermissions() async {
    final result = await requestPermissionFlow();
    return result.isAuthorized;
  }

  Future<NotificationPermissionResult> checkPermissionStatus() async {
    await init();
    return _permissionService.checkStatus();
  }

  Future<NotificationPermissionResult> requestPermissionFlow() async {
    await init();

    var result = await _permissionService.ensurePermission();

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      try {
        final exact = await android?.canScheduleExactNotifications();
        if (exact == false && result.isAuthorized) {
          await android?.requestExactAlarmsPermission();
        }
      } catch (_) {
        // Ignore plugin/platform combinations without exact-alarm APIs.
      }
    }

    result = await _permissionService.checkStatus();
    return result;
  }

  Future<bool> openSettings() {
    return _permissionService.openSettings();
  }

  Future<void> syncPhaseOne({
    required UserStateStore store,
    JsonMap? previousState,
    bool recordAppOpen = false,
  }) async {
    await init();

    final currentState = mapCast(store.state);
    if (currentState.isEmpty) return;

    final preferences = NotificationPreferences(store);
    if (recordAppOpen) {
      await preferences.recordAppOpen(DateTime.now());
    }

    final snapshot = preferences.snapshot;
    final previousHabitIds = previousState == null
        ? const <String>[]
        : NotificationRules.activeHabitIds(previousState);
    final currentHabitIds = NotificationRules.activeHabitIds(currentState);
    final removedHabitIds = previousHabitIds
        .where((habitId) => !currentHabitIds.contains(habitId))
        .toList(growable: false);

    if (!snapshot.notificationsEnabled) {
      await _cancelPhaseOneNotifications(
        habitIds: <String>{...currentHabitIds, ...removedHabitIds},
      );
      await cancelDailyMotivation();
      return;
    }

    await _syncLegacyDailyMotivation(snapshot);
    await _syncHabitReminders(
      root: currentState,
      snapshot: snapshot,
      removedHabitIds: removedHabitIds,
    );
    await _syncScheduledRequest(
      request: NotificationRules.buildDayClosureNotification(
        root: currentState,
        preferences: snapshot,
        now: DateTime.now(),
      ),
      fallbackId: RutioNotificationIds.dayClosure,
    );
    await _syncScheduledRequest(
      request: NotificationRules.buildStreakRiskNotification(
        root: currentState,
        preferences: snapshot,
        now: DateTime.now(),
      ),
      fallbackId: RutioNotificationIds.streakRisk,
    );
    await _syncInactivity(snapshot);
    await _triggerCelebrations(
      preferences: preferences,
      snapshot: snapshot,
      previousState: previousState,
      currentState: currentState,
    );
  }

  Future<void> scheduleHabitDailyReminder({
    required String habitId,
    required int hour,
    required int minute,
    String title = 'Rutio',
    required String body,
  }) async {
    await init();
    await _scheduler.scheduleDaily(
      id: RutioNotificationIds.habitReminder(habitId),
      copy: NotificationCopy(title: title, body: body),
      time: NotificationTime(hour: hour, minute: minute),
      payload: RutioNotificationPayloads.habitReminder(habitId),
    );
  }

  Future<void> cancelHabitDailyReminder(String habitId) async {
    await init();
    await _scheduler.cancelHabitReminder(habitId);
  }

  Future<void> scheduleDailyMotivation({
    required int hour,
    required int minute,
    String title = 'Rutio',
    String body = 'Hoy es un buen dia para mantener tu ritmo.',
  }) async {
    await init();
    await _scheduler.scheduleDaily(
      id: RutioNotificationIds.dailyMotivation,
      copy: NotificationCopy(title: title, body: body),
      time: NotificationTime(hour: hour, minute: minute),
      payload: RutioNotificationPayloads.dailyMotivation,
    );
  }

  Future<void> cancelDailyMotivation() async {
    await init();
    await _scheduler.cancel(RutioNotificationIds.dailyMotivation);
  }

  Future<void> debugShowIn3Seconds() {
    return _debugHelpers.showIn3Seconds();
  }

  Future<void> debugScheduleInSeconds(int seconds) {
    return _debugHelpers.scheduleInSeconds(seconds);
  }

  Future<void> debugPrintPending() async {
    final pending = await _debugHelpers.pendingSummary();
    logNotification('Pending notifications: ${pending.length}');
    for (final line in pending) {
      logNotification(line);
    }
  }

  Future<void> _syncLegacyDailyMotivation(
    NotificationPreferencesSnapshot snapshot,
  ) async {
    if (!snapshot.dailyMotivationEnabled) {
      await cancelDailyMotivation();
      return;
    }

    await _scheduler.scheduleDaily(
      id: RutioNotificationIds.dailyMotivation,
      copy: NotificationCopyLibrary.dailyMotivation(
        'Hoy es un buen dia para mantener tu ritmo.',
      ),
      time: snapshot.dailyMotivationTime,
      payload: RutioNotificationPayloads.dailyMotivation,
    );
  }

  Future<void> _syncHabitReminders({
    required JsonMap root,
    required NotificationPreferencesSnapshot snapshot,
    required List<String> removedHabitIds,
  }) async {
    final activeHabitIds = NotificationRules.activeHabitIds(root);
    final reminders = NotificationRules.buildHabitReminders(
      root: root,
      preferences: snapshot,
    );
    final eligibleById = <String, HabitReminderDefinition>{
      for (final reminder in reminders) reminder.habitId: reminder,
    };

    await _cancelObsoleteHabitReminders(activeHabitIds);

    for (final removedHabitId in removedHabitIds) {
      await _scheduler.cancelHabitReminder(removedHabitId);
    }

    for (final habitId in activeHabitIds) {
      final reminder = eligibleById[habitId];
      if (reminder == null) {
        await _scheduler.cancelHabitReminder(habitId);
        continue;
      }

      await _scheduler.scheduleDaily(
        id: RutioNotificationIds.habitReminder(habitId),
        copy: NotificationCopyLibrary.habitReminder(
          habitId: habitId,
          habitName: reminder.habitName,
        ),
        time: reminder.time,
        payload: RutioNotificationPayloads.habitReminder(habitId),
      );
    }
  }

  Future<void> _cancelObsoleteHabitReminders(
      List<String> activeHabitIds) async {
    final pending = await _scheduler.pendingRequests();
    for (final request in pending) {
      final payload = request.payload ?? '';
      if (!payload.startsWith('habit:')) continue;

      final habitId = payload.substring('habit:'.length);
      if (activeHabitIds.contains(habitId)) continue;
      await _scheduler.cancelHabitReminder(habitId);
    }
  }

  Future<void> _syncScheduledRequest({
    required ScheduledNotificationRequest? request,
    required int fallbackId,
  }) async {
    if (request == null) {
      await _scheduler.cancel(fallbackId);
      return;
    }

    await _scheduler.scheduleOneTime(request);
  }

  Future<void> _syncInactivity(
    NotificationPreferencesSnapshot snapshot,
  ) async {
    if (!snapshot.inactivityReengagementEnabled) {
      await _scheduler.cancel(RutioNotificationIds.inactivityReengagement);
      return;
    }

    final request = NotificationRules.buildInactivityNotification(
      preferences: snapshot,
    );

    if (request == null || !request.scheduledFor.isAfter(DateTime.now())) {
      await _scheduler.cancel(RutioNotificationIds.inactivityReengagement);
      return;
    }

    await _scheduler.scheduleOneTime(request);
  }

  Future<void> _triggerCelebrations({
    required NotificationPreferences preferences,
    required NotificationPreferencesSnapshot snapshot,
    required JsonMap? previousState,
    required JsonMap currentState,
  }) async {
    if (!snapshot.streakCelebrationEnabled) return;

    final now = DateTime.now();
    final events = NotificationRules.detectCelebrations(
      previousState: previousState,
      currentState: currentState,
      preferences: snapshot,
      now: now,
    );

    for (final event in events) {
      if (preferences.wasCelebrationSentToday(event.metadataKey, now)) {
        continue;
      }

      await _scheduler.showNow(
        id: RutioNotificationIds.streakCelebration(
          event.habitId,
          event.milestone,
        ),
        copy: NotificationCopyLibrary.streakCelebration(
          habitName: event.habitName,
          milestone: event.milestone,
        ),
        payload: RutioNotificationPayloads.streakCelebration(
          event.habitId,
          event.milestone,
        ),
      );
      await preferences.markCelebrationSent(event.metadataKey, now);
    }
  }

  Future<void> _cancelPhaseOneNotifications({
    required Set<String> habitIds,
  }) async {
    await _scheduler.cancelMany(<int>[
      RutioNotificationIds.dayClosure,
      RutioNotificationIds.streakRisk,
      RutioNotificationIds.inactivityReengagement,
    ]);
    await _scheduler.cancelByPayloadPrefix('habit:');

    for (final habitId in habitIds) {
      await _scheduler.cancelHabitReminder(habitId);
    }
  }
}
