import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_widgets.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shop foundation widgets', () {
    testWidgets('ShopWalletPill shows coin amount', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          const Center(
            child: ShopWalletPill(coins: 240),
          ),
        ),
      );

      expect(find.text('240'), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on_rounded), findsOneWidget);
    });

    testWidgets('ShopItemCard shows title and price', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          const Padding(
            padding: EdgeInsets.all(16),
            child: ShopItemCard(
              title: 'Camel Canvas',
              price: 100,
              description: 'Warm placeholder preview',
              rarity: ShopItemRarity.common,
            ),
          ),
        ),
      );

      expect(find.text('Camel Canvas'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('ShopPrimaryButton disabled does not call onPressed',
        (WidgetTester tester) async {
      var wasPressed = false;

      await tester.pumpWidget(
        _app(
          Center(
            child: ShopPrimaryButton(
              label: 'Buy',
              onPressed: null,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buy'));
      await tester.pump();

      expect(wasPressed, isFalse);
    });

    testWidgets('ShopEmptyState renders message', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          const Center(
            child: ShopEmptyState(
              title: 'Nothing here',
              message: 'New items will appear soon.',
            ),
          ),
        ),
      );

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('New items will appear soon.'), findsOneWidget);
    });
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: child,
    ),
  );
}
