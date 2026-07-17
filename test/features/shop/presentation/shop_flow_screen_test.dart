import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/shop_controller.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/features/shop/presentation/screens/mystery_box_opening_screen.dart';
import 'package:rutio/features/shop/presentation/screens/shop_flow_screen.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopFlowScreen', () {
    testWidgets('renders Home', (WidgetTester tester) async {
      final env = await _createEnv();

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Tienda'), findsOneWidget);
    });

    testWidgets('tap Cosmeticos opens Cosmetics', (WidgetTester tester) async {
      final env = await _createEnv();

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeEntryCosmetics')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Cosm'), findsAtLeastNWidgets(1));
    });

    testWidgets('tap Utilidades opens Utilities', (WidgetTester tester) async {
      final env = await _createEnv();

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeEntryUtilities')),
      );
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.text('Utilidades'), findsAtLeastNWidgets(1));
    });

    testWidgets('tap Mochila opens Backpack', (WidgetTester tester) async {
      final env = await _createEnv();

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeHeroBackpack')),
      );
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.text('Mochila'), findsOneWidget);
    });

    testWidgets('tap Personalizacion opens Customization',
        (WidgetTester tester) async {
      final env = await _createEnv(
        shopState: const ShopState(
          inventory: <OwnedShopItem>[
            OwnedShopItem(itemId: 'wallpaper_mist_blue'),
          ],
          equippedCosmetics:
              EquippedCosmetics(backgroundItemId: 'wallpaper_mist_blue'),
        ),
      );

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeHeroCustomization')),
      );
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.textContaining('Personaliz'), findsOneWidget);
    });

    testWidgets('tap cosmetic opens Detail sheet', (WidgetTester tester) async {
      final env = await _createEnv();

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeEntryCosmetics')),
      );
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detalle'), findsOneWidget);
    });

    testWidgets('purchase cosmetic updates state to equipable',
        (WidgetTester tester) async {
      final env = await _createEnv(walletCoins: 500);

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeEntryCosmetics')),
      );
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const Key('shopCosmeticsDetailAction-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(
          const Key(
            'shopCosmeticsPurchaseConfirmationConfirm-wallpaper_mist_blue',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-wallpaper_mist_blue'),
          ),
          matching: find.text('Comprado'),
        ),
        findsWidgets,
      );
      expect(
        find.byKey(const Key('shopCosmeticsAction-wallpaper_mist_blue')),
        findsNothing,
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopCosmeticsDetailAction-wallpaper_mist_blue')),
        findsOneWidget,
      );
      expect(find.text('Equipar'), findsOneWidget);
    });

    testWidgets('purchase cosmetic can then be equipped',
        (WidgetTester tester) async {
      final env = await _createEnv(walletCoins: 500);

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeEntryCosmetics')),
      );
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const Key('shopCosmeticsDetailAction-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(
          const Key(
            'shopCosmeticsPurchaseConfirmationConfirm-wallpaper_mist_blue',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const Key('shopCosmeticsDetailAction-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-wallpaper_mist_blue'),
          ),
          matching: find.text('Equipado'),
        ),
        findsWidgets,
      );
    });

    testWidgets('purchase utility appears in backpack',
        (WidgetTester tester) async {
      final env = await _createEnv(walletCoins: 500);

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeEntryUtilities')),
      );
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(
        tester,
        find.byKey(const Key('shopUtilityCard-utility_xp_boost_1d')),
      );
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(tester, find.text('Comprar'));
      await tester.pump(const Duration(milliseconds: 400));
      await _tapVisible(
        tester,
        find.byKey(const Key('shopPurchaseConfirmButton')),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Mochila'), findsAtLeastNWidgets(1));
      expect(
        find.byKey(const Key('shopBackpackUse-utility_xp_boost_1d')),
        findsOneWidget,
      );
    });

    testWidgets('utility can be purchased repeatedly from detail flow',
        (WidgetTester tester) async {
      final env = await _createEnv(walletCoins: 500);

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeEntryUtilities')),
      );
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(
        tester,
        find.byKey(const Key('shopUtilityCard-utility_xp_boost_1d')),
      );
      await tester.pump(const Duration(milliseconds: 32));

      await _tapVisible(tester, find.text('Comprar'));
      await tester.pump(const Duration(milliseconds: 400));
      await _tapVisible(
        tester,
        find.byKey(const Key('shopPurchaseConfirmButton')),
      );
      await tester.pumpAndSettle();

      final firstState = await env.shopRepository.load();
      expect(firstState.backpackItems, hasLength(1));
      expect(firstState.backpackItems.first.itemId, 'utility_xp_boost_1d');
      expect(firstState.backpackItems.first.quantity, 1);
      expect(
        find.byKey(const Key('shopBackpackCard-utility_xp_boost_1d')),
        findsOneWidget,
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('shopBackpackCard-utility_xp_boost_1d')),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Comprar'));
      await tester.pump(const Duration(milliseconds: 400));
      await _tapVisible(
        tester,
        find.byKey(const Key('shopPurchaseConfirmButton')),
      );
      await tester.pumpAndSettle();

      final secondState = await env.shopRepository.load();
      expect(secondState.backpackItems, hasLength(1));
      expect(secondState.backpackItems.first.itemId, 'utility_xp_boost_1d');
      expect(secondState.backpackItems.first.quantity, 2);
      expect(
        find.byKey(const Key('shopBackpackCard-utility_xp_boost_1d')),
        findsOneWidget,
      );
    });

    testWidgets('mystery box can be opened from backpack flow',
        (WidgetTester tester) async {
      final env = await _createEnv(walletCoins: 500);

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeEntryUtilities')),
      );
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(
        tester,
        find.byKey(const Key('shopUtilityCard-utility_mystery_box_basic')),
      );
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(tester, find.text('Comprar'));
      await tester.pump(const Duration(milliseconds: 400));
      await _tapVisible(
        tester,
        find.byKey(const Key('shopPurchaseConfirmButton')),
      );
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const Key('shopBackpackUse-utility_mystery_box_basic')),
        findsOneWidget,
      );

      await _pressButton(
        tester,
        find.byKey(const Key('shopBackpackUse-utility_mystery_box_basic')),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.byType(MysteryBoxOpeningScreen), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(
          find.byKey(const Key('mysteryBoxFullscreenImage')), findsOneWidget);
      expect(
          find.byKey(const Key('mysteryBoxInteractionLayer')), findsOneWidget);
      expect(find.text('Tu Mystery Box esta lista'), findsNothing);

      await _tapVisible(
        tester,
        find.byKey(const Key('mysteryBoxInteractionLayer')),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 1250));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MysteryBoxOpeningScreen), findsOneWidget);

      if (find
          .byKey(const Key('mysteryBoxRewardSheet'))
          .evaluate()
          .isNotEmpty) {
        final continueButton = tester.widget<ShopPrimaryButton>(
          find.byKey(const Key('mysteryBoxContinueButton')),
        );
        continueButton.onPressed!.call();
        await tester.pump(const Duration(milliseconds: 120));
        expect(await env.controller.getPendingMysteryBoxOpenings(), isEmpty);
      }
    });

    testWidgets('tap utility opens complete Detail page',
        (WidgetTester tester) async {
      final env = await _createEnv();

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeEntryUtilities')),
      );
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(
        tester,
        find.byKey(const Key('shopUtilityCard-utility_xp_boost_1d')),
      );
      await tester.pump(const Duration(milliseconds: 32));

      expect(
        find.text('Potenciador de XP de 1 día'),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.text(
          'Aumenta temporalmente la experiencia obtenida al completar hábitos.',
        ),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.byKey(const Key('shopItemDetailUtilityTypeValue')),
        findsOneWidget,
      );
      expect(find.text('Comprar'), findsOneWidget);
    });

    testWidgets('utility cards stay compact in the list',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final env = await _createEnv();

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeEntryUtilities')),
      );
      await tester.pump(const Duration(milliseconds: 32));

      final Finder card =
          find.byKey(const Key('shopUtilityCard-utility_xp_boost_1d'));
      await tester.ensureVisible(card);
      final Size cardSize = tester.getSize(card);

      expect(cardSize.height, lessThanOrEqualTo(308));
    });

    testWidgets('tap item in customization opens Detail',
        (WidgetTester tester) async {
      final env = await _createEnv(
        walletCoins: 500,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>['wallpaper_mist_blue'],
          ownedBundleIds: const <String>[],
        ),
      );

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pump(const Duration(milliseconds: 16));

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeHeroCustomization')),
      );
      await tester.pump(const Duration(milliseconds: 32));
      await _tapVisible(
        tester,
        find.byKey(const Key('shopOwnedItem-wallpaper_mist_blue')),
      );
      await tester.pump(const Duration(milliseconds: 32));
      await _pumpUntilText(tester, 'Detalle');

      expect(find.text('Detalle'), findsAtLeastNWidgets(1));
      expect(find.text('Equipar'), findsOneWidget);
      expect(find.text('Comprar'), findsNothing);
    });

    testWidgets(
        'customization reflects equipped state from cosmetics repository',
        (WidgetTester tester) async {
      final env = await _createEnv(
        walletCoins: 500,
        shopState: const ShopState(
          equippedCosmetics:
              EquippedCosmetics(backgroundItemId: 'wallpaper_soft_sage'),
        ),
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>['wallpaper_mist_blue'],
          ownedBundleIds: const <String>[],
          equippedWallpaperId: 'wallpaper_mist_blue',
        ),
      );

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeHeroCustomization')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('shopOwnedItem-wallpaper_mist_blue')),
          matching: find.text('Equipado'),
        ),
        findsWidgets,
      );
      expect(
        find.byKey(const Key('shopOwnedItem-wallpaper_soft_sage')),
        findsNothing,
      );
    });

    testWidgets('customization equip does not show success snackbar',
        (WidgetTester tester) async {
      final env = await _createEnv(
        walletCoins: 500,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>[
            'wallpaper_mist_blue',
            'wallpaper_soft_sage',
          ],
          ownedBundleIds: const <String>[],
          equippedWallpaperId: 'wallpaper_mist_blue',
        ),
      );

      await tester.pumpWidget(_app(_flow(env)));
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('shopHomeHeroCustomization')),
      );
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('shopOwnedEquip-wallpaper_soft_sage')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cosmetico equipado'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.byKey(const Key('shopOwnedStatus-wallpaper_soft_sage')),
        findsOneWidget,
      );
    });
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    home: child,
  );
}

Widget _flow(_Env env) {
  return ShopFlowScreen(
    controller: env.controller,
    cosmeticsController: env.cosmeticsController,
    shopRepository: env.shopRepository,
  );
}

Future<_Env> _createEnv({
  int walletCoins = 320,
  ShopState shopState = const ShopState.initial(),
  ShopCosmeticsState cosmeticsState = const ShopCosmeticsState.initial(),
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
  await ShopCosmeticsRepository().save(cosmeticsState);

  return _Env(
    controller: ShopController(
      userStateStore: store,
      shopRepository: shopRepository,
    ),
    cosmeticsController: ShopCosmeticsController(userStateStore: store),
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
    required this.cosmeticsController,
    required this.shopRepository,
  });

  final ShopController controller;
  final ShopCosmeticsController cosmeticsController;
  final ShopLocalRepository shopRepository;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 16));
}

Future<void> _pressButton(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  final button = tester.widget<ShopPrimaryButton>(finder);
  button.onPressed?.call();
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
