import 'notification_native_models.dart';
import 'personalized_notification_models.dart';

abstract class NotificationNativeGateway {
  Future<NotificationSchedulingCapabilities> getSchedulingCapabilities();

  Future<List<NativePendingNotification>> pendingNotifications();

  Future<void> scheduleNotification({
    required int platformId,
    required String title,
    required String body,
    required String payload,
    required NotificationScheduleSpec scheduleSpec,
    required String effectiveTimezoneId,
  });

  Future<void> cancelNotification(int platformId);
}
