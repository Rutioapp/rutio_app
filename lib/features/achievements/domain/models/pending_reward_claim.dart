import 'package:flutter/foundation.dart';

enum PendingRewardClaimStatus {
  pending,
  awaitingResolution,
}

enum RewardClaimType {
  achievement,
  level,
}

@immutable
class PendingRewardClaim {
  const PendingRewardClaim({
    required this.userId,
    required this.requestId,
    required this.claimType,
    required this.sourceId,
    required this.createdAtMillis,
    required this.lastAttemptAtMillis,
    required this.attemptCount,
    required this.status,
  });

  final String userId;
  final String requestId;
  final RewardClaimType claimType;
  final String sourceId;
  final int createdAtMillis;
  final int lastAttemptAtMillis;
  final int attemptCount;
  final PendingRewardClaimStatus status;

  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(createdAtMillis, isUtc: true);

  DateTime get lastAttemptAt =>
      DateTime.fromMillisecondsSinceEpoch(lastAttemptAtMillis, isUtc: true);

  bool get isAwaitingResolution =>
      status == PendingRewardClaimStatus.awaitingResolution;

  String get sourceKey => '${claimType.name}|$sourceId';

  PendingRewardClaim copyWith({
    String? userId,
    String? requestId,
    RewardClaimType? claimType,
    String? sourceId,
    int? createdAtMillis,
    int? lastAttemptAtMillis,
    int? attemptCount,
    PendingRewardClaimStatus? status,
  }) {
    return PendingRewardClaim(
      userId: userId ?? this.userId,
      requestId: requestId ?? this.requestId,
      claimType: claimType ?? this.claimType,
      sourceId: sourceId ?? this.sourceId,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      lastAttemptAtMillis: lastAttemptAtMillis ?? this.lastAttemptAtMillis,
      attemptCount: attemptCount ?? this.attemptCount,
      status: status ?? this.status,
    );
  }

  factory PendingRewardClaim.fromJson(Map<String, dynamic> json) {
    final userId = _trim(json['userId'] ?? json['user_id']);
    final requestId = _trim(json['requestId'] ?? json['request_id']);
    final claimType = _claimType(json['claimType'] ?? json['claim_type']);
    final sourceId = _trim(json['sourceId'] ?? json['source_id']);
    final createdAtMillis =
        _int(json['createdAtMillis'] ?? json['created_at_millis']);
    final lastAttemptAtMillis =
        _int(json['lastAttemptAtMillis'] ?? json['last_attempt_at_millis']);
    final attemptCount = _int(json['attemptCount'] ?? json['attempt_count']);
    final status = _status(json['status']);

    if (userId == null ||
        requestId == null ||
        claimType == null ||
        sourceId == null ||
        createdAtMillis == null ||
        lastAttemptAtMillis == null ||
        attemptCount == null ||
        status == null) {
      throw const FormatException('Invalid pending reward claim payload.');
    }

    return PendingRewardClaim(
      userId: userId,
      requestId: requestId,
      claimType: claimType,
      sourceId: sourceId,
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
      'claimType': claimType.name,
      'sourceId': sourceId,
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

PendingRewardClaimStatus? _status(Object? value) {
  switch ((value ?? '').toString().trim()) {
    case 'pending':
      return PendingRewardClaimStatus.pending;
    case 'awaitingResolution':
      return PendingRewardClaimStatus.awaitingResolution;
    default:
      return null;
  }
}

RewardClaimType? _claimType(Object? value) {
  switch ((value ?? '').toString().trim()) {
    case 'achievement':
      return RewardClaimType.achievement;
    case 'level':
      return RewardClaimType.level;
    default:
      return null;
  }
}
