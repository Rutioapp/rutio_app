import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live provisional generator caps eligibility at local today', () {
    final source = File(
      'supabase/migrations/20260904100000_weekly_report_live_provisional.sql',
    ).readAsStringSync();

    expect(source, contains('v_local_today := (now() at time zone'));
    expect(source, contains('d::date <= v_local_today'));
    expect(source, contains('l.log_date = v_day'));
    expect(source, contains('delete from public.weekly_report_days'));
    expect(source, contains("if found and v_existing.status = 'final'"));
  });

  test('current-week refresh fix removes ambiguous copy-key overload', () {
    final source = File(
      'supabase/migrations/20260904110000_weekly_report_current_week_refresh_fix.sql',
    ).readAsStringSync();

    expect(source, contains('drop function if exists'));
    expect(source, contains('uuid, date, text, integer, text, uuid'));
    expect(source, contains('revoke all on function'));
  });
}
