import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_monthly_comparison_resolver.dart';

void main() {
  group('resolveHabitStatsMonthlyComparisonCopy', () {
    testWidgets('resolves better state copy with +delta in Spanish',
        (tester) async {
      final l10n = await _l10nForLocale(tester, const Locale('es'));
      final copy = resolveHabitStatsMonthlyComparisonCopy(
        l10n,
        const HabitStatsMonthlyComparisonData(
          currentCompleted: 12,
          previousCompleted: 8,
          delta: 4,
          hasComparison: true,
          trend: HabitStatsComparisonTrend.better,
        ),
      );

      expect(copy.title, 'Comparaci\u00f3n mensual');
      expect(copy.mainText, 'Mejor que el mes pasado');
      expect(copy.secondaryText, '+4 vs mes anterior');
    });

    testWidgets('resolves same state copy in English', (tester) async {
      final l10n = await _l10nForLocale(tester, const Locale('en'));
      final copy = resolveHabitStatsMonthlyComparisonCopy(
        l10n,
        const HabitStatsMonthlyComparisonData(
          currentCompleted: 8,
          previousCompleted: 8,
          delta: 0,
          hasComparison: true,
          trend: HabitStatsComparisonTrend.same,
        ),
      );

      expect(copy.title, 'Monthly comparison');
      expect(copy.mainText, 'Similar pace to last month');
      expect(copy.secondaryText, 'No change vs previous month');
    });

    testWidgets('resolves worse state copy with -delta in English',
        (tester) async {
      final l10n = await _l10nForLocale(tester, const Locale('en'));
      final copy = resolveHabitStatsMonthlyComparisonCopy(
        l10n,
        const HabitStatsMonthlyComparisonData(
          currentCompleted: 6,
          previousCompleted: 9,
          delta: -3,
          hasComparison: true,
          trend: HabitStatsComparisonTrend.worse,
        ),
      );

      expect(copy.title, 'Monthly comparison');
      expect(copy.mainText, 'A bit below last month');
      expect(copy.secondaryText, '-3 vs previous month');
    });

    testWidgets('resolves unavailable state copy in Spanish', (tester) async {
      final l10n = await _l10nForLocale(tester, const Locale('es'));
      final copy = resolveHabitStatsMonthlyComparisonCopy(
        l10n,
        const HabitStatsMonthlyComparisonData(
          currentCompleted: 0,
          previousCompleted: 0,
          delta: 0,
          hasComparison: false,
          trend: HabitStatsComparisonTrend.unavailable,
        ),
      );

      expect(copy.title, 'Comparaci\u00f3n mensual');
      expect(copy.mainText, 'Sin comparaci\u00f3n todav\u00eda');
      expect(
        copy.secondaryText,
        'Cuando haya datos del mes anterior, ver\u00e1s tu evoluci\u00f3n.',
      );
    });
  });
}

Future<AppLocalizations> _l10nForLocale(
  WidgetTester tester,
  Locale locale,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Text(
          context.l10n.habitStatsTitle,
          key: const Key('l10n_probe'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.element(find.byKey(const Key('l10n_probe'))).l10n;
}
