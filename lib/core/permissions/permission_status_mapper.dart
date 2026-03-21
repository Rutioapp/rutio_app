import 'package:permission_handler/permission_handler.dart' as permission_handler;

import 'app_permission.dart';

class PermissionStatusMapper {
  const PermissionStatusMapper._();

  static AppPermissionStatus map(
    permission_handler.PermissionStatus status,
  ) {
    switch (status) {
      case permission_handler.PermissionStatus.denied:
        return AppPermissionStatus.denied;
      case permission_handler.PermissionStatus.restricted:
        return AppPermissionStatus.restricted;
      case permission_handler.PermissionStatus.permanentlyDenied:
        return AppPermissionStatus.permanentlyDenied;
      case permission_handler.PermissionStatus.limited:
        return AppPermissionStatus.limited;
      case permission_handler.PermissionStatus.provisional:
        return AppPermissionStatus.provisional;
      case permission_handler.PermissionStatus.granted:
        return AppPermissionStatus.granted;
    }
  }
}
