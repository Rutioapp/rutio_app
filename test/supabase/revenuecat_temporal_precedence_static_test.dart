import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('corrective policy never orders API v2 by local time', () {
    final sql = File(
      'supabase/migrations_rejected/20261013100000_revenuecat_temporal_precedence_hardening.sql.rejected',
    ).readAsStringSync();
    expect(sql, contains("'observed_v1'"));
    expect(sql, isNot(contains("'authoritative_v1'")));
    expect(sql, contains("'unversioned'"));
    expect(sql, contains('SNAPSHOT_CLOCK_MISMATCH'));
    expect(sql, contains('UNVERSIONED_SNAPSHOT'));
    expect(sql, contains('reconciliation_required = true'));
    expect(sql, contains('v_existing.reconciliation_required'));
    expect(sql, contains('is_active = excluded.is_active'));
    expect(sql, contains("set search_path = ''"));
    expect(sql, contains('revoke all on function'));
  });

  test('v2 webhook path does not synthesize a snapshot version', () {
    final source = File('supabase/functions/revenuecat-webhook/index.ts')
        .readAsStringSync();
    expect(source, contains('enqueue_revenuecat_premium_sync'));
    expect(source, isNot(contains('/v2/projects/')));
    expect(source, isNot(contains('new Date().toISOString()')));
  });

  test('isolated temporal integration scenarios are prepared', () {
    final sql = File(
      'supabase/tests/revenuecat_temporal_precedence_integration.sql',
    ).readAsStringSync();
    expect(sql, contains('unversioned snapshot preserves active entitlement'));
    expect(sql, contains('older observed snapshot ignored'));
    expect(sql, contains('equal observed snapshot requires reconciliation'));
    expect(sql, contains('authoritative reconciliation recovers state'));
    expect(sql, contains('rollback'));
  });
}
