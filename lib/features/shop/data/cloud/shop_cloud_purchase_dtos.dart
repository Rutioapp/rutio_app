import 'dart:convert';

class RemoteShopPurchaseResultDto {
  const RemoteShopPurchaseResultDto({
    required this.requestId,
    required this.operation,
    required this.itemId,
    required this.priceCoins,
    required this.coins,
    required this.walletVersion,
    required this.inventoryQuantity,
  });

  final String requestId;
  final String operation;
  final String itemId;
  final int priceCoins;
  final int coins;
  final int walletVersion;
  final int inventoryQuantity;

  factory RemoteShopPurchaseResultDto.fromRpcResponse(
    Object? response, {
    required String requestedItemId,
    required String requestId,
  }) {
    final payload = _extractMap(response);
    if (payload == null) {
      throw const FormatException('Invalid shop purchase response payload.');
    }

    final normalizedRequestId =
        _trim(payload['requestId'] ?? payload['request_id']);
    final operation = _trim(payload['operation']);
    final itemId = _trim(payload['itemId'] ?? payload['item_id']);
    final priceCoins = _int(payload['priceCoins'] ?? payload['price_coins']);
    final coins = _int(payload['coins']);
    final walletVersion =
        _int(payload['walletVersion'] ?? payload['wallet_version']);
    final inventoryQuantity =
        _int(payload['inventoryQuantity'] ?? payload['inventory_quantity']);

    if (normalizedRequestId == null ||
        !_isUuid(normalizedRequestId) ||
        operation == null ||
        operation != 'purchase' ||
        itemId == null ||
        itemId.isEmpty ||
        itemId != requestedItemId ||
        priceCoins == null ||
        priceCoins < 0 ||
        coins == null ||
        coins < 0 ||
        walletVersion == null ||
        walletVersion < 0 ||
        inventoryQuantity == null ||
        inventoryQuantity <= 0) {
      throw const FormatException('Invalid shop purchase response payload.');
    }

    if (normalizedRequestId != requestId.trim()) {
      throw const FormatException('Shop purchase requestId mismatch.');
    }

    return RemoteShopPurchaseResultDto(
      requestId: normalizedRequestId,
      operation: operation,
      itemId: itemId,
      priceCoins: priceCoins,
      coins: coins,
      walletVersion: walletVersion,
      inventoryQuantity: inventoryQuantity,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requestId': requestId,
      'operation': operation,
      'itemId': itemId,
      'priceCoins': priceCoins,
      'coins': coins,
      'walletVersion': walletVersion,
      'inventoryQuantity': inventoryQuantity,
    };
  }
}

class RemoteShopBundlePurchaseResultDto {
  const RemoteShopBundlePurchaseResultDto({
    required this.requestId,
    required this.bundleId,
    required this.userId,
    required this.coinsDelta,
    required this.walletCoinsAfter,
    required this.wallpaperItemId,
    required this.habitCardItemId,
    required this.userCardItemId,
    required this.isIdempotent,
    required this.createdAt,
  });

  final String requestId;
  final String bundleId;
  final String userId;
  final int coinsDelta;
  final int walletCoinsAfter;
  final String wallpaperItemId;
  final String habitCardItemId;
  final String userCardItemId;
  final bool isIdempotent;
  final DateTime createdAt;

  factory RemoteShopBundlePurchaseResultDto.fromRpcResponse(
    Object? response, {
    required String requestedBundleId,
    required String requestId,
  }) {
    final payload = _extractMap(response);
    if (payload == null) {
      throw const FormatException('Invalid shop bundle purchase response.');
    }

    final normalizedRequestId =
        _trim(payload['requestId'] ?? payload['request_id']);
    final bundleId = _trim(payload['bundleId'] ?? payload['bundle_id']);
    final userId = _trim(payload['userId'] ?? payload['user_id']);
    final coinsDelta =
        _int(payload['coinsDelta'] ?? payload['coins_delta']);
    final walletCoinsAfter =
        _int(payload['walletCoinsAfter'] ?? payload['wallet_coins_after']);
    final wallpaperItemId =
        _trim(payload['wallpaperItemId'] ?? payload['wallpaper_item_id']);
    final habitCardItemId =
        _trim(payload['habitCardItemId'] ?? payload['habit_card_item_id']);
    final userCardItemId =
        _trim(payload['userCardItemId'] ?? payload['user_card_item_id']);
    final isIdempotent =
        _nullableBool(payload['isIdempotent'] ?? payload['is_idempotent']);
    final createdAt =
        _dateTime(payload['createdAt'] ?? payload['created_at']);

    final bundleItemIds = <String>{
      if (wallpaperItemId != null) wallpaperItemId,
      if (habitCardItemId != null) habitCardItemId,
      if (userCardItemId != null) userCardItemId,
    };

    if (normalizedRequestId == null ||
        !_isUuid(normalizedRequestId) ||
        bundleId == null ||
        bundleId.isEmpty ||
        userId == null ||
        !_isUuid(userId) ||
        coinsDelta == null ||
        coinsDelta > 0 ||
        walletCoinsAfter == null ||
        walletCoinsAfter < 0 ||
        wallpaperItemId == null ||
        wallpaperItemId.isEmpty ||
        habitCardItemId == null ||
        habitCardItemId.isEmpty ||
        userCardItemId == null ||
        userCardItemId.isEmpty ||
        bundleItemIds.length != 3 ||
        isIdempotent == null ||
        createdAt == null) {
      throw const FormatException('Invalid shop bundle purchase response.');
    }

    if (normalizedRequestId != requestId.trim()) {
      throw const FormatException('Shop bundle purchase requestId mismatch.');
    }
    if (bundleId != requestedBundleId.trim()) {
      throw const FormatException('Shop bundle purchase bundleId mismatch.');
    }

    return RemoteShopBundlePurchaseResultDto(
      requestId: normalizedRequestId,
      bundleId: bundleId,
      userId: userId,
      coinsDelta: coinsDelta,
      walletCoinsAfter: walletCoinsAfter,
      wallpaperItemId: wallpaperItemId,
      habitCardItemId: habitCardItemId,
      userCardItemId: userCardItemId,
      isIdempotent: isIdempotent,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requestId': requestId,
      'bundleId': bundleId,
      'userId': userId,
      'coinsDelta': coinsDelta,
      'walletCoinsAfter': walletCoinsAfter,
      'wallpaperItemId': wallpaperItemId,
      'habitCardItemId': habitCardItemId,
      'userCardItemId': userCardItemId,
      'isIdempotent': isIdempotent,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

Map<String, dynamic>? _extractMap(Object? response) {
  if (response == null) return null;
  if (response is Map<String, dynamic>) return response;
  if (response is Map) {
    return Map<String, dynamic>.from(response.cast<String, dynamic>());
  }
  if (response is List && response.isNotEmpty) {
    final first = response.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) {
      return Map<String, dynamic>.from(first.cast<String, dynamic>());
    }
  }
  if (response is String) {
    final trimmed = response.trim();
    if (trimmed.isEmpty) return null;
    final decoded = jsonDecode(trimmed);
    return _extractMap(decoded);
  }
  return null;
}

String? _trim(Object? value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString().trim());
}

DateTime? _dateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final normalized = value.toString().trim();
  if (normalized.isEmpty) return null;
  return DateTime.tryParse(normalized);
}

bool? _nullableBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return null;
}

bool _isUuid(String value) {
  final uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-'
    r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  return uuidPattern.hasMatch(value);
}
