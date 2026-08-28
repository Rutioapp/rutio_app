import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/personalized_notification_ids.dart';
import '../../domain/personalized_notification_models.dart';
import '../../domain/personalized_notification_ports.dart';
import 'notification_local_storage_scope.dart';

class SharedPreferencesNotificationScheduleStore
    implements NotificationScheduleStore {
  SharedPreferencesNotificationScheduleStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const int _schemaVersion = 1;

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  @override
  Future<NotificationScheduleManifest?> load(NotificationScope scope) async {
    final prefs = await _sharedPreferencesProvider();
    final raw =
        prefs.getString(NotificationLocalStorageScope.manifestKey(scope));
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return _decodeManifest(
        Map<String, dynamic>.from(decoded.cast<String, dynamic>()),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(
    NotificationScope scope,
    NotificationScheduleManifest manifest,
  ) async {
    if (scope.userId != manifest.scope.userId ||
        scope.installId != manifest.scope.installId) {
      throw StateError('Manifest scope does not match storage scope.');
    }
    final prefs = await _sharedPreferencesProvider();
    await prefs.setString(
      NotificationLocalStorageScope.manifestKey(scope),
      jsonEncode(_encodeManifest(manifest)),
    );
  }

  @override
  Future<void> clear(NotificationScope scope) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.remove(NotificationLocalStorageScope.manifestKey(scope));
  }

  Future<void> upsertEntry(
    NotificationScope scope,
    NotificationManifestEntry entry, {
    required String timezoneId,
    DateTime? reconciledAt,
    DateTime? reconciledDate,
  }) async {
    final current = await load(scope) ??
        _emptyManifest(
          scope,
          timezoneId: timezoneId,
          reconciledAt: reconciledAt,
          reconciledDate: reconciledDate,
        );
    final nextEntries = <NotificationManifestEntry>[
      ...current.entries.where(
        (existing) => existing.notificationKey != entry.notificationKey,
      ),
      entry,
    ];
    final nextIndex = Map<String, int>.from(current.platformIdIndex)
      ..[entry.notificationKey] = entry.platformId;
    await save(
      scope,
      current.copyWith(
        timezoneId: timezoneId,
        lastReconciledAt: (reconciledAt ?? DateTime.now()).toUtc(),
        lastReconciledDate:
            _normalizeDate(reconciledDate ?? reconciledAt ?? DateTime.now()),
        entries: nextEntries,
        platformIdIndex: nextIndex,
      ),
    );
  }

  Future<void> removeEntry(
    NotificationScope scope,
    String notificationKey,
  ) async {
    final current = await load(scope);
    if (current == null) return;
    final nextEntries = current.entries
        .where((entry) => entry.notificationKey != notificationKey)
        .toList(growable: false);
    final nextIndex = Map<String, int>.from(current.platformIdIndex)
      ..remove(notificationKey);
    await save(
      scope,
      current.copyWith(
        entries: nextEntries,
        platformIdIndex: nextIndex,
      ),
    );
  }

  Future<void> savePlatformIdMapping(
    NotificationScope scope, {
    required NotificationFamily family,
    required String notificationKey,
    required int platformId,
    String? timezoneId,
  }) async {
    _validatePlatformId(notificationKey, family, platformId);
    final current = await load(scope) ??
        _emptyManifest(
          scope,
          timezoneId: timezoneId ?? 'unknown',
        );
    final nextIndex = Map<String, int>.from(current.platformIdIndex);
    final existingKey = nextIndex.entries
        .where((entry) => entry.value == platformId)
        .map((entry) => entry.key)
        .cast<String?>()
        .firstWhere(
          (value) => value != null && value != notificationKey,
          orElse: () => null,
        );
    if (existingKey != null) {
      throw StateError(
        'Platform id $platformId is already assigned to $existingKey.',
      );
    }

    nextIndex[notificationKey] = platformId;
    await save(
      scope,
      current.copyWith(
        timezoneId: timezoneId ?? current.timezoneId,
        platformIdIndex: nextIndex,
      ),
    );
  }

  NotificationScheduleManifest _emptyManifest(
    NotificationScope scope, {
    required String timezoneId,
    DateTime? reconciledAt,
    DateTime? reconciledDate,
  }) {
    final now = (reconciledAt ?? DateTime.now()).toUtc();
    return NotificationScheduleManifest(
      scope: scope,
      scopeEpochAtPlanTime: scope.scopeEpoch,
      timezoneId: timezoneId,
      lastReconciledAt: now,
      lastReconciledDate:
          _normalizeDate(reconciledDate ?? reconciledAt ?? DateTime.now()),
      entries: const <NotificationManifestEntry>[],
      platformIdIndex: const <String, int>{},
    );
  }

  Map<String, dynamic> _encodeManifest(NotificationScheduleManifest manifest) {
    return <String, dynamic>{
      'schemaVersion': _schemaVersion,
      'scope': <String, dynamic>{
        'userId': manifest.scope.userId,
        'scopeEpoch': manifest.scope.scopeEpoch,
        'installId': manifest.scope.installId,
        'locale': manifest.scope.locale,
      },
      'scopeEpochAtPlanTime': manifest.scopeEpochAtPlanTime,
      'timezoneId': manifest.timezoneId,
      'lastReconciledAt': manifest.lastReconciledAt.toIso8601String(),
      'lastReconciledDate': manifest.lastReconciledDate.toIso8601String(),
      'entries': manifest.entries.map(_encodeEntry).toList(growable: false),
      'platformIdIndex': manifest.platformIdIndex,
    };
  }

  Map<String, dynamic> _encodeEntry(NotificationManifestEntry entry) {
    return <String, dynamic>{
      'notificationKey': entry.notificationKey,
      'platformId': entry.platformId,
      'family': entry.family.name,
      'kind': entry.kind.name,
      'payload': entry.payload,
      'templateId': entry.templateId,
      'scheduledAt': entry.scheduledAt.toIso8601String(),
      'planVersion': entry.planVersion,
      'sourceFingerprint': entry.sourceFingerprint,
    };
  }

  NotificationScheduleManifest? _decodeManifest(Map<String, dynamic> json) {
    final scopeJson = json['scope'];
    final lastReconciledAt = DateTime.tryParse(
      (json['lastReconciledAt'] ?? '').toString(),
    );
    final lastReconciledDate = DateTime.tryParse(
      (json['lastReconciledDate'] ?? '').toString(),
    );
    if (scopeJson is! Map ||
        lastReconciledAt == null ||
        lastReconciledDate == null) {
      return null;
    }

    final scopeMap =
        Map<String, dynamic>.from(scopeJson.cast<String, dynamic>());
    final scope = _decodeScope(scopeMap);
    if (scope == null) return null;

    final entries = _decodeEntries(json['entries']);
    final platformIdIndex = _decodePlatformIdIndex(json['platformIdIndex']);

    return NotificationScheduleManifest(
      scope: scope,
      scopeEpochAtPlanTime: _readInt(
        json['scopeEpochAtPlanTime'],
        scope.scopeEpoch,
      ),
      timezoneId: _readString(json['timezoneId'], 'unknown'),
      lastReconciledAt: lastReconciledAt.toUtc(),
      lastReconciledDate: _normalizeDate(lastReconciledDate.toUtc()),
      entries: entries,
      platformIdIndex: platformIdIndex,
    );
  }

  NotificationScope? _decodeScope(Map<String, dynamic> json) {
    final userId = _nullableString(json['userId']);
    final installId = _nullableString(json['installId']);
    final locale = _nullableString(json['locale']);
    if (userId == null || installId == null || locale == null) return null;

    try {
      return NotificationScope(
        userId: userId,
        scopeEpoch: _readInt(json['scopeEpoch'], 0),
        installId: installId,
        locale: locale,
      );
    } on ArgumentError {
      return null;
    }
  }

  List<NotificationManifestEntry> _decodeEntries(dynamic raw) {
    if (raw is! List) return const <NotificationManifestEntry>[];
    final entries = <NotificationManifestEntry>[];
    for (final item in raw.whereType<Map>()) {
      final entry =
          _decodeEntry(Map<String, dynamic>.from(item.cast<String, dynamic>()));
      if (entry != null) {
        entries.add(entry);
      }
    }
    return entries;
  }

  NotificationManifestEntry? _decodeEntry(Map<String, dynamic> json) {
    final key = _nullableString(json['notificationKey']);
    final family = _readFamily(json['family']);
    final kind = _readKind(json['kind']);
    final scheduledAt =
        DateTime.tryParse((json['scheduledAt'] ?? '').toString());
    final platformId = _readNullableInt(json['platformId']);
    if (key == null ||
        family == null ||
        kind == null ||
        scheduledAt == null ||
        platformId == null) {
      return null;
    }
    return NotificationManifestEntry(
      notificationKey: key,
      platformId: platformId,
      family: family,
      kind: kind,
      payload: _readString(json['payload'], ''),
      templateId: _readString(json['templateId'], ''),
      scheduledAt: scheduledAt.toUtc(),
      planVersion: _readInt(json['planVersion'], 1),
      sourceFingerprint: _readString(json['sourceFingerprint'], ''),
    );
  }

  Map<String, int> _decodePlatformIdIndex(dynamic raw) {
    if (raw is! Map) return const <String, int>{};
    final result = <String, int>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString().trim();
      final value = _readNullableInt(entry.value);
      if (key.isEmpty || value == null) continue;
      result[key] = value;
    }
    return result;
  }

  void _validatePlatformId(
    String notificationKey,
    NotificationFamily family,
    int platformId,
  ) {
    final range = NotificationIdNamespace.rangeForFamily(family);
    if (!range.contains(platformId)) {
      throw StateError(
        'Platform id $platformId for $notificationKey is outside ${family.name} range.',
      );
    }
  }

  NotificationFamily? _readFamily(dynamic raw) {
    final value = _nullableString(raw);
    if (value == null) return null;
    for (final family in NotificationFamily.values) {
      if (family.name == value) return family;
    }
    return null;
  }

  NotificationKind? _readKind(dynamic raw) {
    final value = _nullableString(raw);
    if (value == null) return null;
    for (final kind in NotificationKind.values) {
      if (kind.name == value) return kind;
    }
    return null;
  }

  int _readInt(dynamic raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    final parsed = int.tryParse((raw ?? '').toString().trim());
    return parsed ?? fallback;
  }

  int? _readNullableInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse((raw ?? '').toString().trim());
  }

  String _readString(dynamic raw, String fallback) {
    final value = _nullableString(raw);
    return value ?? fallback;
  }

  String? _nullableString(dynamic raw) {
    final value = (raw ?? '').toString().trim();
    return value.isEmpty ? null : value;
  }

  DateTime _normalizeDate(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
