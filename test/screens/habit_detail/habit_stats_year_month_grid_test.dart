import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_year_month_grid.dart';

void main() {
  group('HabitStatsYearMonthGrid', () {
    testWidgets('renders year calendar grid, localized month labels and legend',
        (tester) async {
      await tester.pumpWidget(
        _app(
          size: const Size(430, 1200),
          locale: const Locale('es'),
          child: HabitStatsYearMonthGrid(
            year: 2026,
            months: _calendarMonths(2026),
            accentColor: const Color(0xFF6A8C6B),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('habit_stats_year_calendar_grid')),
          findsOneWidget);
      expect(find.byKey(const Key('habit_stats_year_calendar_month_grid')),
          findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('Ene'), findsOneWidget);
      expect(find.text('Dic'), findsOneWidget);
      expect(find.text('Hecho'), findsOneWidget);
      expect(find.text('Omitido'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.byKey(const Key('habit_stats_year_calendar_legend_done')),
          findsOneWidget);
      expect(find.byKey(const Key('habit_stats_year_calendar_legend_skipped')),
          findsOneWidget);
      expect(find.byKey(const Key('habit_stats_year_calendar_legend_missed')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders day state dots and builds without overflow on compact width',
        (tester) async {
      await tester.pumpWidget(
        _app(
          size: const Size(320, 568),
          child: HabitStatsYearMonthGrid(
            year: 2026,
            months: _calendarMonths(2026),
            accentColor: const Color(0xFF6A8C6B),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
            const Key('habit_stats_year_calendar_day_2026_1_1_completed')),
        findsOneWidget,
      );
      expect(
        find.byKey(
            const Key('habit_stats_year_calendar_day_2026_1_2_skipped')),
        findsOneWidget,
      );
      expect(
        find.byKey(
            const Key('habit_stats_year_calendar_day_2026_1_3_missed')),
        findsOneWidget,
      );
      expect(
        find.byKey(
            const Key('habit_stats_year_calendar_day_2026_1_4_future')),
        findsOneWidget,
      );
      expect(
        find.byKey(
            const Key('habit_stats_year_calendar_day_2026_1_5_unavailable')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('habit_stats_year_calendar_month_12')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
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
      child: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    ),
  );
}

List<HabitStatsYearCalendarMonth> _calendarMonths(int year) {
  return List<HabitStatsYearCalendarMonth>.generate(12, (index) {
    final month = index + 1;
    final monthStart = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingEmptyDays =
        (monthStart.weekday - DateTime.monday + 7) % DateTime.daysPerWeek;

    final days = List<HabitStatsYearCalendarDay>.generate(daysInMonth, (offset) {
      final day = offset + 1;
      final date = DateTime(year, month, day);
      HabitStatsYearCalendarDayStatus status = HabitStatsYearCalendarDayStatus.missed;
      if (month == 1 && day == 1) status = HabitStatsYearCalendarDayStatus.completed;
      if (month == 1 && day == 2) status = HabitStatsYearCalendarDayStatus.skipped;
      if (month == 1 && day == 3) status = HabitStatsYearCalendarDayStatus.missed;
      if (month == 1 && day == 4) status = HabitStatsYearCalendarDayStatus.future;
      if (month == 1 && day == 5) {
        status = HabitStatsYearCalendarDayStatus.unavailable;
      }
      return HabitStatsYearCalendarDay(
        date: date,
        status: status,
      );
    }, growable: false);

    return HabitStatsYearCalendarMonth(
      year: year,
      month: month,
      leadingEmptyDays: leadingEmptyDays,
      days: days,
    );
  }, growable: false);
}
