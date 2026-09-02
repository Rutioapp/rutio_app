import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/20260902110000_weekly_report_habit_classification_backfill.sql',
  ).readAsStringSync();

  test('backfill is snapshot-based, idempotent, and restores final guard', () {
    expect(sql, contains('lock table public.weekly_report_habits in access exclusive mode'));
    expect(sql, contains('classification is distinct from'));
    expect(sql, contains('h.scheduled_count, h.completion_rate'));
    expect(sql, contains('drop trigger if exists trg_weekly_report_habits_guard_final'));
    expect(sql, contains('create trigger trg_weekly_report_habits_guard_final'));
    expect(sql, contains('before insert or update or delete'));
    expect(sql, contains('alter column classification drop default'));
    expect(sql, isNot(contains('Habit live')));
    expect(sql, isNot(contains('grant execute')));
  });

  test('migration keeps the V1 policy in the existing helper', () {
    expect(sql, contains('app_private.weekly_report_habit_classification'));
    expect(sql, isNot(contains("then 'highlighted'")));
    expect(sql, isNot(contains("then 'stable'")));
    expect(sql, isNot(contains("then 'needs_attention'")));
    expect(sql, isNot(contains("then 'unavailable'")));
  });
}
