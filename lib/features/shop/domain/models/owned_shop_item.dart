import 'shop_model_utils.dart';

const Object _ownedUnset = Object();

class OwnedShopItem {
  const OwnedShopItem({
    required this.itemId,
    this.quantity = 1,
    this.acquiredAtMillis,
    this.source,
    this.metadata = const <String, dynamic>{},
  });

  final String itemId;
  final int quantity;
  final int? acquiredAtMillis;
  final String? source;
  final Map<String, dynamic> metadata;

  OwnedShopItem copyWith({
    String? itemId,
    int? quantity,
    Object? acquiredAtMillis = _ownedUnset,
    Object? source = _ownedUnset,
    Map<String, dynamic>? metadata,
  }) {
    return OwnedShopItem(
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      acquiredAtMillis: identical(acquiredAtMillis, _ownedUnset)
          ? this.acquiredAtMillis
          : acquiredAtMillis as int?,
      source: identical(source, _ownedUnset) ? this.source : source as String?,
      metadata: metadata ?? this.metadata,
    );
  }

  factory OwnedShopItem.fromJson(Map<String, dynamic> json) {
    return OwnedShopItem(
      itemId: (json['itemId'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      acquiredAtMillis: (json['acquiredAtMillis'] as num?)?.toInt(),
      source: json['source']?.toString(),
      metadata: shopNormalizeMetadata(shopJsonMap(json['metadata'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'itemId': itemId,
      'quantity': quantity,
      'acquiredAtMillis': acquiredAtMillis,
      'source': source,
      'metadata': metadata.map(
        (String key, dynamic value) => MapEntry(key, shopJsonValue(value)),
      ),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OwnedShopItem &&
        other.itemId == itemId &&
        other.quantity == quantity &&
        other.acquiredAtMillis == acquiredAtMillis &&
        other.source == source &&
        shopDeepEquals(other.metadata, metadata);
  }

  @override
  int get hashCode => Object.hash(
        itemId,
        quantity,
        acquiredAtMillis,
        source,
        shopDeepHash(metadata),
      );
}
