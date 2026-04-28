import '../../../core/notifications/notification_permission_service.dart'
    as core_permission;
import '../../../services/notification_service.dart';
import '../data/notification_permission_preferences.dart';
import '../domain/notification_permission_status.dart';

class NotificationPermissionController {
  NotificationPermissionController({
    NotificationPermissionPreferences? preferences,
    NotificationService? notificationService,
  })  : _preferences = preferences ?? NotificationPermissionPreferences(),
        _notificationService = notificationService ?? NotificationService.instance;

  final NotificationPermissionPreferences _preferences;
  final NotificationService _notificationService;

  Future<NotificationPermissionStatus> getEffectiveStatus() async {
    final systemResult = await _notificationService.checkPermissionStatus();
    final systemStatus = _mapSystemResult(systemResult);

    if (systemStatus == NotificationPermissionStatus.granted) {
      await _preferences.setInternalStatus(NotificationPermissionStatus.granted);
      return NotificationPermissionStatus.granted;
    }

    if (systemStatus == NotificationPermissionStatus.permanentlyDenied) {
      await _preferences.setInternalStatus(
        NotificationPermissionStatus.permanentlyDenied,
      );
      return NotificationPermissionStatus.permanentlyDenied;
    }

    if (systemStatus == NotificationPermissionStatus.denied) {
      await _preferences.setInternalStatus(NotificationPermissionStatus.denied);
      return NotificationPermissionStatus.denied;
    }

    final internalStatus = await _preferences.getInternalStatus();
    return internalStatus;
  }

  Future<bool> shouldShowPostLoginPrompt() async {
    final shown = await _preferences.isPostLoginPromptShown();
    if (shown) return false;

    final status = await getEffectiveStatus();
    return status == NotificationPermissionStatus.unknown;
  }

  Future<void> markPostLoginPromptShown() {
    return _preferences.setPostLoginPromptShown(true);
  }

  Future<void> markSoftDeclined() async {
    await _preferences.setPostLoginPromptShown(true);
    await _preferences.setInternalStatus(NotificationPermissionStatus.softDeclined);
  }

  Future<bool> requestSystemPermission() async {
    final result = await _notificationService.requestPermissionFlow();
    final mapped = _mapSystemResult(result);
    await _preferences.setInternalStatus(mapped);
    return mapped == NotificationPermissionStatus.granted;
  }

  Future<bool> canScheduleNotifications() async {
    final status = await getEffectiveStatus();
    return status == NotificationPermissionStatus.granted;
  }

  Future<bool> ensureCanScheduleFromReminderFlow() async {
    final currentStatus = await getEffectiveStatus();
    if (currentStatus == NotificationPermissionStatus.granted) {
      return true;
    }
    if (currentStatus == NotificationPermissionStatus.softDeclined ||
        currentStatus == NotificationPermissionStatus.permanentlyDenied) {
      return false;
    }

    final systemStatus = await _notificationService.checkPermissionStatus();
    if (!_canRequestSystemPermission(systemStatus)) {
      await _preferences.setInternalStatus(
        NotificationPermissionStatus.permanentlyDenied,
      );
      return false;
    }

    return requestSystemPermission();
  }

  bool _canRequestSystemPermission(
    core_permission.NotificationPermissionResult result,
  ) {
    if (result.isAuthorized) return false;
    return result.canRequest;
  }

  NotificationPermissionStatus _mapSystemResult(
    core_permission.NotificationPermissionResult result,
  ) {
    if (result.isAuthorized) {
      return NotificationPermissionStatus.granted;
    }

    switch (result.status) {
      case core_permission.NotificationPermissionStatus.restricted:
      case core_permission.NotificationPermissionStatus.permanentlyDenied:
        return NotificationPermissionStatus.permanentlyDenied;
      case core_permission.NotificationPermissionStatus.denied:
        return NotificationPermissionStatus.denied;
      case core_permission.NotificationPermissionStatus.notDetermined:
      case core_permission.NotificationPermissionStatus.provisional:
      case core_permission.NotificationPermissionStatus.authorized:
      case core_permission.NotificationPermissionStatus.unknown:
        return NotificationPermissionStatus.unknown;
    }
  }
}
