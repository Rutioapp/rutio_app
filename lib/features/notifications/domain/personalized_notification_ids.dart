import 'package:flutter/foundation.dart';

import 'personalized_notification_models.dart';

@immutable
class NotificationPlatformIdRange {
  const NotificationPlatformIdRange({
    required this.start,
    required this.end,
  }) : assert(start <= end, 'start must be <= end');

  final int start;
  final int end;

  int get size => (end - start) + 1;

  bool contains(int value) => value >= start && value <= end;
}

class NotificationIdNamespace {
  NotificationIdNamespace._();

  static const int payloadVersion = 2;
  static const String namespace = 'rutio:v2';

  static const NotificationPlatformIdRange habitReminderRange =
      NotificationPlatformIdRange(start: 1000, end: 19999);
  static const NotificationPlatformIdRange personalizedGeneralRange =
      NotificationPlatformIdRange(start: 20000, end: 29999);
  static const NotificationPlatformIdRange celebrationRange =
      NotificationPlatformIdRange(start: 30000, end: 39999);
  static const NotificationPlatformIdRange diaryRange =
      NotificationPlatformIdRange(start: 40000, end: 49999);
  static const NotificationPlatformIdRange weeklyReportRange =
      NotificationPlatformIdRange(start: 50000, end: 59999);
  static const NotificationPlatformIdRange systemRange =
      NotificationPlatformIdRange(start: 90000, end: 99999);

  static NotificationPlatformIdRange rangeForFamily(NotificationFamily family) {
    switch (family) {
      case NotificationFamily.habitReminder:
        return habitReminderRange;
      case NotificationFamily.personalizedGeneral:
        return personalizedGeneralRange;
      case NotificationFamily.celebration:
        return celebrationRange;
      case NotificationFamily.diary:
        return diaryRange;
      case NotificationFamily.weeklyReport:
        return weeklyReportRange;
      case NotificationFamily.system:
        return systemRange;
    }
  }

  static String familySegment(NotificationFamily family) {
    switch (family) {
      case NotificationFamily.habitReminder:
        return 'habit';
      case NotificationFamily.personalizedGeneral:
        return 'general';
      case NotificationFamily.celebration:
        return 'celebration';
      case NotificationFamily.diary:
        return 'diary';
      case NotificationFamily.weeklyReport:
        return 'weekly';
      case NotificationFamily.system:
        return 'system';
    }
  }

  static String buildNotificationKey({
    required NotificationFamily family,
    required NotificationKind kind,
    required NotificationScope scope,
    required String entityRef,
    required String slot,
  }) {
    final normalizedEntityRef = _normalizeSegment(entityRef, fallback: 'none');
    final normalizedSlot = _normalizeSegment(slot, fallback: 'default');
    return <String>[
      namespace,
      familySegment(family),
      kind.name,
      scope.scopeHash,
      normalizedEntityRef,
      normalizedSlot,
    ].join(':');
  }

  static String userScopeHash(NotificationScope scope) => scope.scopeHash;

  static String _normalizeSegment(
    String value, {
    required String fallback,
  }) {
    final normalized = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    if (normalized.isEmpty) return fallback;
    return normalized;
  }
}

class NotificationPlatformIdAllocator {
  NotificationPlatformIdAllocator({
    Map<String, int>? initialAssignments,
  }) : _assignedByKey = Map<String, int>.from(initialAssignments ?? const {});

  final Map<String, int> _assignedByKey;

  Map<String, int> snapshot() => Map<String, int>.unmodifiable(_assignedByKey);

  int allocate({
    required NotificationFamily family,
    required String notificationKey,
  }) {
    final existing = _assignedByKey[notificationKey];
    if (existing != null) return existing;

    final range = NotificationIdNamespace.rangeForFamily(family);
    final usedIds = _assignedByKey.values.toSet();
    final baseOffset = _stableHash(notificationKey) % range.size;

    for (var probe = 0; probe < range.size; probe += 1) {
      final candidate = range.start + ((baseOffset + probe) % range.size);
      if (usedIds.contains(candidate)) continue;
      _assignedByKey[notificationKey] = candidate;
      return candidate;
    }

    throw StateError(
      'No platform notification ids available for family ${family.name}.',
    );
  }

  static int _stableHash(String value) {
    const int offset = 0x811c9dc5;
    const int prime = 0x01000193;
    var hash = offset;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * prime) & 0x7fffffff;
    }
    return hash & 0x7fffffff;
  }
}
