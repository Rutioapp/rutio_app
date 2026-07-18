enum PendingShopPurchaseStatus {
  pending,
  awaitingResolution,
}

class PendingShopPurchase {
  const PendingShopPurchase({
    required this.userId,
    required this.requestId,
    required this.itemId,
    required this.createdAtMillis,
    required this.lastAttemptAtMillis,
    required this.attemptCount,
    required this.status,
  });

  final String userId;
  final String requestId;
  final String itemId;
  final int createdAtMillis;
  final int lastAttemptAtMillis;
  final int attemptCount;
  final PendingShopPurchaseStatus status;

  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(createdAtMillis, isUtc: true);

  DateTime get lastAttemptAt =>
      DateTime.fromMillisecondsSinceEpoch(lastAttemptAtMillis, isUtc: true);

  bool get isAwaitingResolution =>
      status == PendingShopPurchaseStatus.awaitingResolution;

  PendingShopPurchase copyWith({
    String? userId,
    String? requestId,
    String? itemId,
    int? createdAtMillis,
    int? lastAttemptAtMillis,
    int? attemptCount,
    PendingShopPurchaseStatus? status,
  }) {
    return PendingShopPurchase(
      userId: userId ?? this.userId,
      requestId: requestId ?? this.requestId,
      itemId: itemId ?? this.itemId,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      lastAttemptAtMillis: lastAttemptAtMillis ?? this.lastAttemptAtMillis,
      attemptCount: attemptCount ?? this.attemptCount,
      status: status ?? this.status,
    );
  }

  factory PendingShopPurchase.fromJson(Map<String, dynamic> json) {
    final userId = _trim(json['userId'] ?? json['user_id']);
    final requestId = _trim(json['requestId'] ?? json['request_id']);
    final itemId = _trim(json['itemId'] ?? json['item_id']);
    final createdAtMillis =
        _int(json['createdAtMillis'] ?? json['created_at_millis']);
    final lastAttemptAtMillis =
        _int(json['lastAttemptAtMillis'] ?? json['last_attempt_at_millis']);
    final attemptCount = _int(json['attemptCount'] ?? json['attempt_count']);
    final status = _status(json['status']);

    if (userId == null ||
        requestId == null ||
        itemId == null ||
        createdAtMillis == null ||
        lastAttemptAtMillis == null ||
        attemptCount == null ||
        status == null) {
      throw const FormatException('Invalid pending shop purchase payload.');
    }

    return PendingShopPurchase(
      userId: userId,
      requestId: requestId,
      itemId: itemId,
      createdAtMillis: createdAtMillis,
      lastAttemptAtMillis: lastAttemptAtMillis,
      attemptCount: attemptCount,
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'requestId': requestId,
      'itemId': itemId,
      'createdAtMillis': createdAtMillis,
      'lastAttemptAtMillis': lastAttemptAtMillis,
      'attemptCount': attemptCount,
      'status': status.name,
    };
  }
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

PendingShopPurchaseStatus? _status(Object? value) {
  switch ((value ?? '').toString().trim()) {
    case 'pending':
      return PendingShopPurchaseStatus.pending;
    case 'awaitingResolution':
      return PendingShopPurchaseStatus.awaitingResolution;
    default:
      return null;
  }
}
