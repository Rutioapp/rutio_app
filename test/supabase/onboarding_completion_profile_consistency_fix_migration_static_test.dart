import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260908150000_onboarding_v1_completion_profile_consistency_fix.sql';

  late String sql;
  late String functionBody;
  late String replayBody;

  setUpAll(() {
    sql = File(migrationPath).readAsStringSync();
    final start = sql.indexOf(
      'create or replace function public.complete_onboarding_v1(',
    );
    final end = sql.indexOf(r'$$;', start);
    expect(start, isNonNegative);
    expect(end, greaterThan(start));
    functionBody = sql.substring(start, end);
    final replayStart =
        functionBody.indexOf("if v_existing.status = 'completed'");
    final replayEnd = functionBody.indexOf(
      '  -- Revalidate account classification',
      replayStart,
    );
    expect(replayStart, isNonNegative);
    expect(replayEnd, greaterThan(replayStart));
    replayBody = functionBody.substring(replayStart, replayEnd);
  });

  test('profile completion consistency is explicit on fresh completion', () {
    expect(
      functionBody,
      contains(
        'id, display_name, onboarding_status, onboarding_version,\n'
        '      onboarding_completed, onboarding_completed_at',
      ),
    );
    expect(
      functionBody,
      contains("v_user_id, v_name, 'completed', 1, true, pg_catalog.now()"),
    );
    expect(
      RegExp(r'onboarding_completed\s*=\s*true')
          .allMatches(functionBody)
          .length,
      3,
    );
  });

  test('completed replay repairs only the legacy completion flag', () {
    expect(
      functionBody,
      contains(
        "set onboarding_completed = true\n"
        "    where id = v_user_id\n"
        "      and onboarding_status = 'completed'\n"
        '      and onboarding_completed_at is not null\n'
        '      and onboarding_completed is distinct from true;',
      ),
    );
    expect(functionBody, contains("'status', 'alreadyCompletedSameOperation'"));
    expect(functionBody, contains('on conflict (operation_id) do nothing'));
    expect(replayBody, isNot(contains('insert into public.habits')));
  });

  test('forward migration preserves the deployed RPC contract and SQL fixes',
      () {
    expect(functionBody, isNot(contains('pg_catalog.trim(')));
    expect(functionBody, isNot(contains('pg_catalog.nullif(')));
    expect(
      RegExp(r'pg_catalog\.btrim\(').allMatches(functionBody),
      hasLength(12),
    );
    expect(
      RegExp(r'nullif\(pg_catalog\.btrim\(').allMatches(functionBody),
      hasLength(6),
    );
    expect(functionBody, contains('returns jsonb'));
    expect(functionBody, contains('security definer'));
    expect(functionBody, contains("set search_path = ''"));
    expect(functionBody, contains('v_user_id uuid := auth.uid()'));
    expect(
      sql,
      contains(
        'alter function public.complete_onboarding_v1(uuid, text, text, jsonb, jsonb, jsonb)',
      ),
    );
    expect(
        sql, contains('revoke all on function public.complete_onboarding_v1'));
    expect(sql,
        contains('grant execute on function public.complete_onboarding_v1'));
  });
}
