import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug reflection only bypasses the final visibility gate', () {
    final source = File(
      'lib/features/weekly_report/presentation/screens/weekly_report_screen.dart',
    ).readAsStringSync();
    expect(source, contains('kDebugMode && debugReflection'));
    expect(source, contains('WeeklyReportReflection('));
    expect(
        source, contains('report.isFinal || (kDebugMode && debugReflection)'));
    expect(source, contains('report.isProvisional'));
    expect(source, contains('WeeklyReportDebugAction'));
    expect(source, contains('weeklyReflectionDebugPreview'));
    expect(source, isNot(contains("status = 'final'")));
  });

  test('debug cleanup uses the real Diary delete flow', () {
    final source = File(
      'lib/features/weekly_report/presentation/widgets/weekly_report_reflection.dart',
    ).readAsStringSync();
    expect(source, contains('deleteDiaryEntry(entry.id)'));
    expect(source, contains('WeeklyReportReflection'));
  });
}
