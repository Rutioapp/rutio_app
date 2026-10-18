import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'RevenueCat response parser uses subscriber.entitlements and fails closed',
      () {
    final source = File('supabase/functions/revenuecat-webhook/logic.ts')
        .readAsStringSync();
    expect(source, contains('const subscriber'));
    expect(source,
        contains('subscriber as Record<string, unknown>).entitlements'));
    expect(source, contains('malformed RevenueCat response'));
    expect(source, contains('Date.parse(expires) > now'));
    expect(source, contains('premium === undefined'));
  });

  test('backfill is server-authorized and resumable', () {
    final source = File('supabase/functions/revenuecat-backfill/index.ts')
        .readAsStringSync();
    expect(source, contains('REVENUECAT_BACKFILL_AUTHORIZATION'));
    expect(source, contains('revenuecat_backfill_runs'));
    expect(source, contains('next_starting_after'));
    expect(source, contains('/v2/projects/'));
    expect(source, contains('getUserById'));
    expect(source, contains('apply_revenuecat_entitlement'));
  });
}
