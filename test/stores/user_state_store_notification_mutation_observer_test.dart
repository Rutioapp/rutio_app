import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore notification mutation observer', () {
    test('forwards habit creation and notification setting changes', () async {
      final observer = _RecordingObserver();
      final store = await _seedStore(observer: observer);

      await store.addHabitFromCatalog(
        habitDef: <String, dynamic>{
          'id': 'habit-1',
          'name': 'Leer',
          'emoji': '📚',
          'type': 'check',
          'metric': <String, dynamic>{'unit': null},
        },
        familyId: 'mind',
      );
      await store.setNotificationsEnabled(false);

      expect(observer.events, <String>[
        'created:habit-1',
        'preferences',
      ]);
    });
  });
}

class _RecordingObserver extends UserStateNotificationMutationObserver {
  final List<String> events = <String>[];

  @override
  void onHabitCreated(String habitId) {
    events.add('created:$habitId');
  }

  @override
  void onNotificationPreferencesChanged() {
    events.add('preferences');
  }
}

Future<UserStateStore> _seedStore({
  required UserStateNotificationMutationObserver observer,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('user-123');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
    notificationMutationObserver: observer,
  );
  await store.save(_baseState());
  return store;
}

Map<String, dynamic> _baseState() {
  final now = DateTime(2026, 8, 29);
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'user-123',
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': now.toUtc().toIso8601String(),
        'activeViewDateKey': '2026-08-29',
        'diaryRewardAppliedDateKeys': <dynamic>[],
      },
      'settings': <String, dynamic>{
        'locale': <String, dynamic>{'languageCode': 'es'},
        'notifications': <String, dynamic>{
          'enabled': true,
          'habitReminders': true,
        },
      },
      'progression': <String, dynamic>{'level': 1, 'xp': 0, 'prestige': 0},
      'wallet': <String, dynamic>{'coins': 0},
      'inventory': <String, dynamic>{'items': <dynamic>[]},
      'profile': <String, dynamic>{
        'equipped': <String, dynamic>{
          'avatar_skin': null,
          'aura': null,
          'badge': null,
          'title': null,
          'animation': null,
        },
        'badges': <String, dynamic>{'owned': <dynamic>[], 'shown': null},
        'achievements': <String, dynamic>{
          'unlocked': <dynamic>[],
          'featured': <dynamic>[],
          'rewardAppliedAchievementIds': <dynamic>[],
          'progress': <String, dynamic>{},
        },
      },
      'activeHabits': <dynamic>[],
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitLogs': <String, dynamic>{},
      },
      'daily': <String, dynamic>{
        'habitsCompletedToday': <String, dynamic>{},
      },
    },
  };
}
