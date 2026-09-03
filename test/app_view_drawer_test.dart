import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
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

  testWidgets('AppViewDrawer opens the productive Weekly Report route',
      (tester) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {'/weekly-report': (_) => const Scaffold(body: Text('Weekly'))},
      home: Scaffold(
        key: scaffoldKey,
        drawer: AppViewDrawer(
          onGoDaily: () {},
          onGoWeekly: () {},
          onGoMonthly: () {},
          onGoDiary: () {},
          onGoDiaryV2: () {},
          onGoArchived: () {},
          onGoStats: () {},
          onGoProfile: () {},
          onGoWeeklyReport: () => Navigator.of(scaffoldKey.currentContext!)
              .pushNamed('/weekly-report'),
        ),
        body: const Text('Home'),
      ),
    ));
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();
    final label =
        AppLocalizations.of(tester.element(find.byType(Scaffold).first))
            .weeklyReportSectionTitle;
    expect(find.text(label), findsOneWidget);
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('AppViewDrawer no longer renders feedback support in Spanish', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(supportSectionFinder, findsNothing);
    expect(reportIssueFinder, findsNothing);
  });

  testWidgets('AppViewDrawer does not render Todo entry', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
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

    expect(find.text(l10n.drawerTodo), findsNothing);
    expect(find.byIcon(Icons.checklist_rounded), findsNothing);
  });

  testWidgets('AppViewDrawer exposes a single visible statistics entry', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    var statsTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
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
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
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
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
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

  testWidgets('AppViewDrawer Tienda entry opens ShopFlowScreen via /shop', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    var shopTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
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
            onGoDiary: () {},
            onGoDiaryV2: () {},
            onGoArchived: () {},
            onGoStats: () {},
            onGoShop: () => shopTapCount++,
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

    await tester.tap(find.text(l10n.shopTitle));
    await tester.pump(const Duration(milliseconds: 600));

    expect(shopTapCount, 1);
  });

  testWidgets('AppViewDrawer Shop entry is localized in English', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
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
            onGoDiary: () {},
            onGoDiaryV2: () {},
            onGoArchived: () {},
            onGoStats: () {},
            onGoShop: () {},
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
    expect(find.text(l10n.shopTitle), findsOneWidget);
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
  HabitStreakSnapshot get globalHabitStreakSnapshot =>
      const HabitStreakSnapshot(
        habitId: '',
        currentStreak: 0,
        bestStreak: 0,
        totalCompletedDays: 0,
      );

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
