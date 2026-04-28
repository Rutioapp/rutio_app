import 'package:shared_preferences/shared_preferences.dart';

import '../domain/notification_permission_status.dart';

class NotificationPermissionPreferences {
  NotificationPermissionPreferences({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const String notificationPermissionPromptShownKey =
      'notificationPermissionPromptShown';
  static const String notificationPermissionInternalStatusKey =
      'notificationPermissionInternalStatus';
  static const String notificationPermissionLastUpdatedAtKey =
      'notificationPermissionLastUpdatedAt';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  Future<bool> isPostLoginPromptShown() async {
    final prefs = await _sharedPreferencesProvider();
    return prefs.getBool(notificationPermissionPromptShownKey) ?? false;
  }

  Future<void> setPostLoginPromptShown(bool shown) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.setBool(notificationPermissionPromptShownKey, shown);
    await _setLastUpdatedAt(prefs, DateTime.now().toUtc());
  }

  Future<NotificationPermissionStatus> getInternalStatus() async {
    final prefs = await _sharedPreferencesProvider();
    final raw = prefs.getString(notificationPermissionInternalStatusKey);
    return notificationPermissionStatusFromStorage(raw);
  }

  Future<void> setInternalStatus(NotificationPermissionStatus status) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.setString(notificationPermissionInternalStatusKey, status.name);
    await _setLastUpdatedAt(prefs, DateTime.now().toUtc());
  }

  Future<void> _setLastUpdatedAt(
    SharedPreferences prefs,
    DateTime value,
  ) async {
    await prefs.setString(
      notificationPermissionLastUpdatedAtKey,
      value.toIso8601String(),
    );
  }
}
