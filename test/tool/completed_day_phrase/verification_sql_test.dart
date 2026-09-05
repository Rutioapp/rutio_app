import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('verification SQL compares regexp capture values as text', () {
    final verificationFiles = Directory('supabase/tests')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.sql'));

    for (final file in verificationFiles) {
      final sql = file.readAsStringSync();
      if (!sql.contains('regexp_matches')) continue;

      expect(
        sql,
        isNot(contains('m.token <> all')),
        reason: '${file.path} compares the regexp text[] directly.',
      );
      expect(
        sql,
        contains(
            "(m.token)[1] <> all (array['name', 'streak_label', 'progress']::text[])"),
        reason: '${file.path} must validate the captured token value.',
      );
    }
  });
}
