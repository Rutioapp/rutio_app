import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/application/shop_controller.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/features/shop/presentation/screens/shop_item_detail_container.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_purchase_confirmation_sheet.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ShopItem cosmeticItem = ShopCatalog.getItemById('wallpaper_mist_blue')!;
  final ShopItem utilityItem = ShopCatalog.getItemById('utility_xp_boost_1d')!;

  group('ShopItemDetailContainer', () {
    testWidgets('pressing Comprar in detail opens confirmation sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _container(
            item: cosmeticItem,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.text('Comprar'));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Confirmar compra'), findsOneWidget);
    });

    testWidgets('confirming purchase calls purchase handler',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      var purchaseCount = 0;
      var purchasedItemId = '';
      var isOwned = false;
      var walletCoins = 240;

      await tester.pumpWidget(
        _app(
          _container(
            item: cosmeticItem,
            loadItemState: (String itemId) async => ShopItemState(
              item: cosmeticItem,
              walletCoins: walletCoins,
              isOwned: isOwned,
              isEquipped: false,
              backpackQuantity: 0,
            ),
            purchaseItem: (String itemId) async {
              purchaseCount++;
              purchasedItemId = itemId;
              isOwned = true;
              walletCoins = 120;
              return ShopControllerResult(
                status: ShopControllerStatus.success,
                item: cosmeticItem,
                shopState: const ShopState(
                  inventory: <OwnedShopItem>[
                    OwnedShopItem(itemId: 'wallpaper_mist_blue'),
                  ],
                ),
                walletCoins: 120,
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.text('Comprar'));
      await tester.pump(const Duration(milliseconds: 16));
      final sheet = tester.widget<ShopPurchaseConfirmationSheet>(
        find.byType(ShopPurchaseConfirmationSheet),
      );
      sheet.onConfirm(cosmeticItem.id);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(purchaseCount, 1);
      expect(purchasedItemId, 'wallpaper_mist_blue');
      expect(find.text('Añadido a tu colección'), findsOneWidget);
    });

    testWidgets('purchase without enough coins shows disabled state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _container(
            item: cosmeticItem,
            walletCoins: 10,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Sin monedas suficientes'), findsOneWidget);
    });

    testWidgets('utility detail allows repeated purchases',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      var purchaseCount = 0;
      var quantity = 0;
      var walletCoins = 500;

      await tester.pumpWidget(
        _app(
          _container(
            item: utilityItem,
            loadItemState: (String itemId) async => ShopItemState(
              item: utilityItem,
              walletCoins: walletCoins,
              isOwned: false,
              isEquipped: false,
              backpackQuantity: quantity,
            ),
            purchaseItem: (String itemId) async {
              purchaseCount++;
              quantity++;
              walletCoins -= utilityItem.priceCoins;
              return ShopControllerResult(
                status: ShopControllerStatus.success,
                item: utilityItem,
                shopState: const ShopState.initial(),
                walletCoins: walletCoins,
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.text('Comprar'));
      await tester.pump(const Duration(milliseconds: 16));
      tester
          .widget<ShopPurchaseConfirmationSheet>(
            find.byType(ShopPurchaseConfirmationSheet),
          )
          .onConfirm(utilityItem.id);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(purchaseCount, 1);
      expect(find.text('Comprar'), findsOneWidget);

      await tester.tap(find.text('Comprar'));
      await tester.pump(const Duration(milliseconds: 16));
      tester
          .widget<ShopPurchaseConfirmationSheet>(
            find.byType(ShopPurchaseConfirmationSheet),
          )
          .onConfirm(utilityItem.id);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(purchaseCount, 2);
      expect(find.text('Comprar'), findsOneWidget);
    });

    testWidgets('double tap while purchase is in flight does not duplicate',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      var purchaseCount = 0;
      var quantity = 0;
      var walletCoins = 500;

      await tester.pumpWidget(
        _app(
          _container(
            item: utilityItem,
            loadItemState: (String itemId) async => ShopItemState(
              item: utilityItem,
              walletCoins: walletCoins,
              isOwned: false,
              isEquipped: false,
              backpackQuantity: quantity,
            ),
            purchaseItem: (String itemId) async {
              purchaseCount++;
              await Future<void>.delayed(const Duration(milliseconds: 200));
              quantity++;
              walletCoins -= utilityItem.priceCoins;
              return ShopControllerResult(
                status: ShopControllerStatus.success,
                item: utilityItem,
                shopState: const ShopState.initial(),
                walletCoins: walletCoins,
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.text('Comprar'));
      await tester.pump(const Duration(milliseconds: 16));
      tester
          .widget<ShopPurchaseConfirmationSheet>(
            find.byType(ShopPurchaseConfirmationSheet),
          )
          .onConfirm(utilityItem.id);
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.text('Comprar'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 250));

      expect(purchaseCount, 1);
      expect(find.text('Comprar'), findsOneWidget);
    });
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Widget _container({
  required ShopItem item,
  int walletCoins = 240,
  bool isOwned = false,
  bool isEquipped = false,
  int backpackQuantity = 0,
  ShopItemStateLoader? loadItemState,
  ShopItemPurchaseHandler? purchaseItem,
  ShopItemEquipHandler? equipItem,
}) {
  return ShopItemDetailContainer(
    itemId: item.id,
    onBackPressed: () {},
    loadItemState: loadItemState ??
        (String itemId) async => ShopItemState(
              item: item,
              walletCoins: walletCoins,
              isOwned: isOwned,
              isEquipped: isEquipped,
              backpackQuantity: backpackQuantity,
            ),
    purchaseItem: purchaseItem ??
        (String itemId) async => ShopControllerResult(
              status: ShopControllerStatus.success,
              item: item,
              shopState: const ShopState.initial(),
              walletCoins: walletCoins,
            ),
    equipItem: equipItem ??
        (String itemId) async => ShopControllerResult(
              status: ShopControllerStatus.success,
              item: item,
              shopState: const ShopState.initial(),
              walletCoins: walletCoins,
            ),
  );
}
