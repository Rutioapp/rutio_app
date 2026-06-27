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
            itemId: 'bg_basic_camel',
            quantity: 1,
            acquiredAtMillis: 123456,
            source: 'shop_purchase',
          ),
        ],
        backpackItems: <BackpackItem>[
          BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 2),
        ],
        equippedCosmetics: EquippedCosmetics(
          backgroundItemId: 'bg_basic_camel',
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
      final item = ShopCatalog.getItemById('bg_basic_camel')!;
      final service = ShopService(
        state: const ShopState(coins: 200),
        nowMillisProvider: () => 111,
      );

      final result = service.purchaseItem(item);

      expect(result.status, ShopOperationStatus.success);
      expect(result.state.coins, 100);
      expect(result.state.inventory, hasLength(1));
      expect(result.state.inventory.first.itemId, 'bg_basic_camel');
      expect(result.state.inventory.first.acquiredAtMillis, 111);
    });

    test('purchases a utility correctly', () {
      final item = ShopCatalog.getItemById('utility_xp_boost_1d')!;
      final service = ShopService(
        state: const ShopState(coins: 200),
      );

      final result = service.purchaseItem(item);

      expect(result.status, ShopOperationStatus.success);
      expect(result.state.coins, 125);
      expect(
        result.state.backpackItems,
        const <BackpackItem>[
          BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 1),
        ],
      );
    });

    test('does not purchase without enough coins', () {
      final item = ShopCatalog.getItemById('bg_landscape_dawn_hills')!;
      final service = ShopService(
        state: const ShopState(coins: 200),
      );

      final result = service.purchaseItem(item);

      expect(result.status, ShopOperationStatus.insufficientCoins);
      expect(result.state, const ShopState(coins: 200));
    });

    test('does not duplicate a cosmetic', () {
      final item = ShopCatalog.getItemById('bg_basic_camel')!;
      final service = ShopService(
        state: const ShopState(
          coins: 500,
          inventory: <OwnedShopItem>[
            OwnedShopItem(itemId: 'bg_basic_camel'),
          ],
        ),
      );

      final result = service.purchaseItem(item);

      expect(result.status, ShopOperationStatus.alreadyOwned);
      expect(result.state.coins, 500);
      expect(result.state.inventory, hasLength(1));
    });

    test('equips a purchased background', () {
      final item = ShopCatalog.getItemById('bg_basic_camel')!;
      final service = ShopService(
        state: const ShopState(
          inventory: <OwnedShopItem>[
            OwnedShopItem(itemId: 'bg_basic_camel'),
          ],
        ),
      );

      final result = service.equipCosmetic(item);

      expect(result.status, ShopOperationStatus.success);
      expect(result.state.equippedCosmetics.backgroundItemId, 'bg_basic_camel');
    });

    test('fails when equipping an unowned cosmetic', () {
      final item = ShopCatalog.getItemById('bg_basic_camel')!;
      final service = ShopService(
        state: const ShopState(),
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
      );

      final result = service.consumeBackpackItem('utility_xp_boost_1d');

      expect(result.status, ShopOperationStatus.success);
      expect(result.state.backpackItems, isEmpty);
    });

    test('coins never go below zero', () {
      final service = ShopService(
        state: const ShopState(coins: 20),
      );

      final result = service.spendCoins(25);

      expect(result.status, ShopOperationStatus.insufficientCoins);
      expect(result.state.coins, 20);
    });

    test('only cosmetics can be equipped', () {
      final item = ShopCatalog.getItemById('utility_xp_boost_1d')!;
      final service = ShopService(
        state: const ShopState(),
      );

      final result = service.equipCosmetic(item);

      expect(result.status, ShopOperationStatus.invalidItemType);
    });

    test('unequip clears the requested slot', () {
      final service = ShopService(
        state: const ShopState(
          equippedCosmetics: EquippedCosmetics(
            backgroundItemId: 'bg_basic_camel',
            habitCardItemId: 'habit_card_basic_sage',
          ),
        ),
      );

      final result = service.unequipCosmetic(CosmeticSlot.background);

      expect(result.status, ShopOperationStatus.success);
      expect(result.state.equippedCosmetics.backgroundItemId, isNull);
      expect(result.state.equippedCosmetics.habitCardItemId, 'habit_card_basic_sage');
    });
  });
}
