import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'SQL expression fix migration hardens every function expression',
    () {
      final migration = File(
        'supabase/migrations/20260908140000_onboarding_v1_completion_sql_expression_fix.sql',
      ).readAsStringSync();
      final functionStart = migration.indexOf(
        'create or replace function public.complete_onboarding_v1(',
      );
      final functionEnd = migration.indexOf(r'$$;', functionStart);

      expect(functionStart, greaterThanOrEqualTo(0));
      expect(functionEnd, greaterThan(functionStart));

      final functionBody = migration.substring(functionStart, functionEnd);

      expect(functionBody, isNot(contains('pg_catalog.trim(')));
      expect(functionBody, isNot(contains('pg_catalog.nullif(')));
      expect(functionBody, isNot(contains('pg_catalog.coalesce(')));
      expect(functionBody, isNot(contains('pg_catalog.greatest(')));
      expect(functionBody, isNot(contains('pg_catalog.least(')));
      expect(functionBody, contains('pg_catalog.btrim('));
      expect(functionBody, contains('nullif(pg_catalog.btrim('));
      expect(functionBody, contains("''::text"));
      expect(
        RegExp(r'pg_catalog\.btrim\(').allMatches(functionBody),
        hasLength(12),
      );
      expect(
        RegExp(r'nullif\(pg_catalog\.btrim\(').allMatches(functionBody),
        hasLength(6),
      );
      expect(
        RegExp(r'pg_catalog\.jsonb_build_object\(').allMatches(functionBody),
        hasLength(5),
      );
      expect(
        functionBody,
        contains(
          "'family_id', nullif(pg_catalog.btrim(p_prepared_habit->>'family_id'), ''::text),\n"
          "      'emoji', nullif(pg_catalog.btrim(p_prepared_habit->>'emoji'), ''::text),",
        ),
      );

      for (final validQualifiedFunction in <String>[
        'pg_catalog.lower(',
        'pg_catalog.jsonb_typeof(',
        'pg_catalog.jsonb_build_object(',
        'pg_catalog.md5(',
        'pg_catalog.lpad(',
        'pg_catalog.char_length(',
        'pg_catalog.now(',
      ]) {
        expect(functionBody, contains(validQualifiedFunction));
      }

      expect(
        functionBody,
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
      expect(functionBody, contains('returns jsonb'));
      expect(functionBody, contains('security definer'));
      expect(functionBody, contains("set search_path = ''"));
      expect(functionBody, contains('auth.uid()'));

      expect(migration, contains('revoke all on function'));
      expect(
        migration,
        contains(
          'grant execute on function public.complete_onboarding_v1('
          'uuid, text, text, jsonb, jsonb, jsonb)\n'
          '  to authenticated',
        ),
      );
    },
  );
}
