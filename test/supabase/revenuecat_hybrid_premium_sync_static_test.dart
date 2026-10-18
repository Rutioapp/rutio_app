import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hybrid D migration is posterior to stage C and does not alter old stages', () {
    final sql = File(
      'supabase/migrations/20261013110000_revenuecat_hybrid_premium_sync.sql',
    ).readAsStringSync();
    expect(sql, contains('revenuecat_premium_sync_queue'));
    expect(sql, contains('revenuecat_premium_subscription_state'));
    expect(sql, contains('enqueue_revenuecat_premium_sync'));
    expect(sql, contains('claim_revenuecat_premium_sync'));
    expect(sql, contains('apply_revenuecat_v2_reconciliation'));
    expect(sql, contains('complete_revenuecat_premium_sync'));
    expect(sql, contains("set search_path = ''"));
    expect(sql, contains('grant execute'));
    expect(sql, contains('to service_role'));
    expect(sql, contains('greatest('));
    expect(sql, contains('reconciliation_blocked'));
    expect(sql, contains('provisional_until'));
    expect(sql, contains('power(2::numeric'));
    expect(sql, isNot(contains('drop table')));
    expect(sql, isNot(contains('truncate')));
    expect(File('supabase/migrations/20261013100000_revenuecat_temporal_precedence_hardening.sql').existsSync(), false);
    expect(File('supabase/migrations_rejected/20261013100000_revenuecat_temporal_precedence_hardening.sql.rejected').existsSync(), true);
  });

  test('webhook never traverses v2 and reconciler requires an explicit allowlisted identity', () {
    final webhook = File('supabase/functions/revenuecat-webhook/index.ts')
        .readAsStringSync();
    final reconcile = File('supabase/functions/revenuecat-reconcile/index.ts')
        .readAsStringSync();
    expect(webhook, contains('enqueue_revenuecat_premium_sync'));
    expect(webhook, contains('apply_revenuecat_positive_event'));
    expect(webhook, isNot(contains('/v2/projects/')));
    expect(reconcile, contains('user_id'));
    expect(reconcile, contains('REVENUECAT_ALLOWED_USER_IDS'));
    expect(reconcile, contains(r'environment=${environment.toLowerCase()}'));
    expect(reconcile, contains('page >= 20'));
    expect(reconcile, contains('fetchNestedItems'));
    expect(reconcile, contains('completeNestedSubscription'));
    expect(reconcile, contains('p_read_complete: true'));
  });

  test('reconcile diagnostics are Sandbox-only and structural', () {
    final reconcile = File('supabase/functions/revenuecat-reconcile/index.ts')
        .readAsStringSync();
    final diagnostics = File(
      'supabase/functions/revenuecat-reconcile/diagnostics.ts',
    ).readAsStringSync();
    expect(reconcile, contains("environment === 'SANDBOX'"));
    expect(reconcile, contains('premiumProductsShape(rawProducts)'));
    expect(diagnostics, contains('productsType'));
    expect(diagnostics, contains('productsIsNull'));
    expect(diagnostics, contains('productsIsArray'));
    expect(diagnostics, contains('hasItems'));
    expect(diagnostics, contains('itemsIsArray'));
    expect(diagnostics, contains('itemsLength'));
    expect(diagnostics, isNot(contains('JSON.stringify')));
    expect(reconcile, isNot(contains('console.warn(rawProducts')));
  });
}
