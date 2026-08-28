import '../../domain/personalized_notification_models.dart';

class NotificationLocalStorageScope {
  NotificationLocalStorageScope._();

  static const String rootPrefix = 'rutio_notifications_v2';
  static const String installIdKey = '$rootPrefix/install_id';

  static String scopedPrefix(NotificationScope scope) {
    final install = Uri.encodeComponent(scope.installId);
    final user = Uri.encodeComponent(scope.userId);
    return '$rootPrefix/installations/$install/users/$user';
  }

  static String preferencesKey(NotificationScope scope) =>
      '${scopedPrefix(scope)}/preferences';

  static String manifestKey(NotificationScope scope) =>
      '${scopedPrefix(scope)}/manifest';

  static String historyKey(NotificationScope scope) =>
      '${scopedPrefix(scope)}/history';
}
