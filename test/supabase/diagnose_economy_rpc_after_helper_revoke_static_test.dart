import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'scripts/staging/diagnose_economy_rpc_after_helper_revoke_read_only.sql',
  ).readAsStringSync().toLowerCase();

  test('inspects the exact RPC chain and owners', () {
    expect(sql, contains('pg_get_functiondef(p.oid)'));
    expect(sql, contains('p.prosecdef'));
    expect(sql, contains('p.proconfig'));
    expect(sql, contains("to_regprocedure('public.complete_habit_economy_v1(text,uuid,date,boolean,integer,text,text)')::oid"));
    expect(sql, contains("to_regprocedure('public.apply_habit_completion_reward(text,uuid,text,text,text)')::oid"));
    expect(sql, contains("to_regprocedure('public.reverse_habit_completion_reward(text,uuid,text,text,text)')::oid"));
  });

  test('checks PUBLIC through ACL grantee zero and keeps role checks effective', () {
    expect(sql, contains('x.grantee = 0'));
    expect(sql, contains("has_function_privilege('authenticated', p.oid, 'execute')"));
    expect(sql, contains("has_function_privilege('anon', p.oid, 'execute')"));
    expect(sql, contains("has_function_privilege('service_role', p.oid, 'execute')"));
    expect(sql, contains("aclexplode(coalesce(p.proacl, acldefault('f', p.proowner)))"));
    expect(sql, isNot(contains("has_function_privilege('public'")));
  });

  test('is read-only and reports partial or absent operation state', () {
    expect(sql, contains('interpretation'));
    expect(sql, contains('object_status'));
    expect(sql, isNot(contains('set role')));
    for (final forbidden in <String>[
      'insert into',
      'update ',
      'delete ',
      'grant ',
      'revoke ',
      'truncate ',
      'drop ',
    ]) {
      expect(sql, isNot(contains(forbidden)));
    }
  });
}
