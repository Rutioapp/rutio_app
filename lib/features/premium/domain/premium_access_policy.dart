import 'premium_access.dart';

enum PremiumFeature {
  weeklyStatistics,
  monthlyStatistics,
  annualStatistics,
  perHabitStatistics,
  weeklyReport,
}

class PremiumAccessPolicy {
  const PremiumAccessPolicy._();

  static bool canAccess(
    PremiumFeature feature,
    PremiumAccessState state,
  ) {
    return state.isPremium;
  }
}
