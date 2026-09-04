import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weekly report has no visible debug controls', () {
    final source = File(
      'lib/features/weekly_report/presentation/screens/weekly_report_screen.dart',
    ).readAsStringSync();
    expect(source, contains('WeeklyReportReflection('));
    expect(source, contains('if (report.isFinal)'));
    expect(source, isNot(contains('Debug')));
    expect(source, isNot(contains('debug')));
    expect(source, isNot(contains('Preview')));
    expect(source, isNot(contains('WeeklyReportDebugAction')));
    expect(source, isNot(contains("status = 'final'")));
  });

  test('productive reflection keeps its save and edit flow', () {
    final source = File(
      'lib/features/weekly_report/presentation/widgets/weekly_report_reflection.dart',
    ).readAsStringSync();
    expect(source, contains('WeeklyReportReflection'));
    expect(source, contains('weeklyReflectionSave'));
    expect(source, contains('weeklyReflectionEdit'));
    expect(source, isNot(contains('Debug')));
    expect(source, isNot(contains('debug')));
  });
}
