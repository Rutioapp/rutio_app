import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/shop_screen.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shop entry point', () {
    testWidgets('ShopScreen wrapper renders ShopFlowScreen', (
      WidgetTester tester,
    ) async {
      final env = await _createEnv();

      await tester.pumpWidget(_wrapWithStore(
        env.store,
        MaterialApp(
          theme: AppTheme.theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ShopScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Tienda'), findsOneWidget);
      expect(find.byKey(const Key('shopHomeEntryCosmetics')), findsOneWidget);
      expect(find.text('Ropa'), findsNothing);
      expect(find.text('Buscar...'), findsNothing);
    });

    testWidgets('named route /shop renders ShopScreen wrapper', (
      WidgetTester tester,
    ) async {
      final env = await _createEnv();

      await tester.pumpWidget(
        _wrapWithStore(
          env.store,
          MaterialApp(
            theme: AppTheme.theme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            initialRoute: '/shop',
            routes: <String, WidgetBuilder>{
              '/shop': (_) => const ShopScreen(),
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Tienda'), findsOneWidget);
      expect(find.byKey(const Key('shopHomeEntryUtilities')), findsOneWidget);
      expect(find.text('Zapatos'), findsNothing);
    });
  });
}

Widget _wrapWithStore(UserStateStore store, Widget child) {
  return ChangeNotifierProvider<UserStateStore>.value(
    value: store,
    child: child,
  );
}

Future<_Env> _createEnv({int walletCoins = 320}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('shop-entry-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState(walletCoins: walletCoins));

  return _Env(store: store);
}

Map<String, dynamic> _baseState({
  required int walletCoins,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'shop-entry-user',
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
        'diaryRewardAppliedDateKeys': <dynamic>[],
      },
      'progression': <String, dynamic>{
        'level': 1,
        'xp': 0,
        'prestige': 0,
      },
      'wallet': <String, dynamic>{'coins': walletCoins},
      'inventory': <String, dynamic>{'items': <dynamic>[]},
      'profile': <String, dynamic>{
        'equipped': <String, dynamic>{},
        'badges': <String, dynamic>{'owned': <dynamic>[], 'shown': null},
        'achievements': <String, dynamic>{
          'unlocked': <dynamic>[],
          'featured': <dynamic>[],
          'rewardAppliedAchievementIds': <dynamic>[],
          'progress': <String, dynamic>{},
        },
      },
      'claims': <String, dynamic>{
        'milestonesClaimed': <dynamic>[],
        'achievementRewardsClaimed': <dynamic>[],
        'prestigeClaimed': <dynamic>[],
      },
      'daily': <String, dynamic>{
        'lastResetDate': '2026-06-27',
        'xpEarnedToday': 0,
        'coinsEarnedToday': 0,
        'habitsCompletedToday': <String, dynamic>{},
      },
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitCountValues': <String, dynamic>{},
        'habitSkips': <String, dynamic>{},
        'habitCompletionTimes': <String, dynamic>{},
      },
      'familyXp': <String, dynamic>{
        'mind': 0,
        'spirit': 0,
        'body': 0,
        'emotional': 0,
        'social': 0,
        'discipline': 0,
        'professional': 0,
      },
      'activeHabits': <dynamic>[],
    },
  };
}

class _Env {
  const _Env({required this.store});

  final UserStateStore store;
}
