import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/statistics/presentation/shared/statistics_best_moment_illustrations.dart';

void main() {
  group('statistics best moment illustration mapper', () {
    test('returns consistent assets per bucket', () {
      expect(
        statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.morning,
        ),
        statisticsBestMomentMorningIllustrationAsset,
      );
      expect(
        statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.midday,
        ),
        statisticsBestMomentMiddayIllustrationAsset,
      );
      expect(
        statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.afternoon,
        ),
        statisticsBestMomentAfternoonIllustrationAsset,
      );
      expect(
        statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.night,
        ),
        statisticsBestMomentNightIllustrationAsset,
      );
    });
  });
}
