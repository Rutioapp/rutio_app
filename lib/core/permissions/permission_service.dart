import 'dart:io';

import 'package:permission_handler/permission_handler.dart' as permission_handler;

import 'app_permission.dart';
import 'permission_status_mapper.dart';

class PermissionService {
  const PermissionService();

  Future<AppPermissionResult> check(AppPermission permission) async {
    final resolvedPermission = _resolvePermission(permission);
    if (resolvedPermission == null) {
      return AppPermissionResult(
        permission: permission,
        status: AppPermissionStatus.granted,
      );
    }

    final status = await resolvedPermission.status;
    return AppPermissionResult(
      permission: permission,
      status: PermissionStatusMapper.map(status),
    );
  }

  Future<AppPermissionResult> request(AppPermission permission) async {
    final resolvedPermission = _resolvePermission(permission);
    if (resolvedPermission == null) {
      return AppPermissionResult(
        permission: permission,
        status: AppPermissionStatus.granted,
      );
    }

    final status = await resolvedPermission.request();
    return AppPermissionResult(
      permission: permission,
      status: PermissionStatusMapper.map(status),
    );
  }

  Future<bool> openSettings() {
    return permission_handler.openAppSettings();
  }

  permission_handler.Permission? _resolvePermission(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return permission_handler.Permission.camera;
      case AppPermission.photos:
        if (Platform.isIOS) {
          return permission_handler.Permission.photos;
        }
        return null;
      case AppPermission.notifications:
        if (Platform.isIOS || Platform.isAndroid) {
          return permission_handler.Permission.notification;
        }
        return null;
    }
  }
}
