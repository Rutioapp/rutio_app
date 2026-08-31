import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('global streak stays aligned with special:imparable', () async {
    final today = DateTime.now();
    final store = await _createStore(
      habits: [
        _habit(id: 'habit-1'),
      ],
      history: _historyWithHabitCompletions(
        <DateTime>[
          today.subtract(const Duration(days: 1)),
          today,
        ],
      ),
    );

    final snapshot = store.globalHabitStreakSnapshot;
    final achievementSnapshot =
        store.achievementMetricSnapshots['special:imparable'];

    expect(snapshot.currentStreak, 2);
    expect(snapshot.bestStreak, 2);
    expect(achievementSnapshot, isNotNull);
    expect(achievementSnapshot!.currentStreak, snapshot.currentStreak);
    expect(achievementSnapshot.bestStreak, snapshot.bestStreak);
  });

  test('global streak is zero when there is no activity', () async {
    final store = await _createStore();

    final snapshot = store.globalHabitStreakSnapshot;

    expect(snapshot.currentStreak, 0);
    expect(snapshot.bestStreak, 0);
    expect(store.achievementMetricSnapshots['special:imparable']!.currentStreak,
        0);
  });

  test('activeDaysCount deduplicates same-day habit and diary activity',
      () async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    final store = await _createStore(
      habits: [
        _habit(id: 'habit-1'),
        _habit(id: 'habit-2'),
      ],
      history: _historyWithHabitCompletions(
        <DateTime>[yesterday, today],
      ),
      diaryEntries: [
        _diaryEntry('diary-1', today, 'Today entry'),
        _diaryEntry('diary-2', twoDaysAgo, 'Earlier entry'),
        _diaryEntry('diary-3', twoDaysAgo, 'Earlier entry duplicate'),
      ],
    );

    expect(store.activeDaysCount, 3);
  });

  test('activeDaysCount is zero when there is no activity', () async {
    final store = await _createStore();

    expect(store.activeDaysCount, 0);
  });
}

Future<UserStateStore> _createStore({
  List<Map<String, dynamic>> habits = const <Map<String, dynamic>>[],
  Map<String, dynamic> history = const <String, dynamic>{},
  List<Map<String, dynamic>> diaryEntries = const <Map<String, dynamic>>[],
}) async {
  final repository = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('global-activity-user');
  final store = UserStateStore(
    repository,
    journalEntrySyncService: JournalEntrySyncService(),
  );

  await store.save(<String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'global-activity-user',
      'profile': <String, dynamic>{'displayName': 'Alex'},
      'progression': <String, dynamic>{'xp': 0},
      'activeHabits': habits,
      'habits': habits,
      'history': {
        'habitCompletions': <String, dynamic>{},
        'habitCountValues': <String, dynamic>{},
        'habitCompletionTimes': <String, dynamic>{},
        'habitSkips': <String, dynamic>{},
        ...history,
      },
      'diaryEntries': diaryEntries,
      'wallet': <String, dynamic>{'coins': 0},
      'featuredAchievementIds': <String>[],
      'unlockedAchievements': <Map<String, dynamic>>[],
      'unlockedAchievementRecords': <Map<String, dynamic>>[],
      'achievementMetricSnapshots': <String, dynamic>{},
      'meta': <String, dynamic>{},
    },
  });
  await store.switchLocalScope(
      userId: 'global-activity-user', forceReload: true);
  return store;
}

Map<String, dynamic> _historyWithHabitCompletions(List<DateTime> days) {
  final completions = <String, dynamic>{};
  final completionTimes = <String, dynamic>{};

  for (final day in days) {
    final key = _dateKey(day);
    completions[key] = <String, dynamic>{
      'habit-1': true,
    };
    completionTimes[key] = <String, dynamic>{
      'habit-1': day.millisecondsSinceEpoch,
    };
  }

  return <String, dynamic>{
    'habitCompletions': completions,
    'habitCountValues': <String, dynamic>{},
    'habitCompletionTimes': completionTimes,
    'habitSkips': <String, dynamic>{},
  };
}

Map<String, dynamic> _habit({
  required String id,
}) {
  return <String, dynamic>{
    'id': id,
    'title': id,
    'type': 'check',
    'schedule': <String, dynamic>{'type': 'daily'},
    'createdAt': '2026-01-01T00:00:00.000',
  };
}

Map<String, dynamic> _diaryEntry(
  String id,
  DateTime createdAt,
  String text,
) {
  return <String, dynamic>{
    'id': id,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'text': text,
  };
}

String _dateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return '${normalized.year.toString().padLeft(4, '0')}-'
      '${normalized.month.toString().padLeft(2, '0')}-'
      '${normalized.day.toString().padLeft(2, '0')}';
}
