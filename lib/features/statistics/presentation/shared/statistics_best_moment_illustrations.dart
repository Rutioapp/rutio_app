enum StatisticsBestMomentBucket {
  morning,
  midday,
  afternoon,
  night,
}

const String statisticsBestMomentMorningIllustrationAsset =
    'assets/images/statistics/best_moment_morning.png';
const String statisticsBestMomentMiddayIllustrationAsset =
    'assets/images/statistics/best_moment_midday.png';
const String statisticsBestMomentAfternoonIllustrationAsset =
    'assets/images/statistics/best_moment_afternoon.png';
const String statisticsBestMomentNightIllustrationAsset =
    'assets/images/statistics/best_moment_night.png';

String statisticsBestMomentIllustrationAssetForBucket(
  StatisticsBestMomentBucket bucket,
) {
  switch (bucket) {
    case StatisticsBestMomentBucket.morning:
      return statisticsBestMomentMorningIllustrationAsset;
    case StatisticsBestMomentBucket.midday:
      return statisticsBestMomentMiddayIllustrationAsset;
    case StatisticsBestMomentBucket.afternoon:
      return statisticsBestMomentAfternoonIllustrationAsset;
    case StatisticsBestMomentBucket.night:
      return statisticsBestMomentNightIllustrationAsset;
  }
}
