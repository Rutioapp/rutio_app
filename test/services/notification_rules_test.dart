import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/services/notification_models.dart';
import 'package:rutio/services/notification_rules.dart';

void main() {
  final now = DateTime(2026, 8, 31, 10);

  test('only configured streak milestones from 7 days produce candidates', () {
    for (final streak in <int>[1, 3, 6]) {
      expect(_detect(now: now, streak: streak), isEmpty);
    }
    for (final streak in <int>[7, 14, 30]) {
      expect(_detect(now: now, streak: streak), hasLength(1));
    }
  });

  test('orders a batch by completion timestamp and falls back to habit order',
      () {
    final timestamped = _detect(
      now: now,
      streak: 7,
      habitIds: <String>['late', 'early'],
      completionTimes: <String, int>{
        'late': 200,
        'early': 100,
      },
    );
    expect(
        timestamped.map((event) => event.habitId), <String>['early', 'late']);

    final fallback = _detect(
      now: now,
      streak: 7,
      habitIds: <String>['first', 'second'],
    );
    expect(fallback.map((event) => event.habitId), <String>['first', 'second']);
  });
}

List<NotificationCelebrationEvent> _detect({
  required DateTime now,
  required int streak,
  List<String> habitIds = const <String>['habit-1'],
  Map<String, int> completionTimes = const <String, int>{},
}) {
  final previousHabits = <dynamic>[];
  final currentHabits = <dynamic>[];
  final completions = <String, dynamic>{};
  for (final habitId in habitIds) {
    previousHabits.add(<String, dynamic>{
      'id': habitId,
      'name': habitId,
      'doneToday': false,
      'schedule': <String, dynamic>{'type': 'daily'},
    });
    currentHabits.add(<String, dynamic>{
      'id': habitId,
      'name': habitId,
      'doneToday': true,
      'schedule': <String, dynamic>{'type': 'daily'},
    });
  }

  final history = <String, dynamic>{
    'habitCompletions': <String, dynamic>{},
    'habitCompletionTimes': <String, dynamic>{nowKey(now): completions},
  };
  for (var index = 1; index < streak; index++) {
    final date = now.subtract(Duration(days: index));
    final dayKey = nowKey(date);
    (history['habitCompletions'] as Map<String, dynamic>)[dayKey] = {
      for (final habitId in habitIds) habitId: true,
    };
  }
  completions.addAll(completionTimes);

  return NotificationRules.detectCelebrations(
    previousState: <String, dynamic>{
      'userState': <String, dynamic>{'activeHabits': previousHabits},
    },
    currentState: <String, dynamic>{
      'userState': <String, dynamic>{
        'activeHabits': currentHabits,
        'history': history,
      },
    },
    preferences: const NotificationPreferencesSnapshot(
      notificationsEnabled: true,
      habitRemindersEnabled: true,
      dayClosureEnabled: true,
      streakRiskEnabled: true,
      streakCelebrationEnabled: true,
      inactivityReengagementEnabled: true,
      dayClosureTime: NotificationTime(hour: 21, minute: 0),
      dailyMotivationEnabled: false,
      dailyMotivationTime: NotificationTime(hour: 21, minute: 0),
      lastAppOpenAt: null,
      metadata: <String, dynamic>{},
    ),
    now: now,
  );
}

String nowKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
