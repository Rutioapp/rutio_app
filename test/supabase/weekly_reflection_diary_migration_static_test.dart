import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weekly reflection migration is additive and owner-safe', () {
    final sql = File(
            'supabase/migrations/20260903100000_weekly_reflection_diary_link.sql')
        .readAsStringSync()
        .toLowerCase();
    expect(sql, contains('add column if not exists weekly_report_id uuid'));
    expect(sql, contains('on delete set null'));
    expect(sql, contains('idx_diary_entries_one_weekly_reflection'));
    expect(sql, contains('unique index'));
    expect(sql, contains('r.user_id = new.user_id'));
    expect(sql, contains('security definer'));
    expect(sql, isNot(contains('drop table')));
    expect(sql, isNot(contains('alter table public.weekly_reports')));
  });
}
