import '../stores/user_state_store.dart';
import 'notification_models.dart';
import 'notification_types.dart';

class NotificationPreferences {
  NotificationPreferences(this._store);

  final UserStateStore _store;

  NotificationPreferencesSnapshot get snapshot {
    final settings = _store.notificationSettings;
    final metadata = Map<String, dynamic>.from(_store.notificationMetadata);

    return NotificationPreferencesSnapshot(
      notificationsEnabled: settings['enabled'] == true,
      habitRemindersEnabled: settings['habitReminders'] != false,
      dayClosureEnabled: settings['dayClosure'] != false,
      streakRiskEnabled: settings['streakRisk'] != false,
      streakCelebrationEnabled: settings['streakCelebration'] != false,
      inactivityReengagementEnabled:
          settings['inactivityReengagement'] != false,
      dayClosureTime: NotificationTime.parse(
        settings['dayClosureTime']?.toString(),
      ),
      dailyMotivationEnabled: settings['dailyMotivation'] == true,
      dailyMotivationTime: NotificationTime.parse(
        settings['dailyMotivationTime']?.toString(),
      ),
      lastAppOpenAt: _parseIso(metadata['lastAppOpenAt']?.toString()),
      metadata: metadata,
    );
  }

  Future<void> setMasterEnabled(bool enabled) {
    return _store
        .updateNotificationSettings(<String, dynamic>{'enabled': enabled});
  }

  Future<void> setHabitRemindersEnabled(bool enabled) {
    return _store.updateNotificationSettings(
      <String, dynamic>{'habitReminders': enabled},
    );
  }

  Future<void> setDayClosureEnabled(bool enabled) {
    return _store
        .updateNotificationSettings(<String, dynamic>{'dayClosure': enabled});
  }

  Future<void> setStreakRiskEnabled(bool enabled) {
    return _store
        .updateNotificationSettings(<String, dynamic>{'streakRisk': enabled});
  }

  Future<void> setStreakCelebrationEnabled(bool enabled) {
    return _store.updateNotificationSettings(
      <String, dynamic>{'streakCelebration': enabled},
    );
  }

  Future<void> setInactivityReengagementEnabled(bool enabled) {
    return _store.updateNotificationSettings(
      <String, dynamic>{'inactivityReengagement': enabled},
    );
  }

  Future<void> setDayClosureTime(NotificationTime time) {
    return _store.updateNotificationSettings(
      <String, dynamic>{'dayClosureTime': time.formatHhMm()},
    );
  }

  Future<void> recordAppOpen(DateTime when) {
    return _store.updateNotificationMetadata(
      <String, dynamic>{'lastAppOpenAt': when.toUtc().toIso8601String()},
    );
  }

  bool wasCelebrationSentToday(String metadataKey, DateTime now) {
    final celebrations = mapCast(snapshot.metadata['celebrationMilestones']);
    return celebrations[metadataKey] == _dateKey(now);
  }

  Future<void> markCelebrationSent(String metadataKey, DateTime when) async {
    final metadata = Map<String, dynamic>.from(_store.notificationMetadata);
    final celebrations = mapCast(metadata['celebrationMilestones']);
    final todayKey = _dateKey(when);

    if (celebrations[metadataKey] == todayKey) {
      return;
    }

    celebrations[metadataKey] = todayKey;
    metadata['celebrationMilestones'] = celebrations;
    await _store.updateNotificationMetadata(
      <String, dynamic>{'celebrationMilestones': celebrations},
    );
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static DateTime? _parseIso(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
