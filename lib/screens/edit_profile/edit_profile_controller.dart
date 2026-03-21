import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/permissions/app_permission.dart';
import '../../core/permissions/permission_guard.dart';
import '../../l10n/l10n.dart';
import '../../stores/user_state_store.dart';
import 'services/avatar_service.dart';

class EditProfileController {
  final formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final goalCtrl = TextEditingController();

  final hasChanges = ValueNotifier<bool>(false);
  final saving = ValueNotifier<bool>(false);
  final avatarPath = ValueNotifier<String>('');

  bool _initialized = false;
  final ImagePicker _picker = ImagePicker();
  final AvatarService _avatarService = const AvatarService();
  final PermissionGuard _permissionGuard = PermissionGuard();

  void dispose() {
    nameCtrl.dispose();
    bioCtrl.dispose();
    goalCtrl.dispose();
    hasChanges.dispose();
    saving.dispose();
    avatarPath.dispose();
  }

  void ensureInitFromStore(UserStateStore store) {
    if (_initialized) return;
    final state = store.state;
    if (state == null) return;

    final userState = (state['userState'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final profile = (userState['profile'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    nameCtrl.text = (profile['displayName'] ?? '').toString();
    bioCtrl.text = (profile['bio'] ?? '').toString();
    goalCtrl.text = (profile['goal'] ?? '').toString();
    avatarPath.value = (profile['avatarUrl'] ?? '').toString();

    nameCtrl.addListener(markChanged);
    bioCtrl.addListener(markChanged);
    goalCtrl.addListener(markChanged);

    _initialized = true;
  }

  void markChanged() {
    if (!hasChanges.value) hasChanges.value = true;
  }

  Future<void> pickAvatar({
    required BuildContext context,
    required ImageSource source,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final permission = source == ImageSource.camera
        ? AppPermission.camera
        : AppPermission.photos;

    try {
      final permissionResult = await _permissionGuard.ensureGranted(permission);
      if (!permissionResult.isGranted) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              permissionResult.shouldOpenSettings
                  ? l10n.permissionSettingsMessageFor(permission)
                  : l10n.permissionMessageFor(permission),
            ),
            behavior: SnackBarBehavior.floating,
            action: permissionResult.shouldOpenSettings
                ? SnackBarAction(
                    label: l10n.commonOpenSettings,
                    onPressed: _permissionGuard.openSettings,
                  )
                : null,
          ),
        );
        return;
      }

      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked == null) return;
      if (!context.mounted) return;

      final File saved = await _avatarService.pickCropAndPersist(
        context: context,
        pickedPath: picked.path,
      );

      avatarPath.value = saved.path;
      hasChanges.value = true;
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.editProfileImageSelectionError('$e')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void removeAvatar() {
    avatarPath.value = '';
    hasChanges.value = true;
  }

  Future<void> save({
    required BuildContext context,
    required UserStateStore store,
  }) async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = context.l10n;

    saving.value = true;
    try {
      final avatarUrl = avatarPath.value.trim();

      await store.updateProfileFields(
        displayName: nameCtrl.text.trim(),
        bio: bioCtrl.text.trim(),
        goal: goalCtrl.text.trim(),
        avatarUrl: avatarUrl,
      );

      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(l10n.editProfileSaveSuccess),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      navigator.pop();
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l10n.editProfileSaveError('$e')),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      saving.value = false;
    }
  }

  Future<bool> onWillPop(BuildContext context) async {
    if (!hasChanges.value) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.editProfileDiscardChangesTitle),
        content: Text(context.l10n.editProfileDiscardChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.l10n.editProfileDiscardChangesAction),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }
}
