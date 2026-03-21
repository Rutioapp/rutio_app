import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../l10n/l10n.dart';

class AvatarService {
  const AvatarService();

  Future<File> pickCropAndPersist({
    required BuildContext context,
    required String pickedPath,
  }) async {
    final cropped =
        await _cropToCircle(context: context, sourcePath: pickedPath);
    final picked = cropped ?? File(pickedPath);
    final saved = await _persistAvatarFile(picked);
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

  Future<File> _persistAvatarFile(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory(p.join(dir.path, 'avatars'));
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }

    final ext =
        p.extension(source.path).isNotEmpty ? p.extension(source.path) : '.jpg';
    final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(avatarDir.path, filename);
    return source.copy(destPath);
  }
}
