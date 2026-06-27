class BackpackItem {
  const BackpackItem({
    required this.itemId,
    this.quantity = 0,
  });

  final String itemId;
  final int quantity;

  BackpackItem copyWith({
    String? itemId,
    int? quantity,
  }) {
    return BackpackItem(
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
    );
  }

  factory BackpackItem.fromJson(Map<String, dynamic> json) {
    return BackpackItem(
      itemId: (json['itemId'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'itemId': itemId,
      'quantity': quantity,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackpackItem &&
        other.itemId == itemId &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => Object.hash(itemId, quantity);
}
