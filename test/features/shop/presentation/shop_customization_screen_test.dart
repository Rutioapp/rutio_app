import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/screens/shop_customization_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<ShopItem> ownedItems = <ShopItem>[
    ShopCatalog.getItemById('wallpaper_warm_beige')!,
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

    testWidgets('renders sections', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: ownedItems)));
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.byKey(const Key('shopCustomizationSection-Fondos')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCustomizationSection-Habit Cards')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCustomizationSection-User Cards')),
        findsOneWidget,
      );
    });

    testWidgets('renders equipped objects', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            items: ownedItems,
            equippedCosmetics: const EquippedCosmetics(
              backgroundItemId: 'wallpaper_warm_beige',
              userCardItemId: 'user_card_dune_layers',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('shopOwnedStatus-wallpaper_warm_beige')), findsOneWidget);
      expect(find.byKey(const Key('shopOwnedStatus-user_card_dune_layers')), findsOneWidget);
      expect(find.text('Equipado'), findsAtLeastNWidgets(1));
    });

    testWidgets('Equipar button calls callback', (WidgetTester tester) async {
      String? pressedItemId;

      await tester.pumpWidget(
        _app(
          _screen(
            items: ownedItems,
            onEquipPressed: (String itemId) => pressedItemId = itemId,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester.ensureVisible(find.byKey(const Key('shopOwnedEquip-wallpaper_warm_beige')));
      await tester.tap(find.byKey(const Key('shopOwnedEquip-wallpaper_warm_beige')));
      await tester.pump(const Duration(milliseconds: 16));

      expect(pressedItemId, 'wallpaper_warm_beige');
    });

    testWidgets('equipped object shows correct state', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            items: ownedItems,
            equippedCosmetics: const EquippedCosmetics(
              backgroundItemId: 'wallpaper_warm_beige',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Equipado'), findsAtLeastNWidgets(1));
      expect(find.byKey(const Key('shopOwnedEquip-wallpaper_warm_beige')), findsOneWidget);
    });

    testWidgets('empty state appears when no objects', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            items: const <ShopItem>[],
            onOpenCosmetics: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Todavia no tienes cosméticos.'), findsOneWidget);
      expect(
        find.text('Compra nuevos objetos en la tienda para personalizar Rutio.'),
        findsOneWidget,
      );
      expect(find.text('Ir a Cosméticos'), findsOneWidget);
    });

    testWidgets('Ir a Cosméticos calls callback', (WidgetTester tester) async {
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

      await tester.tap(find.text('Ir a Cosméticos'));
      await tester.pump(const Duration(milliseconds: 16));

      expect(openedCosmetics, isTrue);
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
  ValueChanged<String>? onEquipPressed,
  ValueChanged<String>? onItemPressed,
  VoidCallback? onOpenCosmetics,
}) {
  return ShopCustomizationScreen(
    walletCoins: 640,
    equippedCosmetics: equippedCosmetics,
    ownedCosmeticItems: items,
    onBackPressed: () {},
    onEquipPressed: onEquipPressed ?? (_) {},
    onItemPressed: onItemPressed ?? (_) {},
    onOpenCosmetics: onOpenCosmetics,
  );
}
