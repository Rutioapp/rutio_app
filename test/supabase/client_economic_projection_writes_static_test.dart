import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20261019110000_revoke_client_economic_projection_writes.sql',
  ).readAsStringSync().toLowerCase();

  test('revokes client DML on both economic state tables', () {
    expect(migration, contains('revoke insert, update, delete'));
    expect(migration, contains('on table public.user_progress'));
    expect(migration, contains('on table public.habit_logs'));
    expect(
        migration, contains('drop policy if exists user_progress_insert_own'));
    expect(migration, contains('drop policy if exists habit_logs_delete_own'));
    expect(migration, isNot(contains('record_habit_log')));
    expect(migration, isNot(contains('revoke select')));
    expect(migration, isNot(contains('grant ')));
  });
}
