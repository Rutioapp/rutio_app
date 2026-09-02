import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/statistics/presentation/v3/screens/statistics_v3_screen.dart';
import 'package:rutio/features/weekly_report/presentation/screens/weekly_report_screen.dart';

void main() {
  testWidgets('debug entry opens the existing Weekly Report route',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => const WeeklyReportDebugEntry(),
          WeeklyReportScreen.route: (_) => const Scaffold(
                body: Text('Weekly Report destination'),
              ),
        },
        initialRoute: '/',
      ),
    );

    expect(find.text('Weekly Report · Debug'), findsOneWidget);
    await tester.tap(find.byKey(const Key('weeklyReportDebugEntry')));
    await tester.pumpAndSettle();

    expect(find.text('Weekly Report destination'), findsOneWidget);
  });
}
