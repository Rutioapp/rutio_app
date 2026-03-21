class ShopService {
  /// Compra un item del store.
  /// - gameConfig: tu GameConfig (con store.items)
  /// - userState: estado del usuario (wallet, inventory, progression)
  ///
  /// Devuelve el userState modificado (para que lo guardes).
  Map<String, dynamic> purchase({
    required Map<String, dynamic> gameConfig,
    required Map<String, dynamic> userState,
    required String itemId,
  }) {
    final gc = gameConfig['gameConfig'] as Map<String, dynamic>;
    final store = gc['store'] as Map<String, dynamic>;
    final items = (store['items'] as List).cast<Map<String, dynamic>>();

    final item = items.firstWhere(
      (it) => it['id'] == itemId,
      orElse: () => throw StateError('Item not found: $itemId'),
    );

    final us = userState['userState'] as Map<String, dynamic>;
    final level = (us['progression']?['level'] ?? 1) as int;
    final coins = (us['wallet']?['coins'] ?? 0) as int;

    // 1) Check unlock
    final unlock = item['unlock'] as Map<String, dynamic>?;
    if (unlock != null && unlock['type'] == 'user_level') {
      final requiredLevel = (unlock['level'] ?? 1) as int;
      if (level < requiredLevel) {
        throw StateError('Item locked. Need level $requiredLevel.');
      }
    }

    // 2) Check already owned (cosméticos normalmente no repetibles)
    final inventory = us['inventory'] as Map<String, dynamic>;
    final invItems = (inventory['items'] as List).cast<Map<String, dynamic>>();
    final alreadyOwned = invItems.any((x) => x['itemId'] == itemId);
    if (alreadyOwned) {
      throw StateError('Item already owned.');
    }

    // 3) Check coins
    final price = (item['price'] ?? 0) as int;
    if (coins < price) {
      throw StateError('Not enough coins.');
    }

    // 4) Apply transaction
    us['wallet']['coins'] = coins - price;

    invItems.add({
      'itemId': itemId,
      'quantity': 1,
      'acquiredAt': DateTime.now().toUtc().toIso8601String(),
      'source': 'shop_purchase',
    });

    return userState;
  }
}
