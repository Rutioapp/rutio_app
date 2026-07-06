import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_collection.dart';
import 'package:rutio/features/shop/presentation/screens/shop_collections_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopCollectionsScreen', () {
    testWidgets('renders list of collections', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen()));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Colecciones'), findsOneWidget);
      expect(find.byKey(const Key('shopCollectionCard-minimal')), findsOneWidget);
      expect(find.byKey(const Key('shopCollectionCard-gradient')), findsOneWidget);
      expect(find.byKey(const Key('shopCollectionCard-landscape')), findsOneWidget);
    });

    testWidgets('shows progress', (WidgetTester tester) async {
      final int minimalTotal = ShopCatalog.itemsByCollection('minimal').length;
      await tester.pumpWidget(
        _app(
          _screen(
            ownedItemIds: const <String>{
              'wallpaper_warm_beige',
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('shopCollectionProgress-minimal')), findsOneWidget);
      expect(find.text('1 / $minimalTotal'), findsOneWidget);
    });

    testWidgets('orders unlocked first', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            ownedItemIds: const <String>{
              'wallpaper_warm_beige',
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      final double minimalDy =
          tester.getTopLeft(find.byKey(const Key('shopCollectionCard-minimal'))).dy;
      final double gradientDy =
          tester.getTopLeft(find.byKey(const Key('shopCollectionCard-gradient'))).dy;
      expect(minimalDy < gradientDy, isTrue);
    });

    testWidgets('tapping collection calls callback', (WidgetTester tester) async {
      String? pressedCollectionId;

      await tester.pumpWidget(
        _app(
          _screen(
            onCollectionPressed: (String collectionId) {
              pressedCollectionId = collectionId;
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.byKey(const Key('shopCollectionCard-minimal')));
      await tester.pump(const Duration(milliseconds: 16));

      expect(pressedCollectionId, 'minimal');
    });

    testWidgets('empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          ShopCollectionsScreen(
            walletCoins: 320,
            collections: const <ShopCollection>[],
            ownedItemIds: const <String>{},
            onBackPressed: () {},
            onCollectionPressed: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('No hay colecciones disponibles.'), findsOneWidget);
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

ShopCollectionsScreen _screen({
  Set<String> ownedItemIds = const <String>{},
  ValueChanged<String>? onCollectionPressed,
}) {
  return ShopCollectionsScreen(
    walletCoins: 320,
    collections: ShopCatalog.allCollections,
    ownedItemIds: ownedItemIds,
    onBackPressed: () {},
    onCollectionPressed: onCollectionPressed ?? (_) {},
  );
}
