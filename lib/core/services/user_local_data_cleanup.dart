import 'dart:io';

import '../../services/notification_service.dart';
import '../../services/session_service.dart';
import '../../stores/user_state_store.dart';

class UserLocalDataCleanup {
  const UserLocalDataCleanup();

  Future<void> clearAll({
    required UserStateStore store,
  }) async {
    await _deleteAvatarFileIfNeeded(store.avatarUrl);
    await NotificationService.instance.cancelAllNotifications();
    await SessionService.instance.clear();
    await store.clearLocalAccountData();
  }

  Future<void> _deleteAvatarFileIfNeeded(String? avatarUrl) async {
    final rawPath = (avatarUrl ?? '').trim();
    if (rawPath.isEmpty) return;

    final parsed = Uri.tryParse(rawPath);
    if (parsed != null && (parsed.scheme == 'http' || parsed.scheme == 'https')) {
      return;
    }

    final resolvedPath =
        (parsed != null && parsed.scheme == 'file') ? parsed.toFilePath() : rawPath;
    final file = File(resolvedPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
