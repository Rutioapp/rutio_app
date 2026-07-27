import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260727190000_revoke_direct_execution_from_legacy_grant_user_reward.sql';

  late String sql;
  late String normalized;

  setUpAll(() {
    sql = File(migrationPath).readAsStringSync();
    normalized = sql.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  });

  test('targets the exact legacy grant_user_reward signature', () {
    expect(
      normalized,
      contains(
        'on function public.grant_user_reward(integer, integer, text, uuid, text)',
      ),
    );
  });

  test('revokes direct execution from client roles and PUBLIC', () {
    expect(
      normalized,
      contains(
        'revoke execute on function public.grant_user_reward(integer, integer, text, uuid, text) from public',
      ),
    );
    expect(
      normalized,
      contains(
        'revoke execute on function public.grant_user_reward(integer, integer, text, uuid, text) from anon',
      ),
    );
    expect(
      normalized,
      contains(
        'revoke execute on function public.grant_user_reward(integer, integer, text, uuid, text) from authenticated',
      ),
    );
  });

  test('keeps only service_role as an explicit non-owner grant', () {
    final grantExecuteMatches = RegExp(
      r'grant\s+execute\s+on\s+function\s+public\.grant_user_reward\(integer,\s*integer,\s*text,\s*uuid,\s*text\)\s+to\s+([a-z_]+)',
    ).allMatches(normalized).toList(growable: false);

    expect(grantExecuteMatches, hasLength(1));
    expect(grantExecuteMatches.single.group(1), 'service_role');
  });

  test('does not replace functions or touch economy data', () {
    expect(normalized, isNot(contains('create or replace function')));
    expect(normalized, isNot(contains('drop function')));
    expect(normalized, isNot(contains('update public.user_progress')));
    expect(normalized, isNot(contains('update public.user_wallets')));
    expect(normalized, isNot(contains('ambar_balance')));
  });

  test('does not modify unrelated reward RPCs', () {
    expect(normalized, isNot(contains('record_habit_log')));
    expect(normalized, isNot(contains('apply_habit_completion_reward')));
    expect(normalized, isNot(contains('reverse_habit_completion_reward')));
  });
}
