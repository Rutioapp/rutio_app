import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
          'supabase/migrations/20260902120000_weekly_report_recommendation_v1.sql')
      .readAsStringSync();

  test('recommendation V1 is snapshot-only, final-only and deterministic', () {
    expect(sql, contains('recommendation_policy_version'));
    expect(sql, contains("recommendation_type in ('reduceFrequency')"));
    expect(sql, contains("x.classification = 'needs_attention'"));
    expect(sql, contains('x.completion_rate asc'));
    expect(sql, contains('x.scheduled_count desc'));
    expect(sql, contains('x.habit_id asc'));
    expect(sql, contains('r.is_first_partial_week'));
    expect(sql, contains("r.status = 'final' and n.status = 'proposed'"));
  });

  test('patch and historical identity are persisted and validated', () {
    expect(sql, contains('habit_name text'));
    expect(sql, contains('current_config jsonb'));
    expect(sql, contains("proposed_patch->>'version' = '1'"));
    expect(sql, contains("proposed_patch->>'type' = 'reduceFrequency'"));
    expect(sql, contains('weekly_report_one_proposed_recommendation'));
  });

  test(
      'report trigger uses its real NEW row and closes the recommendation insert',
      () {
    expect(sql, contains('on public.weekly_reports'));
    expect(sql, contains('after update of refreshed_at, completion_rate'));
    expect(sql, contains('x.report_id = new.id'));
    expect(sql, contains("Trigger table: weekly_reports"));
    expect(sql, isNot(contains('x.report_id = new.report_id')));
    expect(sql, contains("\n  );\n  return new;"));
  });
}
