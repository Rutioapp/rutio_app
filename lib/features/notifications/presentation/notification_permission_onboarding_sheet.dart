import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../application/notification_permission_controller.dart';
import '../domain/notification_permission_status.dart';

enum NotificationPermissionOnboardingOutcome {
  granted,
  denied,
  permanentlyDenied,
  softDeclined,
}

Future<NotificationPermissionOnboardingOutcome>
    showNotificationPermissionOnboardingSheet(
  BuildContext context, {
  required NotificationPermissionController controller,
}) async {
  final result =
      await showModalBottomSheet<NotificationPermissionOnboardingOutcome>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.24),
    builder: (sheetContext) => _NotificationPermissionOnboardingSheet(
      controller: controller,
    ),
  );

  if (result != null) {
    return result;
  }

  await controller.markSoftDeclined();
  return NotificationPermissionOnboardingOutcome.softDeclined;
}

class _NotificationPermissionOnboardingSheet extends StatefulWidget {
  const _NotificationPermissionOnboardingSheet({
    required this.controller,
  });

  final NotificationPermissionController controller;

  @override
  State<_NotificationPermissionOnboardingSheet> createState() =>
      _NotificationPermissionOnboardingSheetState();
}

class _NotificationPermissionOnboardingSheetState
    extends State<_NotificationPermissionOnboardingSheet> {
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxWidth = MediaQuery.sizeOf(context).width > 500 ? 520.0 : 420.0;

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
                      CupertinoIcons.bell_fill,
                      color: isDark
                          ? CupertinoColors.activeBlue
                          : const Color(0xFFBE8C52),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.notificationPermissionTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.notificationPermissionBody,
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
                      onPressed: _isRequesting ? null : _handlePrimaryAction,
                      child: _isRequesting
                          ? const CupertinoActivityIndicator()
                          : Text(l10n.notificationPermissionPrimaryAction),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CupertinoButton(
                    onPressed: _isRequesting ? null : _handleSecondaryAction,
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

  Future<void> _handlePrimaryAction() async {
    if (_isRequesting) return;

    setState(() => _isRequesting = true);
    await widget.controller.markPostLoginPromptShown();
    final granted = await widget.controller.requestSystemPermission();
    if (!mounted) return;

    if (granted) {
      Navigator.of(context).pop(NotificationPermissionOnboardingOutcome.granted);
      return;
    }

    final effectiveStatus = await widget.controller.getEffectiveStatus();
    if (!mounted) return;

    if (effectiveStatus == NotificationPermissionStatus.permanentlyDenied) {
      Navigator.of(context).pop(
        NotificationPermissionOnboardingOutcome.permanentlyDenied,
      );
      return;
    }

    Navigator.of(context).pop(NotificationPermissionOnboardingOutcome.denied);
  }

  Future<void> _handleSecondaryAction() async {
    await widget.controller.markSoftDeclined();
    if (!mounted) return;
    Navigator.of(context).pop(NotificationPermissionOnboardingOutcome.softDeclined);
  }
}
