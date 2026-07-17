import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';

class BackpackItemViewModel {
  const BackpackItemViewModel({
    required this.itemId,
    required this.title,
    required this.description,
    required this.quantity,
    required this.rarity,
    required this.type,
    this.collectionName,
    this.activeEffect,
    this.hasMysteryBoxPendingRecovery = false,
    this.isActivating = false,
  });

  final String itemId;
  final String title;
  final String description;
  final int quantity;
  final ShopItemRarity rarity;
  final ShopItemType type;
  final String? collectionName;
  final ActiveUtilityEffect? activeEffect;
  final bool hasMysteryBoxPendingRecovery;
  final bool isActivating;

  bool get hasQuantity => quantity > 0;
  bool get isBoost =>
      type == ShopItemType.xpBoost || type == ShopItemType.coinBoost;
  bool get isStreakShield => type == ShopItemType.streakShield;
  bool get isStreakRecover => type == ShopItemType.streakRecover;
  bool get isMysteryBox => type == ShopItemType.mysteryBox;
  bool get isActive => activeEffect != null && activeEffect!.isActive;
  int get remainingUses => activeEffect?.remainingUses ?? 0;
  int get totalUses => activeEffect?.totalUses ?? 0;

  BackpackItemViewModel copyWith({
    String? itemId,
    String? title,
    String? description,
    int? quantity,
    ShopItemRarity? rarity,
    ShopItemType? type,
    Object? collectionName = _unset,
    Object? activeEffect = _unset,
    bool? hasMysteryBoxPendingRecovery,
    bool? isActivating,
  }) {
    return BackpackItemViewModel(
      itemId: itemId ?? this.itemId,
      title: title ?? this.title,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      rarity: rarity ?? this.rarity,
      type: type ?? this.type,
      collectionName: identical(collectionName, _unset)
          ? this.collectionName
          : collectionName as String?,
      activeEffect: identical(activeEffect, _unset)
          ? this.activeEffect
          : activeEffect as ActiveUtilityEffect?,
      hasMysteryBoxPendingRecovery:
          hasMysteryBoxPendingRecovery ?? this.hasMysteryBoxPendingRecovery,
      isActivating: isActivating ?? this.isActivating,
    );
  }

  factory BackpackItemViewModel.fromItem(
    ShopItem item, {
    required int quantity,
    String? collectionName,
  }) {
    return BackpackItemViewModel(
      itemId: item.id,
      title: item.title,
      description: item.description,
      quantity: quantity,
      rarity: item.rarity,
      type: item.type,
      collectionName: collectionName ?? item.collectionId,
    );
  }
}

const Object _unset = Object();
