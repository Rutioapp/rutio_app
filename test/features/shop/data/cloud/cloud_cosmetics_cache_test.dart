import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_cache.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_snapshot.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cloud cosmetics cache isolates entries by user id', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final cache = SharedPreferencesCloudCosmeticsCache();
    final now = DateTime.utc(2026, 7, 19, 12);

    final first = CloudCosmeticsSnapshot(
      userId: 'user-a',
      ownedAssetIds: const <String>['wallpaper_mist_blue'],
      ownedBundleIds: const <String>['pack_beige_rutio'],
      catalogBundles: const <RemoteShopBundleDto>[],
      equippedWallpaperId: 'wallpaper_mist_blue',
      equippedHabitCardSkinId: null,
      equippedUserCardSkinId: null,
      catalogVersion: 1,
      fetchedAt: now,
      updatedAt: now,
    );
    final second = CloudCosmeticsSnapshot(
      userId: 'user-b',
      ownedAssetIds: const <String>['user_card_full_moon'],
      ownedBundleIds: const <String>[],
      catalogBundles: const <RemoteShopBundleDto>[],
      equippedWallpaperId: null,
      equippedHabitCardSkinId: null,
      equippedUserCardSkinId: 'user_card_full_moon',
      catalogVersion: 1,
      fetchedAt: now,
      updatedAt: now,
    );

    await cache.save(first);
    await cache.save(second);

    final firstEntry = await cache.read('user-a');
    final secondEntry = await cache.read('user-b');
    final missingEntry = await cache.read('user-c');

    expect(firstEntry?.snapshot.userId, 'user-a');
    expect(firstEntry?.snapshot.ownedAssetIds, contains('wallpaper_mist_blue'));
    expect(firstEntry?.snapshot.ownedBundleIds, contains('pack_beige_rutio'));
    expect(secondEntry?.snapshot.userId, 'user-b');
    expect(
      secondEntry?.snapshot.equippedUserCardSkinId,
      'user_card_full_moon',
    );
    expect(missingEntry, isNull);
  });

  test('cloud cosmetics cache reads snapshots without ownedBundleIds',
      () async {
    final snapshot = CloudCosmeticsSnapshot.fromJson(
      <String, dynamic>{
        'userId': 'user-a',
        'ownedAssetIds': <String>['wallpaper_mist_blue'],
        'catalogBundles': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'pack_beige_rutio',
            'familyId': 'pack_beige_rutio',
            'rarity': 'common',
            'priceCoins': 300,
            'originalPriceCoins': 330,
            'isActive': true,
            'sortOrder': 0,
            'catalogVersion': 1,
            'createdAt': '2026-07-19T12:00:00Z',
            'updatedAt': '2026-07-19T12:00:00Z',
          },
        ],
        'equippedWallpaperId': 'wallpaper_mist_blue',
        'equippedHabitCardSkinId': null,
        'equippedUserCardSkinId': null,
        'catalogVersion': 1,
        'fetchedAt': '2026-07-19T12:00:00Z',
        'updatedAt': '2026-07-19T12:00:00Z',
      },
    );

    expect(snapshot.ownedBundleIds, isEmpty);
    expect(snapshot.catalogBundles, hasLength(1));
  });
}
