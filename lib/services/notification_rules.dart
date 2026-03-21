import 'notification_copy.dart';
import 'notification_models.dart';
import 'notification_types.dart';

class NotificationRules {
  static List<String> activeHabitIds(JsonMap root) {
    return _activeHabits(root)
        .map((habit) => (habit['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  static List<HabitReminderDefinition> buildHabitReminders({
    required JsonMap root,
    required NotificationPreferencesSnapshot preferences,
  }) {
    if (!preferences.notificationsEnabled ||
        !preferences.habitRemindersEnabled) {
      return const <HabitReminderDefinition>[];
    }

    return _activeHabits(root)
        .where((habit) => !_isArchived(habit))
        .where((habit) =>
            habit['reminderEnabled'] == true ||
            habit['remindersEnabled'] == true)
        .map((habit) {
          final id = (habit['id'] ?? '').toString();
          if (id.isEmpty) return null;

          final time = NotificationTime.parse(
            habit['reminderTime']?.toString(),
            fallback: const NotificationTime(hour: 20, minute: 0),
          );

          return HabitReminderDefinition(
            habitId: id,
            habitName: (habit['name'] ?? habit['title'] ?? '').toString(),
            time: time,
          );
        })
        .whereType<HabitReminderDefinition>()
        .toList(growable: false);
  }

  static ScheduledNotificationRequest? buildDayClosureNotification({
    required JsonMap root,
    required NotificationPreferencesSnapshot preferences,
    required DateTime now,
  }) {
    if (!preferences.notificationsEnabled || !preferences.dayClosureEnabled) {
      return null;
    }

    final pendingHabits = _pendingHabitsToday(root, now);
    if (pendingHabits.isEmpty) return null;

    final scheduledFor = preferences.dayClosureTime.onDate(now);
    if (!scheduledFor.isAfter(now)) return null;

    return ScheduledNotificationRequest(
      id: RutioNotificationIds.dayClosure,
      type: RutioNotificationType.dayClosure,
      copy: NotificationCopyLibrary.dayClosure(
        pendingHabits: pendingHabits.length,
      ),
      scheduledFor: scheduledFor,
      payload: RutioNotificationPayloads.dayClosure,
    );
  }

  static ScheduledNotificationRequest? buildStreakRiskNotification({
    required JsonMap root,
    required NotificationPreferencesSnapshot preferences,
    required DateTime now,
  }) {
    if (!preferences.notificationsEnabled || !preferences.streakRiskEnabled) {
      return null;
    }

    final candidate = _bestStreakRiskCandidate(root, now);
    if (candidate == null) return null;

    final dayClosureAt = preferences.dayClosureTime.onDate(now);
    if (!dayClosureAt.isAfter(now)) return null;

    var scheduledFor = dayClosureAt.subtract(const Duration(minutes: 90));
    final fallback = DateTime(now.year, now.month, now.day, 19, 30);

    if (scheduledFor.hour < 18) {
      scheduledFor = fallback;
    }
    if (!scheduledFor.isBefore(dayClosureAt)) {
      scheduledFor = dayClosureAt.subtract(const Duration(minutes: 45));
    }
    if (!scheduledFor.isAfter(now)) return null;

    return ScheduledNotificationRequest(
      id: RutioNotificationIds.streakRisk,
      type: RutioNotificationType.streakRisk,
      copy: NotificationCopyLibrary.streakRisk(
        habitName: candidate.habitName,
        streakLength: candidate.streakLength,
      ),
      scheduledFor: scheduledFor,
      payload: RutioNotificationPayloads.streakRisk,
    );
  }

  static ScheduledNotificationRequest? buildInactivityNotification({
    required NotificationPreferencesSnapshot preferences,
  }) {
    if (!preferences.notificationsEnabled ||
        !preferences.inactivityReengagementEnabled ||
        preferences.lastAppOpenAt == null) {
      return null;
    }

    final scheduledFor =
        preferences.lastAppOpenAt!.add(const Duration(days: 3));

    return ScheduledNotificationRequest(
      id: RutioNotificationIds.inactivityReengagement,
      type: RutioNotificationType.inactivityReengagement,
      copy: NotificationCopyLibrary.inactivityReengagement(),
      scheduledFor: scheduledFor,
      payload: RutioNotificationPayloads.inactivityReengagement,
    );
  }

  static List<NotificationCelebrationEvent> detectCelebrations({
    required JsonMap? previousState,
    required JsonMap currentState,
    required NotificationPreferencesSnapshot preferences,
    required DateTime now,
  }) {
    if (!preferences.notificationsEnabled ||
        !preferences.streakCelebrationEnabled ||
        previousState == null) {
      return const <NotificationCelebrationEvent>[];
    }

    final previousHabits = <String, JsonMap>{
      for (final habit in _activeHabits(previousState))
        (habit['id'] ?? '').toString(): habit,
    };

    final events = <NotificationCelebrationEvent>[];

    for (final habit in _activeHabits(currentState)) {
      final habitId = (habit['id'] ?? '').toString();
      if (habitId.isEmpty || _isArchived(habit)) continue;

      final wasDone = previousHabits[habitId]?['doneToday'] == true;
      final isDone = habit['doneToday'] == true;
      if (wasDone || !isDone) continue;
      if (!_isScheduledForDate(habit, now)) continue;

      final streak = _streakThroughDate(currentState, habit, now);
      if (!RutioNotificationMilestones.streakCelebrations.contains(streak)) {
        continue;
      }

      events.add(
        NotificationCelebrationEvent(
          habitId: habitId,
          habitName: (habit['name'] ?? habit['title'] ?? '').toString(),
          milestone: streak,
          currentStreak: streak,
          metadataKey: '$habitId:$streak',
        ),
      );
    }

    return events;
  }

  static List<JsonMap> _pendingHabitsToday(JsonMap root, DateTime now) {
    return _activeHabits(root)
        .where((habit) => !_isArchived(habit))
        .where((habit) => _isScheduledForDate(habit, now))
        .where((habit) => !_isDoneOnDate(root, habit, now))
        .where((habit) => !_isSkippedOnDate(root, habit, now))
        .toList(growable: false);
  }

  static NotificationStreakRiskCandidate? _bestStreakRiskCandidate(
    JsonMap root,
    DateTime now,
  ) {
    NotificationStreakRiskCandidate? best;

    for (final habit in _activeHabits(root)) {
      if (_isArchived(habit) || !_isScheduledForDate(habit, now)) continue;
      if (_isDoneOnDate(root, habit, now) ||
          _isSkippedOnDate(root, habit, now)) {
        continue;
      }

      final streak = _streakBeforeDate(root, habit, now);
      if (streak < 3) continue;

      final candidate = NotificationStreakRiskCandidate(
        habitId: (habit['id'] ?? '').toString(),
        habitName: (habit['name'] ?? habit['title'] ?? '').toString(),
        streakLength: streak,
      );

      if (best == null || candidate.streakLength > best.streakLength) {
        best = candidate;
      }
    }

    return best;
  }

  static int _streakThroughDate(JsonMap root, JsonMap habit, DateTime date) {
    var streak = 0;
    var cursor = _dateOnly(date);
    var checkedScheduledDays = 0;

    while (checkedScheduledDays < 365) {
      if (_isScheduledForDate(habit, cursor)) {
        checkedScheduledDays += 1;
        if (_isDoneOnDate(root, habit, cursor)) {
          streak += 1;
        } else {
          break;
        }
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  static int _streakBeforeDate(JsonMap root, JsonMap habit, DateTime date) {
    return _streakThroughDate(
      root,
      habit,
      _dateOnly(date).subtract(const Duration(days: 1)),
    );
  }

  static bool _isDoneOnDate(JsonMap root, JsonMap habit, DateTime date) {
    final habitId = (habit['id'] ?? '').toString();
    if (habitId.isEmpty) return false;

    if (_isSameDay(date, DateTime.now())) {
      final todayHabit = _findHabitById(root, habitId) ?? habit;
      return todayHabit['doneToday'] == true &&
          todayHabit['skippedToday'] != true;
    }

    final history = mapCast(_userState(root)['history']);
    final completions = mapCast(history['habitCompletions']);
    final countValues = mapCast(history['habitCountValues']);
    final skipped = mapCast(history['habitSkips']);
    final dayKey = _dateKey(date);

    final doneMap = mapCast(completions[dayKey]);
    final valueMap = mapCast(countValues[dayKey]);
    final skipMap = mapCast(skipped[dayKey]);
    if (skipMap[habitId] == true) return false;

    final type = (habit['type'] ?? 'check').toString();
    if (type == 'count') {
      final currentValue = (valueMap[habitId] as num?)?.toDouble() ?? 0;
      final target = (habit['target'] as num?)?.toDouble() ?? 1;
      return currentValue >= target || doneMap[habitId] == true;
    }

    return doneMap[habitId] == true;
  }

  static bool _isSkippedOnDate(JsonMap root, JsonMap habit, DateTime date) {
    final habitId = (habit['id'] ?? '').toString();
    if (habitId.isEmpty) return false;

    if (_isSameDay(date, DateTime.now())) {
      final todayHabit = _findHabitById(root, habitId) ?? habit;
      return todayHabit['skippedToday'] == true;
    }

    final history = mapCast(_userState(root)['history']);
    final skips = mapCast(history['habitSkips']);
    final daySkips = mapCast(skips[_dateKey(date)]);
    return daySkips[habitId] == true;
  }

  static JsonMap? _findHabitById(JsonMap root, String habitId) {
    for (final habit in _activeHabits(root)) {
      if ((habit['id'] ?? '').toString() == habitId) {
        return habit;
      }
    }
    return null;
  }

  static List<JsonMap> _activeHabits(JsonMap root) {
    return habitListCast(_userState(root)['activeHabits']);
  }

  static JsonMap _userState(JsonMap root) => mapCast(root['userState']);

  static bool _isArchived(JsonMap habit) =>
      habit['archived'] == true || habit['isArchived'] == true;

  static bool _isScheduledForDate(JsonMap habit, DateTime date) {
    final schedule = mapCast(habit['schedule']);
    final type = (schedule['type'] ?? 'daily').toString();

    if (type == 'once') {
      return (schedule['date'] ?? '').toString() == _dateKey(date);
    }

    if (type == 'weekly') {
      final weekdays = (schedule['weekdays'] is List)
          ? (schedule['weekdays'] as List)
              .whereType<num>()
              .map((value) => value.toInt())
              .toList(growable: false)
          : const <int>[];
      return weekdays.contains(date.weekday);
    }

    return true;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
