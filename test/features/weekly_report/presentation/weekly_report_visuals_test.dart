import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/weekly_report/presentation/weekly_report_visuals.dart';

void main() {
  test('completion colors follow the compact weekly report scale', () {
    expect(WeeklyReportVisuals.completionColor(0), WeeklyReportVisuals.warning);
    expect(
        WeeklyReportVisuals.completionColor(.39), WeeklyReportVisuals.warning);
    expect(WeeklyReportVisuals.completionColor(.4), const Color(0xFFC59A3D));
    expect(WeeklyReportVisuals.completionColor(.6), WeeklyReportVisuals.stable);
    expect(
        WeeklyReportVisuals.completionColor(.8), WeeklyReportVisuals.success);
  });

  test('no-plan bars remain neutral regardless of the rate', () {
    expect(
      WeeklyReportVisuals.barColor(WeeklyReportVisualBarState.noPlan, 1),
      WeeklyReportVisuals.neutral,
    );
    expect(
      WeeklyReportVisuals.barColor(WeeklyReportVisualBarState.planned, .2),
      WeeklyReportVisuals.warning,
    );
  });
}
