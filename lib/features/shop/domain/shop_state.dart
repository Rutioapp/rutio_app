import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_model_utils.dart';

class ShopState {
  const ShopState({
    this.coins = 0,
    this.inventory = const <OwnedShopItem>[],
    this.backpackItems = const <BackpackItem>[],
    this.equippedCosmetics = const EquippedCosmetics(),
  });

  const ShopState.initial()
      : coins = 0,
        inventory = const <OwnedShopItem>[],
        backpackItems = const <BackpackItem>[],
        equippedCosmetics = const EquippedCosmetics();

  final int coins;
  final List<OwnedShopItem> inventory;
  final List<BackpackItem> backpackItems;
  final EquippedCosmetics equippedCosmetics;

  ShopState copyWith({
    int? coins,
    List<OwnedShopItem>? inventory,
    List<BackpackItem>? backpackItems,
    EquippedCosmetics? equippedCosmetics,
  }) {
    return ShopState(
      coins: coins ?? this.coins,
      inventory: inventory ?? this.inventory,
      backpackItems: backpackItems ?? this.backpackItems,
      equippedCosmetics: equippedCosmetics ?? this.equippedCosmetics,
    );
  }

  factory ShopState.fromJson(Map<String, dynamic> json) {
    return ShopState(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      inventory: shopJsonList<OwnedShopItem>(
        json['inventory'],
        (dynamic value) => OwnedShopItem.fromJson(shopJsonMap(value)),
      ),
      backpackItems: shopJsonList<BackpackItem>(
        json['backpackItems'],
        (dynamic value) => BackpackItem.fromJson(shopJsonMap(value)),
      ),
      equippedCosmetics: EquippedCosmetics.fromJson(
        shopJsonMap(json['equippedCosmetics']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'coins': coins,
      'inventory': inventory
          .map<Map<String, dynamic>>((OwnedShopItem item) => item.toJson())
          .toList(growable: false),
      'backpackItems': backpackItems
          .map<Map<String, dynamic>>((BackpackItem item) => item.toJson())
          .toList(growable: false),
      'equippedCosmetics': equippedCosmetics.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopState &&
        other.coins == coins &&
        shopDeepEquals(other.inventory, inventory) &&
        shopDeepEquals(other.backpackItems, backpackItems) &&
        other.equippedCosmetics == equippedCosmetics;
  }

  @override
  int get hashCode => Object.hash(
        coins,
        shopDeepHash(inventory),
        shopDeepHash(backpackItems),
        equippedCosmetics,
      );
}
