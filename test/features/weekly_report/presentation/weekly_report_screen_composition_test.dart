import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'habits section precedes the recommendation in the shared composition path',
      () {
    final source = File(
      'lib/features/weekly_report/presentation/screens/weekly_report_screen.dart',
    ).readAsStringSync();

    final habitsIndex =
        source.indexOf('WeeklyReportHabitsSection(habits: report.habits)');
    final recommendationIndex =
        source.indexOf('WeeklyReportRecommendationCard(');

    expect(habitsIndex, greaterThanOrEqualTo(0));
    expect(recommendationIndex, greaterThan(habitsIndex));
    expect(source,
        contains('debugRecommendation ?? report.recommendations.first'));
  });

  test('history action is localized and avoids history loops', () {
    final source = File(
      'lib/features/weekly_report/presentation/screens/weekly_report_screen.dart',
    ).readAsStringSync();
    expect(source, contains('Icons.history_rounded'));
    expect(source, contains('tooltip: context.l10n.weeklyReportHistory'));
    expect(source, contains('WeeklyReportHistoryScreen.route'));
    expect(source, contains('openedFromHistory'));
    expect(source, contains('widget.openedFromHistory'));
  });
}
