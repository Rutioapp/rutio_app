import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/notifications/notification_permission_service.dart'
    as core_permission;
import '../../../stores/user_state_store.dart';
import '../data/local/shared_preferences_notification_install_id_provider.dart';
import '../data/local/shared_preferences_notification_preferences_store.dart';
import '../domain/personalized_notification_models.dart';
import '../domain/personalized_notification_ports.dart';
import 'notification_permission_controller.dart';
import 'personalized_notification_orchestrator.dart';

class PersonalizedNotificationsFeatureGate {
  PersonalizedNotificationsFeatureGate._();

  static bool enabled = const bool.fromEnvironment(
    'RUTIO_ENABLE_PERSONALIZED_NOTIFICATIONS_V2',
    defaultValue: false,
  );
}

enum PersonalizedNotificationToggleStatus {
  applied,
  permissionRecoveryRequired,
  skippedNoUser,
}

@immutable
class PersonalizedNotificationToggleResult {
  const PersonalizedNotificationToggleResult._({
    required this.status,
    this.permissionResult,
  });

  factory PersonalizedNotificationToggleResult.applied() {
    return const PersonalizedNotificationToggleResult._(
      status: PersonalizedNotificationToggleStatus.applied,
    );
  }

  factory PersonalizedNotificationToggleResult.permissionRecoveryRequired(
    core_permission.NotificationPermissionResult permissionResult,
  ) {
    return PersonalizedNotificationToggleResult._(
      status: PersonalizedNotificationToggleStatus.permissionRecoveryRequired,
      permissionResult: permissionResult,
    );
  }

  factory PersonalizedNotificationToggleResult.skippedNoUser() {
    return const PersonalizedNotificationToggleResult._(
      status: PersonalizedNotificationToggleStatus.skippedNoUser,
    );
  }

  final PersonalizedNotificationToggleStatus status;
  final core_permission.NotificationPermissionResult? permissionResult;

  bool get applied => status == PersonalizedNotificationToggleStatus.applied;

  bool get needsRecoverySheet =>
      status ==
          PersonalizedNotificationToggleStatus.permissionRecoveryRequired &&
      permissionResult != null;
}

class PersonalizedNotificationSettingsController extends ChangeNotifier {
  PersonalizedNotificationSettingsController({
    required UserStateStore userStateStore,
    NotificationPreferencesStore? preferencesStore,
    PersonalizedNotificationOrchestrator? orchestrator,
    NotificationInstallIdProvider? installIdProvider,
    NotificationPermissionController? permissionController,
  })  : _userStateStore = userStateStore,
        _preferencesStore =
            preferencesStore ?? SharedPreferencesNotificationPreferencesStore(),
        _orchestrator = orchestrator,
        _installIdProvider = installIdProvider ??
            SharedPreferencesNotificationInstallIdProvider(),
        _permissionController =
            permissionController ?? NotificationPermissionController() {
    _userStateStore.addListener(_handleStoreChanged);
    unawaited(_refreshFromStore());
  }

  final UserStateStore _userStateStore;
  final NotificationPreferencesStore _preferencesStore;
  final PersonalizedNotificationOrchestrator? _orchestrator;
  final NotificationInstallIdProvider _installIdProvider;
  final NotificationPermissionController _permissionController;

  NotificationScope? _scope;
  NotificationPreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _lastError;
  int _refreshToken = 0;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get lastError => _lastError;
  NotificationScope? get scope => _scope;
  bool get hasScope => _scope != null;
  NotificationPreferences get preferences =>
      _preferences ?? NotificationPreferences.defaults();
  bool get personalizedNotificationsEnabled =>
      preferences.masterEnabled && preferences.generalNotificationsEnabled;
  NotificationIntensityPreset get intensityPreset =>
      preferences.intensityPreset;
  NotificationClockTime get referenceTime => preferences.dailyAnchorTime;
  bool get canEdit => hasScope && !_isLoading && !_isSaving;

  @override
  void dispose() {
    _userStateStore.removeListener(_handleStoreChanged);
    super.dispose();
  }

  Future<void> refresh() => _refreshFromStore();

  Future<PersonalizedNotificationToggleResult> setEnabled(
    bool enabled,
  ) async {
    final scope = _scope;
    if (scope == null) {
      return PersonalizedNotificationToggleResult.skippedNoUser();
    }

    if (enabled) {
      final systemResult =
          await _permissionController.getSystemPermissionResult();
      if (systemResult.isAuthorized) {
        await _persistAndReconcile(
          scope,
          (current) => current.copyWith(
            masterEnabled: true,
            generalNotificationsEnabled: true,
          ),
        );
        return PersonalizedNotificationToggleResult.applied();
      }

      if (systemResult.canRequest) {
        final granted = await _permissionController.requestSystemPermission();
        if (granted) {
          await _persistAndReconcile(
            scope,
            (current) => current.copyWith(
              masterEnabled: true,
              generalNotificationsEnabled: true,
            ),
          );
          return PersonalizedNotificationToggleResult.applied();
        }

        final latest = await _permissionController.getSystemPermissionResult();
        return PersonalizedNotificationToggleResult.permissionRecoveryRequired(
          latest,
        );
      }

      return PersonalizedNotificationToggleResult.permissionRecoveryRequired(
        systemResult,
      );
    }

    await _persistAndReconcile(
      scope,
      (current) => current.copyWith(
        masterEnabled: false,
        generalNotificationsEnabled: false,
      ),
    );
    return PersonalizedNotificationToggleResult.applied();
  }

  Future<void> setIntensity(NotificationIntensityPreset preset) async {
    final scope = _scope;
    if (scope == null) return;

    await _persistAndReconcile(
      scope,
      (current) => current.copyWith(intensityPreset: preset),
    );
  }

  Future<void> setReferenceTime(NotificationClockTime time) async {
    final scope = _scope;
    if (scope == null) return;

    await _persistAndReconcile(
      scope,
      (current) => current.copyWith(
        dailyAnchorTime: time,
        wakeTimeSource: WakeTimeSource.userConfigured,
      ),
    );
  }

  Future<void> _refreshFromStore() async {
    final token = ++_refreshToken;
    _setLoading(true);

    final nextScope = await _resolveScope();
    if (token != _refreshToken) return;

    if (nextScope == null) {
      _scope = null;
      _preferences = null;
      _lastError = null;
      _setLoading(false);
      return;
    }

    try {
      final loaded = await _preferencesStore.load(nextScope);
      if (token != _refreshToken) return;
      _scope = nextScope;
      _preferences = loaded;
      _lastError = null;
    } catch (error) {
      if (token != _refreshToken) return;
      _lastError = '$error';
    } finally {
      if (token == _refreshToken) {
        _setLoading(false);
      }
    }
  }

  Future<void> _persistAndReconcile(
    NotificationScope scope,
    NotificationPreferences Function(NotificationPreferences current) update,
  ) async {
    _setSaving(true);
    try {
      final next = await _preferencesStore.update(scope, update);
      _preferences = next;
      _scope = scope;
      _lastError = null;
      notifyListeners();

      if (PersonalizedNotificationsFeatureGate.enabled) {
        await _orchestrator?.reconcilePersonalizedNotificationsNow(
          reason: NotificationReconciliationReason.preferencesChanged,
        );
      }
    } catch (error) {
      _lastError = '$error';
      notifyListeners();
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  Future<NotificationScope?> _resolveScope() async {
    final activeScopeUserId =
        _normalized(_userStateStore.activeLocalScopeUserId);
    final storeUserId = _normalized(_userStateStore.userId);
    if (activeScopeUserId == null ||
        storeUserId == null ||
        activeScopeUserId != storeUserId) {
      return null;
    }

    final installId = await _installIdProvider.getOrCreateInstallId();
    return NotificationScope(
      userId: activeScopeUserId,
      scopeEpoch: _userStateStore.scopeEpoch,
      installId: installId,
      locale: _userStateStore.preferredLanguageCode ?? 'es',
    );
  }

  void _handleStoreChanged() {
    unawaited(_refreshFromStore());
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    if (_isSaving == value) return;
    _isSaving = value;
    notifyListeners();
  }

  String? _normalized(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
