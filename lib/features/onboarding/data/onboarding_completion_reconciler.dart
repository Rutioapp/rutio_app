import '../../../core/notifications/notification_permission_service.dart';
import '../../../services/notification_service.dart';
import '../../../stores/user_state_store.dart';
import '../domain/auth/onboarding_auth_contracts.dart';

/// Applies only post-transaction local effects. Permission is observed, never
/// requested here; a denied permission is a valid no-op for onboarding.
class LocalOnboardingCompletionReconciler
    implements OnboardingCompletionReconciler {
  LocalOnboardingCompletionReconciler({
    required UserStateStore userStateStore,
    NotificationService? notificationService,
  })  : _userStateStore = userStateStore,
        _notificationService =
            notificationService ?? NotificationService.instance;

  final UserStateStore _userStateStore;
  final NotificationService _notificationService;

  @override
  Future<void> reconcile({
    required OnboardingCompletionIntent intent,
    required OnboardingCompletionResult result,
  }) async {
    final reminder = intent.reminder;
    final reminderEnabled = reminder?['enabled'] == true;
    final habitId = result.habitId?.trim();
    if (result.preparedHabitApplied &&
        habitId != null &&
        habitId.isNotEmpty &&
        reminderEnabled) {
      final permission = await _notificationService.checkPermissionStatus();
      if (permission.isAuthorized) {
        final selectedTime = reminder?['selectedTime'];
        if (selectedTime is! Map) {
          throw const FormatException('Enabled reminder has no selected time.');
        }
        final hour = _asInt(selectedTime['hour']);
        final minute = _asInt(selectedTime['minute']);
        if (hour == null || minute == null) {
          throw const FormatException('Enabled reminder has invalid time.');
        }
        final scheduled = await _notificationService.scheduleHabitDailyReminder(
          habitId: habitId,
          hour: hour,
          minute: minute,
          body: 'Es hora de mantener tu hábito.',
        );
        if (!scheduled) {
          throw StateError('Local habit reminder scheduling failed.');
        }
      } else if (permission.status == NotificationPermissionStatus.denied ||
          permission.status == NotificationPermissionStatus.restricted ||
          permission.status == NotificationPermissionStatus.permanentlyDenied ||
          permission.status == NotificationPermissionStatus.notDetermined) {
        // Remote completion remains authoritative. No permission prompt is
        // allowed during completion recovery.
      } else {
        throw StateError('Notification permission status is unavailable.');
      }
    }
    await _userStateStore.setOnboardingDone(true);
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value % 1 == 0) return value.toInt();
    return int.tryParse((value ?? '').toString());
  }
}
