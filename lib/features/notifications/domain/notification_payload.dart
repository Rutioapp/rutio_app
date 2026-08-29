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
