import '../../features/premium/domain/premium_access_policy.dart';
import '../../features/premium/presentation/premium_navigation.dart';
import '../../features/statistics/presentation/v3/models/statistics_v3_period.dart';
import '../../features/onboarding/domain/models/onboarding_types.dart';

abstract final class ProductAnalyticsEvents {
  static const onboardingStarted = 'onboarding_started';
  static const onboardingStepViewed = 'onboarding_step_viewed';
  static const onboardingStepCompleted = 'onboarding_step_completed';
  static const onboardingCompleted = 'onboarding_completed';
  static const habitCreated = 'habit_created';
  static const habitEdited = 'habit_edited';
  static const habitCompleted = 'habit_completed';
  static const habitCompletionUndone = 'habit_completion_undone';
  static const habitArchived = 'habit_archived';
  static const journalEntryCreated = 'journal_entry_created';
  static const statisticsViewed = 'statistics_viewed';
  static const perHabitStatisticsViewed = 'per_habit_statistics_viewed';
  static const weeklyReportViewed = 'weekly_report_viewed';
  static const weeklyReportHistoryViewed = 'weekly_report_history_viewed';
  static const premiumFeatureBlocked = 'premium_feature_blocked';
  static const paywallViewed = 'paywall_viewed';
  static const paywallDismissed = 'paywall_dismissed';
  static const purchaseCompleted = 'purchase_completed';
  static const purchaseCancelled = 'purchase_cancelled';
  static const restoreCompleted = 'restore_completed';
  static const signupCompleted = 'signup_completed';
  static const loginCompleted = 'login_completed';
  static const logoutCompleted = 'logout_completed';
}

String analyticsPremiumFeature(PremiumFeature feature) => switch (feature) {
      PremiumFeature.weeklyStatistics => 'weekly_statistics',
      PremiumFeature.monthlyStatistics => 'monthly_statistics',
      PremiumFeature.annualStatistics => 'annual_statistics',
      PremiumFeature.perHabitStatistics => 'per_habit_statistics',
      PremiumFeature.weeklyReport => 'weekly_report',
    };

String analyticsUpgradeSource(PremiumUpgradeSource source) => switch (source) {
      PremiumUpgradeSource.weeklyStatistics => 'weekly_statistics',
      PremiumUpgradeSource.monthlyStatistics => 'monthly_statistics',
      PremiumUpgradeSource.annualStatistics => 'annual_statistics',
      PremiumUpgradeSource.perHabitStatistics => 'per_habit_statistics',
      PremiumUpgradeSource.weeklyReport => 'weekly_report',
      PremiumUpgradeSource.settings => 'settings',
    };

String analyticsStatisticsPeriod(StatisticsV3Period period) => switch (period) {
      StatisticsV3Period.day => 'daily',
      StatisticsV3Period.week => 'weekly',
      StatisticsV3Period.month => 'monthly',
      StatisticsV3Period.year => 'annual',
    };

String analyticsOnboardingStep(OnboardingStep step) => switch (step) {
      OnboardingStep.name => 'name',
      OnboardingStep.goals => 'goals',
      OnboardingStep.pace => 'pace',
      OnboardingStep.recommendations => 'recommendations',
      OnboardingStep.habit => 'habit',
      OnboardingStep.reminder => 'reminder',
      OnboardingStep.preview => 'preview',
      OnboardingStep.auth || OnboardingStep.emailConfirmation => 'auth',
      OnboardingStep.resolvingAccount ||
      OnboardingStep.finalizing =>
        'preparation',
    };

String analyticsHabitType(Object? value) {
  return (value ?? '').toString().toLowerCase() == 'count' ? 'count' : 'check';
}

String? analyticsTargetPeriod(Object? schedule) {
  if (schedule is Map &&
      schedule['type']?.toString().toLowerCase() == 'weekly') {
    return 'weekly';
  }
  return 'daily';
}
