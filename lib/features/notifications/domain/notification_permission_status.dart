enum NotificationPermissionStatus {
  unknown,
  softDeclined,
  granted,
  denied,
  permanentlyDenied,
}

NotificationPermissionStatus notificationPermissionStatusFromStorage(
  String? raw,
) {
  switch (raw) {
    case 'softDeclined':
      return NotificationPermissionStatus.softDeclined;
    case 'granted':
      return NotificationPermissionStatus.granted;
    case 'denied':
      return NotificationPermissionStatus.denied;
    case 'permanentlyDenied':
      return NotificationPermissionStatus.permanentlyDenied;
    case 'unknown':
    default:
      return NotificationPermissionStatus.unknown;
  }
}
