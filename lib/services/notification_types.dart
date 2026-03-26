import 'package:flutter/foundation.dart';

enum RutioNotificationType {
  habitReminder,
  dayClosure,
  streakRisk,
  streakCelebration,
  inactivityReengagement,
  dailyMotivation,
}

class RutioNotificationChannel {
  static const String id = 'rutio_phase1_notifications_v1';
  static const String name = 'Rutio Notifications';
  static const String description =
      'Habit reminders, streaks and phase 1 local notifications';
  static const String androidSmallIcon = 'ic_notification';
  static const String androidFallbackSmallIcon = 'ic_notification_fallback';
}

class RutioNotificationIds {
  static const int dayClosure = 51001;
  static const int streakRisk = 51002;
  static const int inactivityReengagement = 51003;
  static const int dailyMotivation = 90001;

  static int habitReminder(String habitId) {
    final hash = habitId.hashCode & 0x7fffffff;
    return 10000 + (hash % 40000);
  }

  static int streakCelebration(String habitId, int milestone) {
    final hash = habitId.hashCode & 0x7fffffff;
    return 60000 + ((hash + milestone) % 10000);
  }
}

class RutioNotificationPayloads {
  static const String dayClosure = 'phase1:day_closure';
  static const String streakRisk = 'phase1:streak_risk';
  static const String inactivityReengagement = 'phase1:inactivity_3d';
  static const String dailyMotivation = 'legacy:daily_motivation';

  static String habitReminder(String habitId) => 'habit:$habitId';

  static String streakCelebration(String habitId, int milestone) =>
      'phase1:streak_celebration:$habitId:$milestone';
}

class RutioNotificationMilestones {
  static const List<int> streakCelebrations = <int>[1, 3, 7, 14, 30];
}

typedef JsonMap = Map<String, dynamic>;

JsonMap mapCast(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

List<JsonMap> habitListCast(dynamic value) {
  if (value is! List) return const <JsonMap>[];
  return value
      .whereType<Map>()
      .map((habit) => habit.cast<String, dynamic>())
      .toList(growable: false);
}

void logNotification(String message) {
  if (kDebugMode) {
    debugPrint('[NotificationService] $message');
  }
}

void logNotificationError(
  String message, {
  StackTrace? stackTrace,
}) {
  debugPrint('[NotificationService] ERROR: $message');
  if (stackTrace != null) {
    debugPrintStack(
      label: '[NotificationService]',
      stackTrace: stackTrace,
    );
  }
}
