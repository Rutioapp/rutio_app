import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/notifications/notification_permission_service.dart'
    as core_permission;
import '../../../l10n/l10n.dart';
import '../../../services/notification_service.dart';
import '../application/notification_permission_controller.dart';

enum NotificationPermissionRecoveryOutcome {
  dismissed,
  granted,
  openedSettings,
}

Future<NotificationPermissionRecoveryOutcome>
    showNotificationPermissionRecoverySheet(
  BuildContext context, {
  required NotificationPermissionController controller,
  required core_permission.NotificationPermissionResult permissionResult,
}) async {
  final result =
      await showModalBottomSheet<NotificationPermissionRecoveryOutcome>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.24),
    builder: (sheetContext) => _NotificationPermissionRecoverySheet(
      controller: controller,
      permissionResult: permissionResult,
    ),
  );

  return result ?? NotificationPermissionRecoveryOutcome.dismissed;
}

class _NotificationPermissionRecoverySheet extends StatefulWidget {
  const _NotificationPermissionRecoverySheet({
    required this.controller,
    required this.permissionResult,
  });

  final NotificationPermissionController controller;
  final core_permission.NotificationPermissionResult permissionResult;

  @override
  State<_NotificationPermissionRecoverySheet> createState() =>
      _NotificationPermissionRecoverySheetState();
}

class _NotificationPermissionRecoverySheetState
    extends State<_NotificationPermissionRecoverySheet> {
  bool _isRunningPrimaryAction = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxWidth = MediaQuery.sizeOf(context).width > 500 ? 520.0 : 420.0;
    final canRequest = widget.permissionResult.canRequest;

    final backgroundColor =
        isDark ? const Color(0xFF1D1E20) : const Color(0xFFF8F6F2);
    final titleColor = isDark ? const Color(0xFFF3F4F5) : const Color(0xFF2D1E12);
    final bodyColor = isDark ? const Color(0xFFD4D7DC) : const Color(0xFF6C5B4D);
    final iconBackground =
        isDark ? const Color(0xFF2A2D31) : const Color(0xFFF1E8DB);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.bell_slash_fill,
                      color: isDark
                          ? CupertinoColors.activeBlue
                          : const Color(0xFFBE8C52),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.notificationPermissionDeniedTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.notificationPermissionDeniedBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: bodyColor,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _isRunningPrimaryAction
                          ? null
                          : () => _handlePrimaryAction(canRequest),
                      child: _isRunningPrimaryAction
                          ? const CupertinoActivityIndicator()
                          : Text(
                              canRequest
                                  ? l10n.notificationPermissionPrimaryAction
                                  : l10n.notificationPermissionOpenSettings,
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CupertinoButton(
                    onPressed: _isRunningPrimaryAction
                        ? null
                        : () => Navigator.of(context).pop(
                              NotificationPermissionRecoveryOutcome.dismissed,
                            ),
                    child: Text(
                      l10n.notificationPermissionSecondaryAction,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? CupertinoColors.systemGrey2
                            : const Color(0xFF6F635A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePrimaryAction(bool canRequest) async {
    if (_isRunningPrimaryAction) return;
    setState(() => _isRunningPrimaryAction = true);

    if (canRequest) {
      final granted = await widget.controller.requestSystemPermission();
      if (!mounted) return;
      Navigator.of(context).pop(
        granted
            ? NotificationPermissionRecoveryOutcome.granted
            : NotificationPermissionRecoveryOutcome.dismissed,
      );
      return;
    }

    await NotificationService.instance.openSettings();
    if (!mounted) return;
    Navigator.of(context).pop(NotificationPermissionRecoveryOutcome.openedSettings);
  }
}
