import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/features/achievements/domain/models/habit_streak_snapshot.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/features/statistics/presentation/v3/screens/statistics_v3_screen.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_habit_list_view.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/habit_detail/habit_detail_screen.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Provider.debugCheckInvalidValueType = null;

  group('StatisticsV3 per-habit list view', () {
    testWidgets('shows active habits and excludes archived habits',
        (tester) async {
      final store = _FakeStatisticsV3Store(
        _rootState(
          activeHabits: [
            _habit(id: 'run', title: 'Run', familyId: 'body'),
            _habit(
              id: 'archived',
              title: 'Archived habit',
              familyId: 'mind',
              archived: true,
            ),
          ],
        ),
      );

      await tester.pumpWidget(_app(store));
      await _openHabitListMode(tester);

      expect(find.text('Run'), findsOneWidget);
      expect(find.text('Archived habit'), findsNothing);
    });

    testWidgets('search filters habits by title', (tester) async {
      final store = _FakeStatisticsV3Store(
        _rootState(
          activeHabits: [
            _habit(id: 'run', title: 'Run', familyId: 'body'),
            _habit(id: 'read', title: 'Read', familyId: 'mind'),
          ],
        ),
      );

      await tester.pumpWidget(_app(store));
      await _openHabitListMode(tester);

      await tester.enterText(
        find.byKey(const Key('statisticsV3HabitSearchField')),
        'rea',
      );
      await tester.pumpAndSettle();

      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Run'), findsNothing);
    });

    testWidgets('family chip filters habits by family', (tester) async {
      final store = _FakeStatisticsV3Store(
        _rootState(
          activeHabits: [
            _habit(id: 'run', title: 'Run', familyId: 'body'),
            _habit(id: 'read', title: 'Read', familyId: 'mind'),
          ],
        ),
      );

      await tester.pumpWidget(_app(store));
      await _openHabitListMode(tester);

      await tester.tap(find.byKey(const Key('statisticsV3HabitChip-body')));
      await tester.pumpAndSettle();

      expect(find.text('Run'), findsOneWidget);
      expect(find.text('Read'), findsNothing);
    });

    testWidgets('tapping a habit card opens habit detail in stats tab',
        (tester) async {
      final store = _FakeStatisticsV3Store(
        _rootState(
          activeHabits: [
            _habit(id: 'run', title: 'Run', familyId: 'body'),
          ],
        ),
      );

      await tester.pumpWidget(_app(store));
      await _openHabitListMode(tester);

      await tester.tap(find.byKey(const Key('statisticsV3HabitCard-run')));
      await tester.pumpAndSettle();

      expect(find.byType(HabitDetailScreen), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('shows empty state when there are no active habits',
        (tester) async {
      final store = _FakeStatisticsV3Store(
        _rootState(activeHabits: const []),
      );

      await tester.pumpWidget(_app(store));
      await _openHabitListMode(tester);

      expect(find.text('No active habits yet.'), findsOneWidget);
    });

    testWidgets('keeps long title visible and hides metrics from card UI',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const longTitle =
          'Very long habit title that should never wrap into two lines in this card';
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: StatisticsV3HabitListView(
                items: const [
                  StatisticsV3HabitListItem(
                    habitId: 'long-count',
                    habit: <String, dynamic>{'id': 'long-count'},
                    title: longTitle,
                    emoji: '🥤',
                    familyId: 'spirit',
                    familyName: 'Spirit',
                    familyColor: Color(0xFF72A481),
                    mainMetric: '4 verylongcustomunitname',
                    secondaryMetric: 'Avg: 0.6/day',
                    metricKind: StatisticsV3HabitListMetricKind.count,
                  ),
                ],
                onHabitTap: _noopHabitTap,
                onPlusTap: _noopTap,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('statisticsV3HabitCard-long-count')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('4 verylongcustomunitname'), findsNothing);
      expect(find.text('Avg: 0.6/day'), findsNothing);

      final titleText = tester.widget<Text>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data == longTitle,
        ),
      );
      expect(titleText.maxLines, 1);
      expect(titleText.overflow, TextOverflow.ellipsis);
    });
  });
}

Widget _app(UserStateStore store) {
  return Provider<UserStateStore>.value(
    value: store,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const StatisticsV3Screen(),
    ),
  );
}

Future<void> _openHabitListMode(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.bar_chart_rounded));
  await tester.pumpAndSettle();
}

Map<String, dynamic> _rootState({
  required List<Map<String, dynamic>> activeHabits,
}) {
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
      'activeHabits': activeHabits,
    },
  };
}

Map<String, dynamic> _habit({
  required String id,
  required String title,
  required String familyId,
  bool archived = false,
}) {
  return <String, dynamic>{
    'id': id,
    'title': title,
    'name': title,
    'familyId': familyId,
    'type': 'check',
    'doneToday': false,
    'skippedToday': false,
    'progress': 0,
    'target': 1,
    'emoji': '✨',
    'schedule': <String, dynamic>{'type': 'daily'},
    if (archived) 'archived': true,
  };
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

void _noopTap() {}

void _noopHabitTap(StatisticsV3HabitListItem _) {}

class _FakeStatisticsV3Store implements UserStateStore {
  _FakeStatisticsV3Store(this.state);

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
