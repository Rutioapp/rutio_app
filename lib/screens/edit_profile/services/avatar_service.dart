import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/identity/user_namespace.dart';
import '../../../devtools/rutio_runtime_profile.dart';
import '../../../l10n/l10n.dart';

class AvatarService {
  const AvatarService();

  Future<File> pickCropAndPersist({
    required BuildContext context,
    required String pickedPath,
    required String userId,
  }) async {
    final cropped =
        await _cropToCircle(context: context, sourcePath: pickedPath);
    final picked = cropped ?? File(pickedPath);
    final saved = await persistAvatarFileForUser(
      source: picked,
      userId: userId,
    );
    return saved;
  }

  Future<File?> _cropToCircle({
    required BuildContext context,
    required String sourcePath,
  }) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        maxWidth: 800,
        maxHeight: 800,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 92,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: context.l10n.editProfileCropTitle,
            lockAspectRatio: true,
            hideBottomControls: true,
            cropStyle: CropStyle.rectangle,
            aspectRatioPresets: const [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: context.l10n.editProfileCropTitle,
            aspectRatioLockEnabled: true,
            cropStyle: CropStyle.rectangle,
            aspectRatioPresets: const [CropAspectRatioPreset.square],
          ),
          WebUiSettings(context: context),
        ],
      );

      if (cropped == null) return null;
      return File(cropped.path);
    } catch (_) {
      return null;
    }
  }

  Future<File> persistAvatarFileForUser({
    required File source,
    required String userId,
    Directory? baseDirectory,
    DateTime? timestamp,
    String? environmentId,
  }) async {
    final dir = baseDirectory ?? await getApplicationDocumentsDirectory();
    final avatarDir = Directory(
      p.join(
        dir.path,
        'avatars',
        _safeEnvironmentNamespace(
          environmentId ?? RutioRuntimeProfile.current.profileName,
        ),
        safeUserNamespace(userId),
        'v1',
      ),
    );
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }

    final ext =
        p.extension(source.path).isNotEmpty ? p.extension(source.path) : '.jpg';
    final filename =
        'avatar_${(timestamp ?? DateTime.now()).millisecondsSinceEpoch}$ext';
    final destPath = p.join(avatarDir.path, filename);
    return source.copy(destPath);
  }

  String _safeEnvironmentNamespace(String environmentId) {
    final normalized = environmentId.trim().toLowerCase();
    if (normalized.isEmpty) return 'default';
    return normalized.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  }
}
