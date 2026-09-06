import '../../../core/notifications/notification_permission_service.dart';
import '../../../services/notification_service.dart';
import '../domain/models/onboarding_types.dart';

/// Application boundary used by the coordinator. The presentation layer never
/// reaches the native notification plugin directly.
abstract interface class OnboardingReminderPermissionGateway {
  Future<ReminderPermissionState> requestPermission();
}

class AppOnboardingReminderPermissionGateway
    implements OnboardingReminderPermissionGateway {
  AppOnboardingReminderPermissionGateway({NotificationService? service})
      : _service = service ?? NotificationService.instance;

  final NotificationService _service;

  @override
  Future<ReminderPermissionState> requestPermission() async {
    final result = await _service.requestPermissionFlow();
    return mapPermissionResult(result);
  }

  static ReminderPermissionState mapPermissionResult(
    NotificationPermissionResult result,
  ) {
    switch (result.status) {
      case NotificationPermissionStatus.authorized:
        return ReminderPermissionState.authorized;
      case NotificationPermissionStatus.provisional:
        return ReminderPermissionState.provisional;
      case NotificationPermissionStatus.denied:
        return ReminderPermissionState.denied;
      case NotificationPermissionStatus.restricted:
      case NotificationPermissionStatus.permanentlyDenied:
        return ReminderPermissionState.restricted;
      case NotificationPermissionStatus.notDetermined:
      case NotificationPermissionStatus.unknown:
        return ReminderPermissionState.notRequested;
    }
  }
}
