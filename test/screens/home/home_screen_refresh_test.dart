import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Provider.debugCheckInvalidValueType = null;

  testWidgets('home screen open does not start habits sync automatically',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FakeHomeStore();

    await tester.pumpWidget(_app(store: store));
    await tester.pumpAndSettle();

    expect(store.syncHabitsFromRemoteBestEffortCalls, 0);
    expect(find.text('Drink Water'), findsOneWidget);
  });

  testWidgets('pull-to-refresh triggers habits remote sync manually only',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FakeHomeStore();

    await tester.pumpWidget(_app(store: store));
    await tester.pumpAndSettle();

    expect(store.syncHabitsFromRemoteBestEffortCalls, 0);
    expect(find.text('Drink Water'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(store.syncHabitsFromRemoteBestEffortCalls, 1);
    expect(find.text('Drink Water'), findsOneWidget);
    expect(store.pendingAchievementUnlockCount, 0);
    expect(store.pendingLevelCelebrationCount, 0);
  });

  testWidgets('pull-to-refresh failure keeps local habits intact', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FakeHomeStore(
      syncHabitsFromRemoteBestEffortError: StateError('offline'),
    );

    await tester.pumpWidget(_app(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Drink Water'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(store.syncHabitsFromRemoteBestEffortCalls, 1);
    expect(find.text('Drink Water'), findsOneWidget);
  });
}

Widget _app({required UserStateStore store}) {
  return ChangeNotifierProvider<UserStateStore>.value(
    value: store,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MediaQuery(
        data: MediaQueryData(size: Size(430, 932)),
        child: HomeScreen(),
      ),
    ),
  );
}

class _FakeHomeStore extends ChangeNotifier implements UserStateStore {
  _FakeHomeStore({
    this.syncHabitsFromRemoteBestEffortError,
  });

  final Object? syncHabitsFromRemoteBestEffortError;
  int syncHabitsFromRemoteBestEffortCalls = 0;

  @override
  bool get isLoading => false;

  @override
  Object? get error => null;

  @override
  Map<String, dynamic> get state => <String, dynamic>{
        'userState': <String, dynamic>{
          'profile': <String, dynamic>{
            'displayName': 'Alex',
          },
          'meta': <String, dynamic>{
            'activeViewDateKey': '2026-06-22',
          },
          'progression': <String, dynamic>{
            'level': 1,
            'xp': 0,
            'prestige': 0,
          },
          'wallet': <String, dynamic>{
            'coins': 0,
          },
          'history': <String, dynamic>{
            'habitCompletions': <String, dynamic>{},
            'habitCountValues': <String, dynamic>{},
            'habitSkips': <String, dynamic>{},
          },
          'activeHabits': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'habit-1',
              'name': 'Drink Water',
              'type': 'check',
              'doneToday': false,
              'skippedToday': false,
              'archived': false,
              'createdAt': '2026-06-20T09:00:00.000Z',
              'schedule': <String, dynamic>{
                'type': 'daily',
              },
            },
          ],
        },
      };

  @override
  String? get displayName => 'Alex';

  @override
  String? get avatarUrl => null;

  @override
  int get pendingAchievementUnlockCount => 0;

  @override
  int get pendingLevelCelebrationCount => 0;

  @override
  Future<void> setActiveViewDate(DateTime date) async {}

  @override
  Future<void> syncHabitsFromRemoteBestEffort() async {
    syncHabitsFromRemoteBestEffortCalls += 1;
    if (syncHabitsFromRemoteBestEffortError != null) {
      throw syncHabitsFromRemoteBestEffortError!;
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
