import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/statistics/presentation/v3/screens/statistics_v3_screen.dart';
import 'package:rutio/features/gamification/domain/level_progression.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/profile/models/family_level.dart';
import 'package:rutio/screens/profile/utils/profile_xp.dart';
import 'package:rutio/screens/profile/widgets/family_radar_section.dart';
import 'package:rutio/screens/profile/widgets/progress_bar.dart';
import 'package:rutio/utils/family_theme.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('FamilyRadarSection renders seven families without duplication',
      (tester) async {
    await tester.pumpWidget(
      _app(
        child: FamilyRadarSection(
          accent: const Color(0xFF7A6755),
          familyLevels: _familyLevels(),
          familyColors: FamilyTheme.colors,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mind'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Spirit'), findsOneWidget);
    expect(find.text('Emotional'), findsOneWidget);
    expect(find.text('Social'), findsOneWidget);
    expect(find.text('Discipline'), findsOneWidget);
    expect(find.text('Professional'), findsOneWidget);
    expect(find.byType(ProgressBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FamilyRadarSection stays stable on compact viewport at zero',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _app(
        textScaleFactor: 1.35,
        child: FamilyRadarSection(
          accent: const Color(0xFF7A6755),
          familyLevels: _familyLevels(zeroOnly: true),
          familyColors: FamilyTheme.colors,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mind'), findsOneWidget);
    expect(find.text('Professional'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FamilyRadarSection exposes partial values through semantics',
      (tester) async {
    final families = _familyLevels(
      xps: <int>[720, 0, 540, 0, 260, 0, 0],
    );
    await tester.pumpWidget(
      _app(
        child: FamilyRadarSection(
          accent: const Color(0xFF7A6755),
          familyLevels: families,
          familyColors: FamilyTheme.colors,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Progress by family'), findsOneWidget);
    expect(_semanticsWithLabel(_vertexLabel(families[0])), findsOneWidget);
    expect(_semanticsWithLabel(_vertexLabel(families[1])), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FamilyRadarSection opens Statistics when tapped', (tester) async {
    final store = await _createStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<UserStateStore>.value(
        value: store,
        child: _app(
          child: Builder(
            builder: (context) {
              return FamilyRadarSection(
                accent: const Color(0xFF7A6755),
                familyLevels: _familyLevels(),
                familyColors: FamilyTheme.colors,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StatisticsV3Screen(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(find.byType(StatisticsV3Screen), findsOneWidget);
  });
}

Widget _app({
  required Widget child,
  double textScaleFactor = 1.0,
}) {
  return MaterialApp(
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
    builder: (context, child) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: Scaffold(body: child),
  );
}

List<FamilyLevel> _familyLevels({
  bool zeroOnly = false,
  List<int>? xps,
}) {
  final values = xps ??
      <int>[
        720,
        610,
        540,
        420,
        360,
        240,
        120,
      ];

  final ids = <String>[
    'mind',
    'body',
    'spirit',
    'emotional',
    'social',
    'discipline',
    'professional',
  ];

  final names = <String>[
    'Mind',
    'Body',
    'Spirit',
    'Emotional',
    'Social',
    'Discipline',
    'Professional',
  ];

  return List.generate(ids.length, (index) {
    final xp = zeroOnly ? 0 : values[index];
    return FamilyLevel(
      id: ids[index],
      name: names[index],
      level: LevelProgression.fromTotalXp(xp).level,
      xp: xp,
      xpToNext: LevelProgression.fromTotalXp(xp).xpToNextLevel,
    );
  });
}

String _vertexLabel(FamilyLevel family, {bool useLongLevel = false}) {
  final value = normalizedRadarValue(
    xp: family.xp,
    levelData: LevelData(level: family.level, xpToNext: family.xpToNext),
  );
  final percent = (value.clamp(0.0, 1.0) * 100).round();
  final levelLabel = useLongLevel
      ? 'Level ${family.level}'
      : 'Lvl ${family.level}';
  return '${family.name}: $percent%. $levelLabel.';
}

Finder _semanticsWithLabel(String text) {
  return find.descendant(
    of: find.byType(FamilyRadarSection),
    matching: find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == text,
    ),
  );
}

Future<UserStateStore> _createStore() async {
  final repository = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('profile-radar-user');
  final store = UserStateStore(
    repository,
    journalEntrySyncService: JournalEntrySyncService(),
  );

  await store.save(<String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'profile-radar-user',
      'profile': <String, dynamic>{'displayName': 'Alex'},
      'progression': <String, dynamic>{'xp': 0},
      'activeHabits': <Map<String, dynamic>>[],
      'habits': <Map<String, dynamic>>[],
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
  await store.switchLocalScope(userId: 'profile-radar-user', forceReload: true);
  return store;
}
