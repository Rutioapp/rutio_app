import 'package:flutter/foundation.dart';

enum PendingCurrencyOperationStatus {
  pending,
  awaitingResolution,
}

enum HabitRewardOperationType {
  apply,
  reverse,
}

@immutable
class PendingCurrencyOperation {
  const PendingCurrencyOperation({
    required this.userId,
    required this.requestId,
    required this.habitId,
    required this.logicalDateKey,
    required this.completionEventId,
    required this.operationType,
    required this.createdAtMillis,
    required this.lastAttemptAtMillis,
    required this.attemptCount,
    required this.status,
  });

  final String userId;
  final String requestId;
  final String habitId;
  final String logicalDateKey;
  final String completionEventId;
  final HabitRewardOperationType operationType;
  final int createdAtMillis;
  final int lastAttemptAtMillis;
  final int attemptCount;
  final PendingCurrencyOperationStatus status;

  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(createdAtMillis, isUtc: true);

  DateTime get lastAttemptAt =>
      DateTime.fromMillisecondsSinceEpoch(lastAttemptAtMillis, isUtc: true);

  bool get isAwaitingResolution =>
      status == PendingCurrencyOperationStatus.awaitingResolution;

  String get sourceKey => '$habitId|$logicalDateKey|$completionEventId';

  PendingCurrencyOperation copyWith({
    String? userId,
    String? requestId,
    String? habitId,
    String? logicalDateKey,
    String? completionEventId,
    HabitRewardOperationType? operationType,
    int? createdAtMillis,
    int? lastAttemptAtMillis,
    int? attemptCount,
    PendingCurrencyOperationStatus? status,
  }) {
    return PendingCurrencyOperation(
      userId: userId ?? this.userId,
      requestId: requestId ?? this.requestId,
      habitId: habitId ?? this.habitId,
      logicalDateKey: logicalDateKey ?? this.logicalDateKey,
      completionEventId: completionEventId ?? this.completionEventId,
      operationType: operationType ?? this.operationType,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      lastAttemptAtMillis: lastAttemptAtMillis ?? this.lastAttemptAtMillis,
      attemptCount: attemptCount ?? this.attemptCount,
      status: status ?? this.status,
    );
  }

  factory PendingCurrencyOperation.fromJson(Map<String, dynamic> json) {
    final userId = _trim(json['userId'] ?? json['user_id']);
    final requestId = _trim(json['requestId'] ?? json['request_id']);
    final habitId = _trim(json['habitId'] ?? json['habit_id']);
    final logicalDateKey =
        _trim(json['logicalDateKey'] ?? json['logical_date_key']);
    final completionEventId =
        _trim(json['completionEventId'] ?? json['completion_event_id']);
    final operationType =
        _operationType(json['operationType'] ?? json['operation_type']);
    final createdAtMillis =
        _int(json['createdAtMillis'] ?? json['created_at_millis']);
    final lastAttemptAtMillis =
        _int(json['lastAttemptAtMillis'] ?? json['last_attempt_at_millis']);
    final attemptCount = _int(json['attemptCount'] ?? json['attempt_count']);
    final status = _status(json['status']);

    if (userId == null ||
        requestId == null ||
        habitId == null ||
        logicalDateKey == null ||
        completionEventId == null ||
        operationType == null ||
        createdAtMillis == null ||
        lastAttemptAtMillis == null ||
        attemptCount == null ||
        status == null) {
      throw const FormatException(
          'Invalid pending currency operation payload.');
    }

    return PendingCurrencyOperation(
      userId: userId,
      requestId: requestId,
      habitId: habitId,
      logicalDateKey: logicalDateKey,
      completionEventId: completionEventId,
      operationType: operationType,
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
      'habitId': habitId,
      'logicalDateKey': logicalDateKey,
      'completionEventId': completionEventId,
      'operationType': operationType.name,
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

PendingCurrencyOperationStatus? _status(Object? value) {
  switch ((value ?? '').toString().trim()) {
    case 'pending':
      return PendingCurrencyOperationStatus.pending;
    case 'awaitingResolution':
      return PendingCurrencyOperationStatus.awaitingResolution;
    default:
      return null;
  }
}

HabitRewardOperationType? _operationType(Object? value) {
  switch ((value ?? '').toString().trim()) {
    case 'apply':
      return HabitRewardOperationType.apply;
    case 'reverse':
      return HabitRewardOperationType.reverse;
    default:
      return null;
  }
}
