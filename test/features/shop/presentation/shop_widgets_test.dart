import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_widgets.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:rutio/widgets/currency/amber_coin_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shop foundation widgets', () {
    testWidgets('ShopWalletPill shows coin amount',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          const Center(
            child: ShopWalletPill(coins: 240),
          ),
        ),
      );

      expect(find.text('240'), findsOneWidget);
      expect(find.byType(AmberCoinIcon), findsOneWidget);
      expect(tester.getSize(find.byType(ShopWalletPill)).height,
          greaterThanOrEqualTo(36));
    });

    testWidgets('ShopHeader keeps title centered with wallet on the right',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 400,
            child: ShopHeader(
              title: 'Tienda',
              subtitle: 'Pulido visual',
              leadingIcon: Icons.menu_rounded,
              walletCoins: 123456789,
              useDrawerLeadingStyle: true,
            ),
          ),
        ),
      );

      final Offset titleCenter =
          tester.getCenter(find.byKey(const Key('shopHeaderTitle')));
      expect((titleCenter.dx - 200).abs(), lessThan(1.0));
    });

    testWidgets('ShopHeader keeps title centered without trailing action',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 400,
            child: ShopHeader(
              title: 'Detalle',
              leadingIcon: Icons.arrow_back_ios_new_rounded,
            ),
          ),
        ),
      );

      final Offset titleCenter =
          tester.getCenter(find.byKey(const Key('shopHeaderTitle')));
      expect((titleCenter.dx - 200).abs(), lessThan(1.0));
    });

    testWidgets('ShopHeader shows Colecciones fully on narrow width',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 360,
            child: ShopHeader(
              title: 'Colecciones',
              leadingIcon: Icons.arrow_back_ios_new_rounded,
              walletCoins: 240,
            ),
          ),
        ),
      );

      final RenderParagraph paragraph =
          tester.renderObject(find.text('Colecciones'));
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    testWidgets('ShopHeader shows Personalizar fully on narrow width',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 360,
            child: ShopHeader(
              title: 'Personalizar',
              leadingIcon: Icons.arrow_back_ios_new_rounded,
              walletCoins: 240,
            ),
          ),
        ),
      );

      final RenderParagraph paragraph =
          tester.renderObject(find.text('Personalizar'));
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    testWidgets('ShopHeader shows Cosméticos fully on narrow width',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 360,
            child: ShopHeader(
              title: 'Cosméticos',
              leadingIcon: Icons.arrow_back_ios_new_rounded,
              walletCoins: 240,
            ),
          ),
        ),
      );

      final RenderParagraph paragraph =
          tester.renderObject(find.text('Cosméticos'));
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    testWidgets('ShopItemCard shows title and price',
        (WidgetTester tester) async {
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
    locale: const Locale('es'),
    theme: AppTheme.theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: child,
    ),
  );
}
