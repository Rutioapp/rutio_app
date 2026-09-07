import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_consistency_card.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('keeps raw 4/3 while bounding the visual ring', (tester) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 220,
          height: 210,
          child: StatisticsV3ConsistencyCard(
            title: 'Consistency',
            completedHabits: 4,
            totalHabits: 3,
            consistencyPct: 100,
            progressRatio: 1.333333,
            streakDays: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4 de 3'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not present unverifiable totals as exact', (tester) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 220,
          height: 210,
          child: StatisticsV3ConsistencyCard(
            title: 'Consistency',
            completedHabits: 14,
            totalHabits: 13,
            consistencyPct: 100,
            progressRatio: 1,
            streakDays: 0,
            dataUnavailable: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('—'), findsOneWidget);
    expect(find.text('14 de 13'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}
