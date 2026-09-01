import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 5 read API is owner-scoped and does not grant table reads', () {
    final sql =
        File('supabase/migrations/20260901150000_weekly_report_read_api.sql')
            .readAsStringSync();
    expect(sql, contains('auth.uid()'));
    expect(sql, contains('set search_path = \'\''));
    expect(sql, contains('least(greatest(coalesce(p_limit, 20), 1), 50)'));
    expect(sql, contains('get_my_weekly_report'));
    expect(sql, contains('get_my_latest_weekly_report'));
    expect(sql, contains('list_my_weekly_reports'));
    expect(sql, contains('refresh_my_weekly_report'));
    expect(sql, isNot(contains('grant select on public.weekly_reports')));
    expect(sql, contains("status = 'final'"));
    expect(sql, contains("from public, anon"));
    expect(sql, contains('to authenticated'));
    expect(sql, contains("now() at time zone v_activation.timezone_name"));
    expect(sql, isNot(contains('grant select on public.weekly_report')));
  });
}
