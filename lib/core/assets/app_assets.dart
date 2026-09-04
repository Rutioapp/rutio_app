abstract final class AppAssets {
  static const String gameConfig = 'assets/config/game_config.json';
  static const String habitsCatalog = 'assets/data/habits_catalog.json';
  static const String notificationTemplateCatalog =
      'assets/config/notification_message_catalog.v1.json';
  static const String userStateTemplate =
      'assets/templates/user_state_template.json';

  static String completedDayPhraseFallback(String locale) =>
      'assets/phrase_fallback/$locale.json';
}
