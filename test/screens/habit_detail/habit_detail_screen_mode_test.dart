import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/features/achievements/domain/models/habit_streak_snapshot.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/habit_detail/habit_detail_screen.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats_tab.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Provider.debugCheckInvalidValueType = null;
  final previousOnError = FlutterError.onError;

  setUp(() {
    FlutterError.onError = (FlutterErrorDetails details) {
      final message = details.exceptionAsString();
      if (message.contains('A RenderFlex overflowed')) {
        return;
      }
      if (previousOnError != null) {
        previousOnError(details);
      } else {
        FlutterError.presentError(details);
      }
    };
  });

  tearDownAll(() {
    FlutterError.onError = previousOnError;
  });

  group('HabitDetailScreen modes', () {
    testWidgets('full mode shows both Edit and Statistics tabs',
        (tester) async {
      final store = _FakeStore(_rootState());
      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitDetailScreen(
            habit: _habit(),
            familyColor: Colors.blue,
            mode: HabitDetailScreenMode.full,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = _l10n(tester);
      expect(find.text(l10n.habitDetailEditTab), findsOneWidget);
      expect(find.text(l10n.habitDetailStatsTab), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('statsOnly hides Edit tab and shows stats content',
        (tester) async {
      final store = _FakeStore(_rootState());
      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitDetailScreen(
            habit: _habit(),
            familyColor: Colors.blue,
            mode: HabitDetailScreenMode.statsOnly,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = _l10n(tester);
      expect(find.text(l10n.habitDetailEditTab), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(HabitStatsTab), findsOneWidget);
      expect(find.text(l10n.habitStatsTabLastDaysTitle(7)), findsOneWidget);
      expect(find.text(l10n.habitStatsWeeklyComparisonTitle), findsOneWidget);
      expect(find.text(l10n.habitStatsPeriodWeek), findsOneWidget);
      expect(find.text(l10n.habitStatsPeriodMonth), findsOneWidget);
      expect(find.text(l10n.habitStatsPeriodYear), findsOneWidget);
    });

    testWidgets('statsOnly renders shell for count habits without crashing',
        (tester) async {
      final store = _FakeStore(_rootState());
      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitDetailScreen(
            habit: _habit(type: 'count', target: 8, unit: 'glasses'),
            familyColor: Colors.blue,
            mode: HabitDetailScreenMode.statsOnly,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HabitStatsTab), findsOneWidget);
      expect(find.text(_l10n(tester).habitStatsPeriodWeek), findsOneWidget);
    });

    testWidgets('editOnly hides Statistics tab', (tester) async {
      final store = _FakeStore(_rootState());
      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitDetailScreen(
            habit: _habit(),
            familyColor: Colors.blue,
            mode: HabitDetailScreenMode.editOnly,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = _l10n(tester);
      expect(find.text(l10n.habitDetailStatsTab), findsNothing);
      expect(find.byType(HabitStatsTab), findsNothing);
    });

    testWidgets('editOnly hides old habit-title header', (tester) async {
      final store = _FakeStore(_rootState());
      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitDetailScreen(
            habit: _habit(title: 'Running Title'),
            familyColor: Colors.blue,
            mode: HabitDetailScreenMode.editOnly,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('editOnly shows polished Edit habit header', (tester) async {
      final store = _FakeStore(_rootState());
      await tester.pumpWidget(
        _app(
          store: store,
          child: HabitDetailScreen(
            habit: _habit(),
            familyColor: Colors.blue,
            mode: HabitDetailScreenMode.editOnly,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = _l10n(tester);
      expect(find.text(l10n.editHabitHeaderTitle), findsOneWidget);
      expect(find.text(l10n.editHabitSaveChanges), findsOneWidget);
    });
  });
}

Widget _app({
  required UserStateStore store,
  required Widget child,
}) {
  return Provider<UserStateStore>.value(
    value: store,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(430, 932),
          textScaler: TextScaler.linear(0.3),
        ),
        child: child,
      ),
    ),
  );
}

AppLocalizations _l10n(WidgetTester tester) {
  final context = tester.element(find.byType(HabitDetailScreen));
  return context.l10n;
}

Map<String, dynamic> _rootState() {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'meta': <String, dynamic>{
        'activeViewDateKey': _dateKey(DateTime.now()),
      },
      'daily': <String, dynamic>{},
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitCompletionTimes': <String, dynamic>{},
        'habitSkips': <String, dynamic>{},
        'habitCountValues': <String, dynamic>{},
      },
      'activeHabits': [_habit()],
    },
  };
}

Map<String, dynamic> _habit({
  String id = 'habit-1',
  String title = 'Read',
  String type = 'check',
  int target = 1,
  String unit = 'times',
}) {
  return <String, dynamic>{
    'id': id,
    'title': title,
    'name': title,
    'familyId': 'mind',
    'type': type,
    'doneToday': false,
    'skippedToday': false,
    'progress': 0,
    'target': target,
    'unit': unit,
    'emoji': '✨',
    'schedule': <String, dynamic>{'type': 'daily'},
  };
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class _FakeStore implements UserStateStore {
  _FakeStore(this.state);

  @override
  final Map<String, dynamic>? state;

  @override
  List<Map<String, dynamic>> get activeHabits {
    final userState = state?['userState'];
    if (userState is! Map) return const <Map<String, dynamic>>[];
    final habits = userState['activeHabits'];
    if (habits is! List) return const <Map<String, dynamic>>[];
    return habits
        .whereType<Map>()
        .map(
            (entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()))
        .toList(growable: false);
  }

  @override
  Map<String, HabitStreakSnapshot> get achievementMetricSnapshots =>
      const <String, HabitStreakSnapshot>{};

  @override
  dynamic getActiveHabitById(String id) {
    for (final habit in activeHabits) {
      final habitId = (habit['id'] ?? habit['habitId'] ?? '').toString();
      if (habitId == id) return Map<String, dynamic>.from(habit);
    }
    return null;
  }

  @override
  HabitStreakSnapshot habitStreakSnapshotForHabitId(
    String habitId, {
    DateTime? today,
  }) {
    return HabitStreakSnapshot(
      habitId: habitId,
      currentStreak: 0,
      bestStreak: 0,
      totalCompletedDays: 0,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
