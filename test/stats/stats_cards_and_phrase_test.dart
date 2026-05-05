import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/widgets/stats/stats_count_cards.dart';
import 'package:rutio/widgets/stats/stats_motivational_tip_card.dart';

Widget _app(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('objective card keeps a 2x2 grid', (tester) async {
    await tester.pumpWidget(
      _app(
        const StatsCountObjectiveCard(
          goalCompletedDays: 4,
          partialProgressDays: 2,
          compliancePct: 73.4,
          target: 5,
          accent: Color(0xFF4F46E5),
        ),
      ),
    );

    expect(find.byKey(const Key('stats_objective_grid')), findsOneWidget);
    final grid = tester.widget<GridView>(find.byKey(const Key('stats_objective_grid')));
    final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(find.text('4'), findsWidgets);
  });

  testWidgets('motivational card renders a non-empty dynamic phrase', (tester) async {
    await tester.pumpWidget(
      _app(
        const StatsMotivationalTipCard(
          habitTitle: 'Read',
          streakDays: 8,
          thisWeekDoneDays: 5,
          lastWeekDoneDays: 4,
          bestTimeLabel: 'evening',
          compliancePct: 72,
        ),
      ),
    );

    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.byType(StatsMotivationalTipCard),
        matching: find.byType(RichText),
      ).first,
    );
    final text = (richText.text as TextSpan).toPlainText().trim();
    expect(text.isNotEmpty, isTrue);
  });
}
