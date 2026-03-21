import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../permissions/app_permission.dart';
import '../permissions/permission_service.dart';

enum NotificationPermissionStatus {
  notDetermined,
  denied,
  restricted,
  permanentlyDenied,
  provisional,
  authorized,
  unknown,
}

class NotificationPermissionResult {
  const NotificationPermissionResult({
    required this.status,
  });

  final NotificationPermissionStatus status;

  bool get isAuthorized =>
      status == NotificationPermissionStatus.authorized ||
      status == NotificationPermissionStatus.provisional;

  bool get canRequest =>
      status != NotificationPermissionStatus.restricted &&
      status != NotificationPermissionStatus.permanentlyDenied;

  bool get shouldOpenSettings =>
      status == NotificationPermissionStatus.denied ||
      status == NotificationPermissionStatus.restricted ||
      status == NotificationPermissionStatus.permanentlyDenied;
}

class NotificationPermissionService {
  NotificationPermissionService({
    required FlutterLocalNotificationsPlugin plugin,
    PermissionService? permissionService,
  })  : _plugin = plugin,
        _permissionService = permissionService ?? const PermissionService();

  static const MethodChannel _channel =
      MethodChannel('rutio/notification_permission');

  final FlutterLocalNotificationsPlugin _plugin;
  final PermissionService _permissionService;

  Future<NotificationPermissionResult> checkStatus() async {
    if (Platform.isIOS) {
      final nativeStatus = await _getNativeAppleStatus();
      if (nativeStatus != null) {
        return NotificationPermissionResult(status: nativeStatus);
      }
    }

    final permissionResult =
        await _permissionService.check(AppPermission.notifications);
    return _mapFromAppPermission(permissionResult);
  }

  Future<NotificationPermissionResult> requestPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) async {
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(
        alert: alert,
        badge: badge,
        sound: sound,
      );
      return checkStatus();
    }

    final permissionResult =
        await _permissionService.request(AppPermission.notifications);
    return _mapFromAppPermission(permissionResult);
  }

  Future<NotificationPermissionResult> ensurePermission() async {
    final current = await checkStatus();
    if (current.isAuthorized || !current.canRequest) {
      return current;
    }

    return requestPermission();
  }

  Future<bool> openSettings() {
    return _permissionService.openSettings();
  }

  Future<NotificationPermissionStatus?> _getNativeAppleStatus() async {
    try {
      final rawStatus =
          await _channel.invokeMethod<String>('getNotificationPermissionStatus');
      return _mapFromNative(rawStatus);
    } on PlatformException {
      return null;
    }
  }

  NotificationPermissionResult _mapFromAppPermission(
    AppPermissionResult result,
  ) {
    switch (result.status) {
      case AppPermissionStatus.notDetermined:
        return const NotificationPermissionResult(
          status: NotificationPermissionStatus.notDetermined,
        );
      case AppPermissionStatus.denied:
        return const NotificationPermissionResult(
          status: NotificationPermissionStatus.denied,
        );
      case AppPermissionStatus.restricted:
        return const NotificationPermissionResult(
          status: NotificationPermissionStatus.restricted,
        );
      case AppPermissionStatus.limited:
      case AppPermissionStatus.provisional:
        return const NotificationPermissionResult(
          status: NotificationPermissionStatus.provisional,
        );
      case AppPermissionStatus.permanentlyDenied:
        return const NotificationPermissionResult(
          status: NotificationPermissionStatus.permanentlyDenied,
        );
      case AppPermissionStatus.granted:
        return const NotificationPermissionResult(
          status: NotificationPermissionStatus.authorized,
        );
      case AppPermissionStatus.unknown:
        return const NotificationPermissionResult(
          status: NotificationPermissionStatus.unknown,
        );
    }
  }

  NotificationPermissionStatus? _mapFromNative(String? status) {
    switch (status) {
      case 'notDetermined':
        return NotificationPermissionStatus.notDetermined;
      case 'denied':
        return NotificationPermissionStatus.denied;
      case 'authorized':
        return NotificationPermissionStatus.authorized;
      case 'provisional':
        return NotificationPermissionStatus.provisional;
      case 'restricted':
        return NotificationPermissionStatus.restricted;
      case 'permanentlyDenied':
        return NotificationPermissionStatus.permanentlyDenied;
      case 'unknown':
        return NotificationPermissionStatus.unknown;
      default:
        return null;
    }
  }
}
