import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_cache.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_snapshot.dart';
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
    expect(secondEntry?.snapshot.userId, 'user-b');
    expect(
      secondEntry?.snapshot.equippedUserCardSkinId,
      'user_card_full_moon',
    );
    expect(missingEntry, isNull);
  });
}
