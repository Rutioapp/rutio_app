import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/statistics/presentation/shared/statistics_best_moment_illustrations.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_best_moment_card.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StatisticsV3 Best Moment card', () {
    testWidgets('renders morning bucket illustration', (tester) async {
      await tester.pumpWidget(
        _app(
          _card(
            insight: const StatisticsV3BestMomentInsight(
              hasData: true,
              slot: StatisticsV3BestMomentSlot.morning,
              label: 'Morning',
              count: 4,
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(
        find.byKey(const Key('statisticsV3BestMomentIllustration-morning')),
      );
      expect(
          (image.image as AssetImage).assetName,
          statisticsBestMomentIllustrationAssetForBucket(
            StatisticsBestMomentBucket.morning,
          ));
    });

    testWidgets('renders midday bucket illustration', (tester) async {
      await tester.pumpWidget(
        _app(
          _card(
            insight: const StatisticsV3BestMomentInsight(
              hasData: true,
              slot: StatisticsV3BestMomentSlot.noon,
              label: 'Midday',
              count: 4,
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(
        find.byKey(const Key('statisticsV3BestMomentIllustration-noon')),
      );
      expect(
          (image.image as AssetImage).assetName,
          statisticsBestMomentIllustrationAssetForBucket(
            StatisticsBestMomentBucket.midday,
          ));
    });

    testWidgets('renders afternoon bucket illustration', (tester) async {
      await tester.pumpWidget(
        _app(
          _card(
            insight: const StatisticsV3BestMomentInsight(
              hasData: true,
              slot: StatisticsV3BestMomentSlot.afternoon,
              label: 'Afternoon',
              count: 4,
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(
        find.byKey(const Key('statisticsV3BestMomentIllustration-afternoon')),
      );
      expect(
          (image.image as AssetImage).assetName,
          statisticsBestMomentIllustrationAssetForBucket(
            StatisticsBestMomentBucket.afternoon,
          ));
    });

    testWidgets('renders night bucket illustration', (tester) async {
      await tester.pumpWidget(
        _app(
          _card(
            insight: const StatisticsV3BestMomentInsight(
              hasData: true,
              slot: StatisticsV3BestMomentSlot.night,
              label: 'Night',
              count: 4,
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(
        find.byKey(const Key('statisticsV3BestMomentIllustration-night')),
      );
      expect(
          (image.image as AssetImage).assetName,
          statisticsBestMomentIllustrationAssetForBucket(
            StatisticsBestMomentBucket.night,
          ));
    });

    testWidgets('fallback state renders when no data is available',
        (tester) async {
      await tester.pumpWidget(
        _app(
          _card(
            insight: const StatisticsV3BestMomentInsight(
              hasData: false,
              slot: StatisticsV3BestMomentSlot.morning,
              label: '',
              count: 0,
            ),
          ),
        ),
      );

      expect(find.text('No best moment data yet.'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('does not overflow on compact width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 164,
            child: _card(
              insight: const StatisticsV3BestMomentInsight(
                hasData: true,
                slot: StatisticsV3BestMomentSlot.noon,
                label: 'Midday',
                count: 4,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StatisticsV3BestMomentCard), findsOneWidget);
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

Widget _card({
  required StatisticsV3BestMomentInsight insight,
}) {
  return SizedBox(
    width: 186,
    height: 200,
    child: StatisticsV3BestMomentCard(
      title: 'Best Moment',
      insight: insight,
      fallback: 'No best moment data yet.',
    ),
  );
}
