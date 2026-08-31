import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/achievements/presentation/widgets/featured_achievements_section.dart';
import 'package:rutio/features/statistics/presentation/v3/screens/statistics_v3_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/profile/profile_screen.dart';
import 'package:rutio/screens/profile/widgets/profile_goal_card.dart';
import 'package:rutio/screens/profile/widgets/profile_stats_summary_card.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'Profile shows the summary and goal sections and keeps them actionable',
    (tester) async {
      await _setLargeSurface(tester);
      final store = await _createStore(goal: 'Leer 20 min cada semana');

      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();

      final statsCard = tester.widget<ProfileStatsSummaryCard>(
        find.byType(ProfileStatsSummaryCard),
      );

      expect(find.byType(ProfileStatsSummaryCard), findsOneWidget);
      expect(find.byType(ProfileGoalCard), findsOneWidget);
      expect(find.text('General summary'), findsOneWidget);
      expect(find.text('Pending'), findsNothing);
      expect(find.text('Weekly progress'), findsOneWidget);
      expect(find.text('Leer 20 min cada semana'), findsWidgets);
      expect(statsCard.currentStreakDays, 7);
      expect(statsCard.bestStreakDays, 7);
      expect(statsCard.activeDaysCount, 15);

      await tester.tap(find.byType(ProfileStatsSummaryCard));
      await tester.pumpAndSettle();

      expect(find.byType(StatisticsV3Screen), findsOneWidget);
    },
  );

  testWidgets('Profile goal empty state triggers the edit callback',
      (tester) async {
    await _setLargeSurface(tester);
    final store = await _createStore(goal: null);

    await tester.pumpWidget(
      _app(
        store,
        onEditProfile: () {
          unawaited(
            store.updateProfileFields(goal: 'Nuevo objetivo'),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Define what you want to achieve'), findsOneWidget);
    expect(find.text('Add goal'), findsOneWidget);

    await tester.tap(find.text('Add goal'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo objetivo'), findsWidgets);
  });

  testWidgets('Featured achievements surface remains available from Profile',
      (tester) async {
    await _setLargeSurface(tester);
    final store = await _createStore(goal: 'Keep going');

    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    expect(
      find.byType(FeaturedAchievementsSection, skipOffstage: false),
      findsOneWidget,
    );
  });
}

Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 20000));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

Future<UserStateStore> _createStore({required String? goal}) async {
  final repository = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('profile-phase3-user');
  final store = UserStateStore(
    repository,
    journalEntrySyncService: JournalEntrySyncService(),
    nowProvider: () => DateTime(2026, 8, 30),
  );

  final history = <String, dynamic>{
    'habitCompletions': <String, dynamic>{},
    'habitCompletionTimes': <String, dynamic>{},
    'habitSkips': <String, dynamic>{},
    'habitCountValues': <String, dynamic>{},
  };

  for (final day in <int>[1, 2, 3, 4, 5, 6, 7, 24, 25, 26, 27, 28, 29, 30]) {
    final date = DateTime(2026, 8, day, 8);
    _setCheckCompletion(history, date, 'habit-1');
  }

  final diaryEntries = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'diary-1',
      'createdAt': DateTime(2026, 8, 23, 12).millisecondsSinceEpoch,
      'text': 'Entry',
    },
  ];

  await store.save(<String, dynamic>{
      'userState': <String, dynamic>{
      'userId': 'profile-phase3-user',
      'profile': <String, dynamic>{
        'displayName': 'Alex',
        if (goal != null) 'goal': goal,
      },
      'progression': <String, dynamic>{'xp': 2400},
      'activeHabits': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'habit-1',
          'title': 'Leer',
          'type': 'check',
          'schedule': <String, dynamic>{'type': 'daily'},
          'createdAt': '2026-07-01T00:00:00.000',
        },
      ],
      'habits': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'habit-1',
          'title': 'Leer',
          'type': 'check',
          'schedule': <String, dynamic>{'type': 'daily'},
          'createdAt': '2026-07-01T00:00:00.000',
        },
      ],
      'history': history,
      'diaryEntries': diaryEntries,
      'daily': <String, dynamic>{},
      'meta': <String, dynamic>{
        'activeViewDateKey': '2026-08-30',
        'lastSavedAt': DateTime(2026, 8, 30).toUtc().toIso8601String(),
      },
      'wallet': <String, dynamic>{'coins': 0},
      'featuredAchievementIds': <String>[],
      'unlockedAchievements': <Map<String, dynamic>>[],
      'unlockedAchievementRecords': <Map<String, dynamic>>[],
      'achievementMetricSnapshots': <String, dynamic>{},
    },
  });
  await store.switchLocalScope(
      userId: 'profile-phase3-user', forceReload: true);
  return store;
}

Widget _app(
  UserStateStore store, {
  VoidCallback? onEditProfile,
}) {
  return ChangeNotifierProvider<UserStateStore>.value(
    value: store,
    child: MaterialApp(
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
            size: const Size(800, 5000),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: ProfileScreen(onEditProfile: onEditProfile),
    ),
  );
}

void _setCheckCompletion(
  Map<String, dynamic> history,
  DateTime day,
  String habitId,
) {
  final dayKey = _dateKey(day);
  final completionsRoot =
      history['habitCompletions'] as Map<String, dynamic>? ??
          <String, dynamic>{};
  history['habitCompletions'] = completionsRoot;
  final completionTimesRoot =
      history['habitCompletionTimes'] as Map<String, dynamic>? ??
          <String, dynamic>{};
  history['habitCompletionTimes'] = completionTimesRoot;

  final completions = _ensureDayMap(completionsRoot, dayKey);
  completions[habitId] = true;
  final times = _ensureDayMap(completionTimesRoot, dayKey);
  times[habitId] = DateTime(
    day.year,
    day.month,
    day.day,
    8,
  ).millisecondsSinceEpoch;
}

Map<String, dynamic> _ensureDayMap(
  Map<String, dynamic> root,
  String dayKey,
) {
  final existing = root[dayKey];
  if (existing is Map<String, dynamic>) return existing;
  final next = <String, dynamic>{};
  root[dayKey] = next;
  return next;
}

String _dateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return '${normalized.year.toString().padLeft(4, '0')}-'
      '${normalized.month.toString().padLeft(2, '0')}-'
      '${normalized.day.toString().padLeft(2, '0')}';
}
