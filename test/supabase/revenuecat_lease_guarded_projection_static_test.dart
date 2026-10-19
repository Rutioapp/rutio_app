import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lease-guarded migration is separate and keeps stage B disabled', () {
    final sql = File(
            'supabase/migrations/20261012153000_revenuecat_lease_guarded_projection.sql')
        .readAsStringSync();
    expect(sql, contains('apply_revenuecat_entitlement_for_webhook'));
    expect(sql, contains('apply_revenuecat_entitlement_for_backfill'));
    expect(sql, contains('advance_revenuecat_backfill_run_v2'));
    expect(sql, contains('last_advanced_page_key'));
    expect(sql, contains('last_observed_at'));
    expect(sql, contains('reconciliation_required'));
    expect(sql, contains('claim_revenuecat_reconciliation_batch'));
    expect(sql, contains('apply_revenuecat_reconciliation'));
    expect(sql, contains('fail_revenuecat_reconciliation'));
    expect(sql, contains('processing_lease_until <= clock_timestamp()'));
    expect(sql, contains('p_observed_at < v_existing.last_observed_at'));
    expect(sql, contains('p_observed_at = v_existing.last_observed_at'));
    expect(sql, contains("set search_path = ''"));
    expect(sql, isNot(contains('refresh_my_weekly_report')));
  });

  test('hybrid D keeps webhook signal-only and reconciliation targeted', () {
    final logic = File('supabase/functions/revenuecat-webhook/logic.ts')
        .readAsStringSync();
    final webhook = File('supabase/functions/revenuecat-webhook/index.ts')
        .readAsStringSync();
    final backfill = File('supabase/functions/revenuecat-backfill/index.ts')
        .readAsStringSync();
    expect(webhook, contains('enqueue_revenuecat_premium_sync'));
    expect(webhook, contains('apply_revenuecat_positive_event'));
    expect(webhook, isNot(contains('/v2/projects/')));
    expect(logic, contains('root.request_date_ms'));
    expect(logic, contains('root.request_date'));
    expect(logic, contains('contradictory RevenueCat snapshot time'));
    expect(logic, contains('snapshotReliable'));
    expect(backfill, contains('apply_revenuecat_entitlement_for_backfill'));
    expect(backfill, contains('advance_revenuecat_backfill_run_v2'));
    expect(webhook, contains('length > 8'));
    expect(webhook, contains('classifyTransferIdentities(value)'));
    final reconcile = File('supabase/functions/revenuecat-reconcile/index.ts')
        .readAsStringSync();
    expect(reconcile, contains('claim_revenuecat_premium_sync'));
    expect(reconcile, contains('apply_revenuecat_v2_reconciliation'));
    expect(reconcile, contains('complete_revenuecat_premium_sync'));
    expect(reconcile, contains('user_id'));
    expect(reconcile, contains(r'environment=${environment.toLowerCase()}'));
  });
}
