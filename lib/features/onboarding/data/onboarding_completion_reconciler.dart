import '../../../core/notifications/notification_permission_service.dart';
import '../../../services/notification_service.dart';
import '../../../stores/user_state_store.dart';
import '../domain/auth/onboarding_auth_contracts.dart';
import 'package:flutter/foundation.dart';
import '../../../core/diagnostics/onboarding_runtime_trace.dart';

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
    final habitId = result.habitId?.trim();
    final habitPresent =
        result.preparedHabitApplied && habitId != null && habitId.isNotEmpty;
    _trace('event=start', intent, habitPresent: habitPresent);
    try {
      final reminder = intent.reminder;
      final reminderEnabled = reminder?['enabled'] == true;
      if (habitPresent && reminderEnabled) {
        _trace(
          'event=reminder_reconcile_start',
          intent,
          habitPresent: habitPresent,
        );
        try {
          final permission = await _notificationService.checkPermissionStatus();
          if (permission.isAuthorized) {
            final selectedTime = reminder?['selectedTime'];
            if (selectedTime is! Map) {
              throw const FormatException(
                'Enabled reminder has no selected time.',
              );
            }
            final hour = _asInt(selectedTime['hour']);
            final minute = _asInt(selectedTime['minute']);
            if (hour == null || minute == null) {
              throw const FormatException('Enabled reminder has invalid time.');
            }
            final scheduled =
                await _notificationService.scheduleHabitDailyReminder(
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
              permission.status ==
                  NotificationPermissionStatus.permanentlyDenied ||
              permission.status == NotificationPermissionStatus.notDetermined) {
            // Remote completion remains authoritative. No permission prompt is
            // allowed during onboarding completion recovery.
          } else {
            throw StateError('Notification permission status is unavailable.');
          }
        } catch (error) {
          _trace(
            'event=reminder_reconcile_error error=${error.runtimeType}',
            intent,
            habitPresent: habitPresent,
          );
          rethrow;
        }
        _trace(
          'event=reminder_reconcile_success',
          intent,
          habitPresent: habitPresent,
        );
      }
      _trace('event=local_done_start', intent, habitPresent: habitPresent);
      await _userStateStore.setOnboardingDone(true);
      OnboardingRuntimeTrace.log(
        'ONBOARDING_HANDOFF',
        'event=onboarding_done_set operationId=${_shortId(intent.operationId)} '
            'userId=${_shortId(intent.authenticatedUserId)} draftPresent=true',
      );
      _trace('event=local_done_success', intent, habitPresent: habitPresent);
    } catch (error) {
      _trace(
        'event=error error=${error.runtimeType}',
        intent,
        habitPresent: habitPresent,
      );
      rethrow;
    }
  }

  void _trace(
    String event,
    OnboardingCompletionIntent intent, {
    required bool habitPresent,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[ONBOARDING_CLEANUP] $event '
      'op=${_shortId(intent.operationId)} '
      'user=${_shortId(intent.authenticatedUserId)} '
      'habitPresent=$habitPresent',
    );
  }

  static String _shortId(String value) =>
      value.length <= 8 ? value : value.substring(0, 8);

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value % 1 == 0) return value.toInt();
    return int.tryParse((value ?? '').toString());
  }
}
