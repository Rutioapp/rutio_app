import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'Stage A is infrastructure-only and Stage B owns Weekly Report enforcement',
      () {
    final stageA = File(
            'supabase/migrations/20261012145000_revenuecat_premium_projection_stage_a.sql')
        .readAsStringSync();
    final stageB = File(
            'supabase/migrations/20261012150000_weekly_report_premium_gate_and_rate_limit.sql')
        .readAsStringSync();
    expect(stageA, contains('revenuecat_backfill_runs'));
    expect(stageA, contains('revenuecat_webhook_events'));
    expect(stageA, isNot(contains('weekly report premium required')));
    expect(stageB, contains('ETAPA B'));
    expect(stageB, contains('weekly report premium required'));
    expect(stageB, contains('successful_refresh_count >= 3'));
  });

  test('Stage B preserves the original Weekly Report contract boundaries', () {
    final stageB = File(
            'supabase/migrations/20261012150000_weekly_report_premium_gate_and_rate_limit.sql')
        .readAsStringSync();
    for (final name in [
      'activate_weekly_report',
      'get_my_weekly_report',
      'get_my_latest_weekly_report',
      'list_my_weekly_reports',
      'refresh_my_weekly_report',
      'get_my_weekly_report_by_week_start',
    ]) {
      expect(stageB, contains('create or replace function public.$name'));
    }
    expect(stageB, contains('only the current eligible week may be refreshed'));
    expect(stageB, contains('process_weekly_report_automation'));
    expect(
        stageB,
        contains(
            'if not app_private.is_weekly_report_premium(a.user_id) then continue; end if;'));
  });
}
