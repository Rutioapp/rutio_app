import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20261019100000_revoke_direct_habit_reward_helper_execution.sql',
  ).readAsStringSync().toLowerCase();

  test('keeps habit reward helpers internal', () {
    expect(migration, contains('revoke all on function'));
    expect(
        migration, contains('from public, anon, authenticated, service_role'));
    expect(migration, contains('apply_habit_completion_reward'));
    expect(migration, contains('reverse_habit_completion_reward'));
    expect(migration, isNot(contains('grant execute')));
  });
}
