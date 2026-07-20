import 'package:flutter/foundation.dart';

import '../data/cloud/cloud_wallet_errors.dart';
import '../data/cloud/cloud_wallet_snapshot.dart';
import '../data/cloud/wallet_cache.dart';

enum GlobalWalletStatus {
  loading,
  syncing,
  ready,
  stale,
  unauthenticated,
  walletMissing,
  failed,
}

@immutable
class GlobalWalletState {
  const GlobalWalletState({
    required this.status,
    this.userId,
    this.snapshot,
    this.cachedEntry,
    this.failure,
    this.isFromCache = false,
  });

  final GlobalWalletStatus status;
  final String? userId;
  final CloudWalletSnapshot? snapshot;
  final WalletCacheEntry? cachedEntry;
  final WalletFailure? failure;
  final bool isFromCache;

  factory GlobalWalletState.unauthenticated() {
    return const GlobalWalletState(status: GlobalWalletStatus.unauthenticated);
  }

  factory GlobalWalletState.loading({String? userId, WalletCacheEntry? cache}) {
    return GlobalWalletState(
      status: GlobalWalletStatus.loading,
      userId: userId,
      cachedEntry: cache,
      snapshot: cache?.toSnapshot(),
      isFromCache: cache != null,
    );
  }

  factory GlobalWalletState.syncing({String? userId, WalletCacheEntry? cache}) {
    return GlobalWalletState(
      status: GlobalWalletStatus.syncing,
      userId: userId,
      cachedEntry: cache,
      snapshot: cache?.toSnapshot(),
      isFromCache: cache != null,
    );
  }

  factory GlobalWalletState.ready({
    required String userId,
    required CloudWalletSnapshot snapshot,
    WalletCacheEntry? cache,
  }) {
    return GlobalWalletState(
      status: GlobalWalletStatus.ready,
      userId: userId,
      snapshot: snapshot,
      cachedEntry: cache,
    );
  }

  factory GlobalWalletState.stale({
    required String userId,
    required WalletCacheEntry cacheEntry,
    WalletFailure? failure,
  }) {
    return GlobalWalletState(
      status: GlobalWalletStatus.stale,
      userId: userId,
      snapshot: cacheEntry.toSnapshot(),
      cachedEntry: cacheEntry,
      failure: failure,
      isFromCache: true,
    );
  }

  factory GlobalWalletState.walletMissing({
    required String userId,
    WalletFailure? failure,
  }) {
    return GlobalWalletState(
      status: GlobalWalletStatus.walletMissing,
      userId: userId,
      failure: failure,
    );
  }

  factory GlobalWalletState.failed({
    required WalletFailure failure,
    String? userId,
    WalletCacheEntry? cacheEntry,
  }) {
    return GlobalWalletState(
      status: GlobalWalletStatus.failed,
      userId: userId,
      failure: failure,
      cachedEntry: cacheEntry,
      snapshot: cacheEntry?.toSnapshot(),
      isFromCache: cacheEntry != null,
    );
  }

  bool get hasSnapshot => snapshot != null;

  bool get isStale => status == GlobalWalletStatus.stale;

  bool get isSyncing => status == GlobalWalletStatus.syncing;

  int? get coins => snapshot?.coins;

  GlobalWalletState copyWith({
    GlobalWalletStatus? status,
    String? userId,
    CloudWalletSnapshot? snapshot,
    WalletCacheEntry? cachedEntry,
    WalletFailure? failure,
    bool? isFromCache,
  }) {
    return GlobalWalletState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      snapshot: snapshot ?? this.snapshot,
      cachedEntry: cachedEntry ?? this.cachedEntry,
      failure: failure ?? this.failure,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}
