import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/screens/shop_cosmetics_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<ShopItem> items = ShopCatalog.allItems
      .where((ShopItem item) => item.category == ShopItemCategory.cosmetic)
      .toList(growable: false);

  group('ShopCosmeticsScreen', () {
    testWidgets('renders Cosméticos', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: items)));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Cosméticos'), findsOneWidget);
    });

    testWidgets('shows walletCoins', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: items, walletCoins: 520)));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('520'), findsOneWidget);
    });

    testWidgets('shows filters', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: items)));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('shopCosmeticsFilter-all')), findsOneWidget);
      expect(
        find.byKey(const Key('shopCosmeticsFilter-backgrounds')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCosmeticsFilter-habitCards')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCosmeticsFilter-userCards')),
        findsOneWidget,
      );
    });

    testWidgets('Todos shows the three sections', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: items)));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('shopCosmeticsSection-Fondos')), findsOneWidget);
      expect(
        find.byKey(const Key('shopCosmeticsSection-Cards de hábitos')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCosmeticsSection-Cards de usuario')),
        findsOneWidget,
      );
    });

    testWidgets('Fondos filter shows only Fondos', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: items)));
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-backgrounds')));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('shopCosmeticsSection-Fondos')), findsOneWidget);
      expect(
        find.byKey(const Key('shopCosmeticsSection-Cards de hábitos')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('shopCosmeticsSection-Cards de usuario')),
        findsNothing,
      );
    });

    testWidgets('Cards filter shows only Cards de hábitos',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: items)));
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-habitCards')));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('shopCosmeticsSection-Fondos')), findsNothing);
      expect(
        find.byKey(const Key('shopCosmeticsSection-Cards de hábitos')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCosmeticsSection-Cards de usuario')),
        findsNothing,
      );
    });

    testWidgets('Usuario filter shows only Cards de usuario',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: items)));
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-userCards')));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('shopCosmeticsSection-Fondos')), findsNothing);
      expect(
        find.byKey(const Key('shopCosmeticsSection-Cards de hábitos')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('shopCosmeticsSection-Cards de usuario')),
        findsOneWidget,
      );
    });

    testWidgets('tapping item calls onItemPressed with itemId',
        (WidgetTester tester) async {
      String? pressedItemId;

      await tester.pumpWidget(
        _app(
          _screen(
            items: items,
            onItemPressed: (String itemId) => pressedItemId = itemId,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester.ensureVisible(find.byKey(const Key('shopCosmeticCard-wallpaper_warm_beige')));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tap(find.byKey(const Key('shopCosmeticCard-wallpaper_warm_beige')));
      await tester.pump(const Duration(milliseconds: 16));

      expect(pressedItemId, 'wallpaper_warm_beige');
    });

    testWidgets('equipped item shows visual indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            items: items,
            ownedItemIds: const <String>{'wallpaper_warm_beige'},
            equippedCosmetics: const EquippedCosmetics(
              backgroundItemId: 'wallpaper_warm_beige',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('shopCosmeticStatus-Equipped')), findsOneWidget);
      expect(find.text('Equipped'), findsOneWidget);
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
  int walletCoins = 240,
  Set<String> ownedItemIds = const <String>{},
  EquippedCosmetics equippedCosmetics = const EquippedCosmetics(),
  ValueChanged<String>? onItemPressed,
}) {
  return ShopCosmeticsScreen(
    walletCoins: walletCoins,
    items: items,
    ownedItemIds: ownedItemIds,
    equippedCosmetics: equippedCosmetics,
    onItemPressed: onItemPressed ?? (_) {},
  );
}
