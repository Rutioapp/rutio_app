import 'dart:convert';

class RemoteShopEquipResultDto {
  const RemoteShopEquipResultDto({
    required this.requestId,
    required this.operation,
    required this.itemId,
    required this.slot,
    required this.createdAt,
  });

  final String requestId;
  final String operation;
  final String itemId;
  final String slot;
  final DateTime createdAt;

  factory RemoteShopEquipResultDto.fromRpcResponse(
    Object? response, {
    required String requestedItemId,
    required String requestId,
  }) {
    final payload = _extractMap(response);
    if (payload == null) {
      throw const FormatException('Invalid shop equip response payload.');
    }

    final normalizedRequestId =
        _trim(payload['requestId'] ?? payload['request_id']);
    final operation = _trim(payload['operation']);
    final itemId = _trim(payload['itemId'] ?? payload['item_id']);
    final slot = _trim(payload['slot']);
    final createdAt = _dateTime(payload['createdAt'] ?? payload['created_at']);

    if (normalizedRequestId == null ||
        operation == null ||
        operation != 'equip' ||
        itemId == null ||
        itemId.isEmpty ||
        itemId != requestedItemId ||
        slot == null ||
        slot.isEmpty ||
        createdAt == null) {
      throw const FormatException('Invalid shop equip response payload.');
    }

    if (normalizedRequestId != requestId.trim()) {
      throw const FormatException('Shop equip requestId mismatch.');
    }

    return RemoteShopEquipResultDto(
      requestId: normalizedRequestId,
      operation: operation,
      itemId: itemId,
      slot: slot,
      createdAt: createdAt,
    );
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

DateTime? _dateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final normalized = value.toString().trim();
  if (normalized.isEmpty) return null;
  return DateTime.tryParse(normalized);
}
