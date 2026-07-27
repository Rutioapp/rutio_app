import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rutio/core/supabase/rutio_supabase_client.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
import 'package:rutio/features/shop/application/shop_controller.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_runtime_config.dart';

enum ShopRefreshReason {
  opened,
  resumed,
  connectionRestored,
  manual,
  operation,
  userChanged,
}

enum ShopCloudRefreshStatus {
  success,
  partial,
  skipped,
  failed,
}

@immutable
class ShopCloudRefreshResult {
  const ShopCloudRefreshResult._({
    required this.status,
    required this.reason,
    required this.userId,
    required this.errors,
    this.skipReason,
  });

  factory ShopCloudRefreshResult.success({
    required ShopRefreshReason reason,
    required String userId,
  }) {
    return ShopCloudRefreshResult._(
      status: ShopCloudRefreshStatus.success,
      reason: reason,
      userId: userId,
      errors: const <Object>[],
    );
  }

  factory ShopCloudRefreshResult.partial({
    required ShopRefreshReason reason,
    required String userId,
    required List<Object> errors,
  }) {
    return ShopCloudRefreshResult._(
      status: ShopCloudRefreshStatus.partial,
      reason: reason,
      userId: userId,
      errors: List<Object>.unmodifiable(errors),
    );
  }

  factory ShopCloudRefreshResult.failed({
    required ShopRefreshReason reason,
    required String userId,
    required List<Object> errors,
  }) {
    return ShopCloudRefreshResult._(
      status: ShopCloudRefreshStatus.failed,
      reason: reason,
      userId: userId,
      errors: List<Object>.unmodifiable(errors),
    );
  }

  factory ShopCloudRefreshResult.skipped({
    required ShopRefreshReason reason,
    String? userId,
    required String skipReason,
  }) {
    return ShopCloudRefreshResult._(
      status: ShopCloudRefreshStatus.skipped,
      reason: reason,
      userId: userId,
      errors: const <Object>[],
      skipReason: skipReason,
    );
  }

  final ShopCloudRefreshStatus status;
  final ShopRefreshReason reason;
  final String? userId;
  final List<Object> errors;
  final String? skipReason;
}

class ShopCloudRefreshCoordinator {
  ShopCloudRefreshCoordinator({
    required ShopController shopController,
    required ShopCosmeticsController cosmeticsController,
    required GlobalWalletController walletController,
    required ShopCloudRuntimeConfig runtimeConfig,
    String? Function()? currentUserIdProvider,
    DateTime Function()? nowProvider,
    Duration minRefreshInterval = const Duration(milliseconds: 900),
  })  : _shopController = shopController,
        _cosmeticsController = cosmeticsController,
        _walletController = walletController,
        _runtimeConfig = runtimeConfig,
        _currentUserIdProvider =
            currentUserIdProvider ?? _defaultCurrentUserIdProvider,
        _nowProvider = nowProvider ?? DateTime.now,
        _minRefreshInterval = minRefreshInterval;

  final ShopController _shopController;
  final ShopCosmeticsController _cosmeticsController;
  final GlobalWalletController _walletController;
  final ShopCloudRuntimeConfig _runtimeConfig;
  final String? Function() _currentUserIdProvider;
  final DateTime Function() _nowProvider;
  final Duration _minRefreshInterval;

  Future<ShopCloudRefreshResult>? _activeRefresh;
  DateTime? _lastRefreshStartedAt;

  bool get isRefreshing => _activeRefresh != null;

  Future<ShopCloudRefreshResult> refreshShopCloudState({
    required ShopRefreshReason reason,
    bool force = false,
  }) {
    final active = _activeRefresh;
    if (active != null) {
      _log('skipped reason=${reason.name} skipReason=already_active');
      return active;
    }

    if (!_runtimeConfig.isFullyCloud) {
      final result = ShopCloudRefreshResult.skipped(
        reason: reason,
        skipReason: 'cloud_disabled',
      );
      _log('skipped reason=${reason.name} skipReason=cloud_disabled');
      return Future<ShopCloudRefreshResult>.value(result);
    }

    final userId = _normalizeUserId(_currentUserIdProvider());
    if (userId == null) {
      final result = ShopCloudRefreshResult.skipped(
        reason: reason,
        skipReason: 'unauthenticated',
      );
      _log('skipped reason=${reason.name} skipReason=unauthenticated');
      return Future<ShopCloudRefreshResult>.value(result);
    }

    final now = _nowProvider();
    final lastStartedAt = _lastRefreshStartedAt;
    if (!force &&
        _isDebounceableReason(reason) &&
        lastStartedAt != null &&
        now.difference(lastStartedAt) < _minRefreshInterval &&
        reason != ShopRefreshReason.opened) {
      final result = ShopCloudRefreshResult.skipped(
        reason: reason,
        userId: userId,
        skipReason: 'debounced',
      );
      _log('skipped reason=${reason.name} userId=$userId skipReason=debounced');
      return Future<ShopCloudRefreshResult>.value(result);
    }

    _lastRefreshStartedAt = now;
    late final Future<ShopCloudRefreshResult> refresh;
    refresh = _runRefresh(
      reason: reason,
      userId: userId,
      force: force,
    ).whenComplete(() {
      if (identical(_activeRefresh, refresh)) {
        _activeRefresh = null;
      }
    });
    _activeRefresh = refresh;
    return refresh;
  }

  Future<ShopCloudRefreshResult> _runRefresh({
    required ShopRefreshReason reason,
    required String userId,
    required bool force,
  }) async {
    _log('started reason=${reason.name} userId=$userId force=$force');
    final errors = <Object>[];

    final steps = <_RefreshStep>[
      _RefreshStep(
        label: 'pending_shop_operations',
        action: () => _shopController.resolvePendingPurchasesForCurrentUser(),
      ),
      _RefreshStep(
        label: 'wallet',
        action: () => _walletController.syncSession(
          userId: userId,
          force: force,
        ),
      ),
      _RefreshStep(
        label: 'shop_snapshot',
        action: () => _shopController.hydrateVisibleEconomy(force: force),
      ),
      _RefreshStep(
        label: 'cosmetics',
        action: () => _cosmeticsController.refreshCloudState(force: force),
      ),
      _RefreshStep(
        label: 'active_utility_effects',
        action: () => _shopController.getActiveUtilityEffects(),
      ),
      _RefreshStep(
        label: 'pending_mystery_boxes',
        action: () => _shopController.getPendingMysteryBoxOpenings(),
      ),
    ];

    for (final step in steps) {
      if (!_isCurrentUser(userId)) {
        _log(
            'skipped reason=${reason.name} userId=$userId skipReason=user_changed');
        return ShopCloudRefreshResult.skipped(
          reason: reason,
          userId: userId,
          skipReason: 'user_changed',
        );
      }
      await _runStep(
        label: step.label,
        errors: errors,
        action: step.action,
      );
      if (!_isCurrentUser(userId)) {
        _log(
            'skipped reason=${reason.name} userId=$userId skipReason=user_changed');
        return ShopCloudRefreshResult.skipped(
          reason: reason,
          userId: userId,
          skipReason: 'user_changed',
        );
      }
    }

    if (errors.isEmpty) {
      _log('success reason=${reason.name} userId=$userId');
      return ShopCloudRefreshResult.success(reason: reason, userId: userId);
    }

    final status = errors.length >= 6
        ? ShopCloudRefreshStatus.failed
        : ShopCloudRefreshStatus.partial;
    _log(
      '${status.name} reason=${reason.name} userId=$userId '
      'errorCount=${errors.length}',
    );
    if (status == ShopCloudRefreshStatus.failed) {
      return ShopCloudRefreshResult.failed(
        reason: reason,
        userId: userId,
        errors: errors,
      );
    }
    return ShopCloudRefreshResult.partial(
      reason: reason,
      userId: userId,
      errors: errors,
    );
  }

  Future<void> _runStep({
    required String label,
    required List<Object> errors,
    required Future<Object?> Function() action,
  }) async {
    try {
      await action();
    } catch (error, stackTrace) {
      errors.add(error);
      _log('step_error step=$label error=$error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[shop_cloud_refresh] $message');
  }

  String? _normalizeUserId(String? userId) {
    final normalized = (userId ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }

  bool _isCurrentUser(String userId) {
    return _normalizeUserId(_currentUserIdProvider()) == userId;
  }

  bool _isDebounceableReason(ShopRefreshReason reason) {
    return reason == ShopRefreshReason.resumed ||
        reason == ShopRefreshReason.connectionRestored;
  }

  static String? _defaultCurrentUserIdProvider() {
    try {
      final userId = RutioSupabaseClient.instance.auth.currentUser?.id.trim();
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } catch (_) {
      return null;
    }
  }
}

class _RefreshStep {
  const _RefreshStep({
    required this.label,
    required this.action,
  });

  final String label;
  final Future<Object?> Function() action;
}
