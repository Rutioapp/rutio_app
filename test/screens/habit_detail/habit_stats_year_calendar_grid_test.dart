import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_helpers.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_year_month_grid.dart';

void main() {
  group('HabitStatsYearCalendarGrid', () {
    testWidgets('renders 12 months from resolver output', (tester) async {
      final months = resolveHabitStatsYearCalendarMonths(
        habit: _habit(),
        year: 2026,
        now: DateTime(2026, 5, 20, 10),
        countsByDay: const {},
        countValuesByDay: const {},
        skipsByDay: const {},
      );

      await tester.pumpWidget(
        _app(
          child: HabitStatsYearMonthGrid(
            year: 2026,
            months: months,
            accentColor: const Color(0xFF6A8C6B),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(months, hasLength(12));
      expect(find.byKey(const Key('habit_stats_year_calendar_month_1')),
          findsOneWidget);
      expect(find.byKey(const Key('habit_stats_year_calendar_month_12')),
          findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Dec'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _app({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: child,
      ),
    ),
  );
}

Map<String, dynamic> _habit() {
  return <String, dynamic>{
    'id': 'habit-1',
    'type': 'check',
    'target': 1,
    'createdAt': '2026-01-01',
    'schedule': const {'type': 'daily'},
  };
}
