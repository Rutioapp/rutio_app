import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'personalized_notification_models.dart';

@immutable
class NotificationPayloadV2 {
  const NotificationPayloadV2({
    required this.schema,
    required this.family,
    required this.kind,
    required this.logicalId,
    required this.templateId,
    required this.scopeHash,
    required this.scopeEpoch,
    required this.categoryTag,
    this.route = 'home',
  });

  final int schema;
  final NotificationFamily family;
  final NotificationKind kind;
  final String logicalId;
  final String templateId;
  final String scopeHash;
  final int scopeEpoch;
  final String categoryTag;
  final String route;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schema': schema,
      'family': family.name,
      'kind': kind.wireName,
      'logicalId': logicalId,
      'templateId': templateId,
      'scopeHash': scopeHash,
      'scopeEpoch': scopeEpoch,
      'categoryTag': categoryTag,
      'route': route,
    };
  }

  String encode() => jsonEncode(toJson());

  static NotificationPayloadV2? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return fromJson(
        Map<String, Object?>.from(decoded.cast<String, Object?>()),
      );
    } catch (_) {
      return null;
    }
  }

  static NotificationPayloadV2? fromJson(Map<String, Object?> json) {
    final schema = _readInt(json['schema'] ?? json['v']);
    final familyName = _readString(json['family']);
    final kindName = _readString(json['kind']);
    final logicalId = _readString(json['logicalId'] ?? json['notificationKey']);
    final templateId = _readString(json['templateId']);
    final scopeHash = _readString(json['scopeHash']);
    final scopeEpoch = _readInt(json['scopeEpoch']);
    final categoryTag = _readString(json['categoryTag']);
    if (schema == null ||
        schema < 2 ||
        familyName == null ||
        kindName == null ||
        logicalId == null ||
        templateId == null ||
        scopeHash == null ||
        scopeEpoch == null ||
        categoryTag == null) {
      return null;
    }

    NotificationFamily? family;
    for (final candidate in NotificationFamily.values) {
      if (candidate.name == familyName) {
        family = candidate;
        break;
      }
    }
    if (family == null) {
      return null;
    }

    NotificationKind kind;
    try {
      kind = notificationKindFromWireName(kindName);
    } on ArgumentError {
      return null;
    }

    return NotificationPayloadV2(
      schema: schema,
      family: family,
      kind: kind,
      logicalId: logicalId,
      templateId: templateId,
      scopeHash: scopeHash,
      scopeEpoch: scopeEpoch,
      categoryTag: categoryTag,
      route: _readString(json['route']) ?? 'home',
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationPayloadV2 &&
            other.schema == schema &&
            other.family == family &&
            other.kind == kind &&
            other.logicalId == logicalId &&
            other.templateId == templateId &&
            other.scopeHash == scopeHash &&
            other.scopeEpoch == scopeEpoch &&
            other.categoryTag == categoryTag &&
            other.route == route;
  }

  @override
  int get hashCode => Object.hash(
        schema,
        family,
        kind,
        logicalId,
        templateId,
        scopeHash,
        scopeEpoch,
        categoryTag,
        route,
      );
}

String? _readString(Object? raw) {
  final value = (raw ?? '').toString().trim();
  return value.isEmpty ? null : value;
}

int? _readInt(Object? raw) {
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  return int.tryParse((raw ?? '').toString().trim());
}
