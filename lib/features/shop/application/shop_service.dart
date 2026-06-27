import 'package:rutio/features/shop/application/shop_operation_result.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';

class ShopService {
  ShopService({
    required this.state,
    int Function()? nowMillisProvider,
  }) : _nowMillisProvider =
            nowMillisProvider ?? (() => DateTime.now().millisecondsSinceEpoch);

  final ShopState state;
  final int Function() _nowMillisProvider;

  bool canAfford(ShopItem item) {
    return state.coins >= item.priceCoins;
  }

  bool ownsItem(String itemId) {
    return state.inventory.any((OwnedShopItem item) => item.itemId == itemId);
  }

  ShopOperationResult purchaseItem(ShopItem item) {
    if (!canAfford(item)) {
      return _result(ShopOperationStatus.insufficientCoins, itemId: item.id);
    }

    if (item.category == ShopItemCategory.cosmetic) {
      if (ownsItem(item.id)) {
        return _result(ShopOperationStatus.alreadyOwned, itemId: item.id);
      }

      final nextInventory = List<OwnedShopItem>.from(state.inventory)
        ..add(
          OwnedShopItem(
            itemId: item.id,
            quantity: 1,
            acquiredAtMillis: _nowMillisProvider(),
            source: 'shop_purchase',
          ),
        );

      return _result(
        ShopOperationStatus.success,
        nextState: state.copyWith(
          coins: state.coins - item.priceCoins,
          inventory: nextInventory,
        ),
        itemId: item.id,
      );
    }

    if (item.category == ShopItemCategory.utility) {
      final addResult = addToBackpack(item.id, 1);
      if (!addResult.isSuccess) {
        return addResult.copyWith(itemId: item.id);
      }

      return _result(
        ShopOperationStatus.success,
        nextState: addResult.state.copyWith(
          coins: addResult.state.coins - item.priceCoins,
        ),
        itemId: item.id,
      );
    }

    return _result(ShopOperationStatus.invalidItemType, itemId: item.id);
  }

  ShopOperationResult equipCosmetic(ShopItem item) {
    if (item.category != ShopItemCategory.cosmetic || item.cosmeticSlot == null) {
      return _result(ShopOperationStatus.invalidItemType, itemId: item.id);
    }

    if (!ownsItem(item.id)) {
      return _result(ShopOperationStatus.itemNotOwned, itemId: item.id);
    }

    final nextEquipped = _equipSlot(
      equippedCosmetics: state.equippedCosmetics,
      slot: item.cosmeticSlot!,
      itemId: item.id,
    );

    return _result(
      ShopOperationStatus.success,
      nextState: state.copyWith(equippedCosmetics: nextEquipped),
      itemId: item.id,
    );
  }

  ShopOperationResult unequipCosmetic(CosmeticSlot slot) {
    final nextEquipped = _equipSlot(
      equippedCosmetics: state.equippedCosmetics,
      slot: slot,
      itemId: null,
    );

    return _result(
      ShopOperationStatus.success,
      nextState: state.copyWith(equippedCosmetics: nextEquipped),
    );
  }

  ShopOperationResult addCoins(int amount) {
    if (amount < 0) {
      return _result(ShopOperationStatus.invalidQuantity);
    }

    return _result(
      ShopOperationStatus.success,
      nextState: state.copyWith(coins: state.coins + amount),
    );
  }

  ShopOperationResult spendCoins(int amount) {
    if (amount < 0) {
      return _result(ShopOperationStatus.invalidQuantity);
    }

    if (amount > state.coins) {
      return _result(ShopOperationStatus.insufficientCoins);
    }

    return _result(
      ShopOperationStatus.success,
      nextState: state.copyWith(coins: state.coins - amount),
    );
  }

  ShopOperationResult addToBackpack(String itemId, int quantity) {
    if (quantity <= 0) {
      return _result(ShopOperationStatus.invalidQuantity, itemId: itemId);
    }

    final nextItems = List<BackpackItem>.from(state.backpackItems);
    final index = nextItems.indexWhere((BackpackItem item) => item.itemId == itemId);
    if (index == -1) {
      nextItems.add(BackpackItem(itemId: itemId, quantity: quantity));
    } else {
      nextItems[index] = nextItems[index].copyWith(
        quantity: nextItems[index].quantity + quantity,
      );
    }

    return _result(
      ShopOperationStatus.success,
      nextState: state.copyWith(backpackItems: nextItems),
      itemId: itemId,
    );
  }

  ShopOperationResult consumeBackpackItem(String itemId) {
    final nextItems = List<BackpackItem>.from(state.backpackItems);
    final index = nextItems.indexWhere((BackpackItem item) => item.itemId == itemId);
    if (index == -1) {
      return _result(ShopOperationStatus.backpackItemNotFound, itemId: itemId);
    }

    final current = nextItems[index];
    if (current.quantity <= 1) {
      nextItems.removeAt(index);
    } else {
      nextItems[index] = current.copyWith(quantity: current.quantity - 1);
    }

    return _result(
      ShopOperationStatus.success,
      nextState: state.copyWith(backpackItems: nextItems),
      itemId: itemId,
    );
  }

  EquippedCosmetics _equipSlot({
    required EquippedCosmetics equippedCosmetics,
    required CosmeticSlot slot,
    required String? itemId,
  }) {
    switch (slot) {
      case CosmeticSlot.background:
        return equippedCosmetics.copyWith(backgroundItemId: itemId);
      case CosmeticSlot.habitCard:
        return equippedCosmetics.copyWith(habitCardItemId: itemId);
      case CosmeticSlot.userCard:
        return equippedCosmetics.copyWith(userCardItemId: itemId);
    }
  }

  ShopOperationResult _result(
    ShopOperationStatus status, {
    ShopState? nextState,
    String? itemId,
  }) {
    return ShopOperationResult(
      status: status,
      state: nextState ?? state,
      itemId: itemId,
    );
  }
}
