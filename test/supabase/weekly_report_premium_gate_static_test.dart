import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Premium gate migration protects every Weekly Report boundary', () {
    final sql = File(
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
      expect(sql, contains(name));
    }
    expect(sql, contains('auth.uid()'));
    expect(sql, contains('weekly report premium required'));
    expect(sql, contains('revenuecat_entitlement_state'));
    expect(sql, contains('revoke all on public.revenuecat_entitlement_state'));
    expect(sql, contains('to service_role'));
  });

  test('refresh rate limit is transactional and charges only after generation',
      () {
    final sql = File(
            'supabase/migrations/20261012150000_weekly_report_premium_gate_and_rate_limit.sql')
        .readAsStringSync();
    expect(sql, contains('successful_refresh_count >= 3'));
    expect(sql, contains("interval '15 minutes'"));
    expect(sql, contains('for update'));
    expect(
        sql.indexOf(
            'v_report := app_private.generate_or_refresh_weekly_report'),
        lessThan(sql.indexOf(
            'successful_refresh_count = successful_refresh_count + 1')));
  });
}
