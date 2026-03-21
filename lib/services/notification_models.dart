import 'notification_types.dart';

class NotificationTime {
  const NotificationTime({
    required this.hour,
    required this.minute,
  });

  final int hour;
  final int minute;

  static const NotificationTime defaultDayClosure = NotificationTime(
    hour: 21,
    minute: 0,
  );

  static NotificationTime parse(
    String? raw, {
    NotificationTime fallback = defaultDayClosure,
  }) {
    if (raw == null || raw.trim().isEmpty) return fallback;

    final parts = raw.split(':');
    final hour = int.tryParse(parts.first);
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : fallback.minute;

    if (hour == null || hour < 0 || hour > 23) return fallback;
    if (minute == null || minute < 0 || minute > 59) return fallback;

    return NotificationTime(hour: hour, minute: minute);
  }

  String formatHhMm() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime onDate(DateTime date) =>
      DateTime(date.year, date.month, date.day, hour, minute);
}

class NotificationCopy {
  const NotificationCopy({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

class ScheduledNotificationRequest {
  const ScheduledNotificationRequest({
    required this.id,
    required this.type,
    required this.copy,
    required this.scheduledFor,
    required this.payload,
    this.repeatDaily = false,
  });

  final int id;
  final RutioNotificationType type;
  final NotificationCopy copy;
  final DateTime scheduledFor;
  final String payload;
  final bool repeatDaily;
}

class HabitReminderDefinition {
  const HabitReminderDefinition({
    required this.habitId,
    required this.habitName,
    required this.time,
  });

  final String habitId;
  final String habitName;
  final NotificationTime time;
}

class NotificationPreferencesSnapshot {
  const NotificationPreferencesSnapshot({
    required this.notificationsEnabled,
    required this.habitRemindersEnabled,
    required this.dayClosureEnabled,
    required this.streakRiskEnabled,
    required this.streakCelebrationEnabled,
    required this.inactivityReengagementEnabled,
    required this.dayClosureTime,
    required this.dailyMotivationEnabled,
    required this.dailyMotivationTime,
    required this.lastAppOpenAt,
    required this.metadata,
  });

  final bool notificationsEnabled;
  final bool habitRemindersEnabled;
  final bool dayClosureEnabled;
  final bool streakRiskEnabled;
  final bool streakCelebrationEnabled;
  final bool inactivityReengagementEnabled;
  final NotificationTime dayClosureTime;
  final bool dailyMotivationEnabled;
  final NotificationTime dailyMotivationTime;
  final DateTime? lastAppOpenAt;
  final JsonMap metadata;
}

class NotificationStreakRiskCandidate {
  const NotificationStreakRiskCandidate({
    required this.habitId,
    required this.habitName,
    required this.streakLength,
  });

  final String habitId;
  final String habitName;
  final int streakLength;
}

class NotificationCelebrationEvent {
  const NotificationCelebrationEvent({
    required this.habitId,
    required this.habitName,
    required this.milestone,
    required this.currentStreak,
    required this.metadataKey,
  });

  final String habitId;
  final String habitName;
  final int milestone;
  final int currentStreak;
  final String metadataKey;
}
