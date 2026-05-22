import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/count_last7days_chart_painter.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_count_last7_days_chart.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';

void main() {
  group('HabitStatsCountLast7DaysChart', () {
    testWidgets('renders weekday labels and markers for mixed values',
        (tester) async {
      final days = _buildDays(const [0, 2, 1, 4, 3, 6, 5]);

      await tester.pumpWidget(
        _wrap(
          width: 330,
          child: HabitStatsCountLast7DaysChart(days: days),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HabitStatsCountLast7DaysChart), findsOneWidget);
      expect(find.byKey(const Key('habit_stats_count_last7_plot')),
          findsOneWidget);
      for (var i = 0; i < 7; i += 1) {
        expect(find.byKey(Key('habit_stats_count_last7_weekday_$i')),
            findsOneWidget);
        expect(find.byKey(Key('habit_stats_count_last7_marker_$i')),
            findsOneWidget);
      }
      expect(find.text('0'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles all-zero values without errors', (tester) async {
      final days = _buildDays(const [0, 0, 0, 0, 0, 0, 0]);

      await tester.pumpWidget(
        _wrap(
          width: 330,
          child: HabitStatsCountLast7DaysChart(days: days),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HabitStatsCountLast7DaysChart), findsOneWidget);
      expect(find.byKey(const Key('habit_stats_count_last7_plot')),
          findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stays stable on compact width', (tester) async {
      final days = _buildDays(const [1, 1, 2, 8, 2, 1, 1]);

      await tester.pumpWidget(
        _wrap(
          width: 280,
          child: HabitStatsCountLast7DaysChart(days: days),
        ),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 7; i += 1) {
        expect(find.byKey(Key('habit_stats_count_last7_weekday_$i')),
            findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles a high peak value without overflow', (tester) async {
      final days = _buildDays(const [1, 1, 3, 48, 2, 1, 1]);

      await tester.pumpWidget(
        _wrap(
          width: 320,
          child: HabitStatsCountLast7DaysChart(days: days),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HabitStatsCountLast7DaysChart), findsOneWidget);
      expect(find.byKey(const Key('habit_stats_count_last7_plot')),
          findsOneWidget);
      final scale = CountLast7DaysChartScale.fromDays(
        const [1, 1, 3, 48, 2, 1, 1],
      );
      final maxLabel = formatCountLast7DaysAxisLabel(
        scale.tickValues.last,
        fractionDigits: scale.fractionDigits,
      );
      expect(find.text(maxLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders compact y-axis labels for large values',
        (tester) async {
      final days = _buildDays(const [7200, 7600, 8000, 6800, 5000, 3000, 1200]);

      await tester.pumpWidget(
        _wrap(
          width: 330,
          child: HabitStatsCountLast7DaysChart(days: days),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('8k'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CountLast7DaysChartScale', () {
    test('small range uses readable integer ticks', () {
      final scale = CountLast7DaysChartScale.fromDays(const [0, 1, 3]);

      expect(scale.tickValues.first, 0);
      expect(scale.tickValues.last, greaterThanOrEqualTo(3));
      expect(scale.tickValues.length, lessThanOrEqualTo(5));
      expect(scale.fractionDigits, 0);
    });

    test('medium range includes quarter-style ticks', () {
      final scale = CountLast7DaysChartScale.fromDays(const [20, 42, 67, 100]);

      expect(scale.tickValues, containsAll(<num>[0, 25, 50, 75, 100]));
      expect(scale.tickValues.length, lessThanOrEqualTo(5));
    });

    test('large range keeps labels readable', () {
      final scale =
          CountLast7DaysChartScale.fromDays(const [1200, 8000, 3600, 2500]);

      expect(scale.tickValues.first, 0);
      expect(scale.tickValues.last, greaterThanOrEqualTo(8000));
      expect(scale.tickValues.length, lessThanOrEqualTo(5));
    });

    test('top tick is always >= max value', () {
      const values = <num>[900, 800, 650, 650, 8800, 0, 0];
      final scale = CountLast7DaysChartScale.fromDays(values);

      expect(scale.tickValues.last, greaterThanOrEqualTo(8800));
    });

    test('all-zero values include baseline label', () {
      final scale = CountLast7DaysChartScale.fromDays(const [0, 0, 0, 0]);

      expect(scale.tickValues.first, 0);
      expect(scale.tickValues.last, greaterThan(0));
    });

    test('equal non-zero values build a valid scale', () {
      final scale = CountLast7DaysChartScale.fromDays(const [5, 5, 5, 5]);

      expect(scale.tickValues.first, 0);
      expect(scale.tickValues.last, greaterThanOrEqualTo(5));
      expect(scale.tickValues.length, lessThanOrEqualTo(5));
    });

    test('decimal values use at most one fractional digit', () {
      final scale =
          CountLast7DaysChartScale.fromDays(const [0.4, 1.1, 1.8, 0.7]);

      expect(scale.tickValues.first, 0);
      expect(scale.tickValues.last, greaterThanOrEqualTo(1.8));
      expect(scale.fractionDigits, lessThanOrEqualTo(1));
      final decimalLabel = formatCountLast7DaysAxisLabel(
        scale.tickValues[1],
        fractionDigits: scale.fractionDigits,
      );
      if (scale.fractionDigits > 0) {
        expect(decimalLabel.contains('.'), isTrue);
      }
    });

    test('all-zero values stay on baseline', () {
      const values = <num>[0, 0, 0, 0, 0, 0, 0];
      final scale = CountLast7DaysChartScale.fromDays(values);
      final points = buildCountLast7DaysChartPoints(
        values: values,
        maxWidth: 140,
        maxHeight: 80,
        scale: scale,
      );

      expect(points, hasLength(7));
      final baseline = points.first.dy;
      for (final point in points) {
        expect(point.dy, closeTo(baseline, 0.0001));
      }
    });

    test('high peak is mapped above neighboring points', () {
      const values = <num>[1, 2, 12, 3, 2, 1, 1];
      final scale = CountLast7DaysChartScale.fromDays(values);
      final points = buildCountLast7DaysChartPoints(
        values: values,
        maxWidth: 210,
        maxHeight: 90,
        scale: scale,
      );

      expect(points, hasLength(7));
      expect(points[2].dy < points[1].dy, isTrue);
      expect(points[2].dy < points[3].dy, isTrue);
    });

    test('monotone curve keeps consecutive zero values flat at baseline', () {
      const values = <num>[25, 0, 0];
      final scale = CountLast7DaysChartScale.fromDays(values);
      final points = buildCountLast7DaysChartPoints(
        values: values,
        maxWidth: 210,
        maxHeight: 90,
        scale: scale,
      );
      final segments = buildCountLast7DaysMonotoneSegments(
        points: points,
        minY: scale.topPadding,
        maxY: 90 - scale.bottomPadding,
      );
      final baseline = 90 - scale.bottomPadding;

      expect(points[1].dy, closeTo(baseline, 0.0001));
      expect(points[2].dy, closeTo(baseline, 0.0001));
      expect(segments, hasLength(2));
      expect(segments[1].control1.dy, closeTo(baseline, 0.0001));
      expect(segments[1].control2.dy, closeTo(baseline, 0.0001));
    });

    test('monotone segments stay inside plot bounds and use data points', () {
      const values = <num>[900, 800, 650, 650, 0, 0, 0];
      final scale = CountLast7DaysChartScale.fromDays(values);
      final top = scale.topPadding;
      final bottom = 100 - scale.bottomPadding;
      final points = buildCountLast7DaysChartPoints(
        values: values,
        maxWidth: 240,
        maxHeight: 100,
        scale: scale,
      );
      final segments = buildCountLast7DaysMonotoneSegments(
        points: points,
        minY: top,
        maxY: bottom,
      );

      expect(segments.first.start, points.first);
      expect(segments.last.end, points.last);
      for (final segment in segments) {
        expect(segment.control1.dy, inInclusiveRange(top, bottom));
        expect(segment.control2.dy, inInclusiveRange(top, bottom));
      }
    });
  });

  group('Chart Axis Value Formatting', () {
    test('formats 8000 as 8k', () {
      expect(formatChartAxisValue(8000), '8k');
    });

    test('formats 1000 as 1k', () {
      expect(formatChartAxisValue(1000), '1k');
    });

    test('formats 2500 as 2.5k', () {
      expect(formatChartAxisValue(2500), '2.5k');
    });

    test('keeps small values as normal integers', () {
      expect(formatChartAxisValue(100), '100');
    });
  });
}

Widget _wrap({
  required double width,
  required Widget child,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: child,
        ),
      ),
    ),
  );
}

List<HabitStatsCountLast7DayItem> _buildDays(List<num> values) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return List<HabitStatsCountLast7DayItem>.generate(
    values.length,
    (index) => HabitStatsCountLast7DayItem(
      date: DateTime(2026, 5, 10 + index),
      weekdayLabel: labels[index % labels.length],
      value: values[index],
      valueLabel: values[index].toString(),
      fillRatio: 0,
    ),
    growable: false,
  );
}
