import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260901110000_weekly_report_history_sync.sql',
  ).readAsStringSync().toLowerCase();
  final baselineSchema = File(
    'supabase/sql/supabase_backend_phase_9_schema_patch.sql',
  ).readAsStringSync().toLowerCase();

  test('persists explicit skip state and retains logical activity identity',
      () {
    expect(migration, contains('add column if not exists is_skipped boolean'));
    expect(migration, contains("confrelid = 'public.habits'::regclass"));
    expect(migration, contains('drop constraint'));
    expect(migration, contains('idx_habit_logs_user_habit_date'));
    expect(migration, contains('user_id'));
    expect(baselineSchema, contains('auth.uid() = user_id'));
    expect(migration, contains('revoke all on public.habit_logs from anon'));
    expect(
      migration,
      isNot(contains('habit_id uuid not null references public.habits')),
    );
  });

  test('uses validated local effective metadata in config capture', () {
    expect(migration, contains('new.effective_from'));
    expect(migration, contains('new.effective_timezone_name'));
    expect(migration, contains('new.source_mutation_id'));
    expect(migration, contains("interval '5 minutes'"));
    expect(migration,
        contains('on conflict (user_id, habit_id, source_mutation_id)'));
    expect(migration, contains('statement_timestamp()'));
    expect(migration, contains('source_mutation_id text'));
    expect(migration, contains('effective_from timestamptz'));
    expect(migration, contains('effective_timezone_name text'));
  });
}
