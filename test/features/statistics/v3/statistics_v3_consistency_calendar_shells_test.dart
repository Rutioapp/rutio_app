import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_consistency_palette.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_monthly_calendar_shell.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_yearly_consistency_shell.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  group('Statistics V3 consistency calendar shells', () {
    testWidgets('monthly calendar renders rounded day cells', (tester) async {
      final days = _buildMonthDays(
        DateTime(2026, 5, 1),
        today: DateTime(2026, 5, 20),
      );

      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 360,
            child: StatisticsV3MonthlyCalendarShell(
              title: 'Consistency calendar',
              subtitle: 'Month rhythm at a glance',
              days: days,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mayFifthKey = find.byKey(const Key('statisticsV3MonthDay_2026-05-05'));
      expect(mayFifthKey, findsOneWidget);
      final cell = tester.widget<Container>(mayFifthKey);
      final decoration = cell.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(find.byKey(const Key('statisticsV3ConsistencyLegend')), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('1–39%'), findsOneWidget);
      expect(find.text('40–74%'), findsOneWidget);
      expect(find.text('75–100%'), findsOneWidget);
      expect(find.text('No data'), findsNothing);
      expect(find.text('Future'), findsNothing);
      expect(find.byKey(const Key('statisticsV3ConsistencyLegend_unavailable')),
          findsNothing);
      expect(find.byKey(const Key('statisticsV3ConsistencyLegend_future')),
          findsNothing);
      for (final bucket in StatisticsV3ConsistencyPalette.percentageBuckets) {
        expect(
          find.byKey(Key('statisticsV3ConsistencyLegend_${bucket.intensity.name}')),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('monthly calendar renders calm future and unavailable states',
        (tester) async {
      final days = _buildMonthDays(
        DateTime(2026, 5, 1),
        today: DateTime(2026, 5, 20),
      );

      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 360,
            child: StatisticsV3MonthlyCalendarShell(
              title: 'Consistency calendar',
              subtitle: 'Month rhythm at a glance',
              days: days,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final unavailableKey =
          find.byKey(const Key('statisticsV3MonthDay_2026-05-03'));
      final futureKey = find.byKey(const Key('statisticsV3MonthDay_2026-05-28'));
      expect(unavailableKey, findsOneWidget);
      expect(futureKey, findsOneWidget);

      final unavailableDecoration =
          (tester.widget<Container>(unavailableKey).decoration! as BoxDecoration);
      final futureDecoration =
          (tester.widget<Container>(futureKey).decoration! as BoxDecoration);
      expect(unavailableDecoration.color, isNot(equals(futureDecoration.color)));
    });

    testWidgets('year calendar renders without overflow on compact width',
        (tester) async {
      final months = _buildYearMonths(today: DateTime(2026, 5, 20));

      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 280,
            child: StatisticsV3YearlyConsistencyShell(
              title: 'Yearly consistency',
              subtitle: 'Month-by-month consistency for the current year',
              months: months,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('statisticsV3YearCalendarGrid')), findsOneWidget);
      expect(find.byKey(const Key('statisticsV3YearDay_2026-05-20')), findsOneWidget);
      expect(find.byKey(const Key('statisticsV3ConsistencyLegend')), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('1–39%'), findsOneWidget);
      expect(find.text('40–74%'), findsOneWidget);
      expect(find.text('75–100%'), findsOneWidget);
      expect(find.text('No data'), findsNothing);
      expect(find.text('Future'), findsNothing);
    });
  });
}

Widget _app(
  Widget child, {
  Locale? locale,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ListView(
        children: [child],
      ),
    ),
  );
}

List<StatisticsV3MonthlyCalendarDay> _buildMonthDays(
  DateTime monthStart, {
  required DateTime today,
}) {
  final daysInMonth = DateUtils.getDaysInMonth(monthStart.year, monthStart.month);
  return List<StatisticsV3MonthlyCalendarDay>.generate(daysInMonth, (index) {
    final date = monthStart.add(Duration(days: index));
    final day = date.day;
    final isFuture = date.isAfter(today);

    if (isFuture) {
      return StatisticsV3MonthlyCalendarDay(
        date: date,
        completedCount: 0,
        expectedCount: 0,
        percentage: 0,
        isToday: false,
        isFuture: true,
        isCurrentMonth: true,
      );
    }

    if (day == 3) {
      return StatisticsV3MonthlyCalendarDay(
        date: date,
        completedCount: 0,
        expectedCount: 0,
        percentage: 0,
        isToday: false,
        isFuture: false,
        isCurrentMonth: true,
      );
    }

    final percentage = day <= 7 ? 20 : (day <= 14 ? 60 : 85);
    return StatisticsV3MonthlyCalendarDay(
      date: date,
      completedCount: percentage >= 80 ? 1 : 0,
      expectedCount: 1,
      percentage: percentage,
      isToday: day == today.day,
      isFuture: false,
      isCurrentMonth: true,
    );
  }, growable: false);
}

List<StatisticsV3YearlyConsistencyMonth> _buildYearMonths({
  required DateTime today,
}) {
  return List<StatisticsV3YearlyConsistencyMonth>.generate(12, (index) {
    final month = index + 1;
    final monthStart = DateTime(today.year, month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(today.year, month);
    final days = List<StatisticsV3YearlyConsistencyDay>.generate(
      daysInMonth,
      (dayIndex) {
        final date = monthStart.add(Duration(days: dayIndex));
        final isFuture = date.isAfter(today);
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final expectedCount = isFuture ? 0 : (dayIndex % 5 == 0 ? 0 : 1);
        final percentage =
            isFuture || expectedCount == 0 ? 0 : ((dayIndex * 13) % 100);

        return StatisticsV3YearlyConsistencyDay(
          date: date,
          completedCount: percentage >= 60 ? 1 : 0,
          expectedCount: expectedCount,
          percentage: percentage,
          isToday: isToday,
          isFuture: isFuture,
        );
      },
      growable: false,
    );

    final nonFutureDays = days.where((day) => !day.isFuture);
    final expectedCount =
        nonFutureDays.fold<int>(0, (sum, day) => sum + day.expectedCount);
    final completedCount =
        nonFutureDays.fold<int>(0, (sum, day) => sum + day.completedCount);
    final percentage = expectedCount == 0
        ? 0
        : ((completedCount / expectedCount) * 100).round();

    return StatisticsV3YearlyConsistencyMonth(
      month: month,
      year: today.year,
      completedCount: completedCount,
      expectedCount: expectedCount,
      percentage: percentage,
      isCurrentMonth: month == today.month,
      isFuture: monthStart.isAfter(today),
      days: days,
    );
  }, growable: false);
}
