import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/edit_profile/edit_profile_screen.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Edit profile renders the redesigned shell', (tester) async {
    final store = await _createStore(
      profile: <String, dynamic>{
        'displayName': 'Vicenç',
        'bio': 'Enfocado en mejorar cada día.',
        'goal': 'Mejorar un 1% cada día',
      },
      xp: 1200,
      coins: 9940,
    );

    await tester.pumpWidget(_app(store));
    await tester.tap(find.text('Open edit profile'));
    await tester.pumpAndSettle();

    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.byKey(const Key('editProfileAvatarButton')), findsOneWidget);
    expect(find.byKey(const Key('editProfilePreviewName')), findsOneWidget);
    expect(find.byKey(const Key('editProfilePreviewGoal')), findsOneWidget);
    expect(find.text('Level'), findsOneWidget);
    expect(find.text('XP'), findsOneWidget);
    expect(find.text('Coins'), findsOneWidget);
    expect(find.text('Name'), findsNothing);
    expect(find.text('Bio'), findsNothing);
    expect(find.text('Goal'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('editProfileNameField')),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('editProfileBioField')),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('editProfileGoalField')),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
    expect(find.byKey(const Key('editProfileSaveButton')), findsOneWidget);
  });

  testWidgets('Edit profile updates the preview live before saving',
      (tester) async {
    final store = await _createStore(
      profile: <String, dynamic>{
        'displayName': 'Vicenç',
        'bio': 'Enfocado en mejorar cada día.',
        'goal': 'Mejorar un 1% cada día',
      },
      xp: 1200,
      coins: 9940,
    );

    await tester.pumpWidget(_app(store));
    await tester.tap(find.text('Open edit profile'));
    await tester.pumpAndSettle();

    final nameField = find.byType(EditableText).first;
    await tester.enterText(
      nameField,
      'Marina',
    );
    await tester.pump();

    expect(find.text('Marina', skipOffstage: false), findsWidgets);
    expect(store.displayName, 'Vicenç');
    expect(store.goalText, 'Mejorar un 1% cada día');

    await tester.tap(find.byKey(const Key('editProfileSaveButton')));
    await tester.pumpAndSettle();

    expect(store.displayName, 'Marina');
    expect(store.goalText, 'Mejorar un 1% cada día');
  });

  testWidgets('Edit profile keeps the avatar selector accessible', (
    tester,
  ) async {
    final store = await _createStore(
      profile: <String, dynamic>{
        'displayName': 'Vicenç',
        'bio': 'Enfocado en mejorar cada día.',
        'goal': 'Mejorar un 1% cada día',
      },
      xp: 1200,
      coins: 9940,
    );

    await tester.pumpWidget(_app(store));
    await tester.tap(find.text('Open edit profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('editProfileAvatarButton')));
    await tester.pumpAndSettle();

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
  });

  testWidgets('Edit profile shows the name placeholder when empty', (
    tester,
  ) async {
    final store = await _createStore(
      profile: <String, dynamic>{
        'displayName': '',
        'bio': '',
        'goal': '',
      },
      xp: 0,
      coins: 0,
    );

    await tester.pumpWidget(_app(store));
    await tester.tap(find.text('Open edit profile'));
    await tester.pumpAndSettle();

    expect(find.text('Write your username here'), findsOneWidget);
    expect(store.displayName, '');
  });
}

Future<UserStateStore> _createStore({
  required Map<String, dynamic> profile,
  required int xp,
  required int coins,
}) async {
  final repository = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('edit-profile-user');
  final store = UserStateStore(
    repository,
    journalEntrySyncService: JournalEntrySyncService(),
  );

  await store.save(<String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'edit-profile-user',
      'profile': profile,
      'progression': <String, dynamic>{'xp': xp},
      'activeHabits': <Map<String, dynamic>>[],
      'habits': <Map<String, dynamic>>[],
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitCountValues': <String, dynamic>{},
      },
      'wallet': <String, dynamic>{'coins': coins},
      'featuredAchievementIds': <String>[],
      'unlockedAchievements': <Map<String, dynamic>>[],
      'unlockedAchievementRecords': <Map<String, dynamic>>[],
      'achievementMetricSnapshots': <String, dynamic>{},
    },
  });
  await store.switchLocalScope(userId: 'edit-profile-user', forceReload: true);
  return store;
}

Widget _app(UserStateStore store) {
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
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EditProfileScreen(),
                  ),
                );
              },
              child: const Text('Open edit profile'),
            ),
          ),
        ),
      ),
    ),
  );
}
