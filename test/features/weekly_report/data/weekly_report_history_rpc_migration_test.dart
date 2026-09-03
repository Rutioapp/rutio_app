import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('history alias repair preserves the applied RPC contract', () {
    final migration = File(
      'supabase/migrations/20260903140000_weekly_report_history_rpc_alias_fix.sql',
    ).readAsStringSync();
    final function = migration
        .split('create or replace function public.list_my_weekly_reports')
        .last;

    expect(migration,
        contains('create or replace function public.list_my_weekly_reports('));
    expect(
        function,
        contains(
            'p_before_week_start date default null, p_limit integer default 20'));
    expect(
        function,
        contains(
            'returns jsonb language plpgsql stable security definer set search_path = \'\''));
    expect(function, contains("'reportId', x.id"));
    expect(function, contains("'weekStartDate', x.week_start_date"));
    expect(function, contains("'weekEndDate', x.week_end_date"));
    expect(function, contains("'status', x.status"));
    expect(function, contains("'completionRate', x.completion_rate"));
    expect(function, contains("'completedCount', x.completed_count"));
    expect(function, contains("'scheduledCount', x.scheduled_count"));
    expect(function, contains("'firstPartialWeek', x.is_first_partial_week"));
    expect(function, contains("'refreshedAt', x.refreshed_at"));
    expect(function, contains("'finalizedAt', x.finalized_at"));
    expect(
        function,
        contains(
            'p_before_week_start is null or r.week_start_date < p_before_week_start'));
    expect(function, contains('order by r.week_start_date desc, r.id desc'));
    expect(function, isNot(contains("'reportId', r.id")));
    expect(function, isNot(contains('grant execute')));
    expect(function, isNot(contains('p_user_id')));
  });
}
