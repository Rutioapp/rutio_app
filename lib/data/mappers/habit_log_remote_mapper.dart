import '../models/remote/remote_habit_log.dart';

class HabitLogRemoteMapper {
  const HabitLogRemoteMapper._();

  static RemoteHabitLog? toRemoteHabitLog({
    required Map<String, dynamic> localHabit,
    required String userId,
    required DateTime date,
    bool? isCompleted,
    bool? isSkipped,
    num? countValue,
    String? note,
    String source = 'manual',
  }) {
    final remoteHabitId = extractRemoteHabitId(localHabit);
    if (remoteHabitId == null) return null;

    final normalizedDate = DateTime(date.year, date.month, date.day);
    final skipped = isSkipped == true;
    final type = _normalizeHabitType(
      localHabit['type'] ??
          localHabit['trackingType'] ??
          localHabit['habitType'] ??
          localHabit['tracking'],
    );

    if (type == 'count') {
      final rawValue = _safeNum(
        countValue ?? localHabit['progress'],
        fallback: 0,
      ).clamp(0, double.infinity);
      final target = _safePositiveNum(localHabit['target'], fallback: 1);
      final completed = !skipped &&
          ((isCompleted == true) || rawValue >= target);

      return RemoteHabitLog(
        id: '',
        userId: userId,
        habitId: remoteHabitId,
        logDate: normalizedDate,
        value: rawValue.toInt(),
        isCompleted: completed,
        note: _nullableTrim(note),
        source: _normalizeSource(source),
        raw: Map<String, dynamic>.from(localHabit),
      );
    }

    final completed = !skipped && (isCompleted == true);
    return RemoteHabitLog(
      id: '',
      userId: userId,
      habitId: remoteHabitId,
      logDate: normalizedDate,
      value: completed ? 1 : 0,
      isCompleted: completed,
      note: _nullableTrim(note),
      source: _normalizeSource(source),
      raw: Map<String, dynamic>.from(localHabit),
    );
  }

  static String? extractRemoteHabitId(Map<String, dynamic> localHabit) {
    final rawRemoteId = _nullableTrim(
      localHabit['remoteId'] ??
          localHabit['remoteHabitId'] ??
          localHabit['supabaseHabitId'],
    );
    if (rawRemoteId == null || !_isUuid(rawRemoteId)) return null;
    return rawRemoteId.toLowerCase();
  }

  static String _normalizeHabitType(dynamic value) {
    final normalized = (value ?? '').toString().trim().toLowerCase();
    return normalized == 'count' || normalized == 'counter' || normalized == 'number'
        ? 'count'
        : 'check';
  }

  static String _normalizeSource(dynamic value) {
    final normalized = (value ?? '').toString().trim().toLowerCase();
    switch (normalized) {
      case 'manual':
      case 'migration':
      case 'system':
        return normalized;
      default:
        return 'manual';
    }
  }

  static String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static num _safeNum(dynamic value, {num fallback = 0}) {
    if (value is num) return value;
    final parsed = num.tryParse((value ?? '').toString().trim());
    return parsed ?? fallback;
  }

  static num _safePositiveNum(dynamic value, {num fallback = 1}) {
    final parsed = _safeNum(value, fallback: fallback);
    return parsed > 0 ? parsed : fallback;
  }

  static bool _isUuid(String value) {
    final uuidRegExp = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegExp.hasMatch(value);
  }
}
