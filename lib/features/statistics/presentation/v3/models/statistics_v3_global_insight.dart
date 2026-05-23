import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';

enum StatisticsV3GlobalInsightType {
  noData,
  positiveConsistency,
  featuredFamily,
  bestMoment,
  lowActivity,
}

class StatisticsV3GlobalInsight {
  const StatisticsV3GlobalInsight({
    required this.type,
    this.familyName,
    this.momentLabel,
    this.momentSlot,
  });

  final StatisticsV3GlobalInsightType type;
  final String? familyName;
  final String? momentLabel;
  final StatisticsV3BestMomentSlot? momentSlot;
}
