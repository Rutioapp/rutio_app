import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/statistics/presentation/shared/statistics_best_moment_illustrations.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_metric_grid.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Habit stats Best Moment metric card', () {
    testWidgets('renders new morning illustration', (tester) async {
      await tester.pumpWidget(
        _app(_gridWithBestMoment(HabitStatsBestMomentSlot.morning)),
      );

      final image = tester.widget<Image>(
        find.byKey(const Key('habitStatsBestMomentIllustration-morning')),
      );
      expect(
        (image.image as AssetImage).assetName,
        statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.morning,
        ),
      );
    });

    testWidgets('renders new midday illustration', (tester) async {
      await tester.pumpWidget(
        _app(_gridWithBestMoment(HabitStatsBestMomentSlot.noon)),
      );

      final image = tester.widget<Image>(
        find.byKey(const Key('habitStatsBestMomentIllustration-noon')),
      );
      expect(
        (image.image as AssetImage).assetName,
        statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.midday,
        ),
      );
    });

    testWidgets('renders new afternoon illustration', (tester) async {
      await tester.pumpWidget(
        _app(_gridWithBestMoment(HabitStatsBestMomentSlot.afternoon)),
      );

      final image = tester.widget<Image>(
        find.byKey(const Key('habitStatsBestMomentIllustration-afternoon')),
      );
      expect(
        (image.image as AssetImage).assetName,
        statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.afternoon,
        ),
      );
    });

    testWidgets('renders new night illustration', (tester) async {
      await tester.pumpWidget(
        _app(_gridWithBestMoment(HabitStatsBestMomentSlot.night)),
      );

      final image = tester.widget<Image>(
        find.byKey(const Key('habitStatsBestMomentIllustration-night')),
      );
      expect(
        (image.image as AssetImage).assetName,
        statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.night,
        ),
      );
    });

    testWidgets('fallback no-data state still renders', (tester) async {
      await tester.pumpWidget(
        _app(
          _gridWithMetric(
            const HabitStatsMetricGridItem(
              icon: Icons.schedule_rounded,
              title: 'Best moment',
              value: '-',
              subtitle: 'No data yet',
              iconColor: Color(0xFF4E7D35),
              useBestMomentVisual: false,
              bestMomentSlot: HabitStatsBestMomentSlot.unknown,
            ),
          ),
        ),
      );

      expect(find.text('-'), findsOneWidget);
      expect(find.text('No data yet'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('remains stable on compact width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 320,
            child: _gridWithBestMoment(HabitStatsBestMomentSlot.noon),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

Widget _gridWithBestMoment(HabitStatsBestMomentSlot slot) {
  return _gridWithMetric(
    HabitStatsMetricGridItem(
      icon: Icons.schedule_rounded,
      title: 'Best moment',
      value: 'Morning',
      subtitle: 'Your strongest time',
      iconColor: const Color(0xFF4E7D35),
      useBestMomentVisual: true,
      bestMomentSlot: slot,
    ),
  );
}

Widget _gridWithMetric(HabitStatsMetricGridItem metric) {
  return SizedBox(
    width: 210,
    height: 200,
    child: HabitStatsMetricGrid.custom(
      metrics: <HabitStatsMetricGridItem>[metric],
    ),
  );
}
