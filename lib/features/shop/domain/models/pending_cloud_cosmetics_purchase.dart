enum PendingCloudCosmeticsPurchaseType {
  cosmeticPurchase,
  bundlePurchase,
}

enum PendingCloudCosmeticsPurchaseStatus {
  pending,
  awaitingResolution,
}

class PendingCloudCosmeticsPurchase {
  const PendingCloudCosmeticsPurchase({
    required this.userId,
    required this.requestId,
    required this.operationType,
    required this.resourceId,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    required this.status,
    this.lastFailureCode,
  });

  final String userId;
  final String requestId;
  final PendingCloudCosmeticsPurchaseType operationType;
  final String resourceId;
  final int createdAtMillis;
  final int updatedAtMillis;
  final PendingCloudCosmeticsPurchaseStatus status;
  final String? lastFailureCode;

  String get logicalKey => logicalKeyFor(
        operationType: operationType,
        resourceId: resourceId,
      );

  bool get isAwaitingResolution =>
      status == PendingCloudCosmeticsPurchaseStatus.awaitingResolution;

  PendingCloudCosmeticsPurchase copyWith({
    String? userId,
    String? requestId,
    PendingCloudCosmeticsPurchaseType? operationType,
    String? resourceId,
    int? createdAtMillis,
    int? updatedAtMillis,
    PendingCloudCosmeticsPurchaseStatus? status,
    Object? lastFailureCode = _unset,
  }) {
    return PendingCloudCosmeticsPurchase(
      userId: userId ?? this.userId,
      requestId: requestId ?? this.requestId,
      operationType: operationType ?? this.operationType,
      resourceId: resourceId ?? this.resourceId,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      status: status ?? this.status,
      lastFailureCode: identical(lastFailureCode, _unset)
          ? this.lastFailureCode
          : lastFailureCode as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'requestId': requestId,
      'operationType': operationType.name,
      'resourceId': resourceId,
      'createdAtMillis': createdAtMillis,
      'updatedAtMillis': updatedAtMillis,
      'status': status.name,
      if (lastFailureCode != null) 'lastFailureCode': lastFailureCode,
    };
  }

  factory PendingCloudCosmeticsPurchase.fromJson(Map<String, dynamic> json) {
    final userId = _trim(json['userId'] ?? json['user_id']);
    final requestId = _trim(json['requestId'] ?? json['request_id']);
    final operationType =
        _operationType(json['operationType'] ?? json['operation_type']);
    final resourceId = _trim(json['resourceId'] ?? json['resource_id']);
    final createdAtMillis =
        _int(json['createdAtMillis'] ?? json['created_at_millis']);
    final updatedAtMillis =
        _int(json['updatedAtMillis'] ?? json['updated_at_millis']);
    final status = _status(json['status']);

    if (userId == null ||
        requestId == null ||
        operationType == null ||
        resourceId == null ||
        createdAtMillis == null ||
        updatedAtMillis == null ||
        status == null) {
      throw const FormatException('Invalid pending cloud cosmetics purchase.');
    }

    return PendingCloudCosmeticsPurchase(
      userId: userId,
      requestId: requestId,
      operationType: operationType,
      resourceId: resourceId,
      createdAtMillis: createdAtMillis,
      updatedAtMillis: updatedAtMillis,
      status: status,
      lastFailureCode:
          _trim(json['lastFailureCode'] ?? json['last_failure_code']),
    );
  }

  static String logicalKeyFor({
    required PendingCloudCosmeticsPurchaseType operationType,
    required String resourceId,
  }) {
    final prefix = switch (operationType) {
      PendingCloudCosmeticsPurchaseType.cosmeticPurchase => 'cosmetic',
      PendingCloudCosmeticsPurchaseType.bundlePurchase => 'bundle',
    };
    return '$prefix:${resourceId.trim()}';
  }
}

const Object _unset = Object();

String? _trim(Object? value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString().trim());
}

PendingCloudCosmeticsPurchaseType? _operationType(Object? value) {
  switch ((value ?? '').toString().trim()) {
    case 'cosmeticPurchase':
      return PendingCloudCosmeticsPurchaseType.cosmeticPurchase;
    case 'bundlePurchase':
      return PendingCloudCosmeticsPurchaseType.bundlePurchase;
  }
  return null;
}

PendingCloudCosmeticsPurchaseStatus? _status(Object? value) {
  switch ((value ?? '').toString().trim()) {
    case 'pending':
      return PendingCloudCosmeticsPurchaseStatus.pending;
    case 'awaitingResolution':
      return PendingCloudCosmeticsPurchaseStatus.awaitingResolution;
  }
  return null;
}
