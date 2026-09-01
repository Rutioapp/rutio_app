import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum Phase1NotificationTimingKind {
  habitReminder,
  dailyMotivation,
  dayClosure,
  streakRisk,
  inactivity,
}

enum Phase1NotificationRecurrence { none, daily }

/// A Phase 1 scheduling intent, not evidence that the OS delivered it.
class Phase1NotificationScheduleIntent {
  const Phase1NotificationScheduleIntent({
    required this.logicalId,
    required this.platformId,
    required this.kind,
    required this.scheduledFor,
    required this.isUserConfigured,
    this.recurrence = Phase1NotificationRecurrence.none,
  });

  final String logicalId;
  final int platformId;
  final Phase1NotificationTimingKind kind;
  final DateTime scheduledFor;
  final bool isUserConfigured;
  final Phase1NotificationRecurrence recurrence;

  bool get repeatsDaily => recurrence == Phase1NotificationRecurrence.daily;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'logicalId': logicalId,
        'platformId': platformId,
        'kind': kind.name,
        'scheduledFor': scheduledFor.toLocal().toIso8601String(),
        'isUserConfigured': isUserConfigured,
        'recurrence': recurrence.name,
      };

  static Phase1NotificationScheduleIntent? fromJson(dynamic value) {
    if (value is! Map) return null;

    try {
      final logicalId = value['logicalId']?.toString().trim() ?? '';
      final platformId = int.tryParse(value['platformId']?.toString() ?? '');
      final kind = _parseKind(value['kind']?.toString());
      final scheduledFor = DateTime.tryParse(
        value['scheduledFor']?.toString() ?? '',
      );
      if (logicalId.isEmpty || platformId == null || kind == null) return null;
      if (scheduledFor == null) return null;

      return Phase1NotificationScheduleIntent(
        logicalId: logicalId,
        platformId: platformId,
        kind: kind,
        scheduledFor: scheduledFor.toLocal(),
        isUserConfigured: value['isUserConfigured'] == true,
        recurrence: _parseRecurrence(value['recurrence']?.toString()),
      );
    } catch (_) {
      return null;
    }
  }

  static Phase1NotificationTimingKind? _parseKind(String? value) {
    for (final kind in Phase1NotificationTimingKind.values) {
      if (kind.name == value) return kind;
    }
    return null;
  }

  static Phase1NotificationRecurrence _parseRecurrence(String? value) {
    return value == Phase1NotificationRecurrence.daily.name
        ? Phase1NotificationRecurrence.daily
        : Phase1NotificationRecurrence.none;
  }
}

abstract interface class Phase1NotificationTimingSource {
  Future<List<Phase1NotificationScheduleIntent>> upcomingForScope({
    String? scopeKey,
    DateTime? now,
    DateTime? horizonEnd,
  });
}

abstract interface class Phase1NotificationScheduleRegistry
    implements Phase1NotificationTimingSource {
  Future<List<Phase1NotificationScheduleIntent>> readAll();

  Future<void> upsert(Phase1NotificationScheduleIntent intent);

  Future<void> remove(String logicalId);

  Future<void> removeByPlatformId(int platformId);

  Future<void> removeByScope();
}

/// SharedPreferences-backed, user/install-scoped sidecar for Phase 1 timing.
///
/// Daily entries keep their local wall-clock time in [scheduledFor]. When read
/// after that occurrence, the next local date is calculated; no delivery is
/// inferred from this registry.
class SharedPreferencesPhase1NotificationScheduleRegistry
    implements Phase1NotificationScheduleRegistry {
  SharedPreferencesPhase1NotificationScheduleRegistry({
    required String scope,
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  })  : _scope = _normalizeScope(scope),
        _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const String _keyPrefix =
      'rutio.notifications.phase1_timing_registry_v1_';
  static final Map<String, Future<void>> _writeChains =
      <String, Future<void>>{};

  final String _scope;
  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  String get _key => '$_keyPrefix${_safeScope(_scope)}';

  @override
  Future<List<Phase1NotificationScheduleIntent>> readAll() async {
    final prefs = await _sharedPreferencesProvider();
    return _decode(prefs.getString(_key));
  }

  @override
  Future<List<Phase1NotificationScheduleIntent>> upcomingForScope({
    String? scopeKey,
    DateTime? now,
    DateTime? horizonEnd,
  }) async {
    if (scopeKey != null && _normalizeScope(scopeKey) != _scope) {
      return const [];
    }
    final current = (now ?? DateTime.now()).toLocal();
    final end = horizonEnd?.toLocal();
    final result = <Phase1NotificationScheduleIntent>[];
    for (final intent in await readAll()) {
      var occurrence = _nextOccurrence(intent, current);
      if (!occurrence.scheduledFor.isAfter(current)) continue;
      result.add(occurrence);
      if (!intent.repeatsDaily || end == null) continue;

      occurrence = _nextOccurrence(intent, occurrence.scheduledFor);
      if (occurrence.scheduledFor.isBefore(end) ||
          occurrence.scheduledFor.isAtSameMomentAs(end)) {
        result.add(occurrence);
      }
    }
    return result;
  }

  @override
  Future<void> upsert(Phase1NotificationScheduleIntent intent) {
    return _enqueue(() async {
      final entries = await readAll();
      final next = <Phase1NotificationScheduleIntent>[
        for (final entry in entries)
          if (entry.logicalId != intent.logicalId) entry,
        intent,
      ];
      await _write(next);
    });
  }

  @override
  Future<void> remove(String logicalId) {
    return _enqueue(() async {
      final entries = await readAll();
      final next = entries
          .where((entry) => entry.logicalId != logicalId)
          .toList(growable: false);
      if (next.length != entries.length) await _write(next);
    });
  }

  @override
  Future<void> removeByPlatformId(int platformId) {
    return _enqueue(() async {
      final entries = await readAll();
      final next = entries
          .where((entry) => entry.platformId != platformId)
          .toList(growable: false);
      if (next.length != entries.length) await _write(next);
    });
  }

  @override
  Future<void> removeByScope() {
    return _enqueue(() async {
      final prefs = await _sharedPreferencesProvider();
      await prefs.remove(_key);
    });
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final previous = _writeChains[_key] ?? Future<void>.value();
    final next = previous.then((_) => operation());
    _writeChains[_key] = next.whenComplete(() {
      if (identical(_writeChains[_key], next)) _writeChains.remove(_key);
    });
    return next;
  }

  Future<void> _write(List<Phase1NotificationScheduleIntent> entries) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.setString(
      _key,
      jsonEncode(<String, dynamic>{
        'version': 1,
        'entries': entries.map((entry) => entry.toJson()).toList(),
      }),
    );
  }

  List<Phase1NotificationScheduleIntent> _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      final values = decoded is Map ? decoded['entries'] : decoded;
      if (values is! List) return const [];
      return values
          .map(Phase1NotificationScheduleIntent.fromJson)
          .whereType<Phase1NotificationScheduleIntent>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Phase1NotificationScheduleIntent _nextOccurrence(
    Phase1NotificationScheduleIntent intent,
    DateTime now,
  ) {
    if (!intent.repeatsDaily) return intent;

    var next = DateTime(
      now.year,
      now.month,
      now.day,
      intent.scheduledFor.hour,
      intent.scheduledFor.minute,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return Phase1NotificationScheduleIntent(
      logicalId: intent.logicalId,
      platformId: intent.platformId,
      kind: intent.kind,
      scheduledFor: next,
      isUserConfigured: intent.isUserConfigured,
      recurrence: intent.recurrence,
    );
  }

  static String _normalizeScope(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? 'guest' : normalized;
  }

  static String _safeScope(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
}

/// Scope-aware adapter used by Personalized without exposing NotificationService.
class SharedPreferencesPhase1NotificationTimingSource
    implements Phase1NotificationTimingSource {
  const SharedPreferencesPhase1NotificationTimingSource();

  @override
  Future<List<Phase1NotificationScheduleIntent>> upcomingForScope({
    String? scopeKey,
    DateTime? now,
    DateTime? horizonEnd,
  }) {
    return SharedPreferencesPhase1NotificationScheduleRegistry(
      scope: scopeKey ?? 'guest',
    ).upcomingForScope(now: now, horizonEnd: horizonEnd);
  }
}
