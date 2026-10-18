import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _normalized(String value) =>
    value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').toLowerCase();

void main() {
  test('logical deletion migration revokes physical client deletes', () {
    final migration = _normalized(
      File('scripts/staging/bootstrap/04c_habit_logical_delete.sql')
          .readAsStringSync(),
    );

    expect(
      migration,
      contains(
        'revoke delete on table public.habits from public, anon, authenticated',
      ),
    );
    expect(migration, isNot(contains('delete from public.habits')));
    expect(migration, contains('begin;'));
    expect(migration, contains('commit;'));
  });

  test('Flutter deletion archives and preserves local history', () {
    final repository = _normalized(
      File('lib/data/repositories/habit_repository.dart').readAsStringSync(),
    );
    final sync = _normalized(
      File('lib/data/services/habit_sync_service.dart').readAsStringSync(),
    );
    final store = _normalized(
      File('lib/stores/user_state_store_habits.dart').readAsStringSync(),
    );

    expect(repository, contains("'is_archived': true"));
    expect(repository, isNot(contains('.delete()')));
    expect(sync, contains('synchabitarchived('));
    expect(sync, contains("'is_archived': true"));
    expect(store, contains('logical deletion must never purge local activity'));
  });
}
