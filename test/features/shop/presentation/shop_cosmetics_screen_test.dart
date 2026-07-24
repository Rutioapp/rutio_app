import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_errors.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_repository.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_snapshot.dart';
import 'package:rutio/features/global_wallet/data/cloud/wallet_cache.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/features/shop/presentation/screens/shop_cosmetics_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testUserId = 'shop-cosmetics-screen-user';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopCosmeticsScreen', () {
    testWidgets('renders cached state on the first frame',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
        findsOneWidget,
      );

      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'confirmed wallet balance updates the header without re-entering',
        (WidgetTester tester) async {
      final walletRepo = _FakeCloudWalletRepository()
        ..enqueueSuccess(
          _walletSnapshot(
            userId: 'shop-cosmetics-screen-user',
            coins: 777,
            version: 2,
            updatedAt: DateTime.utc(2026, 7, 19, 16),
          ),
        );
      final walletController = GlobalWalletController(
        repository: walletRepo,
        cache: _MemoryWalletCache(),
        currentUserIdProvider: () => 'shop-cosmetics-screen-user',
        enabled: true,
      );
      addTearDown(walletController.dispose);
      await walletController.applyConfirmedBalance(
        userId: 'shop-cosmetics-screen-user',
        coins: 600,
        version: 1,
        updatedAt: DateTime.utc(2026, 7, 19, 15),
      );
      final controller = await _createController(
        walletCoins: 600,
        globalWalletController: walletController,
      );

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('600'), findsWidgets);

      await walletController.applyConfirmedBalance(
        userId: 'shop-cosmetics-screen-user',
        coins: 777,
        version: 2,
        updatedAt: DateTime.utc(2026, 7, 19, 16),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('777'), findsWidgets);

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-packs')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('777'), findsWidgets);
    });

    testWidgets('shows cosmetics catalog with assets and packs',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shopHeaderTitle')), findsOneWidget);
      await _scrollToShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
      );
      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
        findsOneWidget,
      );
      await _scrollToShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsBundleCard-pack_beige_rutio')),
      );
      expect(
        find.byKey(const Key('shopCosmeticsBundleCard-pack_beige_rutio')),
        findsOneWidget,
      );
    });

    testWidgets('refresh updates the visible content after entry',
        (WidgetTester tester) async {
      final controller = await _createRefreshableController(
        walletCoins: 600,
        initialCosmeticsState: const ShopCosmeticsState.initial(),
        refreshedCosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>['wallpaper_mist_blue'],
          ownedBundleIds: const <String>[],
        ),
        refreshedWalletCoins: 720,
      );

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pump();

      final Finder card = await _scrollToShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
      );

      expect(
        find.descendant(of: card, matching: find.text('Comprar')),
        findsOneWidget,
      );

      controller.completeRefresh();
      await _drainBackgroundRefresh(tester);

      final Finder refreshedCard = await _scrollToShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
      );

      expect(
        find.descendant(of: refreshedCard, matching: find.text('Comprado')),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: refreshedCard,
          matching:
              find.byKey(const Key('shopCosmeticsAction-wallpaper_mist_blue')),
        ),
        findsNothing,
      );
    });

    testWidgets('only builds visible cards initially',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);
      await controller.getState();

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pump();

      expect(
        find.byKey(const Key('shopCosmeticsBundleCard-pack_manchas_salvajes')),
        findsNothing,
      );

      await _scrollToShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsBundleCard-pack_manchas_salvajes')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopCosmeticsBundleCard-pack_manchas_salvajes')),
        findsOneWidget,
      );
    });

    testWidgets('tabs filter wallpapers cards and packs correctly',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-wallpapers')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-habit_card_warm_beige')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('shopCosmeticsBundleCard-pack_beige_rutio')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-cards')));
      await tester.pumpAndSettle();
      final Finder habitCard = await _scrollToShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-habit_card_warm_beige')),
      );
      expect(habitCard, findsOneWidget);
      final Finder userCard = await _scrollToShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-user_card_warm_beige')),
      );
      expect(userCard, findsOneWidget);
      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-packs')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('shopCosmeticsGrid')),
        const Offset(0, 1200),
      );
      await tester.pumpAndSettle();
      await _scrollToShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsBundleCard-pack_beige_rutio')),
      );
      expect(
        find.byKey(const Key('shopCosmeticsBundleCard-pack_beige_rutio')),
        findsOneWidget,
      );
      expect(find.text('Nada por mostrar'), findsNothing);
      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
        findsNothing,
      );
    });

    testWidgets(
        'habit card catalog card renders only background swatch without applied content',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-cards')));
      await tester.pumpAndSettle();

      final Finder card = await _scrollToShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-habit_card_warm_beige')),
      );

      expect(card, findsOneWidget);
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(
            const Key('shopAssetVisualPreview-habit_card_warm_beige'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(
            const Key('shopHabitCardAppliedPreview-habit_card_warm_beige'),
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('Leer 10 min')),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('07:30')),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('3/7 esta semana')),
        findsNothing,
      );
    });

    testWidgets('locked states show Comprar and packs stay visible',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      final Finder card = await _scrollToShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
      );

      expect(
        find.descendant(
          of: card,
          matching: find.text('Comprar'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-packs')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopCosmeticsBundleCard-pack_beige_rutio')),
        findsOneWidget,
      );
      expect(find.text('Nada por mostrar'), findsNothing);
    });

    testWidgets('partially owned packs show the completion CTA',
        (WidgetTester tester) async {
      final controller = await _createController(
        walletCoins: 600,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>['wallpaper_rutio_beige'],
          ownedBundleIds: const <String>[],
        ),
      );

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-packs')));
      await tester.pumpAndSettle();

      expect(find.text('Completar pack'), findsOneWidget);
      expect(
        find.byKey(const Key('shopCosmeticsAction-pack_beige_rutio')),
        findsOneWidget,
      );
    });

    testWidgets('owned asset hides CTA and equipped asset shows state only',
        (WidgetTester tester) async {
      final controller = await _createController(
        walletCoins: 600,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>[
            'wallpaper_mist_blue',
            'habit_card_warm_beige',
          ],
          ownedBundleIds: const <String>[],
          equippedHabitCardSkinId: 'habit_card_warm_beige',
        ),
      );

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      final Finder card = await _scrollToShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
      );

      expect(
        find.descendant(
          of: card,
          matching: find.byKey(
            const Key('shopCosmeticsAction-wallpaper_mist_blue'),
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('Comprado')),
        findsWidgets,
      );

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-cards')));
      await tester.pumpAndSettle();

      final Finder habitCard = await _scrollToShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-habit_card_warm_beige')),
      );

      expect(
        find.descendant(
          of: habitCard,
          matching: find.text('Equipado'),
        ),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: habitCard,
          matching: find.byKey(
            const Key('shopCosmeticsAction-habit_card_warm_beige'),
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('tapping Comprar opens confirmation and does not buy yet',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('shopCosmeticsAction-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key(
              'shopCosmeticsPurchaseConfirmationConfirm-wallpaper_mist_blue'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-wallpaper_mist_blue'),
          ),
          matching: find.text('Comprar'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('canceling asset confirmation does not buy item',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('shopCosmeticsAction-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('shopCosmeticsPurchaseConfirmationCancel')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-wallpaper_mist_blue'),
          ),
          matching: find.text('Comprar'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('confirming asset purchase updates state to equipable',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('shopCosmeticsAction-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key(
              'shopCosmeticsPurchaseConfirmationConfirm-wallpaper_mist_blue'),
        ),
      );
      await tester.pumpAndSettle();

      final Finder refreshedCard = await _scrollToShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
      );

      expect(
        find.descendant(
          of: refreshedCard,
          matching:
              find.byKey(const Key('shopCosmeticsAction-wallpaper_mist_blue')),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: refreshedCard, matching: find.text('Comprado')),
        findsWidgets,
      );
    });

    testWidgets('insufficient balance does not allow purchase',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 10);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: await _scrollToShopItem(
            tester,
            find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
          ),
          matching: find.text('Saldo insuficiente'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('purchased asset keeps owned state without CTA in card',
        (WidgetTester tester) async {
      final controller = await _createController(
        walletCoins: 600,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>['wallpaper_mist_blue'],
          ownedBundleIds: const <String>[],
        ),
      );

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      final Finder card = await _scrollToShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
      );

      expect(
        find.descendant(
          of: card,
          matching: find.byKey(
            const Key('shopCosmeticsAction-wallpaper_mist_blue'),
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('Comprado')),
        findsWidgets,
      );
    });

    testWidgets('unowned cosmetics appear before owned cosmetics',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = await _createController(
        walletCoins: 600,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>['wallpaper_mist_blue'],
          ownedBundleIds: const <String>[],
        ),
      );

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      final List<String> visibleIds = _sortedVisibleEntryIds(controller.state!);
      expect(
        visibleIds.indexOf('shopCosmeticsAssetCard-habit_card_warm_beige') <
            visibleIds.indexOf('shopCosmeticsAssetCard-wallpaper_mist_blue'),
        isTrue,
      );
    });

    testWidgets('detail sheet shows rarity and packs filter shows packs',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await _tapVisibleShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
      );

      expect(find.byKey(const Key('shopCosmeticsDetailSheet')), findsOneWidget);
      expect(find.byKey(const Key('shopCosmeticsRarity-common')), findsWidgets);

      Navigator.of(
        tester.element(find.byKey(const Key('shopCosmeticsDetailSheet'))),
      ).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-packs')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('shopCosmeticsBundleCard-pack_beige_rutio')),
        findsOneWidget,
      );
      expect(find.text('Nada por mostrar'), findsNothing);
    });

    testWidgets('habit card detail sheet keeps applied preview',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-cards')));
      await tester.pumpAndSettle();
      await _tapVisibleShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-habit_card_warm_beige')),
      );

      expect(find.byKey(const Key('shopCosmeticsDetailSheet')), findsOneWidget);
      expect(
        find.byKey(
            const Key('shopHabitCardAppliedPreview-habit_card_warm_beige')),
        findsOneWidget,
      );
      expect(find.text('Leer 10 min'), findsOneWidget);
    });

    testWidgets('user card detail sheet keeps applied preview',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-cards')));
      await tester.pumpAndSettle();
      await _tapVisibleShopItem(
        tester,
        find.byKey(const Key('shopCosmeticsAssetCard-user_card_warm_beige')),
      );

      expect(find.byKey(const Key('shopCosmeticsDetailSheet')), findsOneWidget);
      expect(
        find.byKey(
            const Key('shopUserCardAppliedPreview-user_card_warm_beige')),
        findsOneWidget,
      );
      expect(find.text('Rutio User'), findsOneWidget);
    });

    testWidgets(
        'small-width cosmetics grid keeps habit card products stable without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-cards')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-habit_card_warm_beige')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
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

Future<Finder> _scrollToShopItem(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder);
    await tester.pump();
    return finder;
  }

  final Finder grid = find.byKey(const Key('shopCosmeticsGrid'));
  if (grid.evaluate().isEmpty) {
    throw StateError('No cosmetics grid found');
  }
  final Finder scrollable = find
      .descendant(
        of: grid,
        matching: find.byType(Scrollable),
      )
      .first;

  for (int attempt = 0; attempt < 2 && finder.evaluate().isEmpty; attempt++) {
    if (attempt == 1) {
      await tester.drag(scrollable, const Offset(0, 800));
      await tester.pumpAndSettle();
    }

    try {
      await tester.scrollUntilVisible(
        finder,
        600,
        scrollable: scrollable,
      );
      await tester.pump();
    } on StateError {
      // Try the opposite direction after the next reset pass.
    }
  }

  if (finder.evaluate().isEmpty) {
    throw StateError('Unable to reveal cosmetics item');
  }

  await tester.ensureVisible(finder);
  await tester.pump();
  return finder;
}

Future<void> _tapVisibleShopItem(WidgetTester tester, Finder finder) async {
  final Finder visibleFinder = await _scrollToShopItem(tester, finder);
  await tester.tap(visibleFinder);
  await tester.pumpAndSettle();
}

Future<void> _drainBackgroundRefresh(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

List<String> _sortedVisibleEntryIds(ShopCosmeticsState state) {
  final List<_TestShopEntry> entries = <_TestShopEntry>[
    ...ShopAssetsCatalog.allAssets.map(
      (ShopAsset asset) => _TestAssetEntry(
        id: 'shopCosmeticsAssetCard-${asset.id}',
        asset: asset,
        ownershipRank: _assetOwnershipRank(
          state.assetOwnershipState(
            asset,
            bundles: ShopAssetsCatalog.allBundles,
          ),
        ),
      ),
    ),
    ...ShopAssetsCatalog.allBundles.map(
      (ShopBundle bundle) => _TestBundleEntry(
        id: 'shopCosmeticsBundleCard-${bundle.id}',
        rarity: bundle.rarity,
        sortOrder: bundle.sortOrder,
        ownershipRank: 1,
        categoryOrder: 3,
      ),
    ),
  ]..sort(_compareTestEntries);

  return entries
      .map((_TestShopEntry entry) => entry.id)
      .toList(growable: false);
}

int _assetOwnershipRank(ShopAssetOwnershipState state) {
  switch (state) {
    case ShopAssetOwnershipState.locked:
      return 0;
    case ShopAssetOwnershipState.owned:
    case ShopAssetOwnershipState.includedInOwnedBundle:
    case ShopAssetOwnershipState.equipped:
      return 1;
  }
}

int _compareTestEntries(_TestShopEntry a, _TestShopEntry b) {
  final int ownershipCompare = a.ownershipRank.compareTo(b.ownershipRank);
  if (ownershipCompare != 0) return ownershipCompare;

  final int rarityCompare =
      _rarityOrder(a.rarity).compareTo(_rarityOrder(b.rarity));
  if (rarityCompare != 0) return rarityCompare;

  final int categoryCompare = a.categoryOrder.compareTo(b.categoryOrder);
  if (categoryCompare != 0) return categoryCompare;

  return a.sortOrder.compareTo(b.sortOrder);
}

int _rarityOrder(ShopAssetRarity rarity) {
  switch (rarity) {
    case ShopAssetRarity.common:
      return 0;
    case ShopAssetRarity.rare:
      return 1;
    case ShopAssetRarity.epic:
      return 2;
    case ShopAssetRarity.legendary:
      return 3;
  }
}

sealed class _TestShopEntry {
  const _TestShopEntry({
    required this.id,
    required this.rarity,
    required this.sortOrder,
    required this.ownershipRank,
    required this.categoryOrder,
  });

  final String id;
  final ShopAssetRarity rarity;
  final int sortOrder;
  final int ownershipRank;
  final int categoryOrder;
}

class _TestAssetEntry extends _TestShopEntry {
  _TestAssetEntry({
    required super.id,
    required this.asset,
    required super.ownershipRank,
  }) : super(
          rarity: asset.rarity,
          sortOrder: asset.sortOrder,
          categoryOrder: switch (asset.category) {
            ShopAssetCategory.wallpaper => 0,
            ShopAssetCategory.habitCard => 1,
            ShopAssetCategory.userCard => 2,
          },
        );

  final ShopAsset asset;
}

class _TestBundleEntry extends _TestShopEntry {
  _TestBundleEntry({
    required super.id,
    required super.rarity,
    required super.sortOrder,
    required super.ownershipRank,
    required super.categoryOrder,
  });
}

Future<ShopCosmeticsController> _createController({
  required int walletCoins,
  ShopCosmeticsState cosmeticsState = const ShopCosmeticsState.initial(),
  GlobalWalletController? globalWalletController,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final repository = await _shopRepository();
  await repository.save(cosmeticsState);

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope(testUserId);
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState(walletCoins: walletCoins));

  final controller = ShopCosmeticsController(
    userStateStore: store,
    globalWalletController: globalWalletController,
    cloudEnabled: false,
  );
  await controller.getState();
  addTearDown(() {
    controller.dispose();
    store.dispose();
  });
  return controller;
}

Future<_RefreshableShopCosmeticsController> _createRefreshableController({
  required int walletCoins,
  required ShopCosmeticsState initialCosmeticsState,
  required ShopCosmeticsState refreshedCosmeticsState,
  required int refreshedWalletCoins,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final repository = await _shopRepository();
  await repository.save(initialCosmeticsState);

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope(testUserId);
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState(walletCoins: walletCoins));

  final controller = _RefreshableShopCosmeticsController(
    userStateStore: store,
    initialState: initialCosmeticsState,
    initialWalletCoins: walletCoins,
    refreshedState: refreshedCosmeticsState,
    refreshedWalletCoins: refreshedWalletCoins,
  );
  addTearDown(() {
    controller.dispose();
    store.dispose();
  });
  return controller;
}

Map<String, dynamic> _baseState({
  required int walletCoins,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': testUserId,
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
        'diaryRewardAppliedDateKeys': <dynamic>[],
      },
      'progression': <String, dynamic>{
        'level': 1,
        'xp': 0,
        'prestige': 0,
      },
      'wallet': <String, dynamic>{'coins': walletCoins},
      'inventory': <String, dynamic>{'items': <dynamic>[]},
      'profile': <String, dynamic>{
        'equipped': <String, dynamic>{},
        'badges': <String, dynamic>{'owned': <dynamic>[], 'shown': null},
        'achievements': <String, dynamic>{
          'unlocked': <dynamic>[],
          'featured': <dynamic>[],
          'rewardAppliedAchievementIds': <dynamic>[],
          'progress': <String, dynamic>{},
        },
      },
      'claims': <String, dynamic>{
        'milestonesClaimed': <dynamic>[],
        'achievementRewardsClaimed': <dynamic>[],
        'prestigeClaimed': <dynamic>[],
      },
      'daily': <String, dynamic>{
        'lastResetDate': '2026-07-06',
        'xpEarnedToday': 0,
        'coinsEarnedToday': 0,
        'habitsCompletedToday': <String, dynamic>{},
      },
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitCountValues': <String, dynamic>{},
        'habitSkips': <String, dynamic>{},
        'habitCompletionTimes': <String, dynamic>{},
      },
      'familyXp': <String, dynamic>{
        'mind': 0,
        'spirit': 0,
        'body': 0,
        'emotional': 0,
        'social': 0,
        'discipline': 0,
        'professional': 0,
      },
      'activeHabits': <dynamic>[],
    },
  };
}

Future<ShopCosmeticsRepository> _shopRepository() async {
  final preferences = await SharedPreferences.getInstance();
  return ShopCosmeticsRepository(
    sharedPreferencesProvider: () async => preferences,
    scopeResolver: () => testUserId,
  );
}

class _RefreshableShopCosmeticsController extends ShopCosmeticsController {
  _RefreshableShopCosmeticsController({
    required super.userStateStore,
    required ShopCosmeticsState initialState,
    required int initialWalletCoins,
    required ShopCosmeticsState refreshedState,
    required int refreshedWalletCoins,
  })  : _state = initialState,
        _walletCoins = initialWalletCoins,
        _refreshedState = refreshedState,
        _refreshedWalletCoins = refreshedWalletCoins,
        super(cloudEnabled: false);

  ShopCosmeticsState _state;
  int _walletCoins;
  final ShopCosmeticsState _refreshedState;
  final int _refreshedWalletCoins;
  final Completer<ShopCosmeticsState> _stateCompleter =
      Completer<ShopCosmeticsState>();

  @override
  ShopCosmeticsState? get state => _state;

  @override
  Future<ShopCosmeticsState> getState() {
    return _stateCompleter.future.then((ShopCosmeticsState value) {
      _state = value;
      return value;
    });
  }

  @override
  Future<int> getWalletCoins() {
    return Future<int>.value(_walletCoins);
  }

  void completeRefresh() {
    if (!_stateCompleter.isCompleted) {
      _stateCompleter.complete(_refreshedState);
    }
    _walletCoins = _refreshedWalletCoins;
  }
}

class _FakeCloudWalletRepository implements CloudWalletRepository {
  final List<Future<WalletReadResult<CloudWalletSnapshot>>> _responses =
      <Future<WalletReadResult<CloudWalletSnapshot>>>[];

  void enqueueSuccess(CloudWalletSnapshot snapshot) {
    _responses.add(
      Future<WalletReadResult<CloudWalletSnapshot>>.value(
        WalletReadResult<CloudWalletSnapshot>.success(data: snapshot),
      ),
    );
  }

  @override
  Future<WalletReadResult<CloudWalletSnapshot>> fetchWallet() {
    if (_responses.isEmpty) {
      throw StateError('No queued wallet response.');
    }
    return _responses.removeAt(0);
  }
}

class _MemoryWalletCache implements WalletCache {
  final Map<String, WalletCacheEntry> _entries = <String, WalletCacheEntry>{};

  @override
  Future<WalletCacheEntry?> read(String userId) async => _entries[userId];

  @override
  Future<WalletCacheEntry?> save(CloudWalletSnapshot snapshot) async {
    final next = WalletCacheEntry.fromSnapshot(
      snapshot,
      cachedAt: DateTime.now().toUtc(),
    );
    _entries[snapshot.userId] = next;
    return next;
  }

  @override
  Future<void> clearForUser(String userId) async {
    _entries.remove(userId);
  }
}

CloudWalletSnapshot _walletSnapshot({
  required String userId,
  required int coins,
  required int version,
  required DateTime updatedAt,
}) {
  return CloudWalletSnapshot(
    userId: userId,
    coins: coins,
    version: version,
    createdAt: updatedAt,
    updatedAt: updatedAt,
    fetchedAt: updatedAt,
  );
}
