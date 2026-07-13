import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/screens/shop_customization_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<ShopItem> ownedItems = <ShopItem>[
    ShopCatalog.getItemById('wallpaper_mist_blue')!,
    ShopCatalog.getItemById('habit_card_soft_camel')!,
    ShopCatalog.getItemById('user_card_dune_layers')!,
  ];

  group('ShopCustomizationScreen', () {
    testWidgets('renders Preview', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: ownedItems)));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('shopCustomizationPreview')), findsOneWidget);
      expect(find.text('Preview actual'), findsOneWidget);
    });

    testWidgets('renders filter chips and default section',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: ownedItems)));
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.byKey(const Key('shopCustomizationFilter-backgrounds')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCustomizationFilter-habitCards')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCustomizationFilter-userCards')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCustomizationCategory-backgrounds')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCustomizationCategory-habitCards')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('shopCustomizationCategory-userCards')),
        findsNothing,
      );
    });

    testWidgets('switching filter updates visible category',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: ownedItems)));
      await tester.pump(const Duration(milliseconds: 16));

      await tester.ensureVisible(
        find.byKey(const Key('shopCustomizationFilter-habitCards')),
      );
      await tester.tap(
        find.byKey(const Key('shopCustomizationFilter-habitCards')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopCustomizationCategory-habitCards')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCustomizationCategory-backgrounds')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('shopCustomizationCategory-userCards')),
        findsNothing,
      );
      expect(find.text('Habit Cards'), findsWidgets);
    });

    testWidgets('renders equipped background in default filter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            items: ownedItems,
            equippedCosmetics: const EquippedCosmetics(
              backgroundItemId: 'wallpaper_mist_blue',
              userCardItemId: 'user_card_dune_layers',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.byKey(const Key('shopOwnedStatus-wallpaper_mist_blue')),
        findsOneWidget,
      );
      expect(find.text('Equipado'), findsAtLeastNWidgets(1));
      expect(find.text('Disponible'), findsNothing);
    });

    testWidgets('Equipar button calls callback', (WidgetTester tester) async {
      String? pressedItemId;

      await tester.pumpWidget(
        _app(
          _screen(
            items: ownedItems,
            onEquipPressed: (String itemId) async => pressedItemId = itemId,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester.ensureVisible(
        find.byKey(const Key('shopOwnedEquip-wallpaper_mist_blue')),
      );
      await tester.tap(
        find.byKey(const Key('shopOwnedEquip-wallpaper_mist_blue')),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(pressedItemId, 'wallpaper_mist_blue');
    });

    testWidgets('equipped object shows correct state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            items: ownedItems,
            equippedCosmetics: const EquippedCosmetics(
              backgroundItemId: 'wallpaper_mist_blue',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Equipado'), findsAtLeastNWidgets(1));
      expect(
        find.byKey(const Key('shopOwnedEquip-wallpaper_mist_blue')),
        findsOneWidget,
      );
      expect(find.text('Disponible'), findsNothing);
    });

    testWidgets('empty state appears when no objects',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            items: const <ShopItem>[],
            onOpenCosmetics: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.byKey(
            const Key('shopCustomizationCategoryEmptyState-backgrounds')),
        findsOneWidget,
      );
      expect(
        find.text(
            'Cuando consigas cosméticos de esta categoría aparecerán en esta sección.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('shopCustomizationOpenCosmetics')),
          findsOneWidget);
    });

    testWidgets('Ir a CosmÃ©ticos calls callback', (WidgetTester tester) async {
      var openedCosmetics = false;

      await tester.pumpWidget(
        _app(
          _screen(
            items: const <ShopItem>[],
            onOpenCosmetics: () {
              openedCosmetics = true;
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester.ensureVisible(
        find.byKey(const Key('shopCustomizationOpenCosmetics')),
      );
      await tester.tap(find.byKey(const Key('shopCustomizationOpenCosmetics')));
      await tester.pump(const Duration(milliseconds: 16));

      expect(openedCosmetics, isTrue);
    });

    testWidgets('V1 cosmetics controller shows owned assets from new system',
        (WidgetTester tester) async {
      final controller = await _createCosmeticsController(
        walletCoins: 640,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>['wallpaper_mist_blue'],
          ownedBundleIds: const <String>['bundle_warm_beige'],
          equippedHabitCardSkinId: 'habit_card_warm_beige',
        ),
      );

      await tester.pumpWidget(
        _app(
          _screen(
            items: const <ShopItem>[],
            cosmeticsController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopOwnedItem-wallpaper_mist_blue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopOwnedItem-habit_card_warm_beige')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('shopOwnedItem-user_card_warm_beige')),
        findsNothing,
      );
      expect(find.text('Equipado'), findsNothing);
      expect(find.text('Pack'), findsNothing);

      await tester.ensureVisible(
        find.byKey(const Key('shopCustomizationFilter-habitCards')),
      );
      await tester
          .tap(find.byKey(const Key('shopCustomizationFilter-habitCards')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopOwnedItem-habit_card_warm_beige')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopOwnedStatus-habit_card_warm_beige')),
        findsOneWidget,
      );
      expect(find.text('Equipado'), findsAtLeastNWidgets(1));

      await tester.ensureVisible(
        find.byKey(const Key('shopCustomizationFilter-userCards')),
      );
      await tester
          .tap(find.byKey(const Key('shopCustomizationFilter-userCards')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopOwnedItem-user_card_warm_beige')),
        findsOneWidget,
      );
    });

    testWidgets('controller-backed equip refreshes UI from persisted state',
        (WidgetTester tester) async {
      final controller = await _createCosmeticsController(
        walletCoins: 640,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>[
            'wallpaper_mist_blue',
            'wallpaper_soft_sage',
          ],
          ownedBundleIds: const <String>[],
          equippedWallpaperId: 'wallpaper_mist_blue',
        ),
      );

      await tester.pumpWidget(
        _app(
          _screen(items: const <ShopItem>[], cosmeticsController: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopOwnedStatus-wallpaper_mist_blue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopOwnedStatus-wallpaper_soft_sage')),
        findsNothing,
      );

      await tester.ensureVisible(
        find.byKey(const Key('shopOwnedEquip-wallpaper_soft_sage')),
      );
      await tester.tap(
        find.byKey(const Key('shopOwnedEquip-wallpaper_soft_sage')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopOwnedStatus-wallpaper_soft_sage')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopOwnedStatus-wallpaper_mist_blue')),
        findsNothing,
      );
    });

    testWidgets('controller-backed equip refreshes habit cards immediately',
        (WidgetTester tester) async {
      final controller = await _createCosmeticsController(
        walletCoins: 640,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>[
            'habit_card_warm_beige',
            'habit_card_soft_camel',
          ],
          ownedBundleIds: const <String>[],
          equippedHabitCardSkinId: 'habit_card_warm_beige',
        ),
      );

      await tester.pumpWidget(
        _app(
          _screen(items: const <ShopItem>[], cosmeticsController: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('shopCustomizationFilter-habitCards')),
      );
      await tester
          .tap(find.byKey(const Key('shopCustomizationFilter-habitCards')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopOwnedStatus-habit_card_warm_beige')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('shopOwnedEquip-habit_card_soft_camel')),
      );
      await tester
          .tap(find.byKey(const Key('shopOwnedEquip-habit_card_soft_camel')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopOwnedStatus-habit_card_soft_camel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopOwnedStatus-habit_card_warm_beige')),
        findsNothing,
      );
    });

    testWidgets('controller-backed equip refreshes user cards immediately',
        (WidgetTester tester) async {
      final controller = await _createCosmeticsController(
        walletCoins: 640,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>[
            'user_card_warm_beige',
            'user_card_soft_camel',
          ],
          ownedBundleIds: const <String>[],
          equippedUserCardSkinId: 'user_card_warm_beige',
        ),
      );

      await tester.pumpWidget(
        _app(
          _screen(items: const <ShopItem>[], cosmeticsController: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('shopCustomizationFilter-userCards')),
      );
      await tester
          .tap(find.byKey(const Key('shopCustomizationFilter-userCards')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopOwnedStatus-user_card_warm_beige')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('shopOwnedEquip-user_card_soft_camel')),
      );
      await tester
          .tap(find.byKey(const Key('shopOwnedEquip-user_card_soft_camel')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopOwnedStatus-user_card_soft_camel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopOwnedStatus-user_card_warm_beige')),
        findsNothing,
      );
    });

    testWidgets('equipped item button stays disabled and cannot re-equip',
        (WidgetTester tester) async {
      var pressedCount = 0;

      await tester.pumpWidget(
        _app(
          _screen(
            items: <ShopItem>[ShopCatalog.getItemById('wallpaper_mist_blue')!],
            equippedCosmetics: const EquippedCosmetics(
              backgroundItemId: 'wallpaper_mist_blue',
            ),
            onEquipPressed: (_) async {
              pressedCount += 1;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(const Key('shopOwnedEquip-wallpaper_mist_blue')),
          matching: find.byType(InkWell),
        ),
      );
      expect(button.onTap, isNull);
      expect(pressedCount, 0);
    });

    testWidgets('preview updates immediately when equipped wallpaper changes',
        (WidgetTester tester) async {
      final controller = await _createCosmeticsController(
        walletCoins: 640,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>[
            'wallpaper_mist_blue',
            'wallpaper_soft_sage',
          ],
          ownedBundleIds: const <String>[],
          equippedWallpaperId: 'wallpaper_mist_blue',
        ),
      );

      await tester.pumpWidget(
        _app(
          _screen(items: const <ShopItem>[], cosmeticsController: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Mist Blue Wallpaper'),
        findsWidgets,
      );

      await tester.ensureVisible(
        find.byKey(const Key('shopOwnedEquip-wallpaper_soft_sage')),
      );
      await tester
          .tap(find.byKey(const Key('shopOwnedEquip-wallpaper_soft_sage')));
      await tester.pumpAndSettle();

      expect(
        find.text('Soft Sage Wallpaper'),
        findsWidgets,
      );
    });

    testWidgets(
        'owned cosmetics grid does not overflow with long wallpaper names',
        (WidgetTester tester) async {
      final List<ShopItem> longWallpaperItems = <ShopItem>[
        ShopCatalog.getItemById('wallpaper_mist_blue')!,
        ShopCatalog.getItemById('wallpaper_soft_sage')!,
        ShopCatalog.getItemById('wallpaper_off_white')!,
        ShopCatalog.getItemById('wallpaper_cream_yellow')!,
      ];

      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(_screen(items: longWallpaperItems)));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopOwnedEquip-wallpaper_mist_blue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopOwnedEquip-wallpaper_off_white')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('owned cards hide description and metadata chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            items: <ShopItem>[
              ShopCatalog.getItemById('wallpaper_mist_blue')!,
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.text('Warm neutral background for calm focus.'), findsNothing);
      expect(find.text('Common'), findsNothing);
      expect(find.text('Disponible'), findsNothing);
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

Widget _screen({
  required List<ShopItem> items,
  EquippedCosmetics equippedCosmetics = const EquippedCosmetics(),
  Future<void> Function(String itemId)? onEquipPressed,
  ValueChanged<String>? onItemPressed,
  VoidCallback? onOpenCosmetics,
  ShopCosmeticsController? cosmeticsController,
}) {
  return ShopCustomizationScreen(
    walletCoins: 640,
    equippedCosmetics: equippedCosmetics,
    ownedCosmeticItems: items,
    onBackPressed: () {},
    onEquipPressed:
        onEquipPressed ?? cosmeticsController?.equipAsset ?? (_) async {},
    onItemPressed: onItemPressed ?? (_) {},
    onOpenCosmetics: onOpenCosmetics,
    cosmeticsController: cosmeticsController,
  );
}

Future<ShopCosmeticsController> _createCosmeticsController({
  required int walletCoins,
  ShopCosmeticsState cosmeticsState = const ShopCosmeticsState.initial(),
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await ShopCosmeticsRepository().save(cosmeticsState);

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('shop-customization-screen-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(
    <String, dynamic>{
      'userState': <String, dynamic>{
        'userId': 'shop-customization-screen-user',
        'wallet': <String, dynamic>{'coins': walletCoins},
      },
    },
  );

  return ShopCosmeticsController(userStateStore: store);
}
