import 'package:flutter/foundation.dart';
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
  static const String _logPrefix = '[NotificationPermissionOnboarding]';

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('$_logPrefix $message');
  }

  Future<bool> isPostLoginPromptShown() async {
    final prefs = await _sharedPreferencesProvider();
    final value = prefs.getBool(notificationPermissionPromptShownKey) ?? false;
    _log('prefs.read: promptShown=$value');
    return value;
  }

  Future<void> setPostLoginPromptShown(bool shown) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.setBool(notificationPermissionPromptShownKey, shown);
    await _setLastUpdatedAt(prefs, DateTime.now().toUtc());
    _log('prefs.write: promptShown=$shown');
  }

  Future<NotificationPermissionStatus> getInternalStatus() async {
    final prefs = await _sharedPreferencesProvider();
    final raw = prefs.getString(notificationPermissionInternalStatusKey);
    final parsed = notificationPermissionStatusFromStorage(raw);
    _log('prefs.read: internalStatusRaw=$raw parsed=$parsed');
    return parsed;
  }

  Future<void> setInternalStatus(NotificationPermissionStatus status) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.setString(notificationPermissionInternalStatusKey, status.name);
    await _setLastUpdatedAt(prefs, DateTime.now().toUtc());
    _log('prefs.write: internalStatus=$status');
  }

  Future<void> _setLastUpdatedAt(
    SharedPreferences prefs,
    DateTime value,
  ) async {
    await prefs.setString(
      notificationPermissionLastUpdatedAtKey,
      value.toIso8601String(),
    );
    _log('prefs.write: lastUpdatedAt=${value.toIso8601String()}');
  }
}
