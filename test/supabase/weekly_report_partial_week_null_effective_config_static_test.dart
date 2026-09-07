import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'supabase/migrations/20260907110000_weekly_report_partial_week_null_effective_config_fix.sql',
  ).readAsStringSync();

  test('guards NULL effective configs before quota-segment insertion', () {
    expect(source, contains('or v_cfg.id is null'));
    expect(source, contains('or v_cfg.effective_local_date is null'));
    expect(source, contains('or v_cfg.schedule is null'));
    expect(source,
        contains("v_cfg.schedule->>'type' is distinct from 'timesPerWeek'"));
  });

  test('guards NULL effective configs before occurrence generation', () {
    final occurrenceGuard = RegExp(
      r'if not found\s+or v_cfg\.id is null\s+or v_cfg\.effective_local_date is null\s+or v_cfg\.schedule is null\s+or v_cfg\.effective_local_date > v_day\s+or v_cfg\.is_archived then',
    );
    expect(occurrenceGuard.allMatches(source), hasLength(1));
  });

  test('keeps the helper contract unchanged and only forwards the generator',
      () {
    expect(
        source,
        contains(
            'create or replace function app_private.generate_or_refresh_weekly_report'));
    expect(
        source,
        isNot(contains(
            'create or replace function app_private.weekly_report_effective_config')));
    expect(
        source,
        contains(
            'if found and v_existing.status = \'final\' then return v_existing; end if;'));
    expect(source, contains('if not found\n         or v_cfg.id is null'));
  });

  test('preserves partial-week and Monday finalization contracts', () {
    final automation = File(
      'supabase/migrations/20260903150000_weekly_report_phase_12_automation.sql',
    ).readAsStringSync();
    expect(source,
        contains('v_activation.activation_local_date > p_week_start_date'));
    expect(automation, contains('extract(isodow from local_now)::int = 1'));
    expect(automation, contains('perform app_private.finalize_weekly_report'));
  });

  test('keeps effective-date filtering before daily occurrence reads', () {
    final occurrenceGuard = RegExp(
      r'if not found\s+or v_cfg\.id is null[\s\S]*?or v_cfg\.effective_local_date > v_day[\s\S]*?then\s+continue;[\s\S]*?select \* into v_log',
    );
    expect(occurrenceGuard.hasMatch(source), isTrue);
  });
}
