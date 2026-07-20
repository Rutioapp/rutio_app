import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_snapshot.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_errors.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_snapshot.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';

void main() {
  test(
      'cloud cosmetics snapshot updatedAt follows remote row timestamps only',
      () {
    final fetchedAt = DateTime.utc(2026, 7, 20, 12);
    final equippedAt = DateTime.utc(2026, 7, 20, 11);
    final inventoryUpdatedAt = DateTime.utc(2026, 7, 20, 9);
    final snapshot = ShopCloudSnapshot(
      authenticatedUserId: 'cloud-user',
      catalogItems: const <RemoteShopItemDto>[],
      wallet: null,
      inventory: <RemoteInventoryItemDto>[
        RemoteInventoryItemDto(
          id: 'inventory-row-1',
          userId: 'cloud-user',
          itemId: 'wallpaper_dusty_lilac',
          quantity: 1,
          acquisitionSource: 'purchase',
          acquiredAt: inventoryUpdatedAt,
          updatedAt: inventoryUpdatedAt,
        ),
      ],
      equippedCosmetics: <RemoteEquippedCosmeticDto>[
        RemoteEquippedCosmeticDto(
          userId: 'cloud-user',
          slot: RemoteShopEquipSlot.screenBackground,
          itemId: 'wallpaper_dusty_lilac',
          equippedAt: equippedAt,
        ),
      ],
      fetchedAt: fetchedAt,
      catalogVersion: 7,
      warnings: const <ShopCloudWarning>[],
    );

    final cloudSnapshot = CloudCosmeticsSnapshot.fromShopSnapshot(snapshot);

    expect(cloudSnapshot.fetchedAt, fetchedAt);
    expect(cloudSnapshot.updatedAt, equippedAt);
    expect(cloudSnapshot.updatedAt, isNot(fetchedAt));
    expect(cloudSnapshot.equippedWallpaperId, 'wallpaper_dusty_lilac');
    expect(
      cloudSnapshot.ownedAssetIds,
      contains('wallpaper_dusty_lilac'),
    );
    expect(
      ShopAssetsCatalog.getAssetById(cloudSnapshot.equippedWallpaperId!),
      isNotNull,
    );
  });

  test('compareCloudCosmeticsSnapshots prefers the newer equip revision', () {
    final confirmed = CloudCosmeticsSnapshot(
      userId: 'cloud-user',
      ownedAssetIds: const <String>[
        'wallpaper_mist_blue',
        'wallpaper_dusty_lilac',
      ],
      equippedWallpaperId: 'wallpaper_dusty_lilac',
      equippedHabitCardSkinId: null,
      equippedUserCardSkinId: null,
      catalogVersion: 7,
      fetchedAt: DateTime.utc(2026, 7, 20, 11),
      updatedAt: DateTime.utc(2026, 7, 20, 11),
    );
    final staleRead = CloudCosmeticsSnapshot(
      userId: 'cloud-user',
      ownedAssetIds: const <String>[
        'wallpaper_mist_blue',
        'wallpaper_dusty_lilac',
      ],
      equippedWallpaperId: 'wallpaper_mist_blue',
      equippedHabitCardSkinId: null,
      equippedUserCardSkinId: null,
      catalogVersion: 7,
      fetchedAt: DateTime.utc(2026, 7, 20, 12),
      updatedAt: DateTime.utc(2026, 7, 20, 10),
    );

    final comparison = compareCloudCosmeticsSnapshots(staleRead, confirmed);

    expect(comparison.isNewerOrEqual, isFalse);
    expect(comparison.replacedBy, confirmed);
  });
}
