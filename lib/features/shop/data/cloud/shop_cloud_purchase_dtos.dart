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

bool _isUuid(String value) {
  final uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-'
    r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  return uuidPattern.hasMatch(value);
}
