import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/services/notification_models.dart';
import 'package:rutio/services/notification_scheduler.dart';
import 'package:rutio/services/notification_service.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('allows one streak milestone per local day and persists its marker',
      () async {
    final calls = <int>[];
    final service = NotificationService.forTesting(
      _RecordingScheduler(calls),
    );
    final repo = UserStateRepository(storage: UserStateStorage())
      ..setActiveUserScope('notification-test');
    final store = await _store(repo);
    final firstDay = DateTime(2026, 8, 31, 10);

    await service.triggerCelebrationsForTesting(
      store: store,
      previousState: _state(
        habitId: 'a',
        streak: 6,
        doneToday: false,
        day: firstDay,
      ),
      currentState: _state(
        habitId: 'a',
        streak: 7,
        doneToday: true,
        day: firstDay,
      ),
      now: firstDay,
    );
    await service.triggerCelebrationsForTesting(
      store: store,
      previousState: _state(
        habitId: 'b',
        streak: 6,
        doneToday: false,
        day: firstDay,
      ),
      currentState: _state(
        habitId: 'b',
        streak: 7,
        doneToday: true,
        day: firstDay,
      ),
      now: firstDay,
    );
    await service.triggerCelebrationsForTesting(
      store: store,
      previousState: _state(
        habitId: 'c',
        streak: 13,
        doneToday: false,
        day: firstDay,
      ),
      currentState: _state(
        habitId: 'c',
        streak: 14,
        doneToday: true,
        day: firstDay,
      ),
      now: firstDay,
    );

    expect(calls, hasLength(1));
    expect(
        store.notificationMetadata['streakMilestoneDailySent'],
        <String, dynamic>{
          'dateKey': '2026-08-31',
          'habitId': 'a',
          'milestone': 7,
          'sentAt': '2026-08-31T08:00:00.000Z',
        });
    expect(
        store.notificationMetadata['celebrationMilestones'], <String, dynamic>{
      'a:7': '2026-08-31',
    });

    final reopened = UserStateStore(
      repo,
      journalEntrySyncService: JournalEntrySyncService(),
    );
    await reopened.load();
    await service.triggerCelebrationsForTesting(
      store: reopened,
      previousState: _state(
        habitId: 'a',
        streak: 6,
        doneToday: false,
        day: firstDay,
      ),
      currentState: _state(
        habitId: 'a',
        streak: 7,
        doneToday: true,
        day: firstDay,
      ),
      now: firstDay,
    );
    expect(calls, hasLength(1));

    await service.triggerCelebrationsForTesting(
      store: store,
      previousState: _state(
        habitId: 'd',
        streak: 6,
        doneToday: false,
        day: DateTime(2026, 9, 1, 10),
      ),
      currentState: _state(
        habitId: 'd',
        streak: 7,
        doneToday: true,
        day: DateTime(2026, 9, 1, 10),
      ),
      now: DateTime(2026, 9, 1, 10),
    );
    expect(calls, hasLength(2));
  });
}

class _RecordingScheduler extends NotificationScheduler {
  _RecordingScheduler(this.calls) : super(FlutterLocalNotificationsPlugin());

  final List<int> calls;

  @override
  Future<void> showNow({
    required int id,
    required NotificationCopy copy,
    required String payload,
  }) async {
    calls.add(id);
  }
}

Future<UserStateStore> _store(UserStateRepository repo) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(<String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'notification-test',
      'settings': <String, dynamic>{
        'notifications': <String, dynamic>{
          'enabled': true,
          'streakCelebration': true,
          'metadata': <String, dynamic>{},
        },
      },
      'activeHabits': <dynamic>[],
      'history': <String, dynamic>{},
    },
  });
  return store;
}

Map<String, dynamic> _state({
  required String habitId,
  required int streak,
  required bool doneToday,
  required DateTime day,
}) {
  final completions = <String, dynamic>{};
  for (var index = 1; index < streak; index++) {
    final date = day.subtract(Duration(days: index));
    completions['${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}'] = <String, dynamic>{
      habitId: true
    };
  }
  if (doneToday) {
    completions['${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}'] = <String, dynamic>{
      habitId: true
    };
  }
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'activeHabits': <dynamic>[
        <String, dynamic>{
          'id': habitId,
          'name': habitId,
          'doneToday': doneToday,
          'schedule': <String, dynamic>{'type': 'daily'},
        },
      ],
      'history': <String, dynamic>{'habitCompletions': completions},
    },
  };
}
