import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/presentation/models/backpack_item_view_model.dart';
import 'package:rutio/features/shop/presentation/screens/shop_backpack_screen.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopBackpackScreen', () {
    testWidgets('empty backpack shows EmptyState', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            items: const <BackpackItemViewModel>[],
            onOpenUtilities: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('La mochila esta vacia'), findsOneWidget);
      expect(
        find.text('Compra utilidades en la tienda para encontrarlas aqui.'),
        findsOneWidget,
      );
      expect(find.text('Ir a Utilidades'), findsOneWidget);
    });

    testWidgets('items show grouped sections', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: _items())));
      await tester.pump(const Duration(milliseconds: 16));

      expect(
          find.byKey(const Key('shopBackpackSection-Boosts')), findsOneWidget);
      expect(
          find.byKey(const Key('shopBackpackSection-Rachas')), findsOneWidget);
      expect(
          find.byKey(const Key('shopBackpackSection-Cajas')), findsOneWidget);
    });

    testWidgets('quantity appears correctly', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: _items())));
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.descendant(
          of: find.byKey(const Key('shopBackpackQuantity-utility_xp_boost_1d')),
          matching: find.text('x2'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopBackpackQuantity-utility_streak_recover_1'),
          ),
          matching: find.text('x1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopBackpackQuantity-utility_mystery_box_basic'),
          ),
          matching: find.text('x3'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Use button calls callback', (WidgetTester tester) async {
      String? usedItemId;

      await tester.pumpWidget(
        _app(
          _screen(
            items: _items(),
            onUsePressed: (String itemId) => usedItemId = itemId,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester
          .tap(find.byKey(const Key('shopBackpackUse-utility_xp_boost_1d')));
      await tester.pump(const Duration(milliseconds: 16));

      expect(usedItemId, 'utility_xp_boost_1d');
    });

    testWidgets('tapping card calls onItemPressed',
        (WidgetTester tester) async {
      String? pressedItemId;

      await tester.pumpWidget(
        _app(
          _screen(
            items: _items(),
            onItemPressed: (String itemId) => pressedItemId = itemId,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      final Offset tapPoint = tester.getTopLeft(
            find.byKey(const Key('shopBackpackCard-utility_xp_boost_1d')),
          ) +
          const Offset(20, 20);
      await tester.tapAt(tapPoint);
      await tester.pump(const Duration(milliseconds: 16));

      expect(pressedItemId, 'utility_xp_boost_1d');
    });

    testWidgets('empty state button calls onOpenUtilities',
        (WidgetTester tester) async {
      var openedUtilities = false;

      await tester.pumpWidget(
        _app(
          _screen(
            items: const <BackpackItemViewModel>[],
            onOpenUtilities: () {
              openedUtilities = true;
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.text('Ir a Utilidades'));
      await tester.pump(const Duration(milliseconds: 16));

      expect(openedUtilities, isTrue);
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
  required List<BackpackItemViewModel> items,
  ValueChanged<String>? onItemPressed,
  ValueChanged<String>? onUsePressed,
  VoidCallback? onOpenUtilities,
}) {
  return ShopBackpackScreen(
    walletCoins: 420,
    items: items,
    onBackPressed: () {},
    onItemPressed: onItemPressed ?? (_) {},
    onUsePressed: onUsePressed ?? (_) {},
    onOpenUtilities: onOpenUtilities,
  );
}

List<BackpackItemViewModel> _items() {
  return <BackpackItemViewModel>[
    const BackpackItemViewModel(
      itemId: 'utility_xp_boost_1d',
      title: 'XP Boost 1 Dia',
      description: 'Duplica la ganancia de XP durante un dia.',
      quantity: 2,
      rarity: ShopItemRarity.common,
      type: ShopItemType.xpBoost,
    ),
    const BackpackItemViewModel(
      itemId: 'utility_streak_recover_1',
      title: 'Streak Recover',
      description: 'Recupera una racha perdida una vez.',
      quantity: 1,
      rarity: ShopItemRarity.rare,
      type: ShopItemType.streakRecover,
    ),
    const BackpackItemViewModel(
      itemId: 'utility_mystery_box_basic',
      title: 'Mystery Box Basic',
      description: 'Caja misteriosa basica con sorpresa futura.',
      quantity: 3,
      rarity: ShopItemRarity.common,
      type: ShopItemType.mysteryBox,
    ),
  ];
}
