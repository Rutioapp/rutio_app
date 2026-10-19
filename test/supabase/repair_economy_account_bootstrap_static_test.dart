import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/20261019120000_repair_economy_account_bootstrap.sql',
  ).readAsStringSync().toLowerCase();

  test('uses a server-owned SECURITY DEFINER with an empty search path', () {
    expect(sql, contains('security definer'));
    expect(sql, contains("set search_path = ''"));
    expect(sql, contains('alter function app_private.bootstrap_user_wallet_on_auth_insert()'));
    expect(sql, contains('owner to postgres'));
  });

  test('is idempotent and preserves existing wallet state', () {
    expect(sql, contains('on conflict (user_id) do nothing'));
    expect(sql, contains('where not exists'));
    expect(sql, contains('values (new.id, 0, 0)'));
    expect(sql, contains('select u.id, 0, 0'));
  });

  test('installs only the named auth trigger and closes direct execution', () {
    expect(sql, contains('drop trigger if exists trg_auth_users_bootstrap_user_wallet on auth.users'));
    expect(sql, contains('create trigger trg_auth_users_bootstrap_user_wallet'));
    expect(sql, contains('from public, anon, authenticated, service_role'));
    expect(sql, isNot(contains('grant execute')));
    expect(sql, isNot(contains('update public.user_wallets')));
    expect(sql, isNot(contains('delete from public.user_wallets')));
  });
}
