import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/screens/shop_item_detail_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ShopItem cosmeticItem = ShopCatalog.getItemById('wallpaper_mist_blue')!;
  final ShopItem utilityItem = ShopCatalog.getItemById('utility_xp_boost_1d')!;
  final ShopItem coinBoostItem =
      ShopCatalog.getItemById('utility_coin_boost_1d')!;
  final ShopItem streakRecoverItem =
      ShopCatalog.getItemById('utility_streak_recover_1')!;
  final ShopItem streakShieldItem =
      ShopCatalog.getItemById('utility_streak_shield_1')!;

  group('ShopItemDetailScreen', () {
    testWidgets('renders title name and description',
        (WidgetTester tester) async {
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
      expect(find.text('Mist Blue Wallpaper'), findsAtLeastNWidgets(1));
      expect(
          find.byKey(const Key('shopItemDetailDescription')), findsOneWidget);
      expect(
        find.text('Fondo azul niebla suave para una base limpia y serena.'),
        findsOneWidget,
      );
    });

    testWidgets('shows walletCoins', (WidgetTester tester) async {
      await tester
          .pumpWidget(_app(_screen(item: cosmeticItem, walletCoins: 540)));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('540'), findsOneWidget);
    });

    testWidgets('unowned item shows Comprar', (WidgetTester tester) async {
      await tester
          .pumpWidget(_app(_screen(item: cosmeticItem, walletCoins: 540)));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Comprar'), findsOneWidget);
    });

    testWidgets('insufficient balance shows disabled button',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(_app(_screen(item: cosmeticItem, walletCoins: 10)));
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
      expect(
          find.byKey(const Key('shopItemDetailStatusValue')), findsOneWidget);
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

    testWidgets('XP Boost detail renders summary content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            item: utilityItem,
            walletCoins: 540,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('XP Boost 1 Dia'), findsOneWidget);
      expect(find.text('Utilidad'), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const Key('shopItemDetailTitle'))).dy <
            tester
                .getTopLeft(
                  find.byKey(const Key('shopItemDetailUtilityPreview')),
                )
                .dy,
        isTrue,
      );
      expect(
        find.text(
            'Aumenta temporalmente la experiencia obtenida al completar habitos.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('shopItemDetailTitle')), findsOneWidget);
      expect(
          find.byKey(const Key('shopItemDetailDescription')), findsOneWidget);
      expect(
        find.byKey(const Key('shopItemDetailUtilityTypeValue')),
        findsOneWidget,
      );
      expect(
        find.text('24 horas'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopItemDetailUtilityEffectValue')),
        findsOneWidget,
      );
      expect(find.text('75 coins'), findsOneWidget);
      expect(find.text('Comprar'), findsOneWidget);
      expect(find.text('Necesitas mas monedas para conseguir esta utilidad.'),
          findsNothing);
    });

    testWidgets('Coin Boost detail renders summary content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            item: coinBoostItem,
            walletCoins: 540,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Coin Boost 1 Dia'), findsOneWidget);
      expect(find.text('Utilidad'), findsNothing);
      expect(
        find.text(
            'Aumenta temporalmente las monedas obtenidas al completar habitos.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopItemDetailUtilityTypeValue')),
        findsOneWidget,
      );
      expect(find.text('24 horas'), findsOneWidget);
      expect(
        find.byKey(const Key('shopItemDetailUtilityEffectValue')),
        findsOneWidget,
      );
      expect(find.text('100 coins'), findsOneWidget);
      expect(find.text('Comprar'), findsOneWidget);
    });

    testWidgets('Streak Recover detail renders summary content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            item: streakRecoverItem,
            walletCoins: 540,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Streak Recover'), findsOneWidget);
      expect(find.text('Utilidad'), findsNothing);
      expect(
        find.text('Permite recuperar una racha perdida una vez.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopItemDetailUtilityTypeValue')),
        findsOneWidget,
      );
      expect(find.text('1 uso'), findsOneWidget);
      expect(
        find.byKey(const Key('shopItemDetailUtilityEffectValue')),
        findsOneWidget,
      );
      expect(find.text('250 coins'), findsOneWidget);
      expect(find.text('Comprar'), findsOneWidget);
    });

    testWidgets('Streak Shield detail renders summary content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            item: streakShieldItem,
            walletCoins: 540,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Streak Shield'), findsOneWidget);
      expect(find.text('Utilidad'), findsNothing);
      expect(
        find.text('Protege una racha frente a un dia fallado.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopItemDetailUtilityTypeValue')),
        findsOneWidget,
      );
      expect(find.text('1 uso'), findsOneWidget);
      expect(
        find.byKey(const Key('shopItemDetailUtilityEffectValue')),
        findsOneWidget,
      );
      expect(find.text('300 coins'), findsOneWidget);
      expect(find.text('Comprar'), findsOneWidget);
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

    testWidgets('tap Equipar calls onEquipPressed',
        (WidgetTester tester) async {
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
