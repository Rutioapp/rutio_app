import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260908130000_onboarding_v1_completion_trim_fix.sql';

  late String sql;
  late String functionBody;

  setUpAll(() {
    sql = File(migrationPath).readAsStringSync();
    final start = sql.indexOf(
      'create or replace function public.complete_onboarding_v1(',
    );
    final end = sql.indexOf(r'$$;', start);
    expect(start, isNonNegative);
    expect(end, isNonNegative);
    functionBody = sql.substring(start, end);
  });

  test('forward migration replaces every invalid trim call', () {
    expect(functionBody, isNot(contains('pg_catalog.trim(')));
    expect(
      RegExp(r'pg_catalog\.btrim\(').allMatches(functionBody).length,
      12,
    );
  });

  test('preserves AUTH-3 function security and signature', () {
    expect(
      sql,
      contains(
        'create or replace function public.complete_onboarding_v1(\n'
        '  p_operation_id uuid,\n'
        '  p_account_resolution text,\n'
        '  p_prepared_habit_decision text,\n'
        '  p_profile jsonb default \'{}\'::jsonb,\n'
        '  p_prepared_habit jsonb default null,\n'
        '  p_reminder jsonb default null',
      ),
    );
    expect(sql, contains('security definer'));
    expect(sql, contains("set search_path = ''"));
    expect(sql, contains('v_user_id uuid := auth.uid()'));
    expect(sql,
        contains('grant execute on function public.complete_onboarding_v1'));
    expect(sql, contains('to authenticated'));
    expect(
        sql, contains('revoke all on function public.complete_onboarding_v1'));
  });
}
