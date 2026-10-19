import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('transient reconcile failures return the queue item to pending', () {
    final sql = File(
      'supabase/migrations/20261016100000_revenuecat_hybrid_premium_sync_retry_fix.sql',
    ).readAsStringSync();

    expect(sql, contains("when p_success then false"));
    expect(sql, contains("when left(coalesce(p_error_code, ''), 10) = 'PERMANENT:' then false"));
    expect(sql, contains('else true'));
    expect(sql, contains('and lease_token = p_lease_token'));
    expect(sql, contains('security definer set search_path = \'\''));
    expect(sql, contains('grant execute on function public.complete_revenuecat_premium_sync'));
  });
}
