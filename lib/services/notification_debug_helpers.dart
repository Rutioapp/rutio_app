import 'notification_models.dart';
import 'notification_scheduler.dart';
import 'notification_types.dart';

class NotificationDebugHelpers {
  NotificationDebugHelpers(this._scheduler);

  final NotificationScheduler _scheduler;

  Future<void> showIn3Seconds() async {
    await _scheduler.showNow(
      id: RutioNotificationIds.debugImmediate,
      copy: const NotificationCopy(
        title: 'TEST Rutio',
        body: 'Si ves esto, permisos y canal estan OK.',
      ),
      payload: 'debug:immediate',
    );

    await _scheduler.scheduleOneTime(
      ScheduledNotificationRequest(
        id: RutioNotificationIds.debugScheduled,
        type: RutioNotificationType.dailyMotivation,
        copy: const NotificationCopy(
          title: 'TEST Rutio (3s)',
          body: 'Si ves esto, el scheduling tambien esta OK.',
        ),
        scheduledFor: DateTime.now().add(const Duration(seconds: 3)),
        payload: 'debug:scheduled',
      ),
    );
  }

  Future<void> scheduleInSeconds(int seconds) {
    return _scheduler.scheduleOneTime(
      ScheduledNotificationRequest(
        id: RutioNotificationIds.debugAlarmBase + seconds,
        type: RutioNotificationType.dailyMotivation,
        copy: NotificationCopy(
          title: 'TEST Rutio (${seconds}s)',
          body: 'Test programado a +${seconds}s.',
        ),
        scheduledFor: DateTime.now().add(Duration(seconds: seconds)),
        payload: 'debug:$seconds',
      ),
    );
  }

  Future<List<String>> pendingSummary() async {
    final pending = await _scheduler.pendingRequests();
    return pending
        .map(
          (request) =>
              'id=${request.id} title=${request.title} payload=${request.payload}',
        )
        .toList(growable: false);
  }
}
