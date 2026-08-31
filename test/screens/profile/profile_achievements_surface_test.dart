import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/achievements/presentation/widgets/featured_achievements_section.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/profile/profile_screen.dart';
import 'package:rutio/screens/profile/widgets/profile_option_tile.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Profile keeps the main featured achievements surface only', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    final store = await _createStore();

    await tester.pumpWidget(_profileApp(store));
    await tester.pumpAndSettle();

    expect(
      find.byType(FeaturedAchievementsSection, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byType(ProfileOptionTile), findsNothing);
    expect(find.text('Achievements'), findsNothing);
    expect(find.text('Logros'), findsNothing);
  });

  testWidgets('FeaturedAchievementsSection remains tappable', (tester) async {
    var tapped = false;

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
          body: FeaturedAchievementsSection(
            featuredAchievements: const [],
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    final inkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byType(FeaturedAchievementsSection),
        matching: find.byType(InkWell),
      ),
    );
    inkWell.onTap?.call();
    await tester.pump();

    expect(tapped, isTrue);
  });
}

Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 20000));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

Future<UserStateStore> _createStore() async {
  final repository = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('profile-achievements-user');
  final store = UserStateStore(
    repository,
    journalEntrySyncService: JournalEntrySyncService(),
  );

  await store.save(<String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'profile-achievements-user',
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
  await store.switchLocalScope(
      userId: 'profile-achievements-user', forceReload: true);
  return store;
}

Widget _profileApp(UserStateStore store) {
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
      home: const ProfileScreen(),
    ),
  );
}
