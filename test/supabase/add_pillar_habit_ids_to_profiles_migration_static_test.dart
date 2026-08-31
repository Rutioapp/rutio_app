import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260830090000_add_pillar_habit_ids_to_profiles.sql';

  late String sql;
  late String normalized;

  setUpAll(() {
    sql = File(migrationPath).readAsStringSync();
    normalized = sql.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  });

  test('keeps the pillar habit column nullable-safe and bounded', () {
    expect(normalized, contains('add column if not exists pillar_habit_ids uuid[]'));
    expect(
      normalized,
      contains("set pillar_habit_ids = coalesce(pillar_habit_ids, '{}'::uuid[])"),
    );
    expect(
      normalized,
      contains("alter column pillar_habit_ids set default '{}'::uuid[]"),
    );
    expect(normalized, contains('alter column pillar_habit_ids set not null'));
    expect(
      normalized,
      contains(
        'add constraint profiles_pillar_habit_ids_limit_check check (cardinality(pillar_habit_ids) <= 3)',
      ),
    );
    expect(normalized, contains('comment on column public.profiles.pillar_habit_ids'));
  });

  test('adds backend ownership validation for pillar habit ids', () {
    expect(normalized, contains('create schema if not exists app_private'));
    expect(
      normalized,
      contains(
        'create or replace function app_private.validate_profile_pillar_habit_ids()',
      ),
    );
    expect(normalized, contains('returns trigger'));
    expect(normalized, contains('security definer'));
    expect(normalized, contains("set search_path = ''"));
    expect(
      normalized,
      contains(
        'before insert or update of pillar_habit_ids on public.profiles',
      ),
    );
    expect(normalized, contains("coalesce(new.pillar_habit_ids, '{}'::uuid[])"));
    expect(normalized, contains('pillar habits must not contain null values'));
    expect(normalized, contains('count(distinct habit_id)'));
    expect(normalized, contains('pillar habits may contain at most 3 items'));
    expect(normalized, contains('pillar habits must be unique'));
    expect(normalized, contains('from public.habits as habit'));
    expect(normalized, contains('habit.user_id = new.id'));
    expect(normalized, contains('alter function app_private.validate_profile_pillar_habit_ids() owner to postgres'));
    expect(normalized, contains('revoke all on function app_private.validate_profile_pillar_habit_ids()'));
  });

  test('keeps the migration non-destructive and committed', () {
    expect(normalized, startsWith('begin;'));
    expect(normalized.trimRight(), endsWith('commit;'));
    expect(normalized, isNot(contains('delete from public.profiles')));
    expect(normalized, isNot(contains('drop table public.profiles')));
    expect(normalized, isNot(contains('drop column pillar_habit_ids')));
  });
}
