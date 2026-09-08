import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260908100000_onboarding_v1_idempotent_completion.sql',
  );
  final manualValidation = File(
    'supabase/manual_checks/onboarding_v1_auth_completion_validation.sql',
  );

  test('AUTH-3 migration exposes only auth.uid-owned completion RPC', () {
    final sql = migration.readAsStringSync();
    expect(
        sql,
        contains(
            'create table if not exists app_private.onboarding_completion_operations'));
    expect(sql,
        contains('create or replace function public.complete_onboarding_v1('));
    expect(sql, contains('v_user_id uuid := auth.uid()'));
    expect(sql, contains('set search_path = \'\''));
    expect(sql,
        contains('grant execute on function public.complete_onboarding_v1'));
    expect(sql, contains('to authenticated'));
    expect(sql, contains('on conflict (operation_id) do nothing'));
    expect(sql, contains('alreadyCompletedSameOperation'));
    expect(sql, contains('operation_conflict'));
    expect(sql, contains('md5(v_payload::text)'));
    expect(sql, contains('preparedHabitApplied'));
    expect(sql, contains('return v_result'));
    expect(
        sql, contains('get diagnostics v_inserted_profile_count = row_count'));
    expect(sql, contains('status = \'completed\''));
    expect(
        sql,
        contains(
            'revoke all on table app_private.onboarding_completion_operations'));
    expect(sql, contains("v_client_resolution = 'newaccount'"));
    expect(sql, contains("v_decision = 'keep'"));
    expect(sql, contains("v_decision not in ('keep', 'discard')"));
    expect(sql, isNot(contains('p_user_id')));
    expect(sql, isNot(contains('p_password')));
    expect(sql, isNot(contains('p_access_token')));
  });

  test('manual validation script is explicit and never auto-runs', () {
    final sql = manualValidation.readAsStringSync();
    expect(sql, startsWith('-- MANUAL VALIDATION ONLY'));
    expect(sql, contains('-- DO NOT RUN BLINDLY'));
    expect(sql, contains('<QA_USER_UUID>'));
    expect(sql, contains('set local request.jwt.claim.sub'));
    expect(sql, contains('complete_onboarding_v1'));
    expect(sql, contains('ROLLBACK'));
  });
}
