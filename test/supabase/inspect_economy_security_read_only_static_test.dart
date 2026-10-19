import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'scripts/staging/inspect_economy_security_read_only.sql',
  ).readAsStringSync().toLowerCase();

  test('uses a single oid type for regclass and regprocedure values', () {
    expect(sql, contains("to_regclass('public.user_wallets')::oid"));
    expect(
        sql,
        contains(
            "to_regprocedure('public.apply_habit_completion_reward(text,uuid,text,text,text)')::oid"));
    expect(sql,
        contains('required_objects(object_kind, object_name, object_oid)'));
  });

  test('handles PUBLIC through ACL grantee zero', () {
    expect(sql, contains('acl.grantee = 0'));
    expect(
        sql,
        contains(
            "aclexplode(coalesce(p.proacl, acldefault('f', p.proowner)))"));
    expect(
        sql,
        contains(
            "aclexplode(coalesce(c.relacl, acldefault('r', c.relowner)))"));
    expect(sql, isNot(contains("has_function_privilege('public'")));
    expect(sql, isNot(contains("has_table_privilege('public'")));
  });

  test('remains read-only and preserves six inspection blocks', () {
    final blockHeaders = sql
        .split('\n')
        .where((line) =>
            RegExp(r'^-- [1-6]').hasMatch(line.trim()) &&
            line.trim().contains(')'))
        .length;
    expect(blockHeaders, 6);
    final executableLines = sql
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => !line.startsWith('--'))
        .where((line) => !line.startsWith('/*'))
        .where((line) => !line.startsWith('*'))
        .where((line) => !line.startsWith('*/'));
    for (final forbidden in <String>[
      'set role',
      'grant ',
      'revoke ',
      'insert into',
      'update ',
      'delete ',
      'truncate ',
      'drop ',
    ]) {
      expect(executableLines.any((line) => line.startsWith(forbidden)), isFalse,
          reason: 'found forbidden statement: $forbidden');
    }
  });
}
