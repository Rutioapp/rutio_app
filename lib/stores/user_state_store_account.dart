part of 'user_state_store.dart';

Future<void> _clearLocalAccountData(
  UserStateStore store, {
  bool preserveLanguageCode = true,
}) async {
  final preservedLanguageCode =
      preserveLanguageCode ? _preferredLanguageCode(store) : null;

  await store._repo.resetToTemplate();
  final resetRoot = await store._repo.loadOrCreate();
  final userState = _ensureUserStateRoot(resetRoot);
  final meta = _map(userState['meta']);

  meta['onboardingDone'] = false;
  meta.remove('authEmail');
  userState['meta'] = meta;

  if (preservedLanguageCode != null) {
    final settings = _ensureSettingsRoot(userState);
    final localeSettings = _map(settings['locale']);
    localeSettings['languageCode'] = preservedLanguageCode;
    settings['locale'] = localeSettings;
    userState['settings'] = settings;
  }

  resetRoot['userState'] = userState;
  await store._repo.save(resetRoot);

  store._state = resetRoot;
  store._loading = false;
  store._error = null;
  store._emitChanged();
}

Future<void> _applySupabaseIdentity(
  UserStateStore store, {
  required String userId,
  String? email,
  String? displayName,
  String? avatarUrl,
}) async {
  if (store._state == null) {
    if (!store._loading) {
      await store.load();
    }
    if (store._state == null) return;
  }

  final root = Map<String, dynamic>.from(store._state!);
  final userState = _ensureUserStateRoot(root);
  final meta = _map(userState['meta']);
  final profile = _map(userState['profile']);

  userState['userId'] = userId;

  final normalizedEmail = (email ?? '').trim().toLowerCase();
  if (normalizedEmail.isNotEmpty) {
    meta['authEmail'] = normalizedEmail;
    profile['email'] = normalizedEmail;
  }

  final normalizedDisplayName = (displayName ?? '').trim();
  if (normalizedDisplayName.isNotEmpty) {
    profile['displayName'] = normalizedDisplayName;
  }

  final normalizedAvatarUrl = (avatarUrl ?? '').trim();
  if (normalizedAvatarUrl.isNotEmpty) {
    profile['avatarUrl'] = normalizedAvatarUrl;
  }

  userState['meta'] = meta;
  userState['profile'] = profile;
  _touchLastSavedAt(userState);

  root['userState'] = userState;
  store._state = root;

  store._emitChanged();
  await store._repo.save(root);
}

Future<void> _clearSupabaseIdentity(UserStateStore store) async {
  if (store._state == null) {
    if (!store._loading) {
      await store.load();
    }
    if (store._state == null) return;
  }

  final root = Map<String, dynamic>.from(store._state!);
  final userState = _ensureUserStateRoot(root);
  final meta = _map(userState['meta']);
  final profile = _map(userState['profile']);

  userState.remove('userId');
  meta.remove('authEmail');
  profile.remove('email');
  profile.remove('displayName');

  userState['meta'] = meta;
  userState['profile'] = profile;
  _touchLastSavedAt(userState);

  root['userState'] = userState;
  store._state = root;

  store._emitChanged();
  await store._repo.save(root);
}

Map<String, dynamic> _ensureSettingsRoot(Map<String, dynamic> userState) {
  final settings = _map(userState['settings']);
  userState['settings'] = settings;
  return settings;
}

Map<String, dynamic> _ensureNotificationsSettings(
  Map<String, dynamic> userState,
) {
  final settings = _ensureSettingsRoot(userState);
  final notifications = _map(settings['notifications']);
  settings['notifications'] = notifications;
  userState['settings'] = settings;
  return notifications;
}

Map<String, dynamic> _notificationSettings(UserStateStore store) {
  if (store._state == null) return <String, dynamic>{};

  final userState = _ensureUserStateRoot(store._state!);
  final notifications = _ensureNotificationsSettings(userState);

  notifications['enabled'] ??= true;
  notifications['habitReminders'] ??= true;
  notifications['dayClosure'] ??= true;
  notifications['dayClosureTime'] ??= '21:00';
  notifications['streakRisk'] ??= true;
  notifications['streakCelebration'] ??= true;
  notifications['inactivityReengagement'] ??= true;
  notifications['dailyMotivation'] ??= true;
  notifications['marketing'] ??= false;
  notifications['dailyMotivationTime'] ??= '21:00';
  notifications['metadata'] ??= <String, dynamic>{};

  return Map<String, dynamic>.from(notifications);
}

String? _preferredLanguageCode(UserStateStore store) {
  if (store._state == null) return null;

  final userState = _ensureUserStateRoot(store._state!);
  final settings = _ensureSettingsRoot(userState);
  final localeSettings = _map(settings['locale']);
  final code =
      (localeSettings['languageCode'] ?? '').toString().trim().toLowerCase();

  if (code == 'es' || code == 'en') return code;
  return null;
}

Map<String, dynamic> _notificationMetadata(UserStateStore store) {
  if (store._state == null) return <String, dynamic>{};

  final userState = _ensureUserStateRoot(store._state!);
  final notifications = _ensureNotificationsSettings(userState);
  final metadata = _map(notifications['metadata']);

  metadata['celebrationMilestones'] ??= <String, dynamic>{};
  notifications['metadata'] = metadata;

  return Map<String, dynamic>.from(metadata);
}

Future<void> _setNotificationsEnabled(
  UserStateStore store,
  bool enabled,
) async {
  if (store._state == null) return;

  final root = store._state!;
  final userState = _ensureUserStateRoot(root);
  final notifications = _ensureNotificationsSettings(userState);

  notifications['enabled'] = enabled;
  userState['settings'] = _ensureSettingsRoot(userState);

  await store.save(root);
}

Future<void> _setDailyMotivationEnabled(
  UserStateStore store,
  bool enabled,
) async {
  if (store._state == null) return;

  final root = store._state!;
  final userState = _ensureUserStateRoot(root);
  final notifications = _ensureNotificationsSettings(userState);

  notifications['dailyMotivation'] = enabled;
  userState['settings'] = _ensureSettingsRoot(userState);

  await store.save(root);
}

Future<void> _setMarketingNotificationsEnabled(
  UserStateStore store,
  bool enabled,
) async {
  if (store._state == null) return;

  final root = store._state!;
  final userState = _ensureUserStateRoot(root);
  final notifications = _ensureNotificationsSettings(userState);

  notifications['marketing'] = enabled;
  userState['settings'] = _ensureSettingsRoot(userState);

  await store.save(root);
}

Future<void> _setDailyMotivationTime(
  UserStateStore store,
  String hhmm,
) async {
  if (store._state == null) return;

  final root = store._state!;
  final userState = _ensureUserStateRoot(root);
  final notifications = _ensureNotificationsSettings(userState);

  notifications['dailyMotivationTime'] = hhmm;
  userState['settings'] = _ensureSettingsRoot(userState);

  await store.save(root);
}

Future<void> _updateNotificationSettings(
  UserStateStore store,
  Map<String, dynamic> patch,
) async {
  if (store._state == null || patch.isEmpty) return;

  final root = store._state!;
  final userState = _ensureUserStateRoot(root);
  final notifications = _ensureNotificationsSettings(userState);
  final before = jsonEncode(notifications);

  patch.forEach((key, value) {
    if (value == null) {
      notifications.remove(key);
    } else {
      notifications[key] = value;
    }
  });

  if (before == jsonEncode(notifications)) return;

  userState['settings'] = _ensureSettingsRoot(userState);
  await store.save(root);
}

Future<void> _updateNotificationMetadata(
  UserStateStore store,
  Map<String, dynamic> patch,
) async {
  if (store._state == null || patch.isEmpty) return;

  final root = store._state!;
  final userState = _ensureUserStateRoot(root);
  final notifications = _ensureNotificationsSettings(userState);
  final metadata = _map(notifications['metadata']);
  final before = jsonEncode(metadata);

  patch.forEach((key, value) {
    if (value == null) {
      metadata.remove(key);
    } else {
      metadata[key] = value;
    }
  });

  if (before == jsonEncode(metadata)) return;

  notifications['metadata'] = metadata;
  userState['settings'] = _ensureSettingsRoot(userState);

  await store.save(root);
}

Future<void> _setPreferredLanguageCode(
  UserStateStore store,
  String languageCode,
) async {
  if (store._state == null) return;

  final normalized = languageCode.trim().toLowerCase();
  if (normalized != 'es' && normalized != 'en') return;

  final root = store._state!;
  final userState = _ensureUserStateRoot(root);
  final settings = _ensureSettingsRoot(userState);
  final localeSettings = _map(settings['locale']);

  localeSettings['languageCode'] = normalized;
  settings['locale'] = localeSettings;
  userState['settings'] = settings;

  await store.save(root);
}

Map<String, dynamic> _profile(UserStateStore store) {
  if (store._state == null) return <String, dynamic>{};

  final userState = _ensureUserStateRoot(store._state!);
  return _map(userState['profile']);
}

Future<void> _updateProfileFields(
  UserStateStore store, {
  String? displayName,
  String? bio,
  String? goal,
  String? avatarUrl,
}) async {
  if (store._state == null) return;

  final root = store._state!;
  final userState = _ensureUserStateRoot(root);
  final profile = _map(userState['profile']);

  if (displayName != null) profile['displayName'] = displayName;
  if (bio != null) profile['bio'] = bio;
  if (goal != null) profile['goal'] = goal;

  if (avatarUrl != null) {
    if (avatarUrl.trim().isEmpty) {
      profile.remove('avatarUrl');
    } else {
      profile['avatarUrl'] = avatarUrl.trim();
    }
  }

  userState['profile'] = profile;
  _touchLastSavedAt(userState);

  root['userState'] = userState;
  store._state = root;

  store._emitChanged();
  await store._repo.save(root);
}

Future<bool> _buyItem(
  UserStateStore store, {
  required String itemId,
  required int price,
}) async {
  final root = store._state;
  if (root == null) return false;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);

  final wallet = _map(userState['wallet']);
  final coins = ((wallet['coins'] as num?) ?? 0).toInt();

  if (coins < price) return false;

  final inventory = _map(userState['inventory']);
  final items =
      _list(inventory['items']).map((entry) => entry.toString()).toList();

  if (items.contains(itemId)) return false;

  items.add(itemId);
  wallet['coins'] = coins - price;
  inventory['items'] = items;

  userState['wallet'] = wallet;
  userState['inventory'] = inventory;

  await store.save(root);
  return true;
}

Future<void> _equip(
  UserStateStore store, {
  required String slot,
  required String itemId,
}) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  _ensureDailyReset(userState);

  final profile = _map(userState['profile']);
  final equipped = _map(profile['equipped']);

  equipped[slot] = itemId;
  profile['equipped'] = equipped;
  userState['profile'] = profile;

  await store.save(root);
}
