class BackpackItem {
  const BackpackItem({
    required this.itemId,
    this.quantity = 0,
    this.updatedAtMillis,
  });

  final String itemId;
  final int quantity;
  final int? updatedAtMillis;

  String get utilityId => itemId;

  BackpackItem copyWith({
    String? itemId,
    int? quantity,
    Object? updatedAtMillis = _unset,
  }) {
    return BackpackItem(
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      updatedAtMillis: identical(updatedAtMillis, _unset)
          ? this.updatedAtMillis
          : updatedAtMillis as int?,
    );
  }

  factory BackpackItem.fromJson(Map<String, dynamic> json) {
    final utilityId = (json['utilityId'] ?? json['itemId'] ?? '').toString();
    return BackpackItem(
      itemId: utilityId,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      updatedAtMillis: (json['updatedAtMillis'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'itemId': itemId,
      'utilityId': utilityId,
      'quantity': quantity,
      'updatedAtMillis': updatedAtMillis,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackpackItem &&
        other.itemId == itemId &&
        other.quantity == quantity &&
        other.updatedAtMillis == updatedAtMillis;
  }

  @override
  int get hashCode => Object.hash(itemId, quantity, updatedAtMillis);
}

const Object _unset = Object();
