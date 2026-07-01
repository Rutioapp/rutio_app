import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/shop_controller.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/features/shop/presentation/screens/shop_flow_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopFlowScreen', () {
    testWidgets('renders Home', (WidgetTester tester) async {
      final env = await _createEnv();

      await tester.pumpWidget(_app(ShopFlowScreen(
        controller: env.controller,
        shopRepository: env.shopRepository,
      )));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Tienda'), findsOneWidget);
    });

    testWidgets('tap Cosméticos opens Cosmetics', (WidgetTester tester) async {
      final env = await _createEnv();

      await tester.pumpWidget(_app(ShopFlowScreen(
        controller: env.controller,
        shopRepository: env.shopRepository,
      )));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(tester, find.byKey(const Key('shopHomeEntryCosmetics')));
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.text('Cosméticos'), findsAtLeastNWidgets(1));
      expect(find.text('Personaliza tu Rutio'), findsAtLeastNWidgets(1));
    });

    testWidgets('tap Utilidades opens Utilities', (WidgetTester tester) async {
      final env = await _createEnv();

      await tester.pumpWidget(_app(ShopFlowScreen(
        controller: env.controller,
        shopRepository: env.shopRepository,
      )));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(tester, find.byKey(const Key('shopHomeEntryUtilities')));
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.text('Utilidades'), findsAtLeastNWidgets(1));
    });

    testWidgets('tap Colecciones opens Collections', (WidgetTester tester) async {
      final env = await _createEnv();

      await tester.pumpWidget(_app(ShopFlowScreen(
        controller: env.controller,
        shopRepository: env.shopRepository,
      )));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(tester, find.byKey(const Key('shopHomeEntryCollections')));
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.text('Colecciones'), findsAtLeastNWidgets(1));
    });

    testWidgets('tap Mochila opens Backpack', (WidgetTester tester) async {
      final env = await _createEnv();

      await tester.pumpWidget(_app(ShopFlowScreen(
        controller: env.controller,
        shopRepository: env.shopRepository,
      )));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(tester, find.byKey(const Key('shopHomeHeroBackpack')));
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.text('Mochila'), findsOneWidget);
    });

    testWidgets('tap Personalización opens Customization', (WidgetTester tester) async {
      final env = await _createEnv(
        shopState: const ShopState(
          inventory: <OwnedShopItem>[
            OwnedShopItem(itemId: 'bg_basic_camel'),
          ],
          equippedCosmetics: EquippedCosmetics(backgroundItemId: 'bg_basic_camel'),
        ),
      );

      await tester.pumpWidget(_app(ShopFlowScreen(
        controller: env.controller,
        shopRepository: env.shopRepository,
      )));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(tester, find.byKey(const Key('shopHomeHeroCustomization')));
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.text('Personalización'), findsOneWidget);
    });

    testWidgets('tap cosmetic opens Detail', (WidgetTester tester) async {
      final env = await _createEnv();

      await tester.pumpWidget(_app(ShopFlowScreen(
        controller: env.controller,
        shopRepository: env.shopRepository,
      )));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(tester, find.byKey(const Key('shopHomeEntryCosmetics')));
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(tester, find.byKey(const Key('shopCosmeticCard-bg_basic_camel')));
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.text('Detalle'), findsOneWidget);
    });

    testWidgets('purchase cosmetic updates state to owned',
        (WidgetTester tester) async {
      final env = await _createEnv(walletCoins: 500);

      await tester.pumpWidget(_app(ShopFlowScreen(
        controller: env.controller,
        shopRepository: env.shopRepository,
      )));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(tester, find.byKey(const Key('shopHomeEntryCosmetics')));
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(tester, find.byKey(const Key('shopCosmeticCard-bg_basic_camel')));
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(tester, find.text('Comprar'));
      await tester.pump(const Duration(milliseconds: 400));
      await _tapVisible(tester, find.byKey(const Key('shopPurchaseConfirmButton')));
      await tester.pump(const Duration(milliseconds: 32));
      await _pumpUntilText(tester, 'Comprado');

      expect(
        tester.widget<Text>(find.byKey(const Key('shopItemDetailStatusValue'))).data,
        'Comprado',
      );
    });

    testWidgets('purchase cosmetic updates equippedCosmetics via equip',
        (WidgetTester tester) async {
      final env = await _createEnv(walletCoins: 500);

      await tester.pumpWidget(_app(ShopFlowScreen(
        controller: env.controller,
        shopRepository: env.shopRepository,
      )));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(tester, find.byKey(const Key('shopHomeEntryCosmetics')));
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(tester, find.byKey(const Key('shopCosmeticCard-bg_basic_camel')));
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(tester, find.text('Comprar'));
      await tester.pump(const Duration(milliseconds: 400));
      await _tapVisible(tester, find.byKey(const Key('shopPurchaseConfirmButton')));
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(tester, find.text('Equipar'));
      await tester.pump(const Duration(milliseconds: 32));

      expect(
        tester.widget<Text>(find.byKey(const Key('shopItemDetailStatusValue'))).data,
        'Equipado',
      );
    });

    testWidgets('purchase utility appears in backpack', (WidgetTester tester) async {
      final env = await _createEnv(walletCoins: 500);

      await tester.pumpWidget(_app(ShopFlowScreen(
        controller: env.controller,
        shopRepository: env.shopRepository,
      )));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(tester, find.byKey(const Key('shopHomeEntryUtilities')));
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(tester, find.byKey(const Key('shopUtilityCard-utility_xp_boost_1d')));
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(tester, find.text('Comprar'));
      await tester.pump(const Duration(milliseconds: 400));
      await _tapVisible(tester, find.byKey(const Key('shopPurchaseConfirmButton')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Mochila'), findsAtLeastNWidgets(1));
      expect(
        find.byKey(const Key('shopBackpackUse-utility_xp_boost_1d')),
        findsOneWidget,
      );
    });

    testWidgets('tap item in customization opens Detail',
        (WidgetTester tester) async {
      final env = await _createEnv(
        walletCoins: 500,
        shopState: const ShopState(
          inventory: <OwnedShopItem>[
            OwnedShopItem(itemId: 'bg_basic_camel'),
          ],
        ),
      );

      await tester.pumpWidget(_app(ShopFlowScreen(
        controller: env.controller,
        shopRepository: env.shopRepository,
      )));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(tester, find.byKey(const Key('shopHomeHeroCustomization')));
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(tester, find.byKey(const Key('shopOwnedItem-bg_basic_camel')));
      await tester.pump(const Duration(milliseconds: 32));
      await _pumpUntilText(tester, 'Detalle');

      expect(find.text('Detalle'), findsAtLeastNWidgets(1));
    });
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

Future<_Env> _createEnv({
  int walletCoins = 320,
  ShopState shopState = const ShopState.initial(),
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('shop-flow-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState(walletCoins: walletCoins));

  final shopRepository = ShopLocalRepository();
  await shopRepository.save(shopState);

  return _Env(
    controller: ShopController(
      userStateStore: store,
      shopRepository: shopRepository,
    ),
    shopRepository: shopRepository,
  );
}

Map<String, dynamic> _baseState({
  required int walletCoins,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'shop-flow-user',
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
  const _Env({
    required this.controller,
    required this.shopRepository,
  });

  final ShopController controller;
  final ShopLocalRepository shopRepository;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 16));
}

Future<void> _pumpUntilText(
  WidgetTester tester,
  String text, {
  int maxAttempts = 10,
}) async {
  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    if (find.text(text).evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 32));
  }
}
