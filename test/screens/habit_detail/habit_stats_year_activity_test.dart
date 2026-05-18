import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_year_activity_section.dart';

void main() {
  group('HabitStatsYearActivitySection', () {
    testWidgets('renders yearly activity rows', (tester) async {
      await tester.pumpWidget(
        _app(
          child: HabitStatsYearActivitySection(
            monthSummaries: _summaries(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('habit_stats_year_activity_card')),
          findsOneWidget);
      expect(find.text('Yearly activity'), findsOneWidget);
      expect(find.text('Best month'), findsOneWidget);
      expect(find.text('Quietest month'), findsOneWidget);
      expect(find.text('Active months'), findsOneWidget);
      expect(find.text('Rhythm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders safely on constrained width', (tester) async {
      await tester.pumpWidget(
        _app(
          size: const Size(320, 568),
          child: HabitStatsYearActivitySection(
            monthSummaries: _summaries(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('habit_stats_year_activity_card')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows calm placeholders when there is no activity',
        (tester) async {
      await tester.pumpWidget(
        _app(
          locale: const Locale('es'),
          child: HabitStatsYearActivitySection(
            monthSummaries: const <HabitStatsYearMonthSummary>[
              HabitStatsYearMonthSummary(
                month: 1,
                completedDays: 0,
                accumulatedValue: 0,
                trackableDays: 0,
                status: HabitStatsYearMonthStatus.unavailable,
              ),
              HabitStatsYearMonthSummary(
                month: 2,
                completedDays: 0,
                accumulatedValue: 0,
                trackableDays: 0,
                status: HabitStatsYearMonthStatus.future,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('\u2014'), findsNWidgets(2));
      expect(find.text('Sin datos aún'), findsOneWidget);
      expect(find.text('0 meses'), findsOneWidget);
      expect(find.text('# mes'), findsNothing);
      expect(find.text('# meses'), findsNothing);
    });

    testWidgets('renders singular active month value in English',
        (tester) async {
      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          child: HabitStatsYearActivitySection(
            monthSummaries: const <HabitStatsYearMonthSummary>[
              HabitStatsYearMonthSummary(
                month: 1,
                completedDays: 3,
                accumulatedValue: 3,
                trackableDays: 30,
                status: HabitStatsYearMonthStatus.low,
                performancePct: 20,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 month'), findsOneWidget);
      expect(find.text('# month'), findsNothing);
    });

    testWidgets('renders plural active months value in English',
        (tester) async {
      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          child: HabitStatsYearActivitySection(
            monthSummaries: _summaries(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 months'), findsOneWidget);
      expect(find.text('# months'), findsNothing);
    });
  });
}

Widget _app({
  required Widget child,
  Size size = const Size(430, 932),
  Locale? locale,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(body: child),
    ),
  );
}

List<HabitStatsYearMonthSummary> _summaries() {
  return const <HabitStatsYearMonthSummary>[
    HabitStatsYearMonthSummary(
      month: 1,
      completedDays: 5,
      accumulatedValue: 5,
      trackableDays: 30,
      status: HabitStatsYearMonthStatus.low,
      performancePct: 25,
    ),
    HabitStatsYearMonthSummary(
      month: 2,
      completedDays: 18,
      accumulatedValue: 18,
      trackableDays: 30,
      status: HabitStatsYearMonthStatus.high,
      performancePct: 82,
    ),
    HabitStatsYearMonthSummary(
      month: 3,
      completedDays: 0,
      accumulatedValue: 0,
      trackableDays: 0,
      status: HabitStatsYearMonthStatus.future,
    ),
  ];
}
