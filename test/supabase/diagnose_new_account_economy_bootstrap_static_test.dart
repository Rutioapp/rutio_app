import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'scripts/staging/diagnose_new_account_economy_bootstrap_read_only.sql',
  ).readAsStringSync().toLowerCase();

  test('inspects bootstrap triggers and the account economic state', () {
    expect(sql, contains('pg_get_triggerdef'));
    expect(sql, contains('auth.users'));
    expect(sql, contains('bootstrap_user_wallet_on_auth_insert'));
    expect(sql, contains('auth_users_without_wallet'));
    expect(sql, contains('rpc_requires_wallet'));
    expect(sql, contains('rpc_refreshes_progress'));
  });

  test('is read-only and never calls a remote RPC', () {
    expect(sql, isNot(contains('set role')));
    expect(sql, isNot(contains('perform ')));
    final executableLines = sql
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => !line.startsWith('--'));
    for (final forbidden in <String>[
      'insert into',
      'update ',
      'delete ',
      'grant ',
      'revoke ',
      'truncate ',
      'drop ',
      'set ',
    ]) {
      expect(
        executableLines.any((line) => line.startsWith(forbidden)),
        isFalse,
        reason: 'found forbidden statement: $forbidden',
      );
    }
  });
}
