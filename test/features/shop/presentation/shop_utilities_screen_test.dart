import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/screens/shop_utilities_screen.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_utility_item_card.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopUtilitiesScreen', () {
    testWidgets('shows all utility filters and switches sections',
        (WidgetTester tester) async {
      final List<ShopItem> items = <ShopItem>[
        _item(
          id: 'utility_xp_boost_1d',
          title: 'XP Boost 1 Day',
          type: ShopItemType.xpBoost,
        ),
        _item(
          id: 'utility_coin_boost_1d',
          title: 'Coin Boost 1 Day',
          type: ShopItemType.coinBoost,
        ),
        _item(
          id: 'utility_streak_recover',
          title: 'Streak Recovery',
          type: ShopItemType.streakRecover,
        ),
        _item(
          id: 'utility_streak_shield',
          title: 'Streak Shield',
          type: ShopItemType.streakShield,
        ),
        _item(
          id: 'utility_mystery_box_basic',
          title: 'Mystery Box',
          type: ShopItemType.mysteryBox,
        ),
      ];

      await tester.pumpWidget(
        _app(
          ShopUtilitiesScreen(
            walletCoins: 250,
            items: items,
            onItemPressed: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shopUtilitiesFilter-all')), findsOneWidget);
      expect(
        find.byKey(const Key('shopUtilitiesFilter-boosts')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopUtilitiesFilter-streaks')),
        findsOneWidget,
      );
      expect(
          find.byKey(const Key('shopUtilitiesSection-Boosts')), findsOneWidget);
      expect(
          find.byKey(const Key('shopUtilitiesSection-Rachas')), findsOneWidget);

      await tester.tap(find.byKey(const Key('shopUtilitiesFilter-boosts')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('shopUtilitiesSection-Boosts')), findsOneWidget);
      expect(
          find.byKey(const Key('shopUtilitiesSection-Rachas')), findsNothing);

      await tester.tap(find.byKey(const Key('shopUtilitiesFilter-streaks')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('shopUtilitiesSection-Boosts')), findsNothing);
      expect(
          find.byKey(const Key('shopUtilitiesSection-Rachas')), findsOneWidget);
    });

    testWidgets(
        'mystery box uses a larger visual scale without breaking layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          ShopUtilitiesScreen(
            walletCoins: 250,
            items: <ShopItem>[
              _item(
                id: 'utility_mystery_box_basic',
                title: 'Mystery Box',
                type: ShopItemType.mysteryBox,
                assetRef: 'assets/shop/utilities/mystery_box_basic.png',
              ),
            ],
            onItemPressed: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.byKey(const Key('shopUtilityAssetArt-utility_mystery_box_basic')),
        findsOneWidget,
      );
      expect(find.byType(ShopUtilityItemCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    home: child,
  );
}

ShopItem _item({
  required String id,
  required String title,
  required ShopItemType type,
  String? assetRef,
}) {
  return ShopItem(
    id: id,
    title: title,
    type: type,
    rarity: ShopItemRarity.rare,
    priceCoins: 50,
    assetRef: assetRef ?? 'assets/images/shop/utilities/$id.png',
  );
}
