import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _normalized(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

void main() {
  const migrationPath =
      'supabase/migrations/20261012130000_harden_analytics_view_exposure.sql';

  late String migration;

  setUpAll(() {
    migration = _normalized(File(migrationPath).readAsStringSync());
  });

  test('targets all internal analytics and rollout views', () {
    for (final name in <String>[
      'analytics_total_users',
      'analytics_new_users_by_day',
      'analytics_daily_active_users',
      'analytics_habits_created_by_day',
      'analytics_habit_logs_completed_by_day',
      'analytics_journal_entries_by_day',
      'analytics_achievement_unlocks_by_day',
      'analytics_xp_generated_by_day',
      'analytics_ambar_by_day',
      'analytics_daily_summary',
      'analytics_economic_movements',
      'global_cloud_economy_rollout_status',
    ]) {
      expect(migration, contains("'$name'"));
    }
  });

  test('removes client access and preserves service_role administration', () {
    expect(
      migration,
      contains(
        'revoke all on table %i.%i from public, anon, authenticated',
      ),
    );
    expect(
      migration,
      contains('grant select on table %i.%i to service_role'),
    );
    expect(migration, contains('to_regclass'));
    expect(migration, isNot(contains('security_invoker =')));
    expect(migration, isNot(contains('with (security_invoker')));
  });

  test('does not redefine views or touch economic data', () {
    expect(migration, isNot(contains('create or replace view')));
    expect(migration, isNot(contains('update public.')));
    expect(migration, isNot(contains('insert into public.')));
    expect(migration, isNot(contains('delete from public.')));
  });

  test('no migration grants client SELECT on internal views', () {
    final migrationFiles = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.sql'))
        .where((file) =>
            file.uri.pathSegments.last.compareTo(migrationPath.split('/').last) >
            0);

    for (final file in migrationFiles) {
      final sql = _normalized(file.readAsStringSync());
      expect(sql, isNot(matches(RegExp(
        r'grant\s+select[^;]*analytics_[a-z0-9_]+[^;]*\s+to\s+(anon|authenticated)',
      ))));
      expect(sql, isNot(matches(RegExp(
        r'grant\s+select[^;]*global_cloud_economy_rollout_status[^;]*\s+to\s+authenticated',
      ))));
    }
  });
}
