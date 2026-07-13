import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_widget.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/widgets/backgrounds/home_landscape_background.dart';
import 'package:rutio/widgets/home/user_identity_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('home background keeps fallback scene when no wallpaper is set',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const Stack(
          children: [
            HomeBackground(resolveEquippedWallpaper: false),
          ],
        ),
      ),
    );

    expect(find.byKey(const Key('homeBackgroundWallpaperImage')), findsNothing);
    expect(find.byKey(const Key('homeBackgroundDefaultBackground')),
        findsOneWidget);
    expect(find.byKey(const Key('homeBackgroundDefaultArt')), findsOneWidget);
  });

  testWidgets('home background renders equipped wallpaper image layer',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const Stack(
          children: [
            HomeBackground(
              resolveEquippedWallpaper: false,
              wallpaperAssetPath:
                  'assets/shop/wallpapers/common/wallpaper_mist_blue.webp',
            ),
          ],
        ),
      ),
    );

    expect(
        find.byKey(const Key('homeBackgroundWallpaperImage')), findsOneWidget);
    expect(find.byKey(const Key('homeBackgroundWallpaperOverlay')),
        findsOneWidget);
    expect(find.byKey(const Key('homeBackgroundDefaultArt')), findsOneWidget);
    expect(find.byKey(const Key('homeBackgroundDefaultBackground')),
        findsOneWidget);
  });

  testWidgets(
      'home background resolves equipped wallpaper from cosmetics state',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ShopCosmeticsRepository().save(
      ShopCosmeticsState(
        ownedAssetIds: const <String>['wallpaper_mist_blue'],
        ownedBundleIds: const <String>[],
        equippedWallpaperId: 'wallpaper_mist_blue',
      ),
    );
    final store = await _createStore();
    final cosmeticsController = ShopCosmeticsController(userStateStore: store);
    await cosmeticsController.hydrate();

    await tester.pumpWidget(
      _app(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserStateStore>.value(value: store),
            ChangeNotifierProvider<ShopCosmeticsController>.value(
              value: cosmeticsController,
            ),
          ],
          child: const Stack(
            children: [
              HomeBackground(),
            ],
          ),
        ),
      ),
    );

    expect(
        find.byKey(const Key('homeBackgroundWallpaperImage')), findsOneWidget);
    expect(find.byKey(const Key('homeBackgroundDefaultArt')), findsOneWidget);
  });

  testWidgets('home background invalid wallpaper falls back without crashing',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const Stack(
          children: [
            HomeBackground(
              resolveEquippedWallpaper: false,
              wallpaperAssetPath: 'assets/shop/wallpapers/common/missing.webp',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('homeBackgroundWallpaperImage')), findsOneWidget);
    expect(find.byKey(const Key('homeBackgroundDefaultBackground')),
        findsOneWidget);
    expect(find.byKey(const Key('homeBackgroundDefaultArt')), findsOneWidget);
  });

  testWidgets(
      'home background reacts to equipped wallpaper changes in the same session',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ShopCosmeticsRepository().save(
      ShopCosmeticsState(
        ownedAssetIds: const <String>[
          'wallpaper_mist_blue',
          'wallpaper_soft_sage',
        ],
        ownedBundleIds: const <String>[],
        equippedWallpaperId: 'wallpaper_mist_blue',
      ),
    );
    final store = await _createStore();
    final cosmeticsController = ShopCosmeticsController(userStateStore: store);
    await cosmeticsController.hydrate();

    await tester.pumpWidget(
      _app(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserStateStore>.value(value: store),
            ChangeNotifierProvider<ShopCosmeticsController>.value(
              value: cosmeticsController,
            ),
          ],
          child: const Stack(
            children: [
              HomeBackground(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_wallpaperAssetName(tester), contains('wallpaper_mist_blue'));

    await cosmeticsController.equipAsset('wallpaper_soft_sage');
    await tester.pumpAndSettle();

    expect(
      cosmeticsController.state?.equippedWallpaperId,
      'wallpaper_soft_sage',
    );
    expect(
      find.byKey(const Key('homeBackgroundWallpaperImage')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('homeBackgroundDefaultBackground')),
      findsOneWidget,
    );
  });

  testWidgets('habit card keeps fallback design when no skin is set',
      (tester) async {
    await tester.pumpWidget(
      _app(
        HabitCardWidget(
          title: 'Read',
          description: '20 min',
          familyColor: Colors.blue,
          progress: 0,
        ),
      ),
    );

    expect(find.byKey(const Key('habitCardBackgroundImage')), findsNothing);
  });

  testWidgets('habit card renders equipped skin image layer', (tester) async {
    await tester.pumpWidget(
      _app(
        HabitCardWidget(
          title: 'Read',
          description: '20 min',
          familyColor: Colors.blue,
          progress: 0,
          backgroundImageAssetPath:
              'assets/shop/habit_cards/common/habit_card_rutio_beige.webp',
        ),
      ),
    );

    expect(find.byKey(const Key('habitCardBackgroundImage')), findsOneWidget);
  });

  testWidgets('habit card applies configured alignment and overlay',
      (tester) async {
    final asset = ShopAssetsCatalog.getAssetById('habit_card_violet_flame')!;

    await tester.pumpWidget(
      _app(
        HabitCardWidget(
          title: 'Read',
          description: '20 min',
          familyColor: Colors.blue,
          progress: 0,
          backgroundImageAssetPath: asset.assetPath,
          backgroundImageProvider: asset.imageProvider,
          backgroundImageFit: asset.imageFit,
          backgroundImageAlignment: asset.imageAlignment,
          backgroundOverlayColor: asset.overlayColor,
          backgroundOverlayOpacity: asset.overlayOpacity,
        ),
      ),
    );

    final image = tester.widget<Image>(
      find.byKey(const Key('habitCardBackgroundImage')),
    );

    expect(image.fit, BoxFit.cover);
    expect(image.alignment, const Alignment(0.65, 0));
    expect(find.byType(ClipRRect), findsWidgets);
  });

  testWidgets('user identity row keeps fallback design when no skin is set',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const UserIdentityRow(
          username: 'Alex',
          level: 4,
          coins: 120,
          xpProgress: 0.5,
          backgroundImageAssetPath: null,
        ),
      ),
    );

    expect(
        find.byKey(const Key('userIdentityRowBackgroundImage')), findsNothing);
  });

  testWidgets('user identity row renders equipped skin image layer',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const UserIdentityRow(
          username: 'Alex',
          level: 4,
          coins: 120,
          xpProgress: 0.5,
          backgroundImageAssetPath:
              'assets/shop/user_cards/common/user_card_warm_beige.webp',
        ),
      ),
    );

    expect(find.byKey(const Key('userIdentityRowBackgroundImage')),
        findsOneWidget);
  });

  testWidgets(
      'user identity row resolves equipped user card from cosmetics state',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ShopCosmeticsRepository().save(
      ShopCosmeticsState(
        ownedAssetIds: const <String>['user_card_warm_beige'],
        ownedBundleIds: const <String>[],
        equippedUserCardSkinId: 'user_card_warm_beige',
      ),
    );
    final store = await _createStore();
    final cosmeticsController = ShopCosmeticsController(userStateStore: store);
    await cosmeticsController.hydrate();

    await tester.pumpWidget(
      _app(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserStateStore>.value(value: store),
            ChangeNotifierProvider<ShopCosmeticsController>.value(
              value: cosmeticsController,
            ),
          ],
          child: const UserIdentityRow(
            username: 'Alex',
            level: 4,
            coins: 120,
            xpProgress: 0.5,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('userIdentityRowBackgroundImage')),
        findsOneWidget);
  });
}

Future<UserStateStore> _createStore() async {
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('shop-equipment-ui-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(
    <String, dynamic>{
      'userState': <String, dynamic>{
        'userId': 'shop-equipment-ui-user',
        'wallet': <String, dynamic>{'coins': 120},
      },
    },
  );
  return store;
}

String _wallpaperAssetName(WidgetTester tester) {
  final image = tester.widget<Image>(
    find.byKey(const Key('homeBackgroundWallpaperImage')),
  );
  final provider = image.image;
  if (provider is AssetImage) {
    return provider.assetName;
  }
  return provider.toString();
}
