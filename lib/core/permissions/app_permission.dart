enum AppPermission {
  camera,
  photos,
  notifications,
}

enum AppPermissionStatus {
  notDetermined,
  denied,
  restricted,
  limited,
  permanentlyDenied,
  provisional,
  granted,
  unknown,
}

class AppPermissionResult {
  const AppPermissionResult({
    required this.permission,
    required this.status,
  });

  final AppPermission permission;
  final AppPermissionStatus status;

  bool get isGranted =>
      status == AppPermissionStatus.granted ||
      status == AppPermissionStatus.limited ||
      status == AppPermissionStatus.provisional;

  bool get isLimited => status == AppPermissionStatus.limited;

  bool get canRequest =>
      status != AppPermissionStatus.restricted &&
      status != AppPermissionStatus.permanentlyDenied;

  bool get shouldOpenSettings =>
      status == AppPermissionStatus.restricted ||
      status == AppPermissionStatus.permanentlyDenied;
}
