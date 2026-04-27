import 'package:rutio/core/assets/app_assets.dart';
import 'package:flutter/foundation.dart';

import '../../models/user_state.dart';
import '../local/asset_json_loader.dart';
import '../local/user_state_storage.dart';

class UserStateRepository {
  final UserStateStorage _storage;
  final AssetJsonLoader _assets;
  String? _activeUserId;
  static const bool _autoMigrateLegacyIntoScoped = false;

  UserStateRepository({
    required UserStateStorage storage,
    AssetJsonLoader? assets,
  })  : _storage = storage,
        _assets = assets ?? AssetJsonLoader();

  String? get activeUserId => _activeUserId;

  void setActiveUserScope(String? userId) {
    final normalized = (userId ?? '').trim();
    _activeUserId = normalized.isEmpty ? null : normalized;
    if (kDebugMode) {
      final scope = _activeUserId ?? 'guest';
      debugPrint('[user_state_repository] set active scope: $scope');
    }
  }

  /// Devuelve el estado (si no existe, crea uno desde la plantilla)
  Future<UserState> getUserState() async {
    final json = await loadOrCreate();
    return UserState.fromJson(json);
  }

  /// Guarda el estado actual
  Future<void> saveUserState(UserState state) async {
    await save(state.toJson());
  }

  // ----- Lo que ya tenías -----

  Future<Map<String, dynamic>> loadOrCreate() async {
    final activeUserId = _activeUserId;
    final existing = await _storage.read(userId: activeUserId);
    if (existing != null) {
      _debugLoadedState(
        source: 'scoped_existing',
        userId: activeUserId,
        state: existing,
      );
      return existing;
    }

    if (_autoMigrateLegacyIntoScoped && activeUserId != null) {
      final migrated = await _storage.migrateLegacyToScopedIfEligible(
        userId: activeUserId,
      );
      if (migrated) {
        final scopedAfterMigration = await _storage.read(userId: activeUserId);
        if (scopedAfterMigration != null) {
          _debugLoadedState(
            source: 'legacy_migrated_once',
            userId: activeUserId,
            state: scopedAfterMigration,
          );
          return scopedAfterMigration;
        }
      }
    }

    final template = await _assets.loadJsonMap(AppAssets.userStateTemplate);
    await _storage.write(template, userId: activeUserId);
    _debugLoadedState(
      source: 'template_initialized',
      userId: activeUserId,
      state: template,
    );
    return template;
  }

  Future<void> save(Map<String, dynamic> userStateJson) async {
    final activeScopeUserId = _activeUserId;
    final payloadUserId = _extractUserId(userStateJson);

    // Guard against stale cross-scope writes from in-flight async operations.
    if (activeScopeUserId != null &&
        payloadUserId != null &&
        payloadUserId != activeScopeUserId) {
      if (kDebugMode) {
        debugPrint(
          '[user_state_repository] blocked save due scope mismatch '
          '(activeScope=$activeScopeUserId payloadUserId=$payloadUserId)',
        );
      }
      return;
    }

    if (activeScopeUserId == null && payloadUserId != null) {
      if (kDebugMode) {
        debugPrint(
          '[user_state_repository] blocked guest-scope save containing authenticated userId '
          '(payloadUserId=$payloadUserId)',
        );
      }
      return;
    }

    await _storage.write(userStateJson, userId: _activeUserId);
    if (kDebugMode) {
      final activeHabitsCount = _activeHabitsCount(userStateJson);
      final historyDayCount = _historyDayCount(userStateJson);
      debugPrint(
        '[user_state_repository] save '
        'scope=${_activeUserId ?? 'guest'} '
        'activeHabits=$activeHabitsCount historyDays=$historyDayCount',
      );
    }
  }

  Future<void> resetToTemplate() async {
    final template = await _assets.loadJsonMap(AppAssets.userStateTemplate);
    await _storage.write(template, userId: _activeUserId);
  }

  Future<void> clearActiveScopeState({bool allowLegacyClear = false}) async {
    if (_activeUserId == null && !allowLegacyClear) {
      return;
    }
    await _storage.clear(userId: _activeUserId);
    if (kDebugMode) {
      debugPrint(
        '[user_state_repository] cleared scope state for '
        '${_activeUserId ?? 'guest'}',
      );
    }
  }

  String? _extractUserId(Map<String, dynamic> root) {
    final userState = root['userState'];
    if (userState is! Map) return null;
    final value = (userState['userId'] ?? userState['id'] ?? '')
        .toString()
        .trim();
    return value.isEmpty ? null : value;
  }

  int _activeHabitsCount(Map<String, dynamic> root) {
    final userState = root['userState'];
    if (userState is! Map) return 0;
    final activeHabits = userState['activeHabits'];
    if (activeHabits is! List) return 0;
    return activeHabits.length;
  }

  int _historyDayCount(Map<String, dynamic> root) {
    final userState = root['userState'];
    if (userState is! Map) return 0;
    final history = userState['history'];
    if (history is! Map) return 0;
    final completions = history['habitCompletions'];
    if (completions is! Map) return 0;
    return completions.length;
  }

  void _debugLoadedState({
    required String source,
    required String? userId,
    required Map<String, dynamic> state,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[user_state_repository] load source=$source scope=${userId ?? 'guest'} '
      'activeHabits=${_activeHabitsCount(state)} '
      'historyDays=${_historyDayCount(state)}',
    );
  }
}

