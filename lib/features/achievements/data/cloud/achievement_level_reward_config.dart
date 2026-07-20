class AchievementLevelRewardConfig {
  const AchievementLevelRewardConfig._();

  static const String enabledEnvKey =
      'CLOUD_ACHIEVEMENT_LEVEL_REWARDS_ENABLED';

  static bool get isEnabled =>
      const bool.fromEnvironment(enabledEnvKey, defaultValue: false);

  static bool resolveEnabled({bool? override}) {
    return override ?? isEnabled;
  }
}
