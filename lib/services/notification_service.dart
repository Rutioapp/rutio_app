import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/notifications/notification_permission_service.dart';
import '../stores/user_state_store.dart';
import 'notification_copy.dart';
import 'notification_models.dart';
import 'notification_preferences.dart';
import 'notification_rules.dart';
import 'notification_scheduler.dart';
import 'notification_types.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const MethodChannel _platformNotificationChannel =
      MethodChannel('rutio/notification_permission');
  static const String _productionCleanupKey =
      'rutio.notifications.production_cleanup_v1';
  static const NotificationPermissionResult _unavailablePermissionResult =
      NotificationPermissionResult(
    status: NotificationPermissionStatus.unknown,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  late final NotificationPermissionService _permissionService =
      NotificationPermissionService(plugin: _plugin);

  late final NotificationScheduler _scheduler = NotificationScheduler(
    _plugin,
    androidSmallIcon: () => _androidNotificationIcon,
    onRecoverablePluginError: _recoverFromAndroidPluginCacheError,
  );

  bool _initialized = false;
  bool _initializationFailed = false;
  bool _recoveringAndroidPluginCache = false;
  String _androidNotificationIcon = RutioNotificationChannel.androidSmallIcon;

  Future<void> init() async {
    if (_initialized || _initializationFailed) return;

    try {
      tzdata.initializeTimeZones();
      final localLocation = await _resolveLocalLocation();
      tz.setLocalLocation(localLocation);
      logNotification('Timezone initialized: ${localLocation.name}');

      await _initializePlugin();
      await _scheduler.createChannel();
      await _runOneTimeProductionCleanup();
      _initialized = true;
      logNotification(
        'Notifications initialized. Android icon=$_androidNotificationIcon',
      );
    } on PlatformException catch (error, stackTrace) {
      _initializationFailed = true;
      logNotificationError(
        'Notification init error: $error',
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      _initializationFailed = true;
      logNotificationError(
        'Notification init error: $error',
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> requestPermissions() async {
    final result = await requestPermissionFlow();
    return result.isAuthorized;
  }

  Future<NotificationPermissionResult> checkPermissionStatus() async {
    if (!await _ensureInitialized()) {
      return _unavailablePermissionResult;
    }
    return _permissionService.checkStatus();
  }

  Future<NotificationPermissionResult> requestPermissionFlow() async {
    if (!await _ensureInitialized()) {
      return _unavailablePermissionResult;
    }

    logNotification('Requesting notification permission flow');
    var result = await _permissionService.ensurePermission();
    logNotification('Notification permission status: ${result.status.name}');

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      try {
        final exact = await android?.canScheduleExactNotifications();
        logNotification(
          'Exact alarm permission granted: ${exact == true}',
        );
      } catch (error, stackTrace) {
        // Ignore plugin/platform combinations without exact-alarm APIs.
        logNotificationError(
          'Exact alarm permission flow error: $error',
          stackTrace: stackTrace,
        );
      }
    }

    result = await _permissionService.checkStatus();
    logNotification(
        'Final notification permission status: ${result.status.name}');
    return result;
  }

  Future<bool> openSettings() {
    return _permissionService.openSettings();
  }

  Future<tz.Location> _resolveLocalLocation() async {
    const fallbackName = 'Europe/Madrid';

    try {
      final timeZoneName = await _platformNotificationChannel
          .invokeMethod<String>('getLocalTimeZone');
      if (timeZoneName != null && timeZoneName.trim().isNotEmpty) {
        return tz.getLocation(timeZoneName.trim());
      }
    } on PlatformException catch (error) {
      logNotification('Timezone lookup error: $error');
    } catch (error) {
      logNotification('Timezone lookup error: $error');
    }

    return tz.getLocation(fallbackName);
  }

  Future<bool> _ensureInitialized() async {
    await init();
    return _initialized;
  }

  Future<void> _recoverFromAndroidPluginCacheError(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) async {
    if (!Platform.isAndroid || _recoveringAndroidPluginCache) return;

    _recoveringAndroidPluginCache = true;
    try {
      logNotificationError(
        'Recovering Android notification cache after plugin failure during '
        '$operation: $error',
        stackTrace: stackTrace,
      );
      await _platformNotificationChannel
          .invokeMethod<void>('clearScheduledNotificationsCache');
      logNotification(
        'Android scheduled notification cache cleared successfully.',
      );
    } on PlatformException catch (recoveryError, recoveryStackTrace) {
      logNotificationError(
        'Failed to clear Android scheduled notification cache: $recoveryError',
        stackTrace: recoveryStackTrace,
      );
    } catch (recoveryError, recoveryStackTrace) {
      logNotificationError(
        'Failed to clear Android scheduled notification cache: $recoveryError',
        stackTrace: recoveryStackTrace,
      );
    } finally {
      _recoveringAndroidPluginCache = false;
    }
  }

  Future<void> _initializePlugin() async {
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    if (!Platform.isAndroid) {
      await _plugin.initialize(
        const InitializationSettings(iOS: iosInit),
      );
      return;
    }

    final androidIcons = <String>[
      RutioNotificationChannel.androidSmallIcon,
      if (RutioNotificationChannel.androidFallbackSmallIcon !=
          RutioNotificationChannel.androidSmallIcon)
        RutioNotificationChannel.androidFallbackSmallIcon,
    ];

    for (var index = 0; index < androidIcons.length; index++) {
      final icon = androidIcons[index];

      try {
        await _plugin.initialize(
          InitializationSettings(
            android: AndroidInitializationSettings(icon),
            iOS: iosInit,
          ),
        );
        _androidNotificationIcon = icon;

        if (icon != RutioNotificationChannel.androidSmallIcon) {
          logNotificationError(
            'Android notification icon "${RutioNotificationChannel.androidSmallIcon}" '
            'was unavailable. Using fallback "$icon".',
          );
        }
        return;
      } on PlatformException catch (error, stackTrace) {
        final isInvalidIcon = error.code == 'invalid_icon';
        final isLastAttempt = index == androidIcons.length - 1;

        if (!isInvalidIcon || isLastAttempt) {
          rethrow;
        }

        logNotificationError(
          'Android notification icon "$icon" was not available. '
          'Retrying with "${androidIcons[index + 1]}".',
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> syncPhaseOne({
    required UserStateStore store,
    JsonMap? previousState,
    bool recordAppOpen = false,
  }) async {
    if (!await _ensureInitialized()) return;

    final currentState = mapCast(store.state);
    if (currentState.isEmpty) return;

    final preferences = NotificationPreferences(store);
    if (recordAppOpen) {
      await preferences.recordAppOpen(DateTime.now());
    }

    final snapshot = preferences.snapshot;
    final permissionStatus = await checkPermissionStatus();
    if (!permissionStatus.isAuthorized) {
      logNotification(
        'Skipping notification sync because permission is ${permissionStatus.status.name}',
      );
      return;
    }

    final previousHabitIds = previousState == null
        ? const <String>[]
        : NotificationRules.activeHabitIds(previousState);
    final currentHabitIds = NotificationRules.activeHabitIds(currentState);
    final removedHabitIds = previousHabitIds
        .where((habitId) => !currentHabitIds.contains(habitId))
        .toList(growable: false);

    if (!snapshot.notificationsEnabled) {
      logNotification(
          'Notifications disabled in preferences. Cancelling scheduled items.');
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
    logNotification(
      'Notification sync complete. habits=${currentHabitIds.length} '
      'removed=${removedHabitIds.length}',
    );
  }

  Future<void> scheduleHabitDailyReminder({
    required String habitId,
    required int hour,
    required int minute,
    String title = 'Rutio',
    required String body,
  }) async {
    if (!await _ensureInitialized()) return;
    try {
      await _scheduler.scheduleDaily(
        id: RutioNotificationIds.habitReminder(habitId),
        copy: NotificationCopy(title: title, body: body),
        time: NotificationTime(hour: hour, minute: minute),
        payload: RutioNotificationPayloads.habitReminder(habitId),
      );
    } catch (error, stackTrace) {
      logNotificationError(
        'Schedule habit reminder failed for $habitId: $error',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> cancelHabitDailyReminder(String habitId) async {
    if (!await _ensureInitialized()) return;
    try {
      await _scheduler.cancelHabitReminder(habitId);
    } catch (error, stackTrace) {
      logNotificationError(
        'Cancel habit reminder failed for $habitId: $error',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> scheduleDailyMotivation({
    required int hour,
    required int minute,
    String title = 'Rutio',
    String body = 'Hoy es un buen dia para mantener tu ritmo.',
  }) async {
    if (!await _ensureInitialized()) return;
    try {
      await _scheduler.scheduleDaily(
        id: RutioNotificationIds.dailyMotivation,
        copy: NotificationCopy(title: title, body: body),
        time: NotificationTime(hour: hour, minute: minute),
        payload: RutioNotificationPayloads.dailyMotivation,
      );
    } catch (error, stackTrace) {
      logNotificationError(
        'Schedule daily motivation failed: $error',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> cancelDailyMotivation() async {
    if (!await _ensureInitialized()) return;
    try {
      await _scheduler.cancel(RutioNotificationIds.dailyMotivation);
    } catch (error, stackTrace) {
      logNotificationError(
        'Cancel daily motivation failed: $error',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!await _ensureInitialized()) return;
    try {
      await _scheduler.cancelAll();
      logNotification('All notifications cancelled successfully.');
    } catch (error, stackTrace) {
      logNotificationError(
        'Cancel all notifications failed: $error',
        stackTrace: stackTrace,
      );
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

  Future<void> _runOneTimeProductionCleanup() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_productionCleanupKey) == true) {
      return;
    }

    try {
      logNotification(
        'Running one-time notification cleanup for production release.',
      );
      await _scheduler.cancelAll();
      if (Platform.isAndroid) {
        await _platformNotificationChannel
            .invokeMethod<void>('clearScheduledNotificationsCache');
      }
    } catch (error, stackTrace) {
      logNotificationError(
        'One-time notification cleanup failed: $error',
        stackTrace: stackTrace,
      );
    } finally {
      await prefs.setBool(_productionCleanupKey, true);
    }
  }
}
