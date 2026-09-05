import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/completed_day_phrase/generate_es_release_sql.dart';

void main() {
  test('SQL VALUES helper only comma-separates non-final rows', () {
    expect(joinSqlValues(<String>['(1)', '(2)', '(3)']), '(1),\n(2),\n(3)');
    expect(joinSqlValues(<String>['(1)']), '(1)');
    expect(joinSqlValues(<String>['(1)', '(2)']).split('\n').last, '(2)');
  });

  test('generated multi-row INSERT blocks have no trailing final comma', () {
    final sql = File(
      'supabase/seeds/completed_day_phrase_es_es_v1.sql',
    ).readAsStringSync();
    final block = RegExp(
      r'insert into _completed_day_phrase_expected \([\s\S]*?\) values\n'
      r'([\s\S]*?)\n;',
      caseSensitive: false,
    ).firstMatch(sql);
    expect(block, isNotNull);
    final rows = block!
        .group(1)!
        .trimRight()
        .split('\n')
        .where((line) => line.trimLeft().startsWith('('))
        .toList(growable: false);
    expect(rows, hasLength(300));
    expect(rows.last.trimRight().endsWith(','), isFalse);
    expect(
      rows.take(rows.length - 1).every(
            (row) => row.trimRight().endsWith(','),
          ),
      isTrue,
    );
  });
}
