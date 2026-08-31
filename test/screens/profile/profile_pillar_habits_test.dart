import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/models/remote/remote_profile.dart';
import 'package:rutio/data/repositories/profile_repository.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/profile/widgets/profile_pillar_habits_section.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Profile pillar habits section shows status badges and opens', (
    tester,
  ) async {
    var opened = false;

    await tester.pumpWidget(
      _materialApp(
        child: ProfilePillarHabitsSection(
          accent: const Color(0xFF6C5CE7),
          pillarHabits: const <ProfilePillarHabitCardData>[
            ProfilePillarHabitCardData(
              id: 'habit-1',
              name: 'Leer',
              emoji: '📚',
              currentStreakDays: 12,
            ),
            ProfilePillarHabitCardData(
              id: 'habit-2',
              name: 'Correr',
              emoji: '🏃',
              currentStreakDays: 5,
              isArchived: true,
            ),
            ProfilePillarHabitCardData(
              id: 'habit-3',
              name: 'Agua',
              emoji: '💧',
              currentStreakDays: 3,
              isPaused: true,
            ),
          ],
          onTap: () {
            opened = true;
          },
        ),
      ),
    );

    expect(find.text('Pillar habits'), findsOneWidget);
    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('pillar habit picker blocks the fourth selection',
      (tester) async {
    final repo = _RecordingProfileRepository();
    final store = await _createStore(
      activeHabits: _habitList(),
      profileRepository: repo,
    );
    addTearDown(store.dispose);
    final savedSelections = <String>[];

    await tester.pumpWidget(
      _materialApp(
        store: store,
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showPillarHabitPickerSheet(
                  context,
                  store: store,
                  selectedIds: const <String>[],
                  onSave: (selectedIds) {
                    savedSelections
                      ..clear()
                      ..addAll(selectedIds);
                  },
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Choose pillar habits'), findsOneWidget);

    await tester.tap(find.text('Habit 3'));
    await tester.pump();
    await tester.tap(find.text('Habit 2'));
    await tester.pump();
    await tester.tap(find.text('Habit 1'));
    await tester.pump();

    expect(find.text('3 of 3 selected'), findsOneWidget);

    await tester.tap(find.text('Habit 4'));
    await tester.pump();

    expect(find.text('3 of 3 selected'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(savedSelections, <String>['habit-3', 'habit-2', 'habit-1']);
  });

  test('setPillarHabitIds removes duplicates, keeps order and limits to 3',
      () async {
    final repo = _RecordingProfileRepository();
    final store = await _createStore(
      activeHabits: _habitList(),
      profileRepository: repo,
    );
    addTearDown(store.dispose);

    await store.setPillarHabitIds(
      <String>['habit-3', 'habit-2', 'habit-3', 'habit-1', 'habit-4'],
    );
    await Future<void>.delayed(Duration.zero);

    expect(store.pillarHabitIds, <String>['habit-3', 'habit-2', 'habit-1']);
    expect(repo.lastUpdatedIds, <String>['habit-3', 'habit-2', 'habit-1']);
    expect(
      (store.state?['userState'] as Map?)?['profile'],
      isA<Map>(),
    );
    final profile =
        (store.state?['userState'] as Map?)?['profile'] as Map<String, dynamic>;
    expect(
        profile['pillarHabitIds'], <String>['habit-3', 'habit-2', 'habit-1']);
  });

  test('deleteHabitById removes deleted pillar habit references', () async {
    final repo = _RecordingProfileRepository();
    final store = await _createStore(
      activeHabits: _habitList(),
      profileRepository: repo,
      pillarHabitIds: <String>['habit-1', 'habit-2', 'habit-3'],
    );
    addTearDown(store.dispose);

    await store.deleteHabitById('habit-2');
    await Future<void>.delayed(Duration.zero);

    expect(store.pillarHabitIds, <String>['habit-1', 'habit-3']);
    expect(repo.lastUpdatedIds, <String>['habit-1', 'habit-3']);
  });

  test('applySupabaseIdentity hydrates pillar habits from remote profile',
      () async {
    final repo = _RecordingProfileRepository(
      fetchResult: RepositoryResult<RemoteProfile?>.success(
        data: RemoteProfile(
          id: 'profile-pillars-user',
          onboardingStatus: OnboardingStatus.completed,
          onboardingVersion: 1,
          onboardingCompletedAt: DateTime.utc(2026, 8, 30),
          pillarHabitIds: <String>['habit-3', 'habit-2', 'habit-3', 'missing'],
        ),
      ),
    );
    final store = await _createStore(
      activeHabits: _habitList(),
      profileRepository: repo,
    );
    addTearDown(store.dispose);

    await store.applySupabaseIdentity(
      userId: 'profile-pillars-user',
      email: 'pillars@example.com',
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(store.pillarHabitIds, <String>['habit-3', 'habit-2']);
  });
}

Widget _materialApp({
  UserStateStore? store,
  required Widget child,
}) {
  final app = MaterialApp(
    theme: ThemeData(
      useMaterial3: false,
      splashFactory: NoSplash.splashFactory,
    ),
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  if (store == null) return app;

  return ChangeNotifierProvider<UserStateStore>.value(
    value: store,
    child: app,
  );
}

Future<UserStateStore> _createStore({
  required List<Map<String, dynamic>> activeHabits,
  required ProfileRepository profileRepository,
  List<String> pillarHabitIds = const <String>[],
}) async {
  final repository = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('profile-pillars-user');
  final store = UserStateStore(
    repository,
    journalEntrySyncService: JournalEntrySyncService(),
    profileRepository: profileRepository,
  );

  await store.save(<String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'profile-pillars-user',
      'profile': <String, dynamic>{
        'displayName': 'Alex',
        'pillarHabitIds': pillarHabitIds,
      },
      'progression': <String, dynamic>{'xp': 0},
      'activeHabits': activeHabits,
      'habits': activeHabits,
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitCountValues': <String, dynamic>{},
      },
      'wallet': <String, dynamic>{'coins': 0},
      'featuredAchievementIds': <String>[],
      'unlockedAchievements': <Map<String, dynamic>>[],
      'unlockedAchievementRecords': <Map<String, dynamic>>[],
      'achievementMetricSnapshots': <String, dynamic>{},
    },
  });
  await store.switchLocalScope(
    userId: 'profile-pillars-user',
    forceReload: true,
  );
  return store;
}

List<Map<String, dynamic>> _habitList() {
  return <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'habit-1',
      'name': 'Habit 1',
      'emoji': '1️⃣',
      'type': 'check',
      'schedule': <String, dynamic>{'type': 'daily'},
    },
    <String, dynamic>{
      'id': 'habit-2',
      'name': 'Habit 2',
      'emoji': '2️⃣',
      'type': 'check',
      'schedule': <String, dynamic>{'type': 'daily'},
    },
    <String, dynamic>{
      'id': 'habit-3',
      'name': 'Habit 3',
      'emoji': '3️⃣',
      'type': 'check',
      'schedule': <String, dynamic>{'type': 'daily'},
    },
    <String, dynamic>{
      'id': 'habit-4',
      'name': 'Habit 4',
      'emoji': '4️⃣',
      'type': 'check',
      'schedule': <String, dynamic>{'type': 'daily'},
    },
  ];
}

class _RecordingProfileRepository implements ProfileRepository {
  _RecordingProfileRepository({RepositoryResult<RemoteProfile?>? fetchResult})
      : _fetchResult = fetchResult ??
            const RepositoryResult<RemoteProfile?>.success(data: null);

  final RepositoryResult<RemoteProfile?> _fetchResult;
  List<String>? lastUpdatedIds;

  @override
  Future<RepositoryResult<RemoteProfile?>> fetchCurrentProfile() async {
    return _fetchResult;
  }

  @override
  Future<RepositoryResult<RemoteProfile>> updatePillarHabitIds(
    List<String> habitIds,
  ) async {
    lastUpdatedIds = List<String>.from(habitIds);
    return RepositoryResult<RemoteProfile>.success(
      data: RemoteProfile(
        id: 'profile-pillars-user',
        onboardingStatus: OnboardingStatus.completed,
        onboardingVersion: 1,
        onboardingCompletedAt: DateTime.utc(2026, 8, 30),
        pillarHabitIds: habitIds,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
