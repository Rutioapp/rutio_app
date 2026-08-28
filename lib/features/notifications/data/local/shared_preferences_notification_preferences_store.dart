import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/personalized_notification_models.dart';
import '../../domain/personalized_notification_ports.dart';
import 'notification_local_storage_scope.dart';

class SharedPreferencesNotificationPreferencesStore
    implements NotificationPreferencesStore {
  SharedPreferencesNotificationPreferencesStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const int _schemaVersion = 1;

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  @override
  Future<NotificationPreferences> load(NotificationScope scope) async {
    final prefs = await _sharedPreferencesProvider();
    final raw =
        prefs.getString(NotificationLocalStorageScope.preferencesKey(scope));
    if (raw == null || raw.trim().isEmpty) {
      return NotificationPreferences.defaults();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return NotificationPreferences.defaults();
      return _decodePreferences(
          Map<String, dynamic>.from(decoded.cast<String, dynamic>()));
    } catch (_) {
      return NotificationPreferences.defaults();
    }
  }

  @override
  Future<void> save(
    NotificationScope scope,
    NotificationPreferences preferences,
  ) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.setString(
      NotificationLocalStorageScope.preferencesKey(scope),
      jsonEncode(_encodePreferences(preferences)),
    );
  }

  @override
  Future<NotificationPreferences> update(
    NotificationScope scope,
    NotificationPreferences Function(NotificationPreferences current) update,
  ) async {
    final current = await load(scope);
    final next = update(current);
    await save(scope, next);
    return next;
  }

  @override
  Future<void> reset(NotificationScope scope) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.remove(NotificationLocalStorageScope.preferencesKey(scope));
  }

  Map<String, dynamic> _encodePreferences(NotificationPreferences preferences) {
    return <String, dynamic>{
      'schemaVersion': _schemaVersion,
      'masterEnabled': preferences.masterEnabled,
      'habitRemindersEnabled': preferences.habitRemindersEnabled,
      'generalNotificationsEnabled': preferences.generalNotificationsEnabled,
      'intensityPreset': preferences.intensityPreset.name,
      'generalNotificationCapPerDay': preferences.generalNotificationCapPerDay,
      'maxAdditionalContextualPerDay':
          preferences.maxAdditionalContextualPerDay,
      'preferredGeneralWindow': _encodeTimeWindow(
        preferences.preferredGeneralWindow,
      ),
      'dayClosureTime': preferences.dayClosureTime.formatHhMm(),
      'dailyAnchorTime': preferences.dailyAnchorTime.formatHhMm(),
      'quietHoursStart': preferences.quietHoursStart?.formatHhMm(),
      'quietHoursEnd': preferences.quietHoursEnd?.formatHhMm(),
      'useWakeTimeAsAnchor': preferences.useWakeTimeAsAnchor,
      'wakeTimeSource': preferences.wakeTimeSource.name,
      'fallbackAnchorPolicy': preferences.fallbackAnchorPolicy,
    };
  }

  NotificationPreferences _decodePreferences(Map<String, dynamic> json) {
    final defaults = NotificationPreferences.defaults();
    return NotificationPreferences(
      masterEnabled: _readBool(json['masterEnabled'], defaults.masterEnabled),
      habitRemindersEnabled: _readBool(
        json['habitRemindersEnabled'],
        defaults.habitRemindersEnabled,
      ),
      generalNotificationsEnabled: _readBool(
        json['generalNotificationsEnabled'],
        defaults.generalNotificationsEnabled,
      ),
      intensityPreset: _readIntensityPreset(
        json['intensityPreset'],
        defaults.intensityPreset,
      ),
      generalNotificationCapPerDay: _readNonNegativeInt(
        json['generalNotificationCapPerDay'],
        defaults.generalNotificationCapPerDay,
      ),
      maxAdditionalContextualPerDay: _readNonNegativeInt(
        json['maxAdditionalContextualPerDay'],
        defaults.maxAdditionalContextualPerDay,
      ),
      preferredGeneralWindow: _readTimeWindow(
        json['preferredGeneralWindow'],
        defaults.preferredGeneralWindow,
      ),
      dayClosureTime: _readClockTime(
        json['dayClosureTime'],
        defaults.dayClosureTime,
      ),
      dailyAnchorTime: _readClockTime(
        json['dailyAnchorTime'],
        defaults.dailyAnchorTime,
      ),
      quietHoursStart: _readNullableClockTime(json['quietHoursStart']),
      quietHoursEnd: _readNullableClockTime(json['quietHoursEnd']),
      useWakeTimeAsAnchor: _readBool(
        json['useWakeTimeAsAnchor'],
        defaults.useWakeTimeAsAnchor,
      ),
      wakeTimeSource: _readWakeTimeSource(
        json['wakeTimeSource'],
        defaults.wakeTimeSource,
      ),
      fallbackAnchorPolicy: _readString(
        json['fallbackAnchorPolicy'],
        defaults.fallbackAnchorPolicy,
      ),
    );
  }

  Map<String, dynamic> _encodeTimeWindow(NotificationTimeWindow window) {
    return <String, dynamic>{
      'start': window.start.formatHhMm(),
      'end': window.end.formatHhMm(),
    };
  }

  NotificationTimeWindow _readTimeWindow(
    dynamic raw,
    NotificationTimeWindow fallback,
  ) {
    if (raw is! Map) return fallback;
    final map = Map<String, dynamic>.from(raw.cast<String, dynamic>());
    return NotificationTimeWindow(
      start: _readClockTime(map['start'], fallback.start),
      end: _readClockTime(map['end'], fallback.end),
    );
  }

  NotificationClockTime _readClockTime(
    dynamic raw,
    NotificationClockTime fallback,
  ) {
    if (raw is! String) return fallback;
    return NotificationClockTime.parse(raw, fallback: fallback);
  }

  NotificationClockTime? _readNullableClockTime(dynamic raw) {
    if (raw is! String || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    final parts = trimmed.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return NotificationClockTime(hour: hour, minute: minute);
  }

  NotificationIntensityPreset _readIntensityPreset(
    dynamic raw,
    NotificationIntensityPreset fallback,
  ) {
    final value = _readString(raw, fallback.name);
    return NotificationIntensityPreset.values.firstWhere(
      (preset) => preset.name == value,
      orElse: () => fallback,
    );
  }

  WakeTimeSource _readWakeTimeSource(
    dynamic raw,
    WakeTimeSource fallback,
  ) {
    final value = _readString(raw, fallback.name);
    return WakeTimeSource.values.firstWhere(
      (source) => source.name == value,
      orElse: () => fallback,
    );
  }

  bool _readBool(dynamic raw, bool fallback) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final normalized = (raw ?? '').toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return fallback;
  }

  int _readNonNegativeInt(dynamic raw, int fallback) {
    if (raw is int && raw >= 0) return raw;
    if (raw is num && raw >= 0) return raw.toInt();
    final parsed = int.tryParse((raw ?? '').toString().trim());
    if (parsed == null || parsed < 0) return fallback;
    return parsed;
  }

  String _readString(dynamic raw, String fallback) {
    final normalized = (raw ?? '').toString().trim();
    return normalized.isEmpty ? fallback : normalized;
  }
}
