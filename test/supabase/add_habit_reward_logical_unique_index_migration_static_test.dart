import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260727203000_add_habit_reward_logical_unique_index.sql';
  const indexName =
      'idx_habit_currency_reward_ledger_user_op_habit_date_unique';

  late String sql;
  late String normalized;

  setUpAll(() {
    sql = File(migrationPath).readAsStringSync();
    normalized = sql.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  });

  test('creates only the exact logical unique index transactionally', () {
    expect(normalized, startsWith('begin;'));
    expect(normalized.trimRight(), endsWith('commit;'));
    expect(
      normalized,
      contains(
        'create unique index $indexName on public.habit_currency_reward_ledger ( user_id, operation_type, habit_id, logical_date_key )',
      ),
    );
  });

  test('uses the exact index name, table, and column order', () {
    final indexPattern = RegExp(
      r'create\s+unique\s+index\s+idx_habit_currency_reward_ledger_user_op_habit_date_unique\s+'
      r'on\s+public\.habit_currency_reward_ledger\s*'
      r'\(\s*user_id\s*,\s*operation_type\s*,\s*habit_id\s*,\s*logical_date_key\s*\)',
      caseSensitive: false,
    );

    expect(indexPattern.hasMatch(sql), isTrue);
    expect(RegExp(r'\bcreate\s+unique\s+index\b', caseSensitive: false)
        .allMatches(sql), hasLength(1));
    expect(RegExp(indexName, caseSensitive: false).allMatches(sql), hasLength(1));
  });

  test('does not use optional or non-atomic index variants', () {
    expect(normalized, isNot(contains('concurrently')));
    expect(normalized, isNot(contains('if not exists')));
    expect(normalized, isNot(contains(' where ')));
  });

  test('does not alter schema beyond the single index', () {
    expect(normalized, isNot(contains('alter table')));
    expect(normalized, isNot(contains('add constraint')));
    expect(normalized, isNot(contains('add column')));
    expect(normalized, isNot(contains('drop index')));
    expect(normalized, isNot(contains('drop constraint')));
  });

  test('does not perform DML or modify economic RPCs', () {
    for (final forbidden in <String>[
      'insert into',
      'update ',
      'delete from',
      'create or replace function',
      'apply_habit_completion_reward',
      'reverse_habit_completion_reward',
      'record_habit_log',
      'grant_user_reward',
      'user_wallets',
      'user_progress',
      'xp_events',
      'currency_events',
    ]) {
      expect(normalized, isNot(contains(forbidden)));
    }
  });

  test('does not include Flutter code in the migration', () {
    for (final forbidden in <String>[
      '.dart',
      'flutter',
      'generatedpluginregistrant',
      'generated_plugin_registrant',
      'lib/',
      'android/',
      'ios/',
      'linux/',
      'macos/',
      'windows/',
      'web/',
    ]) {
      expect(normalized, isNot(contains(forbidden)));
    }
  });
}
