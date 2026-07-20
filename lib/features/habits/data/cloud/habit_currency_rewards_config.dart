class HabitCurrencyRewardsConfig {
  const HabitCurrencyRewardsConfig._();

  static const String enabledEnvKey = 'CLOUD_HABIT_REWARDS_ENABLED';

  static bool get isEnabled =>
      const bool.fromEnvironment(enabledEnvKey, defaultValue: false);

  static bool resolveEnabled({bool? override}) {
    return override ?? isEnabled;
  }
}
