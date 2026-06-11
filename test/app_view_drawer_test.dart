import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:rutio/features/achievements/domain/models/habit_streak_snapshot.dart';
import 'package:rutio/features/statistics/presentation/v3/screens/statistics_v3_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/widgets/app_view_drawer.dart';

void main() {
  Provider.debugCheckInvalidValueType = null;

  testWidgets('AppViewDrawer renders support action in Spanish', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          key: scaffoldKey,
          drawer: AppViewDrawer(
            onGoDaily: () {},
            onGoWeekly: () {},
            onGoMonthly: () {},
            onGoTodo: () {},
            onGoDiary: () {},
            onGoDiaryV2: () {},
            onGoArchived: () {},
            onGoStats: () {},
            onGoProfile: () {},
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    scaffoldKey.currentState!.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);
    final supportSectionFinder = find.text(l10n.drawerSectionSupport);
    final reportIssueFinder = find.text(l10n.drawerReportIssue);

    await tester.scrollUntilVisible(
      supportSectionFinder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(supportSectionFinder, findsOneWidget);
    expect(reportIssueFinder, findsOneWidget);
  });

  testWidgets('AppViewDrawer exposes a single visible statistics entry', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    var statsTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          key: scaffoldKey,
          drawer: AppViewDrawer(
            onGoDaily: () {},
            onGoWeekly: () {},
            onGoMonthly: () {},
            onGoTodo: () {},
            onGoDiary: () {},
            onGoDiaryV2: () {},
            onGoArchived: () {},
            onGoStats: () => statsTapCount++,
            onGoProfile: () {},
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    scaffoldKey.currentState!.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);
    final statsFinder = find.text(l10n.drawerStatistics);
    final statsV3Finder = find.text(l10n.drawerStatisticsV3);

    expect(statsFinder, findsOneWidget);
    expect(statsV3Finder, findsNothing);

    await tester.tap(statsFinder);
    await tester.pumpAndSettle();

    expect(statsTapCount, 1);
  });

  testWidgets('AppViewDrawer exposes a single Diary entry without Diary V2', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    var diaryTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          key: scaffoldKey,
          drawer: AppViewDrawer(
            onGoDaily: () {},
            onGoWeekly: () {},
            onGoMonthly: () {},
            onGoTodo: () {},
            onGoDiary: () => diaryTapCount++,
            onGoDiaryV2: () {},
            onGoArchived: () {},
            onGoStats: () {},
            onGoProfile: () {},
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    scaffoldKey.currentState!.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);
    final diaryFinder = find.byIcon(Icons.menu_book_outlined);

    expect(diaryFinder, findsOneWidget);
    expect(find.text('Diario V2'), findsNothing);

    await tester.tap(diaryFinder);
    await tester.pumpAndSettle();

    expect(diaryTapCount, 1);
  });

  testWidgets('AppViewDrawer statistics entry can open StatisticsV3Screen', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          '/stats': (_) => Provider<UserStateStore>.value(
                value: _DrawerStatsFakeStore(),
                child: const StatisticsV3Screen(),
              ),
        },
        home: Scaffold(
          key: scaffoldKey,
          drawer: AppViewDrawer(
            onGoDaily: () {},
            onGoWeekly: () {},
            onGoMonthly: () {},
            onGoTodo: () {},
            onGoDiary: () {},
            onGoDiaryV2: () {},
            onGoArchived: () {},
            onGoStats: () =>
                Navigator.of(scaffoldKey.currentContext!).pushNamed('/stats'),
            onGoProfile: () {},
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    scaffoldKey.currentState!.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final context = tester.element(find.byType(Scaffold).first);
    final l10n = AppLocalizations.of(context);

    await tester.tap(find.text(l10n.drawerStatistics));
    await tester.pumpAndSettle();

    expect(find.byType(StatisticsV3Screen), findsOneWidget);
  });
}

class _DrawerStatsFakeStore implements UserStateStore {
  @override
  final Map<String, dynamic>? state = <String, dynamic>{
    'userState': <String, dynamic>{
      'meta': <String, dynamic>{},
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitCompletionTimes': <String, dynamic>{},
        'habitSkips': <String, dynamic>{},
        'habitCountValues': <String, dynamic>{},
      },
      'profile': <String, dynamic>{'achievements': <String, dynamic>{}},
      'activeHabits': <Map<String, dynamic>>[],
    },
  };

  @override
  List<Map<String, dynamic>> get activeHabits => const <Map<String, dynamic>>[];

  @override
  Map<String, HabitStreakSnapshot> get achievementMetricSnapshots =>
      const <String, HabitStreakSnapshot>{};

  @override
  dynamic getActiveHabitById(String id) => null;

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
