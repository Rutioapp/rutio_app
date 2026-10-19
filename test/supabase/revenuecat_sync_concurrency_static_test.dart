import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'sync hardening adds atomic leases without activating Weekly Report gates',
      () {
    final sql = File(
            'supabase/migrations/20261012152000_revenuecat_sync_concurrency_hardening.sql')
        .readAsStringSync();
    expect(sql, contains('processing_lease_until'));
    expect(sql, contains('claim_revenuecat_webhook_event'));
    expect(sql, contains('finalize_revenuecat_webhook_event'));
    expect(sql, contains('claim_revenuecat_backfill_run'));
    expect(sql, contains('advance_revenuecat_backfill_run'));
    expect(sql, contains('fail_revenuecat_backfill_run'));
    expect(sql, contains("interval '10 minutes'"));
    expect(sql, contains("interval '30 minutes'"));
    expect(
        sql,
        contains(
            'returning processing_lease_token into v_inserted_lease_token'));
    expect(sql, contains("'status', 'claimed'"));
    expect(sql, contains('extensions.gen_random_uuid()'));
    expect(sql, isNot(contains('weekly report premium required')));
    expect(sql, isNot(contains('refresh_my_weekly_report')));
  });

  test(
      'webhook uses database claim/finalize protocol and checks every ledger result',
      () {
    final source = File('supabase/functions/revenuecat-webhook/index.ts')
        .readAsStringSync();
    expect(source, contains('claim_revenuecat_webhook_event'));
    expect(source, contains("p_status: 'processed'"));
    expect(source, contains("p_status: 'failed'"));
    expect(source, contains("claimMap.status === 'in_progress'"));
    expect(source, contains("response({ accepted: false, retry: true }, 503)"));
    expect(source,
        isNot(contains("response({ accepted: false, retry: true }, 202)")));
    expect(source, contains('if (claimError'));
    expect(source, contains('finalizeError ? response'));
    expect(source, contains('if (positiveError)'));
  });

  test('backfill uses one run lease and commits the cursor only after the page',
      () {
    final source = File('supabase/functions/revenuecat-backfill/index.ts')
        .readAsStringSync();
    expect(source, contains('claim_revenuecat_backfill_run'));
    expect(source, contains('advance_revenuecat_backfill_run'));
    expect(source, contains('fail_revenuecat_backfill_run'));
    expect(source, contains('pagination cursor did not advance'));
    expect(source, contains('Supabase Auth lookup unavailable'));
    expect(source, contains('if (advanceError)'));
  });

  test(
      'dynamic PostgreSQL claim scenarios are prepared but not remote-executed',
      () {
    final sql =
        File('supabase/tests/revenuecat_sync_concurrency_integration.sql')
            .readAsStringSync();
    expect(sql, contains('first claim did not return claimed'));
    expect(sql, contains('live duplicate was not in_progress'));
    expect(sql, contains('stale lease unexpectedly finalized'));
    expect(sql, contains('separate PostgreSQL sessions'));
  });
}
