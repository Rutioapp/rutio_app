import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/data/cloud/streak_protection_remote_models.dart';

void main() {
  group('HabitStreakShieldRemote', () {
    test('parses known fields and ignores unknown fields', () {
      final shield = HabitStreakShieldRemote.fromMap(<String, dynamic>{
        'id': 'shield-1',
        'request_id': 'req-1',
        'operation_id': 'op-1',
        'habit_id': 'remote-habit-1',
        'utility_id': 'utility_streak_shield_1',
        'effect_id': 'effect-1',
        'logical_time_zone': 'Europe/Madrid',
        'protected_occurrence_date': '2026-07-25',
        'status': 'armed',
        'activated_at': '2026-07-25T10:30:00+02:00',
        'consumed_at': null,
        'ignored': 'ok',
      });

      expect(shield.id, 'shield-1');
      expect(shield.requestId, 'req-1');
      expect(shield.operationId, 'op-1');
      expect(shield.protectedOccurrenceDate, DateTime(2026, 7, 25));
      expect(shield.protectedOccurrenceDate.isUtc, isFalse);
      expect(shield.activatedAt, DateTime.utc(2026, 7, 25, 8, 30));
      expect(shield.activatedAt.isUtc, isTrue);
    });

    test('fails in a controlled way for invalid required data', () {
      expect(
        () => HabitStreakShieldRemote.fromMap(<String, dynamic>{
          'id': 'shield-1',
          'request_id': 'req-1',
          'operation_id': 'op-1',
          'habit_id': 'remote-habit-1',
          'utility_id': 'utility_streak_shield_1',
          'effect_id': 'effect-1',
          'logical_time_zone': 'Europe/Madrid',
          'protected_occurrence_date': '2026-07-25',
          'status': 'surprise',
          'activated_at': '2026-07-25T10:30:00Z',
        }),
        throwsA(isA<RemoteStreakProtectionParseException>()),
      );
    });
  });

  group('HabitStreakBreakRemote', () {
    test('keeps logical dates date-only and parses timestamptz as UTC', () {
      final streakBreak = HabitStreakBreakRemote.fromMap(<String, dynamic>{
        'id': 'row-1',
        'request_id': 'req-1',
        'recovery_request_id': 'rec-1',
        'break_id': 'break-1',
        'habit_id': 'remote-habit-1',
        'logical_time_zone': 'America/New_York',
        'missed_occurrence_date': '2026-03-08',
        'previous_streak': 9,
        'current_streak_after_break': 0,
        'status': 'recoverable',
        'broken_at': '2026-03-09T01:30:00-04:00',
        'recoverable_until': '2026-03-10T05:00:00Z',
        'recovered_at': null,
        'unknown_field': true,
      });

      expect(streakBreak.missedOccurrenceDate, DateTime(2026, 3, 8));
      expect(streakBreak.requestId, 'req-1');
      expect(streakBreak.recoveryRequestId, 'rec-1');
      expect(streakBreak.missedOccurrenceDate.isUtc, isFalse);
      expect(streakBreak.brokenAt, DateTime.utc(2026, 3, 9, 5, 30));
      expect(streakBreak.recoverableUntil, DateTime.utc(2026, 3, 10, 5));
      expect(streakBreak.brokenAt.isUtc, isTrue);
    });

    test('fails in a controlled way for invalid required data', () {
      expect(
        () => HabitStreakBreakRemote.fromMap(<String, dynamic>{
          'id': 'row-1',
          'request_id': 'req-1',
          'recovery_request_id': 'rec-1',
          'break_id': 'break-1',
          'habit_id': 'remote-habit-1',
          'logical_time_zone': 'Europe/Madrid',
          'missed_occurrence_date': '2026-07-25T00:00:00Z',
          'previous_streak': 1,
          'current_streak_after_break': 0,
          'status': 'recoverable',
          'broken_at': '2026-07-26T10:00:00Z',
          'recoverable_until': '2026-07-27T00:00:00Z',
        }),
        throwsA(isA<RemoteStreakProtectionParseException>()),
      );
    });
  });
}
