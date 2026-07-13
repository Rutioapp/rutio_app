import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/screens/shop_cosmetic_detail_screen.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_wallet_pill.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ShopItem backgroundItem =
      ShopCatalog.getItemById('wallpaper_mist_blue')!;
  final ShopItem habitCardItem =
      ShopCatalog.getItemById('habit_card_warm_beige')!;
  final ShopItem userCardItem =
      ShopCatalog.getItemById('user_card_dune_layers')!;

  group('ShopCosmeticDetailScreen', () {
    testWidgets('renders background detail without Comprar',
        (WidgetTester tester) async {
      String? pressedId;

      await tester.pumpWidget(
        _app(
          _screen(
            item: backgroundItem,
            onEquipPressed: (String itemId) => pressedId = itemId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopCosmeticDetailPreview-background')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('shopCosmeticDetailPreview-background')),
          matching: find.text('Rutio User'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('shopCosmeticDetailPreview-background')),
          matching: find.text('Leer 10 min'),
        ),
        findsNothing,
      );
      expect(find.byType(ShopWalletPill), findsNothing);
      expect(find.text('Comprar'), findsNothing);
      expect(find.text('Equipar'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('shopCosmeticDetailActionButton')),
      );
      await tester.tap(find.byKey(const Key('shopCosmeticDetailActionButton')));
      await tester.pumpAndSettle();

      expect(pressedId, backgroundItem.id);
    });

    testWidgets('renders habit card detail with info',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(item: habitCardItem)));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopCosmeticDetailPreview-habitCard')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('shopCosmeticDetailStatusValue')),
          findsOneWidget);
      expect(find.text('Minimal'), findsOneWidget);
      expect(find.text('Comprar'), findsNothing);
    });

    testWidgets('equipped user card shows disabled Equipado',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            item: userCardItem,
            isEquipped: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopCosmeticDetailPreview-userCard')),
        findsOneWidget,
      );
      expect(find.text('Equipado'), findsAtLeastNWidgets(1));
      final button = tester.widget<ShopPrimaryButton>(
        find.byKey(const Key('shopCosmeticDetailActionButton')),
      );
      expect(button.onPressed, isNull);
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
  bool isEquipped = false,
  ValueChanged<String>? onEquipPressed,
}) {
  return ShopCosmeticDetailScreen(
    item: item,
    isEquipped: isEquipped,
    collectionName: 'Minimal',
    onBackPressed: () {},
    onEquipPressed: onEquipPressed ?? (_) {},
  );
}
