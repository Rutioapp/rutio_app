import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _normalized(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

void main() {
  const migrationPath =
      'supabase/migrations/20261012120000_revoke_user_progress_client_writes.sql';

  late String migration;

  setUpAll(() {
    migration = _normalized(File(migrationPath).readAsStringSync());
  });

  test('revokes client DML on user_progress', () {
    expect(
      migration,
      contains(
        'revoke insert, update, delete on table public.user_progress from public, anon, authenticated',
      ),
    );
  });

  test('removes write policies but preserves the select policy contract', () {
    expect(
      migration,
      contains('drop policy if exists user_progress_insert_own on public.user_progress'),
    );
    expect(
      migration,
      contains('drop policy if exists user_progress_update_own on public.user_progress'),
    );
    expect(
      migration,
      contains('drop policy if exists user_progress_delete_own on public.user_progress'),
    );
    expect(migration, contains('select policy remains unchanged'));
  });

  test('does not alter balances or replace reward RPCs', () {
    expect(migration, isNot(contains('update public.user_progress')));
    expect(migration, isNot(contains('update public.user_wallets')));
    expect(migration, isNot(contains('insert into public.user_wallets')));
    expect(migration, isNot(contains('create or replace function')));
    expect(migration, isNot(contains('claim_level_reward')));
  });
}
