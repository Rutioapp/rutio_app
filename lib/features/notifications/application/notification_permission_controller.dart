import 'package:flutter/foundation.dart';

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

  static const String _logPrefix = '[NotificationPermissionOnboarding]';

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('$_logPrefix $message');
  }

  Future<core_permission.NotificationPermissionResult>
      getSystemPermissionResult() async {
    final result = await _notificationService.checkPermissionStatus();
    _log(
      'getSystemPermissionResult(): status=${result.status.name}, '
      'isAuthorized=${result.isAuthorized}, canRequest=${result.canRequest}',
    );
    return result;
  }

  Future<bool> areNotificationsAllowed() async {
    final systemResult = await getSystemPermissionResult();
    if (systemResult.isAuthorized) {
      await _preferences.setInternalStatus(NotificationPermissionStatus.granted);
    }
    _log('areNotificationsAllowed(): ${systemResult.isAuthorized}');
    return systemResult.isAuthorized;
  }

  Future<NotificationPermissionStatus> getEffectiveStatus() async {
    _log('getEffectiveStatus(): start');
    final systemResult = await getSystemPermissionResult();
    final systemStatus = _mapSystemResult(systemResult);
    _log(
      'getEffectiveStatus(): system permission status detected='
      '${systemResult.status.name}, isAuthorized=${systemResult.isAuthorized}, '
      'canRequest=${systemResult.canRequest}, mapped=$systemStatus',
    );

    if (systemStatus == NotificationPermissionStatus.granted) {
      await _preferences.setInternalStatus(NotificationPermissionStatus.granted);
      _log(
        'getEffectiveStatus(): effectiveStatus=granted (reason: system granted)',
      );
      return NotificationPermissionStatus.granted;
    }

    if (systemStatus == NotificationPermissionStatus.permanentlyDenied) {
      await _preferences.setInternalStatus(
        NotificationPermissionStatus.permanentlyDenied,
      );
      _log(
        'getEffectiveStatus(): effectiveStatus=permanentlyDenied '
        '(reason: system permanentlyDenied/restricted)',
      );
      return NotificationPermissionStatus.permanentlyDenied;
    }

    if (systemStatus == NotificationPermissionStatus.denied) {
      await _preferences.setInternalStatus(NotificationPermissionStatus.denied);
      _log(
        'getEffectiveStatus(): effectiveStatus=denied (reason: system denied)',
      );
      return NotificationPermissionStatus.denied;
    }

    final internalStatus = await _preferences.getInternalStatus();
    _log(
      'getEffectiveStatus(): effectiveStatus=$internalStatus '
      '(reason: system ambiguous -> fallback to internalStatus)',
    );
    return internalStatus;
  }

  Future<bool> shouldShowPostLoginPrompt() async {
    _log('shouldShowPostLoginPrompt(): start');
    final promptShown = await _preferences.isPostLoginPromptShown();
    final internalStatus = await _preferences.getInternalStatus();
    final systemResult = await getSystemPermissionResult();
    final systemStatus = _mapSystemResult(systemResult);

    final hasInternalFinalStatus = internalStatus ==
            NotificationPermissionStatus.granted ||
        internalStatus == NotificationPermissionStatus.denied ||
        internalStatus == NotificationPermissionStatus.permanentlyDenied;

    var shouldShow = false;
    var reason = '';

    if (promptShown) {
      reason = 'promptShown=true';
    } else if (internalStatus == NotificationPermissionStatus.softDeclined) {
      reason = 'internalStatus=softDeclined';
    } else if (hasInternalFinalStatus) {
      reason = 'internalStatus is final ($internalStatus)';
    } else {
      shouldShow = true;
      reason = 'promptShown=false and internalStatus=$internalStatus '
          '(systemStatus=$systemStatus is treated as non-blocking for onboarding)';
    }

    _log(
      'shouldShowPostLoginPrompt(): result=$shouldShow, promptShown=$promptShown, '
      'internalStatus=$internalStatus, system permission status detected='
      '${systemResult.status.name}, mappedSystemStatus=$systemStatus, '
      'reason=$reason',
    );
    return shouldShow;
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

    final systemStatus = await getSystemPermissionResult();
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
