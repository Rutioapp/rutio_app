import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260727213017_enforce_remote_onboarding_transitions.sql';

  late String sql;
  late String normalized;

  setUpAll(() {
    sql = File(migrationPath).readAsStringSync();
    normalized = sql.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  });

  test('creates the private onboarding transition trigger function', () {
    expect(
      normalized,
      contains(
        'create function app_private.enforce_profile_onboarding_transition()',
      ),
    );
    expect(normalized, isNot(contains('create schema if not exists')));
    expect(normalized, isNot(contains('create or replace function')));
    expect(normalized, contains('returns trigger'));
    expect(normalized, contains('security definer'));
    expect(normalized, contains("set search_path = ''"));
  });

  test('creates a before update trigger on public.profiles onboarding columns',
      () {
    expect(normalized, isNot(contains('drop trigger if exists')));
    expect(
      normalized,
      contains(
        'create trigger trg_profiles_enforce_onboarding_transition before update of onboarding_status, onboarding_version, onboarding_completed_at on public.profiles for each row execute function app_private.enforce_profile_onboarding_transition()',
      ),
    );
  });

  test('keeps pending to pending idempotent', () {
    expect(
      normalized,
      contains(
        "if old.onboarding_status = 'pending' and new.onboarding_status in ('pending', 'in_progress') then new.onboarding_completed_at := null; return new",
      ),
    );
  });

  test('uses PostgreSQL statement_timestamp for first completion', () {
    expect(normalized,
        contains('new.onboarding_completed_at := statement_timestamp()'));
    expect(normalized, isNot(contains('now()')));
  });

  test('blocks regressions and arbitrary version changes', () {
    expect(
      normalized,
      contains(
        'if new.onboarding_version is distinct from old.onboarding_version then raise exception',
      ),
    );
    expect(
      normalized,
      contains(
        "if old.onboarding_status = 'in_progress' and new.onboarding_status = 'pending' then raise exception 'invalid onboarding transition: in_progress to pending'",
      ),
    );
    expect(
      normalized,
      contains(
        "if old.onboarding_status = 'completed' and new.onboarding_status in ('pending', 'in_progress') then raise exception 'invalid onboarding transition: completed to %'",
      ),
    );
  });

  test('preserves completed timestamp and version idempotently', () {
    expect(
      normalized,
      contains(
        "if old.onboarding_status = 'completed' and new.onboarding_status = 'completed' then new.onboarding_completed_at := old.onboarding_completed_at; new.onboarding_version := old.onboarding_version; return new",
      ),
    );
  });

  test('does not grant direct execute to authenticated clients', () {
    expect(
      normalized,
      contains(
        'revoke execute on function app_private.enforce_profile_onboarding_transition() from authenticated',
      ),
    );
    expect(normalized, isNot(contains('grant execute')));
  });
}
