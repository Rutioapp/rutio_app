class ShopItemPrice {
  const ShopItemPrice({
    this.coins = 0,
  });

  final int coins;

  ShopItemPrice copyWith({
    int? coins,
  }) {
    return ShopItemPrice(
      coins: coins ?? this.coins,
    );
  }

  factory ShopItemPrice.fromJson(Map<String, dynamic> json) {
    return ShopItemPrice(
      coins: (json['coins'] as num?)?.toInt() ?? (json['priceCoins'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'coins': coins,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopItemPrice && other.coins == coins;
  }

  @override
  int get hashCode => coins.hashCode;

  @override
  String toString() => 'ShopItemPrice(coins: $coins)';
}
