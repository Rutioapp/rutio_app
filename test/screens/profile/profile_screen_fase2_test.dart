import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/gamification/domain/level_progression.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/profile/utils/profile_xp.dart';
import 'package:rutio/screens/profile/widgets/profile_header.dart';
import 'package:rutio/screens/profile/widgets/profile_progress_card.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Profile reads identity, bio and progress from the store', (
    tester,
  ) async {
    final store = await _createStore(
      profile: <String, dynamic>{
        'displayName': 'Álex',
        'bio': 'Nota privada\nmultilínea',
        'goal': 'Leer 20 min',
        'email': 'hidden@example.com',
      },
      xp: 1400,
    );

    final progression = LevelProgression.fromTotalXp(1400);

    await tester.pumpWidget(_app(store));

    expect(find.text('Álex'), findsOneWidget);
    expect(find.text('Nota privada\nmultilínea'), findsOneWidget);
    expect(find.text('Leer 20 min'), findsNothing);
    expect(find.text('hidden@example.com'), findsNothing);
    expect(
      find.text(
        '${formatCompactXp(progression.currentLevelXp, localeName: 'en')} / '
        '${formatCompactXp(progression.xpForNextLevel, localeName: 'en')} XP',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        '${formatCompactXp(progression.xpToNextLevel, localeName: 'en')} XP',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Profile uses goal as fallback when bio is missing', (
    tester,
  ) async {
    final store = await _createStore(
      profile: <String, dynamic>{
        'displayName': 'Alex',
        'bio': '',
        'goal': 'Keep a calm rhythm',
      },
      xp: 0,
    );

    await tester.pumpWidget(_app(store));

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Keep a calm rhythm'), findsOneWidget);
  });

  testWidgets('Profile reflects store changes after an edit action', (
    tester,
  ) async {
    final store = await _createStore(
      profile: <String, dynamic>{
        'displayName': 'Alex',
        'bio': 'Old bio',
        'goal': 'Old goal',
      },
      xp: 120,
    );

    await tester.pumpWidget(
      _app(
        store,
        onEditProfile: () {
          unawaited(
            store.updateProfileFields(
              displayName: 'Nora',
              bio: 'Nueva bio',
              goal: 'Nuevo objetivo',
              avatarUrl: 'file:///tmp/rutio-new-avatar.png',
            ),
          );
        },
      ),
    );

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Old bio'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Nora'), findsOneWidget);
    expect(find.text('Nueva bio'), findsOneWidget);
    expect(find.text('Nuevo objetivo'), findsNothing);
    expect(store.displayName, 'Nora');
    expect(store.bioText, 'Nueva bio');
    expect(store.goalText, 'Nuevo objetivo');
    expect(store.avatarUrl, 'file:///tmp/rutio-new-avatar.png');
  });
}

Future<UserStateStore> _createStore({
  required Map<String, dynamic> profile,
  required int xp,
}) async {
  final repository = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('profile-test-user');
  final store = UserStateStore(
    repository,
    journalEntrySyncService: JournalEntrySyncService(),
  );

  await store.save(<String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'profile-test-user',
      'profile': profile,
      'progression': <String, dynamic>{'xp': xp},
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
  await store.switchLocalScope(userId: 'profile-test-user', forceReload: true);
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
      home: Scaffold(
        body: Consumer<UserStateStore>(
          builder: (context, store, _) {
            final userState =
                (store.state?['userState'] as Map?)?.cast<String, dynamic>() ??
                    <String, dynamic>{};
            final progressionMap =
                (userState['progression'] as Map?)?.cast<String, dynamic>() ??
                    <String, dynamic>{};
            final progression = LevelProgression.fromTotalXp(
              ((progressionMap['xp'] as num?) ?? 0).toInt(),
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ProfileHeader(
                  accent: const Color(0xFF6C5CE7),
                  name: (store.displayName ?? '').trim().isNotEmpty
                      ? store.displayName!.trim()
                      : 'Your profile',
                  note: store.bioText?.trim().isNotEmpty == true
                      ? store.bioText!.trim()
                      : null,
                  goal: store.goalText?.trim().isNotEmpty == true
                      ? store.goalText!.trim()
                      : null,
                  avatarImage: null,
                  onEdit: onEditProfile ?? () {},
                ),
                const SizedBox(height: 16),
                ProfileProgressCard(
                  accent: const Color(0xFF6C5CE7),
                  progression: progression,
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
