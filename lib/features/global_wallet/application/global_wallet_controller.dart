import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';
import '../data/cloud/cloud_wallet_errors.dart';
import '../data/cloud/cloud_wallet_repository.dart';
import '../data/cloud/cloud_wallet_snapshot.dart';
import '../data/cloud/global_cloud_wallet_config.dart';
import '../data/cloud/wallet_cache.dart';
import 'global_wallet_state.dart';

class GlobalWalletController extends ChangeNotifier {
  GlobalWalletController({
    CloudWalletRepository? repository,
    WalletCache? cache,
    String? Function()? currentUserIdProvider,
    bool? enabled,
    DateTime Function()? nowProvider,
  })  : _repository = repository ?? SupabaseCloudWalletRepository(),
        _cache = cache ?? SharedPreferencesWalletCache(),
        _currentUserIdProvider =
            currentUserIdProvider ?? _defaultCurrentUserIdProvider,
        _enabled = GlobalCloudWalletConfig.resolveEnabled(override: enabled),
        _nowProvider = nowProvider ?? DateTime.now;

  final CloudWalletRepository _repository;
  final WalletCache _cache;
  final String? Function() _currentUserIdProvider;
  final bool _enabled;
  final DateTime Function() _nowProvider;

  GlobalWalletState _state = GlobalWalletState.unauthenticated();
  String? _activeUserId;
  int _requestEpoch = 0;
  bool _isDisposed = false;
  final Map<String, int> _confirmedBalanceVersionByUserId = <String, int>{};

  GlobalWalletState get state => _state;

  bool get isEnabled => _enabled;

  String? get activeUserId => _activeUserId;

  Future<GlobalWalletState> syncSession({
    String? userId,
    bool force = false,
  }) async {
    final normalizedUserId = _normalizeUserId(userId ?? _currentUserId());
    if (normalizedUserId == null) {
      return _clearSession();
    }

    _activeUserId = normalizedUserId;
    _requestEpoch += 1;
    final requestEpoch = _requestEpoch;

    if (!_enabled) {
      _state = GlobalWalletState.failed(
        failure: const WalletFailure(
          code: WalletFailureCode.featureDisabled,
          message: 'Global cloud wallet is disabled.',
        ),
        userId: normalizedUserId,
      );
      _notifyWalletListeners();
      return _state;
    }

    final cachedEntry = await _cache.read(normalizedUserId);
    if (!_isRequestCurrent(requestEpoch, normalizedUserId)) {
      return _state;
    }

    _state = cachedEntry != null
        ? GlobalWalletState.syncing(
            userId: normalizedUserId, cache: cachedEntry)
        : GlobalWalletState.loading(userId: normalizedUserId);
    _notifyWalletListeners();

    final result = await _repository.fetchWallet();
    if (!_isRequestCurrent(requestEpoch, normalizedUserId)) {
      return _state;
    }

    if (!result.isSuccess || result.data == null) {
      final failure = result.failure ??
          const WalletFailure(
            code: WalletFailureCode.unknown,
            message: 'Could not fetch global wallet.',
          );

      if (failure.code == WalletFailureCode.walletMissing) {
        _state = GlobalWalletState.walletMissing(
          userId: normalizedUserId,
          failure: failure,
        );
        _notifyWalletListeners();
        return _state;
      }

      if (cachedEntry != null) {
        _state = GlobalWalletState.stale(
          userId: normalizedUserId,
          cacheEntry: cachedEntry,
          failure: failure,
        );
        _notifyWalletListeners();
        return _state;
      }

      _state = GlobalWalletState.failed(
        failure: failure,
        userId: normalizedUserId,
      );
      _notifyWalletListeners();
      return _state;
    }

    final snapshot = result.data!;
    if (snapshot.userId.trim() != normalizedUserId) {
      final failure = const WalletFailure(
        code: WalletFailureCode.sessionChanged,
        message: 'Wallet response did not match the active user.',
      );
      if (cachedEntry != null) {
        _state = GlobalWalletState.stale(
          userId: normalizedUserId,
          cacheEntry: cachedEntry,
          failure: failure,
        );
      } else {
        _state = GlobalWalletState.failed(
          failure: failure,
          userId: normalizedUserId,
        );
      }
      _notifyWalletListeners();
      return _state;
    }

    final storedEntry = await _cache.save(snapshot);
    if (!_isRequestCurrent(requestEpoch, normalizedUserId)) {
      return _state;
    }

    final latestCache = await _cache.read(normalizedUserId);
    if (!_isRequestCurrent(requestEpoch, normalizedUserId)) {
      return _state;
    }

    final effectiveCache = latestCache ??
        storedEntry ??
        WalletCacheEntry.fromSnapshot(
          snapshot,
          cachedAt: _nowProvider().toUtc(),
        );

    if (!snapshotIsNewerOrEqual(snapshot, effectiveCache)) {
      _state = GlobalWalletState.stale(
        userId: normalizedUserId,
        cacheEntry: effectiveCache,
      );
      _notifyWalletListeners();
      return _state;
    }

    _state = GlobalWalletState.ready(
      userId: normalizedUserId,
      snapshot: snapshot,
      cache: effectiveCache,
    );
    _notifyWalletListeners();
    return _state;
  }

  Future<void> applyConfirmedBalance({
    required String userId,
    required int coins,
    int? version,
    DateTime? updatedAt,
  }) async {
    if (_isDisposed) return;
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) return;
    if (coins < 0) {
      throw ArgumentError.value(coins, 'coins', 'must be >= 0');
    }

    final requestEpoch = _requestEpoch;
    final currentUserId = _normalizeUserId(_currentUserId());
    if (currentUserId != normalizedUserId) {
      _debugWalletBalance(
        'confirmed balance ignored: session changed userId=$normalizedUserId',
      );
      return;
    }
    if (_activeUserId != null && _activeUserId != normalizedUserId) {
      _debugWalletBalance(
        'confirmed balance ignored: active wallet changed userId=$normalizedUserId',
      );
      return;
    }

    _activeUserId = normalizedUserId;

    final currentSnapshot =
        _state.userId == normalizedUserId ? _state.snapshot : null;
    final currentCache =
        _state.userId == normalizedUserId ? _state.cachedEntry : null;
    final now = (updatedAt ?? _nowProvider()).toUtc();
    if (version == null &&
        _confirmedBalanceIsOlderThanCurrent(
          userId: normalizedUserId,
          updatedAt: now,
          currentSnapshot: currentSnapshot,
          currentCache: currentCache,
        )) {
      _debugWalletBalance(
        'confirmed balance ignored: older timestamp userId=$normalizedUserId',
      );
      return;
    }
    final confirmedVersion = version ??
        _deriveConfirmedVersion(
          userId: normalizedUserId,
          coins: coins,
          updatedAt: now,
          currentSnapshot: currentSnapshot,
          currentCache: currentCache,
        );

    final currentKnownVersion = _currentKnownVersion(
      userId: normalizedUserId,
      snapshot: currentSnapshot,
      cacheEntry: currentCache,
    );
    if (confirmedVersion < currentKnownVersion) return;
    if (!_isCurrentSession(requestEpoch, normalizedUserId)) return;

    final snapshot = CloudWalletSnapshot(
      userId: normalizedUserId,
      coins: coins,
      version: confirmedVersion,
      createdAt: currentSnapshot?.createdAt.toUtc() ?? now,
      updatedAt: now,
      fetchedAt: now,
    );
    final optimisticCacheEntry = WalletCacheEntry.fromSnapshot(
      snapshot,
      cachedAt: now,
    );

    _confirmedBalanceVersionByUserId[normalizedUserId] = confirmedVersion;
    _state = GlobalWalletState.ready(
      userId: normalizedUserId,
      snapshot: snapshot,
      cache: optimisticCacheEntry,
    );
    _notifyWalletListeners();
    _debugWalletBalance(
      'confirmed balance applied userId=$normalizedUserId '
      'coins=$coins version=$confirmedVersion',
    );

    try {
      await _cache.save(snapshot);
      _debugWalletBalance(
        'confirmed balance cache updated userId=$normalizedUserId '
        'coins=$coins version=$confirmedVersion',
      );
    } catch (error) {
      _debugWalletBalance(
        'confirmed balance cache failed userId=$normalizedUserId error=$error',
      );
    }
  }

  Future<GlobalWalletState> refresh({bool force = false}) {
    return syncSession(force: force);
  }

  Future<GlobalWalletState> clearSession() {
    return _clearSession();
  }

  Future<GlobalWalletState> _clearSession() async {
    _requestEpoch += 1;
    _activeUserId = null;
    _state = GlobalWalletState.unauthenticated();
    _notifyWalletListeners();
    return _state;
  }

  int _currentKnownVersion({
    required String userId,
    CloudWalletSnapshot? snapshot,
    WalletCacheEntry? cacheEntry,
  }) {
    var version = _confirmedBalanceVersionByUserId[userId] ?? -1;
    if (snapshot != null && snapshot.userId == userId) {
      version = version > snapshot.version ? version : snapshot.version;
    }
    if (cacheEntry != null && cacheEntry.userId == userId) {
      version = version > cacheEntry.version ? version : cacheEntry.version;
    }
    return version;
  }

  int _deriveConfirmedVersion({
    required String userId,
    required int coins,
    required DateTime updatedAt,
    CloudWalletSnapshot? currentSnapshot,
    WalletCacheEntry? currentCache,
  }) {
    final knownVersion = _currentKnownVersion(
      userId: userId,
      snapshot: currentSnapshot,
      cacheEntry: currentCache,
    );
    final snapshot = currentSnapshot;
    if (snapshot != null &&
        snapshot.userId == userId &&
        snapshot.coins == coins &&
        !updatedAt.isAfter(snapshot.updatedAt.toUtc())) {
      return knownVersion;
    }
    return knownVersion + 1;
  }

  bool _confirmedBalanceIsOlderThanCurrent({
    required String userId,
    required DateTime updatedAt,
    CloudWalletSnapshot? currentSnapshot,
    WalletCacheEntry? currentCache,
  }) {
    if (currentSnapshot != null &&
        currentSnapshot.userId == userId &&
        updatedAt.isBefore(currentSnapshot.updatedAt.toUtc())) {
      return true;
    }
    if (currentCache != null &&
        currentCache.userId == userId &&
        updatedAt.isBefore(currentCache.updatedAt.toUtc())) {
      return true;
    }
    return false;
  }

  bool snapshotIsNewerOrEqual(
    CloudWalletSnapshot snapshot,
    WalletCacheEntry cacheEntry,
  ) {
    if (snapshot.version != cacheEntry.version) {
      return snapshot.version > cacheEntry.version;
    }
    final updatedComparison =
        snapshot.updatedAt.toUtc().compareTo(cacheEntry.updatedAt);
    if (updatedComparison != 0) return updatedComparison >= 0;
    return true;
  }

  bool _isRequestCurrent(int requestEpoch, String userId) {
    return _isCurrentSession(requestEpoch, userId);
  }

  bool _isCurrentSession(int requestEpoch, String userId) {
    if (_requestEpoch != requestEpoch) return false;
    final currentUserId = _normalizeUserId(_currentUserId());
    if (currentUserId != userId) return false;
    if (_activeUserId != null && _activeUserId != userId) return false;
    return true;
  }

  String? _currentUserId() {
    try {
      return _currentUserIdProvider()?.trim();
    } catch (_) {
      return null;
    }
  }

  String? _normalizeUserId(String? userId) {
    final normalized = (userId ?? '').trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  void _notifyWalletListeners() {
    if (_isDisposed) return;
    notifyListeners();
  }

  void _debugWalletBalance(String message) {
    if (kDebugMode) {
      debugPrint('[global_wallet] $message');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
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
