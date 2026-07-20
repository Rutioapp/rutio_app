import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_purchase_confirmation_sheet.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ShopItem item = ShopCatalog.getItemById('wallpaper_mist_blue')!;

  group('ShopPurchaseConfirmationSheet', () {
    testWidgets('shows item price and walletCoins',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          ShopPurchaseConfirmationSheet(
            item: item,
            walletCoins: 240,
            onCancel: () {},
            onConfirm: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Mist Blue Wallpaper'), findsOneWidget);
      expect(find.text('120 monedas'), findsAtLeastNWidgets(1));
      expect(find.text('240 monedas'), findsOneWidget);
    });

    testWidgets('calculates remaining balance after purchase',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          ShopPurchaseConfirmationSheet(
            item: item,
            walletCoins: 240,
            onCancel: () {},
            onConfirm: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('120 monedas'), findsAtLeastNWidgets(1));
    });

    testWidgets('disables purchase when there are not enough coins',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          ShopPurchaseConfirmationSheet(
            item: item,
            walletCoins: 40,
            onCancel: () {},
            onConfirm: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Saldo insuficiente'), findsAtLeastNWidgets(1));
    });

    testWidgets('pressing Cancelar calls onCancel',
        (WidgetTester tester) async {
      var cancelCount = 0;

      await tester.pumpWidget(
        _app(
          ShopPurchaseConfirmationSheet(
            item: item,
            walletCoins: 240,
            onCancel: () => cancelCount++,
            onConfirm: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.text('Cancelar'));
      await tester.pump(const Duration(milliseconds: 16));

      expect(cancelCount, 1);
    });

    testWidgets('pressing Comprar calls onConfirm with itemId',
        (WidgetTester tester) async {
      String? confirmedId;

      await tester.pumpWidget(
        _app(
          ShopPurchaseConfirmationSheet(
            item: item,
            walletCoins: 240,
            onCancel: () {},
            onConfirm: (String itemId) => confirmedId = itemId,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.text('Comprar'));
      await tester.pump(const Duration(milliseconds: 16));

      expect(confirmedId, item.id);
    });
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('es'),
    theme: AppTheme.theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}
