import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/application/bootstrap/home_background_bootstrapper.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('preloads the equipped wallpaper asset and becomes ready',
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
    final controller = ShopCosmeticsController(userStateStore: store);
    final precachedAssets = <String>[];
    final bootstrapper = HomeBackgroundBootstrapper(
      controller: controller,
      precacheImageCallback: (provider, context) async {
        precachedAssets.add((provider as AssetImage).assetName);
      },
    );

    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Placeholder(),
    ));

    final result =
        await bootstrapper.prepare(tester.element(find.byType(Placeholder)));

    expect(result.usedFallback, isFalse);
    expect(result.didPrecacheCustomWallpaper, isTrue);
    expect(
      precachedAssets,
      <String>['assets/shop/wallpapers/common/wallpaper_mist_blue.webp'],
    );
  });

  testWidgets('falls back when wallpaper precache fails', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ShopCosmeticsRepository().save(
      ShopCosmeticsState(
        ownedAssetIds: const <String>['wallpaper_mist_blue'],
        ownedBundleIds: const <String>[],
        equippedWallpaperId: 'wallpaper_mist_blue',
      ),
    );

    final store = await _createStore();
    final controller = ShopCosmeticsController(userStateStore: store);
    final bootstrapper = HomeBackgroundBootstrapper(
      controller: controller,
      precacheImageCallback: (_, __) async {
        throw StateError('decode failed');
      },
    );

    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Placeholder(),
    ));

    final result =
        await bootstrapper.prepare(tester.element(find.byType(Placeholder)));

    expect(result.usedFallback, isTrue);
    expect(result.didPrecacheCustomWallpaper, isFalse);
    expect(result.wallpaperAsset, isNull);
  });

  testWidgets('invalid wallpaper id uses fallback and does not precache',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ShopCosmeticsRepository().save(
      ShopCosmeticsState(
        ownedAssetIds: const <String>[],
        ownedBundleIds: const <String>[],
        equippedWallpaperId: 'wallpaper_missing',
      ),
    );

    final store = await _createStore();
    final controller = ShopCosmeticsController(userStateStore: store);
    var precacheCalls = 0;
    final bootstrapper = HomeBackgroundBootstrapper(
      controller: controller,
      precacheImageCallback: (_, __) async {
        precacheCalls += 1;
      },
    );

    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Placeholder(),
    ));

    final result =
        await bootstrapper.prepare(tester.element(find.byType(Placeholder)));

    expect(result.usedFallback, isTrue);
    expect(result.didPrecacheCustomWallpaper, isFalse);
    expect(precacheCalls, 0);
  });
}

Future<UserStateStore> _createStore() async {
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('bootstrap-test-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(
    <String, dynamic>{
      'userState': <String, dynamic>{
        'userId': 'bootstrap-test-user',
        'wallet': <String, dynamic>{'coins': 120},
      },
    },
  );
  return store;
}
