import 'package:flutter/foundation.dart';

enum PendingHabitMutationType { create, update, archive }

String pendingHabitMutationTypeName(PendingHabitMutationType type) {
  if (type == PendingHabitMutationType.create) return 'create';
  if (type == PendingHabitMutationType.update) return 'update';
  return 'archive';
}

@immutable
class PendingHabitMutation {
  const PendingHabitMutation({
    required this.operationId,
    required this.userId,
    required this.localHabitId,
    required this.type,
    required this.snapshot,
    required this.createdAt,
    this.remoteHabitId,
    this.revision = 0,
    this.attempts = 0,
    this.lastAttemptAt,
    this.lastError,
    this.uncertain = false,
    this.createSnapshot,
  });

  static const int schemaVersion = 1;

  final String operationId;
  final String userId;
  final String localHabitId;
  final String? remoteHabitId;
  final PendingHabitMutationType type;
  final Map<String, dynamic> snapshot;
  final DateTime createdAt;
  final int revision;
  final int attempts;
  final DateTime? lastAttemptAt;
  final String? lastError;
  final bool uncertain;
  final Map<String, dynamic>? createSnapshot;

  PendingHabitMutation copyWith({
    String? operationId,
    String? userId,
    String? localHabitId,
    String? remoteHabitId,
    PendingHabitMutationType? type,
    Map<String, dynamic>? snapshot,
    DateTime? createdAt,
    int? revision,
    int? attempts,
    DateTime? lastAttemptAt,
    String? lastError,
    bool? uncertain,
    Map<String, dynamic>? createSnapshot,
    bool clearCreateSnapshot = false,
  }) {
    return PendingHabitMutation(
      operationId: operationId ?? this.operationId,
      userId: userId ?? this.userId,
      localHabitId: localHabitId ?? this.localHabitId,
      remoteHabitId: remoteHabitId ?? this.remoteHabitId,
      type: type ?? this.type,
      snapshot: snapshot ?? this.snapshot,
      createdAt: createdAt ?? this.createdAt,
      revision: revision ?? this.revision,
      attempts: attempts ?? this.attempts,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: lastError ?? this.lastError,
      uncertain: uncertain ?? this.uncertain,
      createSnapshot:
          clearCreateSnapshot ? null : (createSnapshot ?? this.createSnapshot),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'operationId': operationId,
      'userId': userId,
      'localHabitId': localHabitId,
      if (remoteHabitId != null) 'remoteHabitId': remoteHabitId,
      'type': pendingHabitMutationTypeName(type),
      'snapshot': snapshot,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'revision': revision,
      'attempts': attempts,
      if (lastAttemptAt != null)
        'lastAttemptAt': lastAttemptAt!.toUtc().toIso8601String(),
      if (lastError != null) 'lastError': lastError,
      'uncertain': uncertain,
      if (createSnapshot != null) 'createSnapshot': createSnapshot,
    };
  }

  static PendingHabitMutation fromJson(Object? raw) {
    if (raw is! Map) throw const FormatException('mutation row is not a map');
    final map = raw.cast<String, dynamic>();
    if (map['schemaVersion'] != schemaVersion) {
      throw const FormatException('mutation schema is incompatible');
    }

    final operationId = _requiredString(map['operationId']);
    final userId = _requiredString(map['userId']);
    final localHabitId = _requiredString(map['localHabitId']);
    final typeName = _requiredString(map['type']);
    final type = PendingHabitMutationType.values.firstWhere(
      (value) => pendingHabitMutationTypeName(value) == typeName,
      orElse: () => throw const FormatException('unknown mutation type'),
    );
    final snapshot = _map(map['snapshot']);
    final createdAt = _requiredDateTime(map['createdAt']);
    final createSnapshot =
        map['createSnapshot'] == null ? null : _map(map['createSnapshot']);

    return PendingHabitMutation(
      operationId: operationId,
      userId: userId,
      localHabitId: localHabitId,
      remoteHabitId: _nullableString(map['remoteHabitId']),
      type: type,
      snapshot: snapshot,
      createdAt: createdAt,
      revision: _nonNegativeInt(map['revision']),
      attempts: _nonNegativeInt(map['attempts']),
      lastAttemptAt: _nullableDateTime(map['lastAttemptAt']),
      lastError: _nullableString(map['lastError']),
      uncertain: map['uncertain'] == true,
      createSnapshot: createSnapshot,
    );
  }

  static String _requiredString(Object? value) {
    final normalized = (value ?? '').toString().trim();
    if (normalized.isEmpty) throw const FormatException('missing mutation id');
    return normalized;
  }

  static String? _nullableString(Object? value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map) throw const FormatException('mutation snapshot invalid');
    return Map<String, dynamic>.from(value.cast<String, dynamic>());
  }

  static int _nonNegativeInt(Object? value) {
    if (value is! int || value < 0) {
      throw const FormatException('mutation counter invalid');
    }
    return value;
  }

  static DateTime _requiredDateTime(Object? value) {
    final parsed = DateTime.tryParse((value ?? '').toString());
    if (parsed == null) {
      throw const FormatException('mutation timestamp invalid');
    }
    return parsed;
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
