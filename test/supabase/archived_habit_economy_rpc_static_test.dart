import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20261019103000_allow_legitimate_archived_habit_reversal.sql',
  ).readAsStringSync().toLowerCase();

  test('rejects new completion but permits the reversal path for archives', () {
    expect(migration,
        contains('coalesce(v_habit.is_archived, false) and p_is_completed'));
    expect(migration, contains("raise exception 'habit is archived'"));
    expect(
        migration,
        contains(
            'if not p_is_completed and (not found or not v_log.is_completed)'));
    expect(migration, contains('public.reverse_habit_completion_reward'));
  });
}
