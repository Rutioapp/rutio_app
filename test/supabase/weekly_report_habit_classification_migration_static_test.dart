import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
          'supabase/migrations/20260902100000_weekly_report_habit_classification.sql')
      .readAsStringSync();

  test('classification V1 policy is centralized and deterministic', () {
    expect(sql, contains('p_completion_rate >= 0.80'));
    expect(sql, contains('p_completion_rate < 0.50'));
    expect(sql, contains("then 'unavailable'"));
    expect(sql, contains("then 'highlighted'"));
    expect(sql, contains("then 'needs_attention'"));
    expect(sql, contains("else 'stable'"));
    expect(sql, contains('immutable'));
  });

  test('snapshot column and payload order are backend-owned', () {
    expect(sql, contains('add column if not exists classification'));
    expect(sql, contains("'classification', h.classification"));
    expect(sql, contains("when 'highlighted' then 1"));
    expect(sql, contains("when 'stable' then 2"));
    expect(sql, contains("when 'needs_attention' then 3"));
    expect(sql, contains('h.name asc, h.habit_id asc'));
  });
}
