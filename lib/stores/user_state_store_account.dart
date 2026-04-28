part of 'user_state_store.dart';

Future<void> _deleteAccount(UserStateStore store) async {
  if (store._isDeletingAccount) return;

  store._isDeletingAccount = true;
  store._accountDeletionError = null;
  store._loading = true;
  store._emitChanged();

  final deletionService = AccountDeletionService();

  try {
    final result = await deletionService.launchDeletionFlow(store: store);
    if (!result.isSuccess) {
      throw result.error ?? StateError('Account deletion failed.');
    }

    // After the server confirms deletion, invalidate any local auth session.
    await _signOutSupabaseSessionIfPresent();
    store._accountDeletionError = null;
  } catch (error) {
    store._accountDeletionError = error;
    rethrow;
  } finally {
    store._isDeletingAccount = false;
    store._loading = false;
    store._emitChanged();
  }
}

void _clearDeleteAccountError(UserStateStore store) {
  if (store._accountDeletionError == null) return;
  store._accountDeletionError = null;
  store._emitChanged();
}

Future<void> _signOutSupabaseSessionIfPresent() async {
  try {
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) return;
    await client.auth.signOut();
  } catch (_) {
    // Keep local deletion successful even if session invalidation fails silently.
  }
}

Future<void> _clearLocalAccountData(
  UserStateStore store, {
  bool preserveLanguageCode = true,
}) async {
  final preservedLanguageCode =
      preserveLanguageCode ? _preferredLanguageCode(store) : null;

  final currentScopedUserId =
      store._repo.activeUserId ?? _normalizedScopeUserId(store.userId);
  if (currentScopedUserId != null && store._repo.activeUserId == null) {
    store._repo.setActiveUserScope(currentScopedUserId);
  }

  await store._repo.clearActiveScopeState();
  await _switchLocalScope(
    store,
    userId: null,
    forceReload: true,
  );

  if (store._state != null && preservedLanguageCode != null) {
    final root = Map<String, dynamic>.from(store._state!);
    final userState = _ensureUserStateRoot(root);
    final settings = _ensureSettingsRoot(userState);
    final localeSettings = _map(settings['locale']);
    localeSettings['languageCode'] = preservedLanguageCode;
    settings['locale'] = localeSettings;
    userState['settings'] = settings;
    root['userState'] = userState;
    await store._repo.save(root);
    store._state = root;
  }

  store._loading = false;
  store._error = null;
  store._emitChanged();
}

Future<void> _clearAuthSessionState(UserStateStore store) async {
  await _signOutSupabaseSessionIfPresent();
  await _switchLocalScope(
    store,
    userId: null,
    forceReload: true,
  );
}

Future<void> _applySupabaseIdentity(
  UserStateStore store, {
  required String userId,
  String? email,
  String? displayName,
  String? avatarUrl,
}) async {
  await _switchLocalScope(
    store,
    userId: userId,
  );

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
  await _switchLocalScope(
    store,
    userId: null,
    forceReload: true,
  );
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
) =>
    _updateNotificationSettings(
      store,
      <String, dynamic>{'enabled': enabled},
    );

Future<void> _setDailyMotivationEnabled(
  UserStateStore store,
  bool enabled,
) =>
    _updateNotificationSettings(
      store,
      <String, dynamic>{'dailyMotivation': enabled},
    );

Future<void> _setMarketingNotificationsEnabled(
  UserStateStore store,
  bool enabled,
) =>
    _updateNotificationSettings(
      store,
      <String, dynamic>{'marketing': enabled},
    );

Future<void> _setDailyMotivationTime(
  UserStateStore store,
  String hhmm,
) =>
    _updateNotificationSettings(
      store,
      <String, dynamic>{'dailyMotivationTime': hhmm},
    );

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

  unawaited(
    _bestEffortSyncNotificationSettingsPatch(
      store,
      patch: patch,
    ),
  );
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
  unawaited(
    _bestEffortSyncPreferredLanguageCode(
      store,
      languageCode: normalized,
    ),
  );
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

  if (displayName != null || avatarUrl != null) {
    unawaited(
      _bestEffortSyncProfileBasics(
        store,
        displayName: displayName,
        avatarUrl: avatarUrl,
      ),
    );
  }
}

Future<void> _bestEffortSyncProfileBasics(
  UserStateStore store, {
  String? displayName,
  String? avatarUrl,
}) async {
  final repository = store._profileRepository;
  if (repository == null) return;

  final shouldClearAvatarUrl = avatarUrl != null && avatarUrl.trim().isEmpty;

  try {
    final result = await repository.updateProfileBasics(
      email: store.authEmail,
      displayName: _nullableTrimValue(displayName),
      avatarUrl:
          shouldClearAvatarUrl ? null : _nullableTrimValue(avatarUrl),
      clearAvatarUrl: shouldClearAvatarUrl,
    );
    if (!result.isSuccess && kDebugMode) {
      debugPrint(
        '[user_state_store] profile basics write-through skipped: ${result.error?.message}',
      );
    }
  } catch (error) {
    _debugProfileWriteThroughWarning(
      'profile basics write-through failed: $error',
    );
  }
}

Future<void> _bestEffortSyncPreferredLanguageCode(
  UserStateStore store, {
  required String languageCode,
}) async {
  final repository = store._profileRepository;
  if (repository == null) return;

  try {
    final result = await repository.updatePreferredLanguage(languageCode);
    if (!result.isSuccess && kDebugMode) {
      debugPrint(
        '[user_state_store] preferred language write-through skipped: ${result.error?.message}',
      );
    }
  } catch (error) {
    _debugProfileWriteThroughWarning(
      'preferred language write-through failed: $error',
    );
  }
}

Future<void> _bestEffortSyncNotificationSettingsPatch(
  UserStateStore store, {
  required Map<String, dynamic> patch,
}) async {
  final repository = store._profileRepository;
  if (repository == null || patch.isEmpty) return;

  final hasNotificationsEnabled = patch.containsKey('enabled');
  final hasDailyMotivationEnabled = patch.containsKey('dailyMotivation');
  final hasMarketingNotificationsEnabled = patch.containsKey('marketing');
  final hasDailyMotivationTime = patch.containsKey('dailyMotivationTime');

  if (!hasNotificationsEnabled &&
      !hasDailyMotivationEnabled &&
      !hasMarketingNotificationsEnabled &&
      !hasDailyMotivationTime) {
    return;
  }

  try {
    final result = await repository.updateNotificationSettings(
      notificationsEnabled:
          hasNotificationsEnabled ? _dynamicBoolOrNull(patch['enabled']) : null,
      dailyMotivationEnabled: hasDailyMotivationEnabled
          ? _dynamicBoolOrNull(patch['dailyMotivation'])
          : null,
      marketingNotificationsEnabled: hasMarketingNotificationsEnabled
          ? _dynamicBoolOrNull(patch['marketing'])
          : null,
      dailyMotivationTime: hasDailyMotivationTime
          ? _nullableTrimValue(patch['dailyMotivationTime'])
          : null,
      includeDailyMotivationTime: hasDailyMotivationTime,
    );
    if (!result.isSuccess && kDebugMode) {
      debugPrint(
        '[user_state_store] notification settings write-through skipped: ${result.error?.message}',
      );
    }
  } catch (error) {
    _debugProfileWriteThroughWarning(
      'notification settings write-through failed: $error',
    );
  }
}

void _debugProfileWriteThroughWarning(String message) {
  if (!kDebugMode) return;
  debugPrint('[user_state_store] $message');
}

bool? _dynamicBoolOrNull(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value > 0;

  final normalized = (value ?? '').toString().trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}

String? _nullableTrimValue(dynamic value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
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
  _queueBestEffortProgressAndRewardSync(
    store,
    userState: userState,
    xpDelta: 0,
    coinsDelta: -price,
    source: 'shop_purchase',
    currencyReason: 'shop_item_purchase',
  );
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
