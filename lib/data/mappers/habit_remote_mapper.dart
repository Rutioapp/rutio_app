import '../models/remote/remote_habit.dart';

class HabitRemoteMapper {
  const HabitRemoteMapper._();

  static RemoteHabit toRemoteHabit(
    Map<String, dynamic> localHabit, {
    required String userId,
    required int sortOrder,
    String? remoteHabitIdOverride,
  }) {
    final normalizedType = _normalizeHabitType(
      localHabit['type'] ??
          localHabit['trackingType'] ??
          localHabit['habitType'] ??
          localHabit['tracking'],
    );

    final reminderEnabled = localHabit['reminderEnabled'] == true ||
        localHabit['remindersEnabled'] == true;

    final targetCount = _resolveTargetCount(
      localHabit: localHabit,
      normalizedType: normalizedType,
    );

    return RemoteHabit(
      id: extractRemoteHabitId(
        localHabit,
        remoteHabitIdOverride: remoteHabitIdOverride,
      ),
      userId: userId,
      name: _requiredName(localHabit),
      familyId: _nullableTrim(localHabit['familyId']),
      emoji: _nullableTrim(localHabit['emoji'] ?? localHabit['habitEmoji']),
      habitType: normalizedType,
      targetCount: targetCount,
      unit: normalizedType == 'count'
          ? _nullableTrim(
              localHabit['unit'] ??
                  localHabit['unitLabel'] ??
                  localHabit['counterUnit'],
            )
          : null,
      colorId:
          _nullableTrim(localHabit['colorId'] ?? localHabit['familyColorId']),
      reminderEnabled: reminderEnabled,
      reminderTime: reminderEnabled
          ? _normalizeReminderTime(localHabit['reminderTime'])
          : null,
      isArchived: localHabit['archived'] == true ||
          localHabit['isArchived'] == true ||
          localHabit['is_archived'] == true,
      sortOrder: _safeInt(localHabit['sortOrder'], fallback: sortOrder),
      createdAt: _nullableDateTime(localHabit['createdAt']),
      updatedAt: _nullableDateTime(localHabit['updatedAt']),
      raw: Map<String, dynamic>.from(localHabit),
    );
  }

  static String? extractLocalHabitId(Map<String, dynamic> localHabit) {
    final id = _nullableTrim(
      localHabit['id'] ??
          localHabit['habitId'] ??
          localHabit['uuid'] ??
          localHabit['key'],
    );
    return id;
  }

  static String? extractRemoteHabitId(
    Map<String, dynamic> localHabit, {
    String? remoteHabitIdOverride,
  }) {
    final override = _nullableTrim(remoteHabitIdOverride);
    if (override != null && _isUuid(override)) {
      return override.toLowerCase();
    }

    final persistedRemoteId = _nullableTrim(
      localHabit['remoteId'] ??
          localHabit['remoteHabitId'] ??
          localHabit['supabaseHabitId'],
    );
    if (persistedRemoteId != null && _isUuid(persistedRemoteId)) {
      return persistedRemoteId.toLowerCase();
    }

    final localId = extractLocalHabitId(localHabit);
    if (localId != null && _isUuid(localId)) {
      return localId.toLowerCase();
    }

    return null;
  }

  static bool isUuid(String value) => _isUuid(value.trim());

  static String _requiredName(Map<String, dynamic> localHabit) {
    final name = _nullableTrim(localHabit['name'] ?? localHabit['title']);
    return name ?? 'Habit';
  }

  static String _normalizeHabitType(dynamic value) {
    final normalized = (value ?? '').toString().trim().toLowerCase();
    return normalized == 'count' || normalized == 'counter' || normalized == 'number'
        ? 'count'
        : 'check';
  }

  static int? _resolveTargetCount({
    required Map<String, dynamic> localHabit,
    required String normalizedType,
  }) {
    final rawTarget = localHabit['targetCount'] ??
        localHabit['target'] ??
        localHabit['goal'] ??
        localHabit['times'] ??
        localHabit['timesPerWeekTarget'];
    final parsed = _nullableInt(rawTarget);
    if (parsed == null || parsed < 1) {
      return normalizedType == 'count' ? 1 : null;
    }

    if (normalizedType == 'check' && parsed <= 1) {
      return null;
    }

    return parsed;
  }

  static String? _normalizeReminderTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return _toHhMmSs(
        value.hour,
        value.minute,
        value.second,
      );
    }

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    final hhMmPattern = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');
    final hhMmMatch = hhMmPattern.firstMatch(raw);
    if (hhMmMatch != null) {
      final hour = int.tryParse(hhMmMatch.group(1) ?? '');
      final minute = int.tryParse(hhMmMatch.group(2) ?? '');
      final second = int.tryParse(hhMmMatch.group(3) ?? '0') ?? 0;
      if (hour == null ||
          minute == null ||
          hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59 ||
          second < 0 ||
          second > 59) {
        return null;
      }
      return _toHhMmSs(hour, minute, second);
    }

    final parsedDateTime = DateTime.tryParse(raw);
    if (parsedDateTime != null) {
      return _toHhMmSs(
        parsedDateTime.hour,
        parsedDateTime.minute,
        parsedDateTime.second,
      );
    }

    return null;
  }

  static String _toHhMmSs(int hour, int minute, int second) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    final ss = second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  static String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static int _safeInt(dynamic value, {required int fallback}) {
    final parsed = _nullableInt(value);
    if (parsed == null) return fallback;
    return parsed;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  static DateTime? _nullableDateTime(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }

  static bool _isUuid(String value) {
    final uuidRegExp = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegExp.hasMatch(value);
  }
}
