import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/personalized_notification_models.dart';
import '../../domain/personalized_notification_ports.dart';
import 'notification_local_storage_scope.dart';

class SharedPreferencesNotificationHistoryStore
    implements NotificationHistoryStore {
  SharedPreferencesNotificationHistoryStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    this.maxRecords = 30,
  })  : assert(maxRecords > 0),
        _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const int _schemaVersion = 1;

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;
  final int maxRecords;

  @override
  Future<NotificationMessageHistorySnapshot?> load(
      NotificationScope scope) async {
    final prefs = await _sharedPreferencesProvider();
    final raw =
        prefs.getString(NotificationLocalStorageScope.historyKey(scope));
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return _decodeHistory(
        Map<String, dynamic>.from(decoded.cast<String, dynamic>()),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(
    NotificationScope scope,
    NotificationMessageHistorySnapshot history,
  ) async {
    final prefs = await _sharedPreferencesProvider();
    final normalized = _normalized(history);
    await prefs.setString(
      NotificationLocalStorageScope.historyKey(scope),
      jsonEncode(_encodeHistory(normalized)),
    );
  }

  @override
  Future<void> clear(NotificationScope scope) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.remove(NotificationLocalStorageScope.historyKey(scope));
  }

  Future<NotificationMessageHistorySnapshot> append(
    NotificationScope scope,
    NotificationDeliveryRecord record, {
    String? categoryTag,
  }) async {
    final current = await load(scope) ?? NotificationMessageHistorySnapshot();
    final recent = <NotificationDeliveryRecord>[
      ...current.recentDeliveries,
      record,
    ];
    final next = NotificationMessageHistorySnapshot(
      recentDeliveries: recent,
      lastSelectedAtByTemplateId: <String, DateTime>{
        ...current.lastSelectedAtByTemplateId,
        record.templateId: record.scheduledAt,
      },
      lastSelectedAtByKind: <String, DateTime>{
        ...current.lastSelectedAtByKind,
        record.kind.name: record.scheduledAt,
      },
      lastSelectedAtByCategoryTag: (categoryTag ?? record.categoryTag) == null
          ? current.lastSelectedAtByCategoryTag
          : <String, DateTime>{
              ...current.lastSelectedAtByCategoryTag,
              (categoryTag ?? record.categoryTag)!: record.scheduledAt,
            },
    );
    final normalized = _normalized(next);
    await save(scope, normalized);
    return normalized;
  }

  NotificationMessageHistorySnapshot _normalized(
    NotificationMessageHistorySnapshot history,
  ) {
    final sorted = history.recentDeliveries.toList(growable: false)
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    final retained = sorted.take(maxRecords).toList(growable: false);
    return history.copyWith(
      recentDeliveries: retained,
    );
  }

  Map<String, dynamic> _encodeHistory(
    NotificationMessageHistorySnapshot history,
  ) {
    return <String, dynamic>{
      'schemaVersion': _schemaVersion,
      'recentDeliveries': history.recentDeliveries
          .map(_encodeDeliveryRecord)
          .toList(growable: false),
      'lastSelectedAtByTemplateId':
          _encodeDateMap(history.lastSelectedAtByTemplateId),
      'lastSelectedAtByKind': _encodeDateMap(history.lastSelectedAtByKind),
      'lastSelectedAtByCategoryTag':
          _encodeDateMap(history.lastSelectedAtByCategoryTag),
    };
  }

  Map<String, dynamic> _encodeDeliveryRecord(
      NotificationDeliveryRecord record) {
    return <String, dynamic>{
      'notificationKey': record.notificationKey,
      'userId': record.userId,
      'templateId': record.templateId,
      'kind': record.kind.name,
      'scheduledAt': record.scheduledAt.toIso8601String(),
      'categoryTag': record.categoryTag,
      'openedAt': record.openedAt?.toIso8601String(),
      'deliveredObservedAt': record.deliveredObservedAt?.toIso8601String(),
      'dismissedObservedAt': record.dismissedObservedAt?.toIso8601String(),
      'suppressionReason': record.suppressionReason?.name,
    };
  }

  Map<String, dynamic> _encodeDateMap(Map<String, DateTime> values) {
    return <String, dynamic>{
      for (final entry in values.entries)
        entry.key: entry.value.toIso8601String(),
    };
  }

  NotificationMessageHistorySnapshot? _decodeHistory(
    Map<String, dynamic> json,
  ) {
    return NotificationMessageHistorySnapshot(
      recentDeliveries: _decodeDeliveryRecords(json['recentDeliveries']),
      lastSelectedAtByTemplateId: _decodeDateMap(
        json['lastSelectedAtByTemplateId'],
      ),
      lastSelectedAtByKind: _decodeDateMap(json['lastSelectedAtByKind']),
      lastSelectedAtByCategoryTag: _decodeDateMap(
        json['lastSelectedAtByCategoryTag'],
      ),
    );
  }

  List<NotificationDeliveryRecord> _decodeDeliveryRecords(dynamic raw) {
    if (raw is! List) return const <NotificationDeliveryRecord>[];
    final records = <NotificationDeliveryRecord>[];
    for (final item in raw.whereType<Map>()) {
      final record = _decodeDeliveryRecord(
        Map<String, dynamic>.from(item.cast<String, dynamic>()),
      );
      if (record != null) {
        records.add(record);
      }
    }
    records.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return records.take(maxRecords).toList(growable: false);
  }

  NotificationDeliveryRecord? _decodeDeliveryRecord(Map<String, dynamic> json) {
    final key = _nullableString(json['notificationKey']);
    final userId = _nullableString(json['userId']);
    final templateId = _nullableString(json['templateId']);
    final kind = _readKind(json['kind']);
    final scheduledAt = _readDateTime(json['scheduledAt']);
    if (key == null ||
        userId == null ||
        templateId == null ||
        kind == null ||
        scheduledAt == null) {
      return null;
    }

    return NotificationDeliveryRecord(
      notificationKey: key,
      userId: userId,
      templateId: templateId,
      kind: kind,
      scheduledAt: scheduledAt,
      categoryTag: _nullableString(json['categoryTag']),
      openedAt: _readDateTime(json['openedAt']),
      deliveredObservedAt: _readDateTime(json['deliveredObservedAt']),
      dismissedObservedAt: _readDateTime(json['dismissedObservedAt']),
      suppressionReason: _readSuppressionReason(json['suppressionReason']),
    );
  }

  Map<String, DateTime> _decodeDateMap(dynamic raw) {
    if (raw is! Map) return const <String, DateTime>{};
    final result = <String, DateTime>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString().trim();
      final value = _readDateTime(entry.value);
      if (key.isEmpty || value == null) continue;
      result[key] = value;
    }
    return result;
  }

  NotificationKind? _readKind(dynamic raw) {
    final value = _nullableString(raw);
    if (value == null) return null;
    for (final kind in NotificationKind.values) {
      if (kind.name == value) return kind;
    }
    return null;
  }

  NotificationSuppressionReason? _readSuppressionReason(dynamic raw) {
    final value = _nullableString(raw);
    if (value == null) return null;
    for (final reason in NotificationSuppressionReason.values) {
      if (reason.name == value) return reason;
    }
    return null;
  }

  DateTime? _readDateTime(dynamic raw) {
    final value = _nullableString(raw);
    if (value == null) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  String? _nullableString(dynamic raw) {
    final value = (raw ?? '').toString().trim();
    return value.isEmpty ? null : value;
  }
}
