abstract final class CrashReportingKeys {
  static const authState = 'auth_state';
  static const premiumStatus = 'premium_status';
  static const currentFeature = 'current_feature';
  static const onboardingState = 'onboarding_state';
  static const appVersion = 'app_version';
  static const buildNumber = 'build_number';
  static const platform = 'platform';
}

abstract final class CrashReportingValues {
  static const anonymous = 'anonymous';
  static const authenticated = 'authenticated';
  static const unknown = 'unknown';
  static const free = 'free';
  static const trial = 'trial';
  static const premium = 'premium';
  static const expired = 'expired';
}

abstract final class CrashReportingReasons {
  static const bootstrapFailure = 'bootstrap_failure';
  static const supabaseInitializationFailure =
      'supabase_initialization_failure';
  static const revenueCatInitializationFailure =
      'revenuecat_initialization_failure';
  static const revenueCatIdentityFailure = 'revenuecat_identity_failure';
}
