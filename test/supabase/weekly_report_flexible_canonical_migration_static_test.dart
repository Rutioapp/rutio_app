import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260907100000_weekly_report_flexible_canonical_backend_v1.sql',
  ).readAsStringSync();

  test('stores raw and capped metrics additively at metrics policy v2', () {
    expect(migration, contains('completed_count_raw'));
    expect(migration, contains('raw_completion_rate'));
    expect(migration, contains('capped_completion_rate'));
    expect(
        migration,
        contains(
            "metrics_data_quality in ('legacy', 'verified', 'partial', 'unverifiable')"));
    expect(migration, contains('metrics_policy_version,\n     generated_at'));
    expect(migration, contains('v_report_quality, 2, now(), now()'));
  });

  test('uses full eligible-week quota and observed-day activity separately',
      () {
    expect(migration, contains('observed boolean not null'));
    expect(migration, contains('where observed order by local_date'));
    expect(migration, contains('where eligible order by local_date'));
    expect(migration, contains('ceil(sum(s.configured_quota) / 7.0)::int'));
    expect(migration, contains("schedule->>'type' = 'timesPerWeek'"));
    expect(
        migration,
        contains(
            "then false\n        else app_private.weekly_report_schedule_matches"));
  });

  test('preserves flexible completed, skipped and neutral activity states', () {
    expect(migration,
        contains("'activity', app_private.weekly_report_flexible_activity"));
    expect(migration, contains("then 'skipped'"));
    expect(migration, contains("else 'neutral'"));
    expect(migration, contains("then 'completed'"),
        reason: 'activity helper must define the completed state');
    expect(migration, contains('completed_count_raw'));
    expect(
        migration,
        contains(
            'count(*) filter (\n            where o.schedule->>\'type\' = \'timesPerWeek\' and o.completed)'));
  });

  test('does not replace raw count with the legacy bounded count', () {
    expect(migration, contains('v_report_completed_raw'));
    expect(migration,
        contains('completed_count_raw = excluded.completed_count_raw'));
    expect(migration, contains("'completedRaw', r.completed_count_raw"));
    expect(migration, contains("'rawRatio', r.raw_completion_rate"));
    expect(migration, contains("'cappedRatio', r.capped_completion_rate"));
    expect(migration, contains("'completedRaw', h.completed_count_raw"));
  });

  test('keeps final snapshots immutable and preserves legacy fields', () {
    expect(
        migration,
        contains(
            "if found and v_existing.status = 'final' then return v_existing; end if;"));
    expect(migration, contains("'completedCount', r.completed_count"));
    expect(migration, contains("'completionRate', r.completion_rate"));
    expect(migration, contains("'completedCount', h.completed_count"));
    expect(migration, contains('Legacy bounded count retained'));
  });
}
