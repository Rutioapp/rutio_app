import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/application/shop_operation_result.dart';
import 'package:rutio/features/shop/application/shop_service.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';

void main() {
  group('ShopState', () {
    test('serializes and deserializes safely', () {
      const state = ShopState(
        coins: 420,
        inventory: <OwnedShopItem>[
          OwnedShopItem(
            itemId: 'wallpaper_warm_beige',
            quantity: 1,
            acquiredAtMillis: 123456,
            source: 'shop_purchase',
          ),
        ],
        backpackItems: <BackpackItem>[
          BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 2),
        ],
        equippedCosmetics: EquippedCosmetics(
          backgroundItemId: 'wallpaper_warm_beige',
        ),
      );

      final restored = ShopState.fromJson(state.toJson());

      expect(restored, state);
    });

    test('copyWith updates fields', () {
      const state = ShopState(coins: 10);

      final updated = state.copyWith(
        coins: 30,
        backpackItems: const <BackpackItem>[
          BackpackItem(itemId: 'utility_coin_boost_1d', quantity: 1),
        ],
      );

      expect(updated.coins, 30);
      expect(updated.backpackItems, hasLength(1));
    });
  });

  group('ShopService', () {
    test('purchases a cosmetic correctly', () {
      final item = ShopCatalog.getItemById('wallpaper_warm_beige')!;
      final service = ShopService(
        state: const ShopState(coins: 999),
        walletCoins: 200,
        nowMillisProvider: () => 111,
      );

      final result = service.purchaseItem(item);

      expect(result.status, ShopOperationStatus.success);
      expect(result.walletCoins, 80);
      expect(result.state.coins, 999);
      expect(result.state.inventory, hasLength(1));
      expect(result.state.inventory.first.itemId, 'wallpaper_warm_beige');
      expect(result.state.inventory.first.acquiredAtMillis, 111);
    });

    test('purchases a utility correctly', () {
      final item = ShopCatalog.getItemById('utility_xp_boost_1d')!;
      final service = ShopService(
        state: const ShopState(coins: 777),
        walletCoins: 200,
      );

      final result = service.purchaseItem(item);

      expect(result.status, ShopOperationStatus.success);
      expect(result.walletCoins, 125);
      expect(result.state.coins, 777);
      expect(
        result.state.backpackItems,
        const <BackpackItem>[
          BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 1),
        ],
      );
    });

    test('purchasing the same utility twice increments backpack quantity', () {
      final item = ShopCatalog.getItemById('utility_xp_boost_1d')!;
      final firstPurchase = ShopService(
        state: const ShopState(),
        walletCoins: 300,
      ).purchaseItem(item);

      final secondPurchase = ShopService(
        state: firstPurchase.state,
        walletCoins: firstPurchase.walletCoins,
      ).purchaseItem(item);

      expect(secondPurchase.status, ShopOperationStatus.success);
      expect(secondPurchase.walletCoins, 150);
      expect(
        secondPurchase.state.backpackItems,
        const <BackpackItem>[
          BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 2),
        ],
      );
    });

    test('does not purchase without enough coins', () {
      final item = ShopCatalog.getItemById('wallpaper_dune_layers')!;
      final service = ShopService(
        state: const ShopState(coins: 999),
        walletCoins: 200,
      );

      final result = service.purchaseItem(item);

      expect(result.status, ShopOperationStatus.insufficientCoins);
      expect(result.walletCoins, 200);
      expect(result.state, const ShopState(coins: 999));
    });

    test('does not duplicate a cosmetic', () {
      final item = ShopCatalog.getItemById('wallpaper_warm_beige')!;
      final service = ShopService(
        state: const ShopState(
          coins: 500,
          inventory: <OwnedShopItem>[
            OwnedShopItem(itemId: 'wallpaper_warm_beige'),
          ],
        ),
        walletCoins: 500,
      );

      final result = service.purchaseItem(item);

      expect(result.status, ShopOperationStatus.alreadyOwned);
      expect(result.walletCoins, 500);
      expect(result.state.coins, 500);
      expect(result.state.inventory, hasLength(1));
    });

    test('equips a purchased background', () {
      final item = ShopCatalog.getItemById('wallpaper_warm_beige')!;
      final service = ShopService(
        state: const ShopState(
          inventory: <OwnedShopItem>[
            OwnedShopItem(itemId: 'wallpaper_warm_beige'),
          ],
        ),
        walletCoins: 0,
      );

      final result = service.equipCosmetic(item);

      expect(result.status, ShopOperationStatus.success);
      expect(result.state.equippedCosmetics.backgroundItemId, 'wallpaper_warm_beige');
    });

    test('fails when equipping an unowned cosmetic', () {
      final item = ShopCatalog.getItemById('wallpaper_warm_beige')!;
      final service = ShopService(
        state: const ShopState(),
        walletCoins: 0,
      );

      final result = service.equipCosmetic(item);

      expect(result.status, ShopOperationStatus.itemNotOwned);
      expect(result.state.equippedCosmetics.backgroundItemId, isNull);
    });

    test('consuming a backpack item reduces quantity', () {
      final service = ShopService(
        state: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 2),
          ],
        ),
        walletCoins: 0,
      );

      final result = service.consumeBackpackItem('utility_xp_boost_1d');

      expect(result.status, ShopOperationStatus.success);
      expect(
        result.state.backpackItems,
        const <BackpackItem>[
          BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 1),
        ],
      );
    });

    test('consuming the last backpack item removes it', () {
      final service = ShopService(
        state: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 1),
          ],
        ),
        walletCoins: 0,
      );

      final result = service.consumeBackpackItem('utility_xp_boost_1d');

      expect(result.status, ShopOperationStatus.success);
      expect(result.state.backpackItems, isEmpty);
    });

    test('consuming an item with zero legacy quantity fails safely', () {
      final service = ShopService(
        state: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 0),
          ],
        ),
        walletCoins: 0,
      );

      final result = service.consumeBackpackItem('utility_xp_boost_1d');

      expect(result.status, ShopOperationStatus.backpackItemNotFound);
      expect(
        result.state.backpackItems,
        const <BackpackItem>[
          BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 0),
        ],
      );
    });

    test('coins never go below zero', () {
      final service = ShopService(
        state: const ShopState(coins: 20),
        walletCoins: 20,
      );

      final result = service.spendCoins(25);

      expect(result.status, ShopOperationStatus.insufficientCoins);
      expect(result.walletCoins, 20);
      expect(result.state.coins, 20);
    });

    test('only cosmetics can be equipped', () {
      final item = ShopCatalog.getItemById('utility_xp_boost_1d')!;
      final service = ShopService(
        state: const ShopState(),
        walletCoins: 0,
      );

      final result = service.equipCosmetic(item);

      expect(result.status, ShopOperationStatus.invalidItemType);
    });

    test('unequip clears the requested slot', () {
      final service = ShopService(
        state: const ShopState(
          equippedCosmetics: EquippedCosmetics(
            backgroundItemId: 'wallpaper_warm_beige',
            habitCardItemId: 'habit_card_soft_camel',
          ),
        ),
        walletCoins: 0,
      );

      final result = service.unequipCosmetic(CosmeticSlot.background);

      expect(result.status, ShopOperationStatus.success);
      expect(result.state.equippedCosmetics.backgroundItemId, isNull);
      expect(result.state.equippedCosmetics.habitCardItemId, 'habit_card_soft_camel');
    });

    test('purchase flow uses wallet coins instead of ShopState coins', () {
      final item = ShopCatalog.getItemById('wallpaper_warm_beige')!;
      final service = ShopService(
        state: const ShopState(coins: 1000),
        walletCoins: 0,
      );

      final result = service.purchaseItem(item);

      expect(result.status, ShopOperationStatus.insufficientCoins);
      expect(result.walletCoins, 0);
      expect(result.state.coins, 1000);
      expect(result.state.inventory, isEmpty);
    });
  });
}
