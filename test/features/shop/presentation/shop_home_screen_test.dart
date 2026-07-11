import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/presentation/screens/shop_home_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopHomeScreen', () {
    testWidgets('renders title Tienda', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen()));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Tienda'), findsOneWidget);
    });

    testWidgets('shows walletCoins', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(walletCoins: 480)));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('480'), findsOneWidget);
    });

    testWidgets('main shop screen shows drawer button instead of back',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen()));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    });

    testWidgets('shows main entry points', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen()));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Cosméticos'), findsOneWidget);
      expect(find.text('Utilidades'), findsOneWidget);
      expect(find.text('Colecciones'), findsNothing);
    });

    testWidgets('tapping Cosméticos calls onOpenCosmetics',
        (WidgetTester tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        _app(
          _screen(
            onOpenCosmetics: () => tapCount++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester.ensureVisible(find.text('Cosméticos'));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tap(find.text('Cosméticos'));
      await tester.pump(const Duration(milliseconds: 16));

      expect(tapCount, 1);
    });

    testWidgets('tapping Utilidades calls onOpenUtilities',
        (WidgetTester tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        _app(
          _screen(
            onOpenUtilities: () => tapCount++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester.ensureVisible(find.text('Utilidades'));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tap(find.text('Utilidades'));
      await tester.pump(const Duration(milliseconds: 16));

      expect(tapCount, 1);
    });

    testWidgets('does not show collections section', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen()));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Destacado'), findsNothing);
      expect(find.text('Landscape'), findsNothing);
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
  int walletCoins = 240,
  VoidCallback? onOpenCosmetics,
  VoidCallback? onOpenUtilities,
}) {
  return ShopHomeScreen(
    walletCoins: walletCoins,
    onOpenCosmetics: onOpenCosmetics ?? () {},
    onOpenUtilities: onOpenUtilities ?? () {},
  );
}
