import 'package:flutter/foundation.dart';

@immutable
class RemoteStreakProtectionParseException implements Exception {
  const RemoteStreakProtectionParseException(this.message);

  final String message;

  @override
  String toString() => 'RemoteStreakProtectionParseException: $message';
}

@immutable
class HabitStreakShieldRemote {
  const HabitStreakShieldRemote({
    required this.id,
    required this.requestId,
    required this.operationId,
    required this.habitId,
    required this.utilityId,
    required this.effectId,
    required this.logicalTimeZone,
    required this.protectedOccurrenceDate,
    required this.status,
    required this.activatedAt,
    this.consumedAt,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String requestId;
  final String operationId;
  final String habitId;
  final String utilityId;
  final String effectId;
  final String logicalTimeZone;
  final DateTime protectedOccurrenceDate;
  final String status;
  final DateTime activatedAt;
  final DateTime? consumedAt;
  final Map<String, dynamic> raw;

  bool get isArmed => status == 'armed';

  factory HabitStreakShieldRemote.fromMap(Map<String, dynamic> map) {
    final status = _requiredString(map, 'status');
    if (!_validShieldStatuses.contains(status)) {
      throw RemoteStreakProtectionParseException(
        'Invalid shield status "$status".',
      );
    }

    return HabitStreakShieldRemote(
      id: _requiredString(map, 'id'),
      requestId: _requiredString(map, 'request_id'),
      operationId: _requiredString(map, 'operation_id'),
      habitId: _requiredString(map, 'habit_id'),
      utilityId: _requiredString(map, 'utility_id'),
      effectId: _requiredString(map, 'effect_id'),
      logicalTimeZone: _requiredString(map, 'logical_time_zone'),
      protectedOccurrenceDate:
          _requiredLogicalDate(map, 'protected_occurrence_date'),
      status: status,
      activatedAt: _requiredInstantUtc(map, 'activated_at'),
      consumedAt: _nullableInstantUtc(map, 'consumed_at'),
      raw: Map<String, dynamic>.from(map),
    );
  }
}

@immutable
class HabitStreakBreakRemote {
  const HabitStreakBreakRemote({
    required this.id,
    required this.requestId,
    required this.recoveryRequestId,
    required this.breakId,
    required this.habitId,
    required this.logicalTimeZone,
    required this.missedOccurrenceDate,
    required this.previousStreak,
    required this.currentStreakAfterBreak,
    required this.status,
    required this.brokenAt,
    required this.recoverableUntil,
    this.recoveredAt,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String requestId;
  final String recoveryRequestId;
  final String breakId;
  final String habitId;
  final String logicalTimeZone;
  final DateTime missedOccurrenceDate;
  final int previousStreak;
  final int currentStreakAfterBreak;
  final String status;
  final DateTime brokenAt;
  final DateTime recoverableUntil;
  final DateTime? recoveredAt;
  final Map<String, dynamic> raw;

  bool get isRecoverable => status == 'recoverable';

  factory HabitStreakBreakRemote.fromMap(Map<String, dynamic> map) {
    final status = _requiredString(map, 'status');
    if (!_validBreakStatuses.contains(status)) {
      throw RemoteStreakProtectionParseException(
        'Invalid streak break status "$status".',
      );
    }

    return HabitStreakBreakRemote(
      id: _requiredString(map, 'id'),
      requestId: _requiredString(map, 'request_id'),
      recoveryRequestId: _requiredString(map, 'recovery_request_id'),
      breakId: _requiredString(map, 'break_id'),
      habitId: _requiredString(map, 'habit_id'),
      logicalTimeZone: _requiredString(map, 'logical_time_zone'),
      missedOccurrenceDate: _requiredLogicalDate(map, 'missed_occurrence_date'),
      previousStreak: _requiredNonNegativeInt(map, 'previous_streak'),
      currentStreakAfterBreak:
          _requiredNonNegativeInt(map, 'current_streak_after_break'),
      status: status,
      brokenAt: _requiredInstantUtc(map, 'broken_at'),
      recoverableUntil: _requiredInstantUtc(map, 'recoverable_until'),
      recoveredAt: _nullableInstantUtc(map, 'recovered_at'),
      raw: Map<String, dynamic>.from(map),
    );
  }
}

@immutable
class ActivateStreakShieldRemoteResult {
  const ActivateStreakShieldRemoteResult({
    required this.shield,
    this.status = 'armed',
    this.isIdempotent = false,
  });

  final HabitStreakShieldRemote shield;
  final String status;
  final bool isIdempotent;

  factory ActivateStreakShieldRemoteResult.fromMap(
    Map<String, dynamic> map,
  ) {
    final shieldMap = _nestedMap(map, const <String>[
          'shield',
          'streak_shield',
          'habit_streak_shield',
        ]) ??
        map;
    return ActivateStreakShieldRemoteResult(
      shield: HabitStreakShieldRemote.fromMap(shieldMap),
      status:
          (map['status'] ?? shieldMap['status'] ?? 'armed').toString().trim(),
      isIdempotent: map['idempotent'] == true || map['is_idempotent'] == true,
    );
  }
}

enum CloseMissedHabitOccurrenceRemoteStatus {
  alreadyContinuous,
  shieldConsumed,
  breakRecorded,
  breakExpired,
}

extension CloseMissedHabitOccurrenceRemoteStatusX
    on CloseMissedHabitOccurrenceRemoteStatus {
  String get key {
    switch (this) {
      case CloseMissedHabitOccurrenceRemoteStatus.alreadyContinuous:
        return 'already_continuous';
      case CloseMissedHabitOccurrenceRemoteStatus.shieldConsumed:
        return 'shield_consumed';
      case CloseMissedHabitOccurrenceRemoteStatus.breakRecorded:
        return 'break_recorded';
      case CloseMissedHabitOccurrenceRemoteStatus.breakExpired:
        return 'break_expired';
    }
  }

  static CloseMissedHabitOccurrenceRemoteStatus? fromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'already_continuous':
        return CloseMissedHabitOccurrenceRemoteStatus.alreadyContinuous;
      case 'shield_consumed':
        return CloseMissedHabitOccurrenceRemoteStatus.shieldConsumed;
      case 'break_recorded':
        return CloseMissedHabitOccurrenceRemoteStatus.breakRecorded;
      case 'break_expired':
        return CloseMissedHabitOccurrenceRemoteStatus.breakExpired;
      default:
        return null;
    }
  }
}

@immutable
class CloseMissedHabitOccurrenceRemoteResult {
  const CloseMissedHabitOccurrenceRemoteResult({
    required this.status,
    this.shield,
    this.breakRecord,
    this.isIdempotent = false,
  });

  final CloseMissedHabitOccurrenceRemoteStatus status;
  final HabitStreakShieldRemote? shield;
  final HabitStreakBreakRemote? breakRecord;
  final bool isIdempotent;

  factory CloseMissedHabitOccurrenceRemoteResult.fromMap(
    Map<String, dynamic> map,
  ) {
    final status = CloseMissedHabitOccurrenceRemoteStatusX.fromKey(
        map['status']?.toString());
    if (status == null) {
      throw const RemoteStreakProtectionParseException(
        'Invalid close missed occurrence status.',
      );
    }

    final shieldMap = _nestedMap(map, const <String>[
      'shield',
      'streak_shield',
      'habit_streak_shield',
    ]);
    final breakMap = _nestedMap(map, const <String>[
      'break',
      'streak_break',
      'habit_streak_break',
    ]);

    return CloseMissedHabitOccurrenceRemoteResult(
      status: status,
      shield:
          shieldMap == null ? null : HabitStreakShieldRemote.fromMap(shieldMap),
      breakRecord:
          breakMap == null ? null : HabitStreakBreakRemote.fromMap(breakMap),
      isIdempotent: map['idempotent'] == true || map['is_idempotent'] == true,
    );
  }
}

@immutable
class RecoverStreakBreakRemoteResult {
  const RecoverStreakBreakRemoteResult({
    required this.status,
    required this.breakRecord,
    this.isIdempotent = false,
  });

  final String status;
  final HabitStreakBreakRemote breakRecord;
  final bool isIdempotent;

  bool get isRecovered => status == 'recovered';
  bool get isExpired => status == 'expired';

  factory RecoverStreakBreakRemoteResult.fromMap(Map<String, dynamic> map) {
    final breakMap = _nestedMap(map, const <String>[
          'break',
          'streak_break',
          'habit_streak_break',
        ]) ??
        map;
    final breakRecord = HabitStreakBreakRemote.fromMap(breakMap);
    final status = (map['status'] ?? breakRecord.status).toString().trim();
    if (status != 'recovered' && status != 'expired') {
      throw RemoteStreakProtectionParseException(
        'Invalid recover streak break status "$status".',
      );
    }
    return RecoverStreakBreakRemoteResult(
      status: status,
      breakRecord: breakRecord,
      isIdempotent: map['idempotent'] == true || map['is_idempotent'] == true,
    );
  }
}

const Set<String> _validShieldStatuses = <String>{
  'armed',
  'consumed',
  'cancelled',
  'expired',
};

const Set<String> _validBreakStatuses = <String>{
  'recoverable',
  'recovered',
  'expired',
};

String _requiredString(Map<String, dynamic> map, String key) {
  final value = (map[key] ?? '').toString().trim();
  if (value.isEmpty) {
    throw RemoteStreakProtectionParseException(
      'Missing required string "$key".',
    );
  }
  return value;
}

int _requiredNonNegativeInt(Map<String, dynamic> map, String key) {
  final raw = map[key];
  final parsed = raw is int
      ? raw
      : raw is num
          ? raw.toInt()
          : int.tryParse((raw ?? '').toString().trim());
  if (parsed == null || parsed < 0) {
    throw RemoteStreakProtectionParseException(
      'Invalid non-negative integer "$key".',
    );
  }
  return parsed;
}

DateTime _requiredLogicalDate(Map<String, dynamic> map, String key) {
  final value = _requiredString(map, key);
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    throw RemoteStreakProtectionParseException(
      'Invalid logical date "$key".',
    );
  }
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

DateTime _requiredInstantUtc(Map<String, dynamic> map, String key) {
  final value = _requiredString(map, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw RemoteStreakProtectionParseException('Invalid timestamp "$key".');
  }
  return parsed.toUtc();
}

DateTime? _nullableInstantUtc(Map<String, dynamic> map, String key) {
  final value = (map[key] ?? '').toString().trim();
  if (value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw RemoteStreakProtectionParseException('Invalid timestamp "$key".');
  }
  return parsed.toUtc();
}

Map<String, dynamic>? _nestedMap(
  Map<String, dynamic> map,
  List<String> candidateKeys,
) {
  for (final key in candidateKeys) {
    final value = map[key];
    if (value is Map) {
      return Map<String, dynamic>.from(value.cast<String, dynamic>());
    }
  }
  return null;
}
