import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260727183000_bootstrap_user_wallets_for_existing_and_new_auth_users.sql';

  late String sql;
  late String normalized;

  setUpAll(() {
    sql = File(migrationPath).readAsStringSync();
    normalized = sql.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  });

  test('creates a private hardened auth.users wallet bootstrap trigger', () {
    expect(normalized, contains('create schema if not exists app_private'));
    expect(
      normalized,
      contains(
        'create or replace function app_private.bootstrap_user_wallet_on_auth_insert()',
      ),
    );
    expect(normalized, contains('returns trigger'));
    expect(normalized, contains('security definer'));
    expect(normalized, contains("set search_path = ''"));
    expect(
      normalized,
      contains(
        'drop trigger if exists trg_auth_users_bootstrap_user_wallet on auth.users',
      ),
    );
    expect(
      normalized,
      contains(
        'create trigger trg_auth_users_bootstrap_user_wallet after insert on auth.users for each row execute function app_private.bootstrap_user_wallet_on_auth_insert()',
      ),
    );
  });

  test('bootstraps wallets from auth.users without using legacy balances', () {
    expect(
      normalized,
      contains(
        'insert into public.user_wallets ( user_id, coins, version ) values ( new.id, 0, 0 ) on conflict (user_id) do nothing',
      ),
    );
    expect(
      normalized,
      contains(
        'insert into public.user_wallets ( user_id, coins, version ) select auth_user.id, 0, 0 from auth.users as auth_user on conflict (user_id) do nothing',
      ),
    );
    expect(normalized, isNot(contains('user_progress')));
    expect(normalized, isNot(contains('ambar_balance')));
  });

  test('keeps client roles from writing wallets or executing the trigger function', () {
    expect(
      normalized,
      contains(
        'revoke execute on function app_private.bootstrap_user_wallet_on_auth_insert() from public',
      ),
    );
    expect(
      normalized,
      contains(
        'revoke execute on function app_private.bootstrap_user_wallet_on_auth_insert() from anon',
      ),
    );
    expect(
      normalized,
      contains(
        'revoke execute on function app_private.bootstrap_user_wallet_on_auth_insert() from authenticated',
      ),
    );
    expect(normalized, isNot(contains('grant insert on public.user_wallets')));
    expect(normalized, isNot(contains('grant update on public.user_wallets')));
    expect(
      normalized,
      isNot(contains('grant all on public.user_wallets')),
    );
  });

  test('does not touch habit reward RPCs or legacy economy functions', () {
    expect(normalized, isNot(contains('apply_habit_completion_reward')));
    expect(normalized, isNot(contains('record_habit_log')));
    expect(normalized, isNot(contains('grant_user_reward')));
    expect(normalized, isNot(contains('create or replace function public.')));
    expect(normalized, isNot(contains('update public.user_wallets')));
    expect(normalized, isNot(contains('set coins')));
    expect(normalized, isNot(contains('set version')));
  });
}
