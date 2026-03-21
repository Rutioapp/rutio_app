import 'app_permission.dart';
import 'permission_service.dart';

class PermissionGuard {
  PermissionGuard({
    PermissionService? permissionService,
  }) : _permissionService = permissionService ?? const PermissionService();

  final PermissionService _permissionService;

  Future<AppPermissionResult> ensureGranted(AppPermission permission) async {
    final current = await _permissionService.check(permission);
    if (current.isGranted || !current.canRequest) {
      return current;
    }

    return _permissionService.request(permission);
  }

  Future<bool> openSettings() {
    return _permissionService.openSettings();
  }
}
