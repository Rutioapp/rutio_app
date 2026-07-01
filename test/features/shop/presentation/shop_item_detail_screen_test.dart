import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/screens/shop_item_detail_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ShopItem cosmeticItem = ShopCatalog.getItemById('bg_basic_camel')!;
  final ShopItem utilityItem = ShopCatalog.getItemById('utility_xp_boost_1d')!;

  group('ShopItemDetailScreen', () {
    testWidgets('renders title name and description', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            item: cosmeticItem,
            collectionName: 'Minimal',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Detalle'), findsOneWidget);
      expect(find.byKey(const Key('shopItemDetailTitle')), findsOneWidget);
      expect(find.text('Camel Canvas'), findsAtLeastNWidgets(1));
      expect(find.byKey(const Key('shopItemDetailDescription')), findsOneWidget);
      expect(
        find.text('Fondo liso camel para una presencia calida.'),
        findsOneWidget,
      );
    });

    testWidgets('shows walletCoins', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(item: cosmeticItem, walletCoins: 540)));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('540'), findsOneWidget);
    });

    testWidgets('unowned item shows Comprar', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(item: cosmeticItem, walletCoins: 540)));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Comprar'), findsOneWidget);
    });

    testWidgets('insufficient balance shows disabled button',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(item: cosmeticItem, walletCoins: 10)));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Sin monedas suficientes'), findsOneWidget);
    });

    testWidgets('owned cosmetic shows Equipar', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            item: cosmeticItem,
            walletCoins: 540,
            isOwned: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Equipar'), findsOneWidget);
    });

    testWidgets('equipped cosmetic shows Equipado disabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            item: cosmeticItem,
            walletCoins: 540,
            isOwned: true,
            isEquipped: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Equipado'), findsAtLeastNWidgets(1));
      expect(find.byKey(const Key('shopItemDetailStatusValue')), findsOneWidget);
    });

    testWidgets('utility with quantity shows En mochila xN',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            item: utilityItem,
            walletCoins: 540,
            backpackQuantity: 3,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('En mochila x3'), findsAtLeastNWidgets(1));
    });

    testWidgets('tap Comprar calls onPurchasePressed',
        (WidgetTester tester) async {
      String? pressedId;

      await tester.pumpWidget(
        _app(
          _screen(
            item: cosmeticItem,
            walletCoins: 540,
            onPurchasePressed: (String itemId) => pressedId = itemId,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.text('Comprar'));
      await tester.pump(const Duration(milliseconds: 16));

      expect(pressedId, cosmeticItem.id);
    });

    testWidgets('tap Equipar calls onEquipPressed', (WidgetTester tester) async {
      String? pressedId;

      await tester.pumpWidget(
        _app(
          _screen(
            item: cosmeticItem,
            walletCoins: 540,
            isOwned: true,
            onEquipPressed: (String itemId) => pressedId = itemId,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.text('Equipar'));
      await tester.pump(const Duration(milliseconds: 16));

      expect(pressedId, cosmeticItem.id);
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
  required ShopItem item,
  int walletCoins = 240,
  bool isOwned = false,
  bool isEquipped = false,
  int? backpackQuantity,
  String? collectionName,
  ValueChanged<String>? onPurchasePressed,
  ValueChanged<String>? onEquipPressed,
}) {
  return ShopItemDetailScreen(
    item: item,
    walletCoins: walletCoins,
    isOwned: isOwned,
    isEquipped: isEquipped,
    backpackQuantity: backpackQuantity,
    collectionName: collectionName,
    onBackPressed: () {},
    onPurchasePressed: onPurchasePressed ?? (_) {},
    onEquipPressed: onEquipPressed ?? (_) {},
  );
}
